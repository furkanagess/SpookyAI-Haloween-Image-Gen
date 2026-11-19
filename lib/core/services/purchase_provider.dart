import 'package:flutter/foundation.dart';
import '../services/premium_service.dart';
import '../services/in_app_purchase_service.dart';
import '../services/android_purchase_service.dart';
import '../services/ios_purchase_service.dart';
import '../utils/platform_utils.dart';

class Pack {
  const Pack({
    required this.name,
    required this.tokens,
    required this.productId,
    required this.price,
    required this.note,
    this.isPremium = false,
    this.isPopular = false,
    this.features = const [],
  });
  final String name;
  final int tokens;
  final String productId; // App Store Product ID
  final String price; // display only
  final String note;
  final bool isPremium;

  /// Highlighted as the recommended pick (one token pack at most).
  final bool isPopular;
  final List<String> features;

  // Get real price from InAppPurchaseService
  String get realPrice {
    final product = InAppPurchaseService.getProductById(productId);
    // Store price is already localized ("$19.99", "₺49,99"). The bundled
    // fallback is a bare USD number, so give it its currency sign.
    return product?.price ?? '\$$price';
  }
}

class PurchaseProvider extends ChangeNotifier {
  // State variables
  List<Pack> _packs = [];
  bool _isPremium = false;
  int? _selectedIndex;
  bool _isLoading = false;

  // Getters
  List<Pack> get packs => List.unmodifiable(_packs);
  bool get isPremium => _isPremium;
  int? get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;

  bool _packsLoading = false;
  Future<void>? _packsFuture;

  /// True while store products are being fetched for the packs list.
  bool get packsLoading => _packsLoading;

  /// Store products (localized prices) are loaded, so packs can be bought.
  bool get storeReady =>
      _packs.isNotEmpty && InAppPurchaseService.products.isNotEmpty;

  /// Loads the packs and their store products if they are not loaded yet.
  /// Safe to call from anywhere (e.g. the post-onboarding paywall); concurrent
  /// calls share one request. [force] re-queries the store (Retry button).
  Future<void> ensurePacksLoaded({bool force = false}) {
    if (!force && storeReady) return Future.value();
    return _packsFuture ??= _loadPacks().whenComplete(
      () => _packsFuture = null,
    );
  }

  Future<void> _loadPacks() async {
    _packsLoading = true;
    notifyListeners();
    try {
      // Startup init may have failed (e.g. offline at launch). It returns
      // before subscribing to the purchase stream in that case, so retrying
      // it does not add a second listener.
      if (!InAppPurchaseService.isAvailable) {
        await InAppPurchaseService.initialize();
      }
      if (InAppPurchaseService.isAvailable &&
          InAppPurchaseService.products.isEmpty) {
        await InAppPurchaseService.forceReloadProducts();
      }
      await _loadPremiumStatus();
      _initializePacks();
    } catch (e) {
      debugPrint('PurchaseProvider: Failed to load packs: $e');
    } finally {
      _packsLoading = false;
      notifyListeners();
    }
  }

  // Initialize the provider
  Future<void> initialize() async {
    debugPrint('PurchaseProvider: Initializing...');
    await _initialize();
    await _loadPremiumStatus();
    _initializePacks();

    // Debug service status
    InAppPurchaseService.debugServiceStatus();

    // Test setup
    final setupOk = await testPurchaseSetup();
    if (!setupOk) {
      debugPrint('PurchaseProvider: WARNING - Purchase setup test failed!');
      debugPrint('PurchaseProvider: This may cause "product not found" errors');
    }
  }

  Future<void> _initialize() async {
    await InAppPurchaseService.initialize();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      _isPremium = await PremiumService.isPremiumUser();
      notifyListeners();
      debugPrint(
        'PurchaseProvider: Premium status loaded - isPremium: $_isPremium',
      );
    } catch (e) {
      _isPremium = false;
      notifyListeners();
      debugPrint('PurchaseProvider: Error loading premium status: $e');
    }
  }

  void _initializePacks() {
    if (PlatformUtils.isAndroid) {
      _packs = AndroidPurchaseService.getAndroidPacks();
      AndroidPurchaseService.debugAndroidPacks();
    } else {
      _packs = IOSPurchaseService.getIOSPacks();
      IOSPurchaseService.debugIOSPacks();
    }
    notifyListeners();
  }

  // Set selected index
  void setSelectedIndex(int? index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set premium status
  void setPremiumStatus(bool isPremium) {
    _isPremium = isPremium;
    notifyListeners();
  }

  // Buy a pack, returns true if purchase completed successfully
  Future<bool> buyPack(Pack pack) async {
    if (_isLoading) {
      debugPrint('PurchaseProvider: Already loading, skipping purchase');
      return false;
    }

    debugPrint(
      'PurchaseProvider: Starting purchase for ${pack.name} (${pack.productId})',
    );
    setLoading(true);

    try {
      // Check if service is available
      if (!InAppPurchaseService.isAvailable) {
        debugPrint('PurchaseProvider: In-app purchase not available');
        return false;
      }

      // Check if products are loaded
      if (InAppPurchaseService.products.isEmpty) {
        debugPrint(
          'PurchaseProvider: No products loaded, attempting to reload...',
        );
        final reloadSuccess = await InAppPurchaseService.forceReloadProducts();
        if (!reloadSuccess) {
          debugPrint('PurchaseProvider: Failed to reload products');
          debugPrint(
            'PurchaseProvider: Query error: ${InAppPurchaseService.queryProductError}',
          );
          return false;
        }
      }

      // Check if specific product is available
      if (!InAppPurchaseService.isProductAvailable(pack.productId)) {
        debugPrint('PurchaseProvider: Product ${pack.productId} not available');
        debugPrint(
          'PurchaseProvider: Available products: ${InAppPurchaseService.products.map((p) => p.id).join(', ')}',
        );
        return false;
      }

      final bool success = await InAppPurchaseService.purchaseProduct(
        pack.productId,
      );

      debugPrint(
        'PurchaseProvider: Purchase result for ${pack.name}: $success',
      );

      if (success) {
        debugPrint('PurchaseProvider: Purchase successful for ${pack.name}');

        // Handle premium subscription differently
        if (pack.isPremium) {
          await PremiumService.activatePremiumSubscription();
          setPremiumStatus(true);
        } else {
          // Regular token purchase - refresh token provider
          // This will be handled by the calling widget
        }

        return true;
      } else {
        debugPrint('PurchaseProvider: Purchase failed for ${pack.name}');
        debugPrint(
          'PurchaseProvider: Query error: ${InAppPurchaseService.queryProductError}',
        );
        debugPrint(
          'PurchaseProvider: Last purchase success: ${InAppPurchaseService.lastPurchaseSuccess}',
        );

        // Additional debugging for iOS
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          debugPrint(
            'PurchaseProvider: iOS platform - checking for timeout or user cancellation',
          );
        }

        return false;
      }
    } catch (e) {
      debugPrint('PurchaseProvider: Error during purchase: $e');
      debugPrint('PurchaseProvider: Stack trace: ${StackTrace.current}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    setLoading(true);

    try {
      await InAppPurchaseService.restorePurchases();
      debugPrint('PurchaseProvider: Purchases restored successfully');
    } catch (e) {
      debugPrint('PurchaseProvider: Error restoring purchases: $e');
    } finally {
      setLoading(false);
    }
  }

  // Get selected pack
  Pack? get selectedPack {
    if (_selectedIndex == null || _selectedIndex! >= _packs.length) {
      return null;
    }
    return _packs[_selectedIndex!];
  }

  // Check if a pack can be selected
  bool canSelectPack(Pack pack) {
    if (pack.isPremium && _isPremium) {
      return false; // Already premium user
    }
    return true;
  }

  // Get price per token for a pack
  String getPricePerToken(Pack pack) {
    if (PlatformUtils.isAndroid) {
      return AndroidPurchaseService.getPricePerToken(pack);
    } else {
      return IOSPurchaseService.getPricePerToken(pack);
    }
  }

  // Test method to verify purchase setup
  Future<bool> testPurchaseSetup() async {
    debugPrint('PurchaseProvider: Testing purchase setup...');

    // Check service availability
    if (!InAppPurchaseService.isAvailable) {
      debugPrint('PurchaseProvider: In-app purchase not available');
      return false;
    }

    // Check products
    if (InAppPurchaseService.products.isEmpty) {
      debugPrint('PurchaseProvider: No products loaded');
      return false;
    }

    // Check for our specific products
    final requiredProducts = [
      '10_token',
      '25_token',
      '60_token',
      '150_token',
      'spookyai_premium',
    ];
    final loadedProductIds = InAppPurchaseService.products
        .map((p) => p.id)
        .toSet();

    for (final productId in requiredProducts) {
      if (!loadedProductIds.contains(productId)) {
        debugPrint('PurchaseProvider: Missing product: $productId');
        return false;
      }
    }

    debugPrint('PurchaseProvider: All required products are available');
    return true;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
