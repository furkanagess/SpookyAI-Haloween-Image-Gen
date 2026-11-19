import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/environment_config.dart';

/// Result of asking the server whether this device may get the free tokens.
enum TrialDecision { granted, alreadyUsed, unknown }

/// Makes the free starter tokens a once-per-device gift, even across
/// uninstall/reinstall.
///
/// * Device id: Android `ANDROID_ID` (survives reinstall, resets on factory
///   reset); iOS a random UUID kept in the Keychain (survives reinstall).
/// * Server ledger: `POST <FAL_PROXY_URL>/trial/claim` stores a salted hash of
///   the id and answers whether this is the first claim (tool/fal_proxy).
class TrialGuardService {
  TrialGuardService._();

  static const _channel = MethodChannel('spookyai/device');
  static const _secure = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _kIosDeviceId = 'device_install_id_v1';

  @visibleForTesting
  static http.Client Function() clientFactory = http.Client.new;

  @visibleForTesting
  static Future<String?> Function()? deviceIdOverride;

  @visibleForTesting
  static Future<TrialDecision> Function()? claimOverride;

  static String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  static Future<String?> deviceId() async {
    if (deviceIdOverride != null) return deviceIdOverride!();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final id = await _channel.invokeMethod<String>('deviceId');
        return (id == null || id.isEmpty) ? null : id;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        var id = await _secure.read(key: _kIosDeviceId);
        if (id == null) {
          final r = Random.secure();
          id = List.generate(
            16,
            (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
          ).join();
          await _secure.write(key: _kIosDeviceId, value: id);
        }
        return id;
      }
    } catch (e) {
      debugPrint('TrialGuard: device id unavailable: $e');
    }
    return null;
  }

  /// Asks the server ledger. [TrialDecision.unknown] when there is no proxy,
  /// no network or the endpoint is not configured.
  static Future<TrialDecision> claim() async {
    if (claimOverride != null) return claimOverride!();
    final base = EnvironmentConfig.falProxyUrl;
    if (base == null) return TrialDecision.unknown;
    final id = await deviceId();
    if (id == null) return TrialDecision.unknown;
    final client = clientFactory();
    try {
      final token = EnvironmentConfig.falProxyToken;
      final res = await client
          .post(
            Uri.parse('$base/trial/claim'),
            headers: {
              'content-type': 'application/json',
              if (token != null) 'x-app-token': token,
            },
            body: jsonEncode({'deviceId': id, 'platform': _platform}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return TrialDecision.unknown;
      final granted = (jsonDecode(res.body) as Map)['granted'];
      if (granted == true) return TrialDecision.granted;
      if (granted == false) return TrialDecision.alreadyUsed;
    } catch (e) {
      debugPrint('TrialGuard: claim failed: $e');
    } finally {
      client.close();
    }
    return TrialDecision.unknown;
  }
}
