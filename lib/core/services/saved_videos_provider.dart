import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// A video made with image to video. Only file names are stored: on iOS the
/// app container's path changes on update, so absolute paths would break.
class SavedVideo {
  const SavedVideo({
    required this.id,
    required this.motionPrompt,
    required this.createdAt,
    required this.videoFile,
    required this.posterFile,
    this.posterIsFrame = false,
  });

  final String id;
  final String motionPrompt;
  final DateTime createdAt;
  final String videoFile;
  final String posterFile;

  /// True when the poster is the clip's own first frame (what the detail
  /// screen shows). Older videos used the source picture until migrated.
  final bool posterIsFrame;

  SavedVideo withPoster(String file) => SavedVideo(
    id: id,
    motionPrompt: motionPrompt,
    createdAt: createdAt,
    videoFile: videoFile,
    posterFile: file,
    posterIsFrame: true,
  );

  /// What the video is called in My Videos and on its detail screen.
  String get title =>
      motionPrompt.trim().isEmpty ? 'Your video' : motionPrompt.trim();

  Map<String, dynamic> toJson() => {
    'id': id,
    'motionPrompt': motionPrompt,
    'createdAt': createdAt.toIso8601String(),
    'videoFile': videoFile,
    'posterFile': posterFile,
    'posterIsFrame': posterIsFrame,
  };

  factory SavedVideo.fromJson(Map<String, dynamic> json) => SavedVideo(
    id: json['id'] as String,
    motionPrompt: (json['motionPrompt'] as String?) ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    videoFile: json['videoFile'] as String,
    posterFile: json['posterFile'] as String,
    posterIsFrame: (json['posterIsFrame'] as bool?) ?? false,
  );
}

/// Keeps the user's videos inside the app (documents folder) with the source
/// picture as the poster, like the Photos tab does for pictures.
class SavedVideosProvider extends ChangeNotifier {
  static const String _key = 'saved_videos';
  static const String _autoExportKey = 'videos_auto_export';
  static const String _dirName = 'spooky_ai_videos';

  List<SavedVideo> _videos = <SavedVideo>[];
  Directory? _dir;
  bool _isLoading = false;
  bool _autoExport = false;

  List<SavedVideo> get videos => _videos;
  bool get isLoading => _isLoading;

  /// Whether a new video is also copied to the phone's photo library.
  bool get autoExport => _autoExport;

  static Future<Directory> _resolveDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/$_dirName');
  }

  String videoPath(SavedVideo v) => '${_dir!.path}/${v.videoFile}';
  String posterPath(SavedVideo v) => '${_dir!.path}/${v.posterFile}';

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _dir = await _resolveDir();
      final prefs = await SharedPreferences.getInstance();
      _autoExport = prefs.getBool(_autoExportKey) ?? false;
      final list = prefs.getStringList(_key) ?? const <String>[];
      final parsed = <SavedVideo>[];
      for (final s in list) {
        try {
          final v = SavedVideo.fromJson(jsonDecode(s) as Map<String, dynamic>);
          if (File(videoPath(v)).existsSync()) parsed.add(v);
        } catch (_) {}
      }
      parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _videos = parsed;
      // Older videos: replace the source-picture poster with the first frame.
      if (parsed.any((v) => !v.posterIsFrame)) unawaited(_migratePosters());
    } catch (_) {
      _videos = <SavedVideo>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setAutoExport(bool value) async {
    _autoExport = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoExportKey, value);
  }

  /// Stores [videoBytes] and returns the record. The poster is the clip's
  /// first frame, so My Videos shows what the detail screen plays;
  /// [posterBytes] (the source picture) is only the fallback. Exports to the
  /// photo library when [autoExport] is on.
  Future<SavedVideo> add({
    required Uint8List videoBytes,
    required Uint8List posterBytes,
    required String motionPrompt,
  }) async {
    final dir = _dir ??= await _resolveDir();
    if (!await dir.exists()) await dir.create(recursive: true);
    final ts = DateTime.now().millisecondsSinceEpoch;
    var video = SavedVideo(
      id: ts.toString(),
      motionPrompt: motionPrompt,
      createdAt: DateTime.now(),
      videoFile: 'spooky_video_$ts.mp4',
      posterFile: 'spooky_video_$ts.png',
    );
    await File(videoPath(video)).writeAsBytes(videoBytes);
    final frame = await _firstFrame(videoPath(video));
    if (frame != null) {
      video = video.withPoster('spooky_video_${ts}_frame.jpg');
      await File(posterPath(video)).writeAsBytes(frame);
    } else {
      await File(posterPath(video)).writeAsBytes(posterBytes);
    }
    _videos = [video, ..._videos];
    await _persist();
    notifyListeners();
    if (_autoExport) await exportToGallery(video);
    return video;
  }

  /// The clip's first frame as JPEG, or null when it cannot be read.
  static Future<Uint8List?> _firstFrame(String path) async {
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        timeMs: 0,
        quality: 85,
      );
      return bytes == null || bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _migratePosters() async {
    var changed = false;
    for (final old in List<SavedVideo>.of(_videos)) {
      if (old.posterIsFrame) continue;
      final frame = await _firstFrame(videoPath(old));
      if (frame == null) continue;
      final updated = old.withPoster('spooky_video_${old.id}_frame.jpg');
      try {
        await File(posterPath(updated)).writeAsBytes(frame);
        final previous = File(posterPath(old));
        if (await previous.exists()) await previous.delete();
      } catch (_) {
        continue;
      }
      _videos = [for (final v in _videos) v.id == old.id ? updated : v];
      changed = true;
    }
    if (changed) {
      await _persist();
      notifyListeners();
    }
  }

  /// Copies a video to the phone's photo library. Never throws.
  Future<bool> exportToGallery(SavedVideo video) async {
    try {
      try {
        if (!await Gal.hasAccess()) await Gal.requestAccess();
      } catch (_) {}
      await Gal.putVideo(videoPath(video));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> delete(String id) async {
    final match = _videos.where((v) => v.id == id).toList();
    if (match.isEmpty) return;
    for (final path in [videoPath(match.first), posterPath(match.first)]) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _videos = _videos.where((v) => v.id != id).toList();
    await _persist();
    notifyListeners();
  }

  /// Total size of all stored videos and posters, in bytes.
  Future<int> storageBytes() async {
    var total = 0;
    for (final v in _videos) {
      for (final path in [videoPath(v), posterPath(v)]) {
        try {
          total += await File(path).length();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<void> deleteAll() async {
    for (final v in List<SavedVideo>.of(_videos)) {
      await delete(v.id);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _videos.map((v) => jsonEncode(v.toJson())).toList(),
    );
  }
}
