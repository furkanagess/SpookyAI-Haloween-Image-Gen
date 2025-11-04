import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AdMobService {
  // iOS Ad Unit ID (updated)
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-3499593115543692/7580246775';

  // Android Ad Unit ID (updated)
  static const String _androidRewardedAdUnitId =
      'ca-app-pub-3499593115543692/4351448208';

  // Test IDs for development
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _dailyAdCountKey = 'daily_ad_count';
  static const String _lastResetTimeKey = 'last_reset_time';
  static const int _maxDailyAds = 5;
  static const double _tokenReward = 0.5;

  static RewardedAd? _rewardedAd;
  static bool _isAdLoaded = false;
  static bool _isAdLoading = false;

  /// Get the appropriate ad unit ID based on platform
  static String _getRewardedAdUnitId() {
    if (kDebugMode) {
      return _testRewardedAdUnitId;
    }

    if (Platform.isIOS) {
      return _iosRewardedAdUnitId;
    } else if (Platform.isAndroid) {
      return _androidRewardedAdUnitId;
    }

    // Fallback to Android for other platforms
    return _androidRewardedAdUnitId;
  }

  /// Initialize AdMob
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();

    if (kDebugMode) {
      // Enable test device for development
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: ['TEST_DEVICE_ID']),
      );
    }
  }

  /// Load a rewarded ad
  static Future<void> loadRewardedAd() async {
    if (_isAdLoading || _isAdLoaded) return;

    _isAdLoading = true;

    final adUnitId = _getRewardedAdUnitId();

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          _isAdLoading = false;
          debugPrint('🎯 AdMob: Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
          _isAdLoading = false;
          debugPrint('🎯 AdMob: Failed to load rewarded ad: $error');
        },
      ),
    );
  }

  /// Check and reset daily ad count if 24 hours have passed
  static Future<void> _checkAndResetDailyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastResetStr = prefs.getString(_lastResetTimeKey);

    if (lastResetStr == null) {
      // First time - initialize reset time
      await prefs.setString(_lastResetTimeKey, now.toIso8601String());
      await prefs.setInt(_dailyAdCountKey, 0);
      return;
    }

    final lastReset = DateTime.parse(lastResetStr);
    final nextReset = lastReset.add(const Duration(hours: 24));

    // Reset if 24 hours have passed
    if (now.isAfter(nextReset) || now.isAtSameMomentAs(nextReset)) {
      await prefs.setString(_lastResetTimeKey, now.toIso8601String());
      await prefs.setInt(_dailyAdCountKey, 0);
    }
  }

  /// Check if user can watch ads (24-hour period)
  static Future<bool> canWatchAdToday() async {
    await _checkAndResetDailyCount();
    final prefs = await SharedPreferences.getInstance();
    final dailyAdCount = prefs.getInt(_dailyAdCountKey) ?? 0;
    return dailyAdCount < _maxDailyAds;
  }

  /// Get remaining ads in current 24-hour period
  static Future<int> getRemainingAdsToday() async {
    await _checkAndResetDailyCount();
    final prefs = await SharedPreferences.getInstance();
    final dailyAdCount = prefs.getInt(_dailyAdCountKey) ?? 0;
    return _maxDailyAds - dailyAdCount;
  }

  /// Check if ad is available and ready to show
  static Future<bool> isAdAvailable() async {
    // Check if user can watch ads today
    final canWatch = await canWatchAdToday();
    if (!canWatch) {
      return false;
    }

    // Check if ad is loaded
    return _isAdLoaded && _rewardedAd != null;
  }

  /// Get time until next ad reset (24-hour period)
  static Future<Duration?> getTimeUntilReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString(_lastResetTimeKey);

    if (lastResetStr == null) {
      return null;
    }

    final lastReset = DateTime.parse(lastResetStr);
    final nextReset = lastReset.add(const Duration(hours: 24));
    final now = DateTime.now();

    if (now.isAfter(nextReset) || now.isAtSameMomentAs(nextReset)) {
      return Duration.zero;
    }

    return nextReset.difference(now);
  }

  /// Show rewarded ad
  static Future<bool> showRewardedAd({
    required Function(double) onRewardEarned,
    required Function(String) onAdFailed,
  }) async {
    // Check if user can watch ads today
    final canWatch = await canWatchAdToday();
    if (!canWatch) {
      final remainingAds = await getRemainingAdsToday();
      if (remainingAds <= 0) {
        final timeUntilReset = await getTimeUntilReset();
        if (timeUntilReset != null && timeUntilReset > Duration.zero) {
          final hours = timeUntilReset.inHours;
          final minutes = timeUntilReset.inMinutes % 60;
          onAdFailed(
            'Daily ad limit reached. Try again in ${hours}h ${minutes}m.',
          );
        } else {
          onAdFailed('Daily ad limit reached. Try again tomorrow.');
        }
      } else {
        onAdFailed('Daily ad limit reached (5 ads per day).');
      }
      return false;
    }

    // Check if ad is loaded
    if (!_isAdLoaded || _rewardedAd == null) {
      onAdFailed('Ad is not ready. Please try again later.');
      return false;
    }

    bool adWatched = false;

    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('🎯 AdMob: Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('🎯 AdMob: Rewarded ad dismissed');
        _rewardedAd?.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;

        // Load next ad
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('🎯 AdMob: Rewarded ad failed to show: $error');
        _rewardedAd?.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        onAdFailed('Failed to show ad: $error');
      },
    );

    _rewardedAd?.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint(
          '🎯 AdMob: User earned reward: ${reward.amount} ${reward.type}',
        );
        adWatched = true;

        // Update daily ad count
        await _incrementDailyAdCount();

        // Give token reward
        onRewardEarned(_tokenReward);
      },
    );

    return adWatched;
  }

  /// Increment daily ad count
  static Future<void> _incrementDailyAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_dailyAdCountKey) ?? 0;
    await prefs.setInt(_dailyAdCountKey, currentCount + 1);
  }

  /// Get daily ad statistics (24-hour period)
  static Future<Map<String, dynamic>> getDailyAdStats() async {
    await _checkAndResetDailyCount();
    final prefs = await SharedPreferences.getInstance();
    final dailyAdCount = prefs.getInt(_dailyAdCountKey) ?? 0;
    final remainingAds = _maxDailyAds - dailyAdCount;
    final timeUntilReset = await getTimeUntilReset();
    final isAdReady = await isAdAvailable();

    return {
      'adsWatchedToday': dailyAdCount,
      'remainingAds': remainingAds,
      'maxDailyAds': _maxDailyAds,
      'tokenReward': _tokenReward,
      'isAdReady': isAdReady,
      'timeUntilReset': timeUntilReset?.inMinutes,
      'canWatchAd': remainingAds > 0 && isAdReady,
    };
  }

  /// Preload ads for better user experience
  static Future<void> preloadAds() async {
    await loadRewardedAd();
  }

  /// Dispose resources
  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
    _isAdLoading = false;
  }
}
