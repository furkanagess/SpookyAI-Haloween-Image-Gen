import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/services/app_icon_service.dart';
import 'package:spooky_ai/core/theme/seasons/season_registry.dart';
import 'package:spooky_ai/core/theme/seasons/season_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('spookyai/app_icon');
  final calls = <MethodCall>[];
  String icon = 'halloween';

  setUp(() {
    calls.clear();
    icon = 'halloween';
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'isSupported':
              return true;
            case 'getIcon':
              return icon;
            case 'setIcon':
              icon = (call.arguments as Map)['icon'] as String;
              return null;
          }
          return null;
        });
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('every season has a bundled icon preview', () {
    for (final season in SeasonRegistry.all) {
      final path = AppIconService.previewAssets[season.id];
      expect(path, isNotNull, reason: '${season.id} has no app icon');
      expect(File(path!).existsSync(), isTrue, reason: path);
    }
  });

  test('sets and reads the icon by season name', () async {
    expect(await AppIconService.isSupported(), isTrue);
    expect(await AppIconService.current(), SeasonId.halloween);
    expect(await AppIconService.setIcon(SeasonId.christmas), isTrue);
    expect(calls.last.arguments, {'icon': 'christmas'});
    expect(await AppIconService.current(), SeasonId.christmas);
  });

  test('reports failure when the platform refuses', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'unsupported');
        });
    expect(await AppIconService.setIcon(SeasonId.christmas), isFalse);
    expect(await AppIconService.current(), SeasonId.halloween);
  });
}
