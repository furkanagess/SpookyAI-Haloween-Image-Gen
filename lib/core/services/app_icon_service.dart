import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../theme/seasons/season_theme.dart';

/// Switches the home-screen app icon between one icon per season.
///
/// Native side: `MainActivity.kt` (launcher activity-aliases) and
/// `AppDelegate.swift` (iOS alternate icons). The icon id sent over the
/// channel is the [SeasonId] name.
class AppIconService {
  AppIconService._();

  static const MethodChannel _channel = MethodChannel('spookyai/app_icon');

  /// In-app preview image for each season's launcher icon.
  static const Map<SeasonId, String> previewAssets = {
    SeasonId.halloween: 'assets/icons/app_icon.png',
    SeasonId.christmas: 'assets/icons/app_icon_christmas.png',
  };

  static bool get _platformHasIcons =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// True on Android/iOS. The row is shown there even if the native side
  /// fails to answer (e.g. after a hot restart without a native rebuild);
  /// a failed switch is reported when the user taps an icon.
  static Future<bool> isSupported() async {
    if (!_platformHasIcons) return false;
    if (defaultTargetPlatform == TargetPlatform.android) return true;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return true;
    }
  }

  /// The season whose icon is currently on the home screen (or will be,
  /// on Android, once the app goes to the background).
  static Future<SeasonId> current() async {
    if (!_platformHasIcons) return SeasonId.halloween;
    try {
      final name = await _channel.invokeMethod<String>('getIcon');
      return SeasonId.values.firstWhere(
        (s) => s.name == name,
        orElse: () => SeasonId.halloween,
      );
    } on PlatformException {
      return SeasonId.halloween;
    } on MissingPluginException {
      return SeasonId.halloween;
    }
  }

  /// Returns false when the platform refused the change.
  static Future<bool> setIcon(SeasonId season) async {
    if (!_platformHasIcons) return false;
    try {
      await _channel.invokeMethod<void>('setIcon', {'icon': season.name});
      return true;
    } on PlatformException catch (e) {
      debugPrint('AppIconService.setIcon failed: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
