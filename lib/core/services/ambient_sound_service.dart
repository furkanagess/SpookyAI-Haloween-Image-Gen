import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/seasons/season_theme.dart';

/// Loops the current season's background sound while the app is in the
/// foreground.
///
/// - One [AudioPlayer], created lazily the first time sound is needed.
/// - Ambient audio session: mixes with the user's music, does not take audio
///   focus and (on iOS) respects the silent switch.
/// - Pauses when the app leaves the foreground, resumes when it returns.
/// - Disabling releases the decoder (`stop`), so it costs nothing while off.
class AmbientSoundController extends ChangeNotifier
    with WidgetsBindingObserver {
  AmbientSoundController({AudioPlayer Function()? playerFactory})
    : _playerFactory = playerFactory ?? _defaultPlayer {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Season -> looping sound. Seasons without an entry stay silent.
  static const Map<SeasonId, String> soundAssets = {
    SeasonId.halloween: 'assets/sounds/halloween.mp3',
    SeasonId.christmas: 'assets/sounds/christmas.mp3',
  };

  static const _kEnabled = 'ambient_sound_enabled';
  static const _kVolume = 'ambient_sound_volume';
  static const double defaultVolume = 0.35;
  static const _fadeDuration = Duration(milliseconds: 700);
  static const _fadeSteps = 14;

  static AudioPlayer _defaultPlayer() => AudioPlayer(
    // Ambient: never request audio focus / activate the session ourselves.
    handleInterruptions: false,
    handleAudioSessionActivation: false,
    androidApplyAudioAttributes: true,
  );

  final AudioPlayer Function() _playerFactory;
  AudioPlayer? _player;
  bool _sessionConfigured = false;

  bool _enabled = true;
  double _volume = defaultVolume;
  SeasonId? _season;
  String? _loadedAsset;
  bool _foreground = true;
  bool _loaded = false;
  bool _disposed = false;
  Timer? _fadeTimer;

  /// Serialises player operations so rapid toggles/season changes can't
  /// interleave `setAsset`/`play`/`stop` calls.
  Future<void> _queue = Future.value();

  bool get enabled => _enabled;
  double get volume => _volume;
  bool get hasSoundForSeason =>
      _season != null && soundAssets.containsKey(_season);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_kEnabled) ?? true;
      _volume = (prefs.getDouble(_kVolume) ?? defaultVolume).clamp(0.0, 1.0);
    } catch (_) {}
    _loaded = true;
    if (!_disposed) notifyListeners();
    _sync();
  }

  /// Called whenever the active season may have changed.
  void setSeason(SeasonId season) {
    if (_season == season) return;
    _season = season;
    _sync();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    _sync();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabled, value);
    } catch (_) {}
  }

  /// Live volume change (slider drag). Call [saveVolume] when the drag ends.
  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    _fadeTimer?.cancel();
    _player?.setVolume(_volume);
    notifyListeners();
    _sync(); // starts at >0, releases at 0
  }

  Future<void> saveVolume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kVolume, _volume);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _sync();
  }

  bool get _shouldPlay =>
      _loaded && _enabled && _foreground && _volume > 0 && hasSoundForSeason;

  void _sync() {
    if (_disposed) return;
    _queue = _queue.then((_) => _apply()).catchError((Object e) async {
      debugPrint('AmbientSound: $e');
      // Drop the broken player; the next sync builds a fresh one.
      _fadeTimer?.cancel();
      final broken = _player;
      _player = null;
      _loadedAsset = null;
      try {
        await broken?.dispose();
      } catch (_) {}
    });
  }

  Future<void> _apply() async {
    if (_disposed) return;
    if (!_shouldPlay) {
      final player = _player;
      if (player == null) return;
      _fadeTimer?.cancel();
      if (!_enabled || !hasSoundForSeason || _volume == 0) {
        // Off for good: release the decoder and buffers.
        await player.stop();
        _loadedAsset = null;
      } else {
        // Backgrounded: keep the position, resume instantly later.
        await player.pause();
      }
      return;
    }

    final asset = soundAssets[_season]!;
    final player = _player ??= _playerFactory();
    await _configureSession();
    if (_loadedAsset != asset) {
      await player.stop();
      await player.setAsset(asset);
      await player.setLoopMode(LoopMode.one);
      _loadedAsset = asset;
    }
    if (player.playing) return;
    await player.setVolume(0);
    // play() completes only when playback stops; don't await it.
    unawaited(player.play());
    _fadeIn(player);
  }

  void _fadeIn(AudioPlayer player) {
    _fadeTimer?.cancel();
    var step = 0;
    _fadeTimer = Timer.periodic(
      Duration(microseconds: _fadeDuration.inMicroseconds ~/ _fadeSteps),
      (t) {
        step++;
        final v = _volume * (step / _fadeSteps);
        player.setVolume(v);
        if (step >= _fadeSteps) t.cancel();
      },
    );
  }

  Future<void> _configureSession() async {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.ambient,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.game,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
          androidWillPauseWhenDucked: false,
        ),
      );
    } catch (e) {
      debugPrint('AmbientSound: session config failed: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _fadeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _player?.dispose();
    super.dispose();
  }
}
