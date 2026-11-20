import 'package:flutter/foundation.dart';
import 'purchase_provider.dart';
import '../utils/platform_utils.dart';

/// Android-specific purchase service
/// Handles Android packages based on Google Play Console configuration
class AndroidPurchaseService {
  AndroidPurchaseService._();

  /// Get Android-specific packages based on Google Play Console
  static List<Pack> getAndroidPacks() {
    return [
      // Premium Subscription Package (at the top)
      // Note: Real price will be fetched from Google Play Console via pack.realPrice
      const Pack(
        name: 'SpookyAI Premium',
        tokens: 50,
        productId: 'spookyai_premium',
        price: '4.99', // Fallback price - real price comes from Google Play
        note: 'Monthly subscription with exclusive benefits',
        isPremium: true,
        features: [
          '50 tokens per month',
          'Access to all prompts',
          'Priority AI processing',
        ],
      ),
      // Android Token Packs - biggest first (Based on Google Play Console
      // screenshot for prices).
      const Pack(
        name: '150 Token',
        tokens: 150,
        productId: '150_token',
        price: '1.000.00',
        note: 'For power users 💀',
      ),
      const Pack(
        name: '60 Token',
        tokens: 60,
        productId: '60_token',
        price: '500.00',
        note: 'Most popular choice 🧙',
        isPopular: true,
      ),
      const Pack(
        name: '25 Token',
        tokens: 25,
        productId: '25_token',
        price: '250.00',
        note: 'A nice step up for regular creators 👻',
      ),
      const Pack(
        name: '10 Token',
        tokens: 10,
        productId: '10_token',
        price: '125.00',
        note: 'Great for small trials 🎃',
      ),
    ];
  }

  /// Get Android-specific product IDs
  static Set<String> getAndroidProductIds() {
    return {
      '10_token',
      '25_token',
      '60_token',
      '150_token',
      'spookyai_premium',
    };
  }

  /// Get price per token for Android (using TRY)
  static String getPricePerToken(Pack pack) {
    final double total = double.tryParse(pack.price) ?? 0;
    if (pack.tokens == 0 || total == 0) return '-';
    final double per = total / pack.tokens;
    return '${per.toStringAsFixed(2)} TRY/token';
  }

  /// Check if running on Android
  static bool get isAndroid => PlatformUtils.isAndroid;

  /// Debug info for Android packages
  static void debugAndroidPacks() {
    if (!isAndroid) return;

    debugPrint('=== Android Purchase Service Debug ===');
    debugPrint('Platform: Android');
    final packs = getAndroidPacks();
    debugPrint('Android Packages (${packs.length}):');
    for (final pack in packs) {
      debugPrint(
        '  • ${pack.name}: TRY ${pack.price} (${pack.tokens} tokens) - ${getPricePerToken(pack)}',
      );
    }
    debugPrint('Product IDs: ${getAndroidProductIds()}');
    debugPrint('=====================================');
  }
}
