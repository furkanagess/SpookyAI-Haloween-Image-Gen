import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for secrets and endpoints. **No secret may live in source.**
///
/// Resolution order for every value: compile-time `--dart-define`, then an
/// optional `.env` loaded at runtime (development only; the file is no longer
/// bundled into the app). There is deliberately no hard-coded fallback.
///
/// Two ways to reach fal:
///  * **Proxy (recommended for release):** set `FAL_PROXY_URL` (and optionally
///    `FAL_PROXY_TOKEN`). The real fal key lives only on the proxy
///    (`tool/fal_proxy`), never in the app binary.
///  * **Direct (development):** set `FAL_AI_API_KEY`. Anything compiled into an
///    app can be extracted, so never ship a build with this set.
class EnvironmentConfig {
  EnvironmentConfig._();

  static const String _keyDefine = String.fromEnvironment('FAL_AI_API_KEY');
  static const String _proxyDefine = String.fromEnvironment('FAL_PROXY_URL');
  static const String _tokenDefine = String.fromEnvironment('FAL_PROXY_TOKEN');

  static const String _rcIosDefine = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const String _rcAndroidDefine = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );

  // RevenueCat *public* SDK keys. RevenueCat designs these to ship inside
  // the app (they can only read offerings / make purchases for this app), so
  // they are not secrets and live here as defaults: a plain `flutter run`
  // is always configured. A --dart-define or .env value still overrides.
  static const String _rcIosDefault = 'appl_EfsuPbaYUuYFriWAOYEJSphnmYU';
  static const String _rcAndroidDefault = 'goog_doAKnxYNMYptByNGrUpwkePeKZY';

  /// RevenueCat public SDK key for the App Store app (appl_...).
  static String get revenueCatIosKey =>
      _pick(_rcIosDefine, 'REVENUECAT_IOS_KEY') ?? _rcIosDefault;

  /// RevenueCat public SDK key for the Play Store app (goog_...).
  static String get revenueCatAndroidKey =>
      _pick(_rcAndroidDefine, 'REVENUECAT_ANDROID_KEY') ?? _rcAndroidDefault;

  static String? _dotenv(String name) {
    try {
      if (!dotenv.isInitialized) return null;
      final v = dotenv.env[name];
      return (v == null || v.trim().isEmpty) ? null : v.trim();
    } catch (_) {
      return null;
    }
  }

  static String? _pick(String define, String name) =>
      define.trim().isNotEmpty ? define.trim() : _dotenv(name);

  /// Direct fal key (development only). Null when not configured.
  static String? get falAiApiKey => _pick(_keyDefine, 'FAL_AI_API_KEY');

  /// Base URL of the fal proxy, without a trailing slash.
  static String? get falProxyUrl {
    final v = _pick(_proxyDefine, 'FAL_PROXY_URL');
    if (v == null) return null;
    return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
  }

  /// Optional shared token the proxy checks (`X-App-Token`). It limits
  /// drive-by use; it is not a substitute for server-side limits.
  static String? get falProxyToken => _pick(_tokenDefine, 'FAL_PROXY_TOKEN');

  static bool get usesFalProxy => falProxyUrl != null;

  /// Host that serves the fal queue API (the proxy mirrors its paths).
  static String get falQueueBase => falProxyUrl ?? 'https://queue.fal.run';

  /// Headers that authenticate a fal request in the active mode.
  /// Throws a clear message when neither a proxy nor a key is configured.
  static Map<String, String> falAuthHeaders() {
    if (usesFalProxy) {
      final token = falProxyToken;
      return {if (token != null) 'X-App-Token': token};
    }
    final key = falAiApiKey;
    if (key == null) {
      throw StateError(
        'FAL is not configured: set FAL_PROXY_URL (release) or '
        'FAL_AI_API_KEY via --dart-define (development).',
      );
    }
    return {'Authorization': 'Key $key'};
  }

  /// Check if image generation can reach fal at all.
  static bool get isFalAiKeyAvailable => usesFalProxy || falAiApiKey != null;

  /// Get all missing required configuration.
  static List<String> getMissingApiKeys() {
    return [if (!isFalAiKeyAvailable) 'FAL_PROXY_URL or FAL_AI_API_KEY'];
  }

  /// Validate all required configuration.
  static bool validateApiKeys() => getMissingApiKeys().isEmpty;

  /// Debug-only hint printed at startup.
  static void debugReport() {
    if (!kDebugMode) return;
    if (!isFalAiKeyAvailable) {
      debugPrint(
        'Warning: no fal configuration. Run with '
        '--dart-define=FAL_AI_API_KEY=... (dev) or FAL_PROXY_URL=... (release).',
      );
    } else if (!usesFalProxy) {
      debugPrint('Using a direct fal key (development mode).');
    }
  }
}
