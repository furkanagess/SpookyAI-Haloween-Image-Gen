import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Funnel analytics and crash reporting. Every call is a no-op if Firebase
/// failed to start, and never throws. Collection is off in debug builds.
///
/// Funnel: onboarding_complete -> first_generation -> generation ->
/// image_saved -> image_shared -> paywall_view -> purchase.
class AnalyticsService {
  AnalyticsService._();

  static bool _ready = false;

  /// `--dart-define=ANALYTICS_DEBUG=true` turns collection on in debug builds
  /// so events and crashes can be checked from a simulator.
  static const _forceInDebug = bool.fromEnvironment('ANALYTICS_DEBUG');

  /// `--dart-define=ANALYTICS_SELF_TEST=true` sends one test event and one
  /// non-fatal error at startup. `=crash` also forces a native crash after
  /// 8 seconds (Crashlytics uploads it on the next launch). Debug only.
  static const _selfTest = String.fromEnvironment('ANALYTICS_SELF_TEST');

  static Future<void> init() async {
    try {
      final enabled = !kDebugMode || _forceInDebug;
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(enabled);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      _ready = true;
      if (kDebugMode && _selfTest.isNotEmpty) await _runSelfTest();
    } catch (e) {
      debugPrint('Analytics init failed: $e');
    }
  }

  static Future<void> _runSelfTest() async {
    final stamp = DateTime.now().toIso8601String();
    await log('analytics_self_test', {'at': stamp});
    await FirebaseCrashlytics.instance.log('self-test breadcrumb $stamp');
    await FirebaseCrashlytics.instance.recordError(
      StateError('Crashlytics self-test (non-fatal) $stamp'),
      StackTrace.current,
      reason: 'analytics self-test',
    );
    debugPrint('ANALYTICS_SELF_TEST: event + non-fatal sent ($stamp)');
    if (_selfTest == 'crash') {
      Future.delayed(const Duration(seconds: 8), () {
        debugPrint('ANALYTICS_SELF_TEST: forcing native crash');
        FirebaseCrashlytics.instance.crash();
      });
    }
  }

  /// Screen-view tracking for MaterialApp.navigatorObservers. Returns a new
  /// observer each call: MaterialApp is rebuilt with a new key on season or
  /// theme changes, and one observer must never sit on two Navigators.
  static List<NavigatorObserver> navigatorObservers() => _ready
      ? [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)]
      : const [];

  static Future<void> log(String name, [Map<String, Object>? params]) async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance
          .logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics log failed ($name): $e');
    }
  }

  static Future<void> recordError(Object error, StackTrace? stack,
      {String? reason}) async {
    if (!_ready) return;
    try {
      await FirebaseCrashlytics.instance
          .recordError(error, stack, reason: reason);
    } catch (_) {}
  }

  // Funnel events. Keep names stable: dashboards depend on them.
  static Future<void> onboardingComplete() => log('onboarding_complete');

  static const _firstGenKey = 'analytics_first_generation_logged';

  static Future<void> generation({
    required String kind,
    required bool success,
  }) async {
    await log('generation', {'kind': kind, 'success': success ? 1 : 0});
    if (!success || !_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_firstGenKey) ?? false) return;
      await prefs.setBool(_firstGenKey, true);
      await log('first_generation', {'kind': kind});
    } catch (_) {}
  }

  static Future<void> imageSaved() => log('image_saved');

  static Future<void> imageShared(String kind) =>
      log('image_shared', {'kind': kind});

  static Future<void> paywallView(String source) =>
      log('paywall_view', {'source': source});

  static Future<void> purchase(String productId) =>
      log('purchase_complete', {'product_id': productId});
}
