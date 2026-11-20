import 'dart:async';
import 'analytics_service.dart';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/environment_config.dart';
import 'premium_service.dart';
import 'token_service.dart';

/// Store product as the UI needs it (id + localized price).
class StoreProductInfo {
  const StoreProductInfo(this.id, this.price, this.product);

  /// Base product id (Play base plan suffix such as `:monthly` stripped).
  final String id;

  /// Localized price string, e.g. "₺49,99".
  final String price;
  final StoreProduct product;
}

/// Purchases through RevenueCat. The public API is the same one the old
/// in_app_purchase implementation exposed, so callers did not change.
class InAppPurchaseService {
  InAppPurchaseService._();

  /// Entitlement identifier configured in the RevenueCat dashboard.
  static const String premiumEntitlement = 'premium';
  static const String premiumProductId = 'spookyai_premium';

  static const Map<String, int> _productTokenMap = {
    '10_token': 10,
    '25_token': 25,
    '60_token': 60,
    '150_token': 150,
  };

  static final List<StoreProductInfo> _products = [];
  static bool _isAvailable = false;
  static bool _configured = false;
  static bool _purchasePending = false;
  static String? _queryProductError;
  static bool _lastPurchaseSuccess = false;
  static bool _lastPurchaseCancelled = false;

  static bool get isAvailable => _isAvailable;
  static bool get purchasePending => _purchasePending;
  static bool get lastPurchaseSuccess => _lastPurchaseSuccess;
  static bool get lastPurchaseCancelled => _lastPurchaseCancelled;
  static String? get queryProductError => _queryProductError;
  static List<StoreProductInfo> get products => _products;

  static String _baseId(String id) => id.split(':').first;

  static Future<void> initialize() async {
    if (_isAvailable) return;
    try {
      if (!_configured) {
        final key = Platform.isIOS
            ? EnvironmentConfig.revenueCatIosKey
            : EnvironmentConfig.revenueCatAndroidKey;
        await Purchases.setLogLevel(
          kDebugMode ? LogLevel.debug : LogLevel.warn,
        );
        await Purchases.configure(PurchasesConfiguration(key));
        Purchases.addCustomerInfoUpdateListener(_syncPremium);
        _configured = true;
      }
      _isAvailable = true;
      await _loadProducts();
      await _syncPremium(await Purchases.getCustomerInfo());
    } catch (e) {
      _queryProductError = e.toString();
      debugPrint('InAppPurchaseService: init failed: $e');
    }
  }

  static Future<bool> _loadProducts() async {
    try {
      final consumables = await Purchases.getProducts(
        _productTokenMap.keys.toList(),
        productCategory: ProductCategory.nonSubscription,
      );
      final subs = await Purchases.getProducts([
        premiumProductId,
      ], productCategory: ProductCategory.subscription);
      _products
        ..clear()
        ..addAll(
          [...consumables, ...subs].map(
            (p) => StoreProductInfo(_baseId(p.identifier), p.priceString, p),
          ),
        );
      _queryProductError = _products.isEmpty ? 'No products found' : null;
      debugPrint(
        'InAppPurchaseService: loaded ${_products.map((p) => p.id).join(', ')}',
      );
      return _products.isNotEmpty;
    } catch (e) {
      _queryProductError = e.toString();
      debugPrint('InAppPurchaseService: product load failed: $e');
      return false;
    }
  }

  /// Keeps the local premium flag in step with the RevenueCat entitlement.
  static Future<void> _syncPremium(CustomerInfo info) async {
    final ent = info.entitlements.active[premiumEntitlement];
    if (ent == null) return;
    final end = ent.expirationDate != null
        ? DateTime.tryParse(ent.expirationDate!)
        : null;
    await PremiumService.setPremiumStatus(
      isPremium: true,
      startDate: DateTime.tryParse(ent.latestPurchaseDate) ?? DateTime.now(),
      endDate: end ?? DateTime.now().add(const Duration(days: 30)),
    );
    // New purchase or renewal → new latestPurchaseDate → +50 tokens, once.
    final granted = await TokenService.grantPremiumTokensForPeriod(
      ent.latestPurchaseDate,
    );
    if (granted) {
      debugPrint(
        'InAppPurchaseService: +${TokenService.premiumTokensPerPeriod} '
        'Premium tokens for period ${ent.latestPurchaseDate}',
      );
    }
  }

  static Future<bool> purchaseProduct(String productId) async {
    _lastPurchaseSuccess = false;
    _lastPurchaseCancelled = false;
    if (!_isAvailable || _purchasePending) return false;
    final item = getProductById(productId);
    if (item == null) {
      _queryProductError = 'Product $productId not available';
      return false;
    }

    _purchasePending = true;
    try {
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(item.product),
      );
      final tokens = _productTokenMap[productId];
      if (tokens != null) {
        await TokenService.addTokens(tokens.toDouble());
      } else if (productId == premiumProductId) {
        if (result.customerInfo.entitlements.active.containsKey(
          premiumEntitlement,
        )) {
          await PremiumService.activatePremiumSubscription();
          await _syncPremium(result.customerInfo);
        }
      }
      _lastPurchaseSuccess = true;
      unawaited(AnalyticsService.purchase(productId));
      return true;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      _lastPurchaseCancelled =
          code == PurchasesErrorCode.purchaseCancelledError;
      _queryProductError = _lastPurchaseCancelled ? 'cancelled' : e.message;
      debugPrint('InAppPurchaseService: purchase failed: $code ${e.message}');
      return false;
    } finally {
      _purchasePending = false;
    }
  }

  /// Kept for compatibility. Consumables are never re-granted on restore.
  static void enableConsumableGrantOnNextRestore() {}

  /// Restores the premium subscription (consumables cannot be restored).
  static Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    try {
      await _syncPremium(await Purchases.restorePurchases());
    } catch (e) {
      debugPrint('InAppPurchaseService: restore failed: $e');
    }
  }

  static StoreProductInfo? getProductById(String productId) {
    for (final p in _products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  static int? getTokensForProduct(String productId) =>
      _productTokenMap[productId];

  static void debugServiceStatus() {
    debugPrint(
      'InAppPurchaseService: available=$_isAvailable pending=$_purchasePending '
      'products=${_products.map((p) => p.id).toList()} error=$_queryProductError',
    );
  }

  static Future<bool> forceReloadProducts() async {
    if (!_isAvailable) return false;
    return _loadProducts();
  }

  static bool isProductAvailable(String productId) =>
      getProductById(productId) != null;

  static void resetPurchaseState() {
    _purchasePending = false;
    _lastPurchaseSuccess = false;
    _lastPurchaseCancelled = false;
    _queryProductError = null;
  }

  static Map<String, dynamic> getPurchaseState() => {
    'isAvailable': _isAvailable,
    'purchasePending': _purchasePending,
    'lastPurchaseSuccess': _lastPurchaseSuccess,
    'lastPurchaseCancelled': _lastPurchaseCancelled,
    'queryProductError': _queryProductError,
    'productsCount': _products.length,
  };
}
