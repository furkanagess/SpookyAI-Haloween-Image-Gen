import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spooky_ai/core/services/ambient_sound_service.dart';
import 'package:spooky_ai/core/theme/seasons/season_registry.dart';
import 'package:spooky_ai/core/theme/seasons/season_theme.dart';

class FakePlayer extends Fake implements AudioPlayer {
  final log = <String>[];
  bool _playing = false;
  String? asset;
  double vol = 1;

  @override
  bool get playing => _playing;
  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async {
    asset = assetPath;
    log.add('asset:$assetPath');
    return null;
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async {}
  @override
  Future<void> setVolume(double volume) async => vol = volume;
  @override
  Future<void> play() async {
    _playing = true;
    log.add('play');
  }

  @override
  Future<void> pause() async {
    _playing = false;
    log.add('pause');
  }

  @override
  Future<void> stop() async {
    if (_playing || asset != null) log.add('stop');
    _playing = false;
  }

  @override
  Future<void> dispose() async {}
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakePlayer player;
  late AmbientSoundController sound;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    player = FakePlayer();
    sound = AmbientSoundController(playerFactory: () => player);
    await sound.load();
  });

  tearDown(() => sound.dispose());

  test('every season has a bundled sound', () {
    for (final s in SeasonRegistry.all) {
      final path = AmbientSoundController.soundAssets[s.id];
      expect(path, isNotNull, reason: '${s.id} has no sound');
      expect(File(path!).existsSync(), isTrue, reason: path);
    }
  });

  test('plays the season sound and switches with the season', () async {
    sound.setSeason(SeasonId.halloween);
    await settle();
    expect(player.asset, 'assets/sounds/halloween.mp3');
    expect(player.playing, isTrue);

    sound.setSeason(SeasonId.christmas);
    await settle();
    expect(player.asset, 'assets/sounds/christmas.mp3');
    expect(player.playing, isTrue);
  });

  test('pauses in background and resumes in foreground', () async {
    sound.setSeason(SeasonId.halloween);
    await settle();
    sound.didChangeAppLifecycleState(AppLifecycleState.paused);
    await settle();
    expect(player.playing, isFalse);
    expect(player.log.last, 'pause');
    sound.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await settle();
    expect(player.playing, isTrue);
  });

  test('disabling stops and persists; volume persists', () async {
    sound.setSeason(SeasonId.halloween);
    await settle();
    await sound.setEnabled(false);
    await settle();
    expect(player.playing, isFalse);
    expect(player.log.last, 'stop');

    sound.setVolume(0.8);
    await sound.saveVolume();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ambient_sound_enabled'), isFalse);
    expect(prefs.getDouble('ambient_sound_volume'), 0.8);
  });
}
