import 'dart:async';
import 'analytics_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';

class SavedImage {
  final String id;
  final String prompt;
  final DateTime createdAt;
  final String filePath;
  final bool isImageToImage;
  final String? originalImagePath;

  SavedImage({
    required this.id,
    required this.prompt,
    required this.createdAt,
    required this.filePath,
    this.isImageToImage = false,
    this.originalImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'createdAt': createdAt.toIso8601String(),
      'filePath': filePath,
      'isImageToImage': isImageToImage,
      'originalImagePath': originalImagePath,
    };
  }

  factory SavedImage.fromJson(Map<String, dynamic> json) {
    return SavedImage(
      id: json['id'],
      prompt: json['prompt'],
      createdAt: DateTime.parse(json['createdAt']),
      filePath: json['filePath'],
      isImageToImage: json['isImageToImage'] ?? false,
      originalImagePath: json['originalImagePath'],
    );
  }
}

class ImageStorageService {
  static const String _imagesKey = 'saved_images';
  static const String _imagesDirectory = 'spooky_ai_images';

  /// The folder that holds the pictures. Resolved on every call: on iOS the
  /// app container's path changes when the app is updated, so an absolute
  /// path stored earlier would stop working.
  static Future<Directory> _imagesDir() async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory('${directory.path}/$_imagesDirectory');
  }

  /// Copies a picture to the phone's photo library (asks for permission).
  /// Never throws; returns whether it worked.
  static Future<bool> exportToGallery(Uint8List bytes, {String? name}) async {
    try {
      // gal asks only for what it needs: add-only on iOS, legacy storage on
      // Android 9 and below, nothing on newer Android.
      try {
        if (!await Gal.hasAccess()) {
          await Gal.requestAccess();
        }
      } catch (_) {}
      await Gal.putImageBytes(
        bytes,
        name: name ?? 'spooky_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      unawaited(AnalyticsService.imageSaved());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Saves a picture inside the app (always) and, when [exportToGallery] is
  /// true, also to the phone's photo library. Pictures are written to the
  /// documents folder, which survives closing the app and updates.
  static Future<String> saveImage({
    required Uint8List imageBytes,
    required String prompt,
    bool isImageToImage = false,
    String? originalImagePath,
    bool exportToGallery = true,
  }) async {
    try {
      final imagesDir = await _imagesDir();

      // Create directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'spooky_creation_$timestamp.png';
      final filePath = '${imagesDir.path}/$filename';

      // Save image to local storage
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Optional export to the photo library (non-fatal on failure).
      if (exportToGallery) {
        await ImageStorageService.exportToGallery(imageBytes, name: filename);
      }

      // Create saved image record
      final savedImage = SavedImage(
        id: timestamp.toString(),
        prompt: prompt,
        createdAt: DateTime.now(),
        filePath: filePath,
        isImageToImage: isImageToImage,
        originalImagePath: originalImagePath,
      );

      // Save metadata to SharedPreferences
      await _saveImageMetadata(savedImage);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  /// Get all saved images
  static Future<List<SavedImage>> getSavedImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = prefs.getStringList(_imagesKey) ?? [];
      final dir = await _imagesDir();

      // Re-point every record at the current folder (by file name) and drop
      // records whose file is really gone, so the gallery never shows holes.
      final kept = <SavedImage>[];
      var changed = false;
      for (final json in imagesJson) {
        final img = SavedImage.fromJson(jsonDecode(json));
        final name = img.filePath.split('/').last;
        final path = '${dir.path}/$name';
        if (!await File(path).exists()) {
          changed = true;
          continue;
        }
        if (path != img.filePath) changed = true;
        kept.add(
          SavedImage(
            id: img.id,
            prompt: img.prompt,
            createdAt: img.createdAt,
            filePath: path,
            isImageToImage: img.isImageToImage,
            originalImagePath: img.originalImagePath,
          ),
        );
      }
      if (changed) await _saveImagesMetadata(kept);
      return kept;
    } catch (e) {
      return [];
    }
  }

  /// Delete an image
  static Future<bool> deleteImage(String imageId) async {
    try {
      final images = await getSavedImages();
      final imageIndex = images.indexWhere((img) => img.id == imageId);

      if (imageIndex == -1) return false;

      final image = images[imageIndex];

      // Delete file from storage
      final file = File(image.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from metadata
      images.removeAt(imageIndex);
      await _saveImagesMetadata(images);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get image bytes from file path
  static Future<Uint8List?> getImageBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Share an image
  static Future<bool> shareImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Note: share_plus will be used in the UI layer
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Save image metadata to SharedPreferences
  static Future<void> _saveImageMetadata(SavedImage image) async {
    final images = await getSavedImages();
    images.insert(0, image); // Add to beginning for newest first
    await _saveImagesMetadata(images);
  }

  /// Save all images metadata to SharedPreferences
  static Future<void> _saveImagesMetadata(List<SavedImage> images) async {
    final prefs = await SharedPreferences.getInstance();
    final imagesJson = images.map((img) => jsonEncode(img.toJson())).toList();
    await prefs.setStringList(_imagesKey, imagesJson);
  }

  /// Clear all saved images
  static Future<void> clearAllImages() async {
    try {
      // Delete all files
      final images = await getSavedImages();
      for (final image in images) {
        final file = File(image.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear metadata
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_imagesKey);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get storage usage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final images = await getSavedImages();
      int totalSize = 0;

      for (final image in images) {
        final file = File(image.filePath);
        if (await file.exists()) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return {
        'count': images.length,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      return {'count': 0, 'totalSize': 0, 'totalSizeMB': '0.00'};
    }
  }
}
