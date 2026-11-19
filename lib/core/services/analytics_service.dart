import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Funnel analytics and crash reporting. Every call is a no-op if Firebase
/// failed to start, and never throws. Collection is off in debug builds.
///
/// Funnel: onboarding_complete -> first_generation -> generation ->
/// image_saved -> image_shared -> paywall_view -> purchase.
class AnalyticsService {
  AnalyticsService._();

  static bool _ready = false;

  static Future<void> init() async {
    try {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      await FirebaseAnalytics.instance
          .setAnalyticsCollectionEnabled(!kDebugMode);

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      _ready = true;
    } catch (e) {
      debugPrint('Analytics init failed: $e');
    }
  }

  static FirebaseAnalyticsObserver? _observer;

  /// Screen-view tracking for MaterialApp.navigatorObservers.
  static FirebaseAnalyticsObserver? get observer => _ready
      ? _observer ??=
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)
      : null;

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
