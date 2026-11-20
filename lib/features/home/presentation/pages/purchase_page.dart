import 'dart:async';
import '../../../../core/services/analytics_service.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/purchase_provider.dart';
import '../../../../core/services/in_app_purchase_service.dart';
import '../../../../core/utils/platform_utils.dart';
import '../widgets/purchase_success_dialog.dart';
import '../widgets/purchase_failed_dialog.dart';
import '../../../../core/services/promo_code_service.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/theme/seasons/season_theme.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage();

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final TextEditingController _promoController = TextEditingController();
  bool _isRedeeming = false;
  int _packPage = 0;
  int _fanStart = 0;
  @override
  void initState() {
    super.initState();
    unawaited(AnalyticsService.paywallView('purchase_page'));
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<PurchaseProvider>();
      await provider.initialize();
      if (!mounted) return;
      // Preselect the recommended pack so buying is a single tap.
      // Start on the most popular pack (60), centred in the fan.
      final order = _tokenOrder(provider);
      if (order.isEmpty) return;
      final popular = order.indexWhere((i) => provider.packs[i].isPopular);
      final start = popular == -1 ? 0 : popular;
      setState(() => _packPage = _fanStart = start);
      provider.setSelectedIndex(order[start]);
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _buy(Pack pack, PurchaseProvider provider) async {
    if (provider.isLoading) return;

    try {
      debugPrint('PurchasePage: Starting purchase for ${pack.name}');
      final bool success = await provider.buyPack(pack);
      debugPrint('PurchasePage: Purchase result: $success');

      if (!mounted) return;

      if (success) {
        debugPrint('PurchasePage: Showing success dialog for ${pack.name}');
        if (pack.isPremium) {
          await showPurchaseSuccessDialog(
            context,
            tokensAdded: pack.tokens,
            isPremiumSubscription: true,
          );
        } else {
          // Refresh token provider for regular purchases
          final tokenProvider = context.read<TokenProvider>();
          await tokenProvider.refreshBalance();
          await showPurchaseSuccessDialog(context, tokensAdded: pack.tokens);
        }
      } else {
        debugPrint('PurchasePage: Purchase failed for ${pack.name}');

        // Check if this was a user cancellation (don't show error dialog)
        final bool isUserCancelled =
            InAppPurchaseService.lastPurchaseCancelled ||
            (InAppPurchaseService.queryProductError?.contains('cancelled') ??
                false);

        if (!isUserCancelled) {
          await PurchaseFailedDialog.show(
            context,
            reason: 'Purchase was not completed. Please try again.',
          );
        } else {
          debugPrint(
            'PurchasePage: User cancelled purchase - not showing error dialog',
          );
        }
      }
    } catch (e) {
      debugPrint('PurchasePage: Exception during purchase: $e');
      if (mounted) {
        String reason = 'An unexpected error occurred during purchase.';

        // Provide more specific error messages based on the error type
        if (e.toString().contains('network')) {
          reason =
              'Network connection failed. Please check your internet and try again.';
        } else if (e.toString().contains('payment')) {
          reason =
              'Payment processing failed. Please verify your payment method.';
        } else if (e.toString().contains('product')) {
          reason = 'Product not available. Please try again later.';
        } else if (e.toString().contains('user') ||
            e.toString().contains('cancelled')) {
          reason = 'Purchase was cancelled by user.';
        }

        await PurchaseFailedDialog.show(context, reason: reason);
      }
    }
  }

  Future<void> _restorePurchases(PurchaseProvider provider) async {
    try {
      await provider.restorePurchases();
      final tokenProvider = context.read<TokenProvider>();
      await tokenProvider.refreshBalance();

      if (mounted) {
        NotificationService.success(
          context,
          message: 'Purchases restored successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        String reason = 'Unable to restore purchases.';

        if (e.toString().contains('network')) {
          reason =
              'Network connection failed. Please check your internet and try again.';
        } else if (e.toString().contains('account')) {
          reason = 'Account verification failed. Please sign in again.';
        } else if (e.toString().contains('no_purchases')) {
          reason = 'No previous purchases found to restore.';
        }

        await PurchaseFailedDialog.show(context, reason: reason);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseProvider>(
      builder: (context, provider, child) {
        final busy = provider.isLoading;
        final premiumIndex = provider.packs.indexWhere((p) => p.isPremium);
        final selectedPack = provider.selectedIndex == null
            ? null
            : provider.packs[provider.selectedIndex!];

        Widget packItem(int index) {
          final pack = provider.packs[index];
          final selected = provider.selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              button: true,
              selected: selected,
              child: GestureDetector(
                onTap: !provider.canSelectPack(pack) || busy
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        provider.setSelectedIndex(index);
                      },
                child: _PremiumSubscriptionCard(
                  pack: pack,
                  selected: selected,
                  isPremiumUser: provider.isPremium,
                ),
              ),
            ),
          );
        }

        final tokenIndexes = _tokenOrder(provider);

        return Scaffold(
          backgroundColor: SeasonPalette.scaffold,
          body: Column(
            children: [
              _BalanceHeader(
                busy: busy,
                onRedeem: _showPromoDialog,
                onRestore: PlatformUtils.isIOS
                    ? () => _restorePurchases(provider)
                    : null,
              ),
              if (premiumIndex != -1) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                  child: packItem(premiumIndex),
                ),
                // Auto-renewal terms (App Store 3.1.2): this card shows
                // the name, monthly price and "Renews monthly · Cancel
                // anytime"; Terms and Privacy links are at the bottom.
              ],
              // The fan takes whatever height is left, so nothing scrolls.
              Expanded(
                child: tokenIndexes.isEmpty
                    ? const SizedBox.shrink()
                    : _PackFan(
                        key: ValueKey('${tokenIndexes.length}-$_fanStart'),
                        packs: [
                          for (final i in tokenIndexes) provider.packs[i],
                        ],
                        allPacks: provider.packs,
                        initialIndex: _packPage.clamp(
                          0,
                          tokenIndexes.length - 1,
                        ),
                        selectedId: selectedPack?.productId,
                        enabled: !busy,
                        onSelected: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _packPage = i);
                          provider.setSelectedIndex(tokenIndexes[i]);
                        },
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegalLink(
                    'Terms of Use',
                    'https://github.com/furkanagess/SpookyAI/blob/main/TERMS_OF_USE.md',
                  ),
                  Text(' • ', style: TextStyle(color: SeasonPalette.mutedText)),
                  _buildLegalLink(
                    'Privacy Policy',
                    'https://github.com/furkanagess/SpookyAI/blob/main/PRIVACY_POLICY.md',
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: _CheckoutBar(
            pack: selectedPack,
            busy: busy,
            onBuy: selectedPack == null || busy
                ? null
                : () => _buy(selectedPack, provider),
          ),
        );
      },
    );
  }

  /// Token pack indexes, biggest pack first (150, 60, 25, 10).
  List<int> _tokenOrder(PurchaseProvider provider) {
    final list = [
      for (var i = 0; i < provider.packs.length; i++)
        if (!provider.packs[i].isPremium) i,
    ];
    list.sort(
      (a, b) => provider.packs[b].tokens.compareTo(provider.packs[a].tokens),
    );
    return list;
  }

  Future<void> _showPromoDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: SeasonPalette.inputFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Redeem Promo Code',
            style: TextStyle(color: SeasonPalette.text),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _promoController,
                style: TextStyle(color: SeasonPalette.text),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter promo code',
                  hintStyle: TextStyle(color: SeasonPalette.mutedText),
                  filled: true,
                  fillColor: SeasonPalette.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: SeasonPalette.text.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: SeasonPalette.text.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: SeasonPalette.accent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isRedeeming ? null : () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: SeasonPalette.mutedText),
              ),
            ),
            FilledButton(
              onPressed: _isRedeeming
                  ? null
                  : () async {
                      await _redeemPromo(closeDialogOnSuccess: true);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: SeasonPalette.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: _isRedeeming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Redeem'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _redeemPromo({bool closeDialogOnSuccess = false}) async {
    if (_isRedeeming) return;
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      await PurchaseFailedDialog.show(
        context,
        reason: 'Please enter a promo code.',
      );
      return;
    }

    setState(() => _isRedeeming = true);
    try {
      final result = await PromoCodeService.redeem(code);
      if (!mounted) return;

      if (result.success) {
        final tokenProvider = context.read<TokenProvider>();
        await tokenProvider.refreshBalance();
        _promoController.clear();
        if (closeDialogOnSuccess) {
          Navigator.of(context).pop();
        }
        await showPurchaseSuccessDialog(
          context,
          tokensAdded: result.tokensGranted,
        );
      } else {
        await PurchaseFailedDialog.show(context, reason: result.message);
      }
    } catch (e) {
      if (mounted) {
        await PurchaseFailedDialog.show(
          context,
          reason: 'Could not redeem the code. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  Widget _buildLegalLink(String text, String url) {
    return InkWell(
      onTap: () => _launchURL(url),
      child: Text(
        text,
        style: TextStyle(color: SeasonPalette.accent, fontSize: 12),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Store price as a number (falls back to the bundled display price).
double? _priceValue(Pack p) =>
    InAppPurchaseService.getProductById(p.productId)?.product.price ??
    double.tryParse(p.price);

/// Real saving per token versus the smallest token pack, in percent.
int? _savingsPercent(Pack pack, List<Pack> all) {
  final tokenPacks = all.where((p) => !p.isPremium && p.tokens > 0).toList();
  if (tokenPacks.isEmpty) return null;
  final base = tokenPacks.reduce((a, b) => a.tokens <= b.tokens ? a : b);
  if (base.productId == pack.productId) return null;
  final bp = _priceValue(base), pp = _priceValue(pack);
  if (bp == null || pp == null || bp <= 0) return null;
  final pct = ((1 - (pp / pack.tokens) / (bp / base.tokens)) * 100).round();
  return pct >= 5 ? pct : null;
}

/// Token packs as a fanned deck (same arrangement as the first onboarding
/// screen): the selected card stands upright in front, neighbours tilt away
/// and shrink; further cards tuck in behind them. Drag or tap to choose.
class _PackFan extends StatefulWidget {
  const _PackFan({
    super.key,
    required this.packs,
    required this.allPacks,
    required this.initialIndex,
    required this.selectedId,
    required this.enabled,
    required this.onSelected,
  });

  final List<Pack> packs;
  final List<Pack> allPacks;
  final int initialIndex;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<int> onSelected;

  @override
  State<_PackFan> createState() => _PackFanState();
}

class _PackFanState extends State<_PackFan>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.initialIndex.toDouble(),
  );
  late int _index = widget.initialIndex;
  double _cardW = 200;

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    final target = i.clamp(0, widget.packs.length - 1);
    final reduce = MediaQuery.of(context).disableAnimations;
    _pos.animateTo(
      target.toDouble(),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
    );
    if (target != _index) {
      setState(() => _index = target);
      widget.onSelected(target);
    } else if (widget.packs[target].productId != widget.selectedId) {
      widget.onSelected(target); // reselect after Premium was picked
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cardH = math.max(180.0, box.maxHeight - 16);
        _cardW = math.min(cardH / 1.35, box.maxWidth * 0.7);
        final h = _cardW * 1.35;
        final last = widget.packs.length - 1;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: widget.enabled
                    ? (d) => _pos.value =
                          (_pos.value - d.delta.dx / (_cardW * 0.7)).clamp(
                            -0.4,
                            widget.packs.length - 0.6,
                          )
                    : null,
                onHorizontalDragEnd: widget.enabled
                    ? (d) {
                        final v = d.primaryVelocity ?? 0;
                        final bias = v.abs() > 300 ? (v < 0 ? 0.5 : -0.5) : 0.0;
                        _goTo((_pos.value + bias).round());
                      }
                    : null,
                child: AnimatedBuilder(
                  animation: _pos,
                  builder: (context, _) {
                    final p = _pos.value;
                    final order = List.generate(widget.packs.length, (i) => i)
                      ..sort((a, b) => (b - p).abs().compareTo((a - p).abs()));
                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [for (final i in order) _placed(i, p, h)],
                    );
                  },
                ),
              ),
            ),
            // Arrow buttons to step between packs.
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _FanArrow(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous pack',
                  onTap: widget.enabled && _index > 0
                      ? () => _goTo(_index - 1)
                      : null,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _FanArrow(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next pack',
                  onTap: widget.enabled && _index < last
                      ? () => _goTo(_index + 1)
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _placed(int i, double p, double h) {
    final d = i - p;
    final a = d.abs();
    final near = math.min(a, 1.0);
    final far = math.max(a - 1, 0.0);
    final dx = d.sign * _cardW * (0.62 * near + 0.26 * far);
    final m = Matrix4.identity()
      ..translateByDouble(dx, 14 * math.min(a, 2.0), 0, 1)
      ..rotateZ(d.clamp(-2.0, 2.0) * 0.16)
      ..scaleByDouble(
        1 - 0.13 * math.min(a, 2.0),
        1 - 0.13 * math.min(a, 2.0),
        1,
        1,
      );
    return Transform(
      transform: m,
      alignment: Alignment.center,
      child: Opacity(
        opacity: (1 - 0.18 * math.min(a, 2.5)).clamp(0.0, 1.0),
        child: GestureDetector(
          onTap: widget.enabled ? () => _goTo(i) : null,
          child: _PackCard(
            pack: widget.packs[i],
            art: _seasonArt()[(i * 2) % _seasonArt().length],
            width: _cardW,
            height: h,
            selected: widget.packs[i].productId == widget.selectedId,
            savings: _savingsPercent(widget.packs[i], widget.allPacks),
          ),
        ),
      ),
    );
  }
}

/// Round translucent arrow over the fan; fades out at the ends.
class _FanArrow extends StatelessWidget {
  const _FanArrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onTap == null ? 0 : 1,
      child: IgnorePointer(
        ignoring: onTap == null,
        child: Material(
          color: Colors.black.withOpacity(0.45),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withOpacity(0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            icon: Icon(icon, color: Colors.white, size: 28),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      ),
    );
  }
}

/// Portrait pack card: full-bleed artwork, big token count, price, savings.
class _PackCard extends StatefulWidget {
  const _PackCard({
    required this.pack,
    required this.art,
    required this.width,
    required this.height,
    required this.selected,
    required this.savings,
  });

  final Pack pack;
  final String art;
  final double width;
  final double height;
  final bool selected;
  final int? savings;

  @override
  State<_PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<_PackCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.pack.isPopular && !MediaQuery.of(context).disableAnimations) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    final accent = SeasonPalette.accent;
    final selected = widget.selected;
    final savings = widget.savings;

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${pack.tokens} tokens, ${pack.realPrice}'
          '${savings != null ? ', save $savings percent' : ''}'
          '${pack.isPopular ? ', most popular' : ''}',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Selection ring: a thin accent outline set 4px outside the card,
          // plus a soft accent glow. Fades in instead of a hard border.
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: selected ? accent : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? accent.withOpacity(0.35)
                      : Colors.black.withOpacity(0.22),
                  blurRadius: selected ? 28 : 14,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Container(
              width: widget.width - 12,
              height: widget.height - 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.art,
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => ColoredBox(color: accent),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.35, 0.75, 1],
                        colors: [
                          Color(0x00000000),
                          Color(0xB3000000),
                          Color(0xF2000000),
                        ],
                      ),
                    ),
                  ),
                  if (savings != null)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'SAVE $savings%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pack.tokens}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text(
                          'TOKENS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: Colors.white24),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  pack.realPrice,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (pack.isPopular)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: 1 + 0.05 * _pulse.value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Premium membership as a wide banner: artwork collage background, crown,
/// a one-line value summary and the monthly price. A soft shine sweeps
/// across it every few seconds so it reads as the "upgrade" option.
class _PremiumSubscriptionCard extends StatefulWidget {
  const _PremiumSubscriptionCard({
    required this.pack,
    required this.selected,
    required this.isPremiumUser,
  });

  final Pack pack;
  final bool selected;
  final bool isPremiumUser;

  @override
  State<_PremiumSubscriptionCard> createState() =>
      _PremiumSubscriptionCardState();
}

class _PremiumSubscriptionCardState extends State<_PremiumSubscriptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations || widget.isPremiumUser) {
      _shine.stop();
    } else if (!_shine.isAnimating) {
      _shine.repeat();
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    final accent = SeasonPalette.accent;
    final active = widget.isPremiumUser;
    final selected = widget.selected;
    final art = _seasonArt();

    return Semantics(
      button: !active,
      selected: selected,
      label: active
          ? 'Premium is active'
          : 'SpookyAI Premium, ${pack.realPrice} per month. ${pack.features.join(', ')}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        height: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? accent.withOpacity(0.4)
                  : Colors.black.withOpacity(0.25),
              blurRadius: selected ? 22 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected || active ? accent : Colors.white.withOpacity(0.14),
            width: selected || active ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Collage background.
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Image.asset(
                        art[(i + 4) % art.length],
                        fit: BoxFit.cover,
                        cacheWidth: 220,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => ColoredBox(color: accent),
                      ),
                    ),
                ],
              ),
            ),
            // Deep scrim, darker on the left where the text sits.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xF2000000), Color(0x99000000)],
                ),
              ),
            ),
            // Periodic shine.
            AnimatedBuilder(
              animation: _shine,
              builder: (_, _) {
                final t = (_shine.value / 0.45).clamp(0.0, 1.0);
                if (t <= 0 || t >= 1) return const SizedBox.shrink();
                return FractionalTranslation(
                  translation: Offset(-1 + 2.2 * t, 0),
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Container(
                      width: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  // Monthly token amount, same typography as the pack cards.
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+${pack.tokens}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'TOKENS / MO',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active ? "YOU'RE PREMIUM" : 'GO PREMIUM',
                          style: TextStyle(
                            color: active ? Colors.white : accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (active)
                          const Text(
                            'Manage it in your store settings',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    pack.realPrice,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '/ month',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        if (!active)
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Renews monthly · Cancel anytime',
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!active) ...[
                    const SizedBox(width: 10),
                    _SelectDot(selected: selected, color: accent),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Packages screen building blocks
// ---------------------------------------------------------------------------

const _artH = 'assets/images/haloween';
const _artX = 'assets/images/christmas/text-to-image';
const _mosaicArt = [
  '$_artH/text-to-image/raven_queen.jpg',
  '$_artH/image-to-image/gothic_royal.png',
  '$_artX/frost_queen.jpg',
  '$_artH/image-to-image/werewolf.png',
  '$_artH/text-to-image/moonlit_witch.png',
  '$_artX/santa_workshop.jpg',
  '$_artH/image-to-image/fortune_teller.png',
  '$_artH/text-to-image/pumpkin_king.png',
];

/// Header: a still mosaic of app artwork behind the user's balance.
class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({
    required this.busy,
    required this.onRedeem,
    required this.onRestore,
  });

  final bool busy;
  final VoidCallback onRedeem;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    final text = SeasonPalette.text;
    final scaffold = SeasonPalette.scaffold;
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: top + 64,
      child: Stack(
        children: [
          // Staggered 4x2 mosaic, slightly scaled for a cropped look.
          Positioned.fill(
            child: ExcludeSemantics(
              child: ClipRect(
                child: Transform.scale(
                  scale: 1.08,
                  child: Row(
                    children: [
                      for (var c = 0; c < 4; c++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: c.isOdd ? 0 : 36,
                              left: 4,
                              right: 4,
                            ),
                            child: Column(
                              children: [
                                for (var r = 0; r < 2; r++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: AspectRatio(
                                        aspectRatio: 0.78,
                                        child: Image.asset(
                                          _mosaicArt[c * 2 + r],
                                          fit: BoxFit.cover,
                                          cacheWidth: 300,
                                          excludeFromSemantics: true,
                                          errorBuilder: (_, _, _) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.5, 1],
                  colors: [
                    scaffold.withOpacity(0.55),
                    scaffold.withOpacity(0.75),
                    scaffold,
                  ],
                ),
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: top + 4,
            left: 4,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.arrow_back_rounded, color: text),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    'Packages',
                    style: TextStyle(
                      color: text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                if (busy)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    ),
                  ),
                _BarPill(
                  icon: Icons.redeem_rounded,
                  label: 'Redeem',
                  onTap: busy ? null : onRedeem,
                ),
                if (onRestore != null)
                  _BarPill(
                    icon: Icons.restore_rounded,
                    label: 'Restore',
                    onTap: busy ? null : onRestore,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Season-matched artwork made with the app, used as visual "pack art".
List<String> _seasonArt() => switch (SeasonPalette.current.id) {
  SeasonId.halloween => const [
    '$_artH/text-to-image/raven_queen.jpg',
    '$_artH/image-to-image/vampire_noble.png',
    '$_artH/text-to-image/pumpkin_king.png',
    '$_artH/image-to-image/enchantedd_witch.png',
    '$_artH/text-to-image/blackcat.jpg',
    '$_artH/image-to-image/werewolf.png',
    '$_artH/text-to-image/ghost_bride.jpg',
    '$_artH/image-to-image/fortune_teller.png',
  ],
  SeasonId.christmas => const [
    '$_artX/frost_queen.jpg',
    '$_artX/santa_workshop.jpg',
    '$_artX/frost_dragon.jpg',
    '$_artX/lantern_snowman.jpg',
    '$_artX/reindeer.jpg',
    '$_artX/gingerbread_village.jpg',
    '$_artX/winter_market.jpg',
    '$_artX/elf.jpg',
  ],
};

/// Compact labeled pill for the top bar (redeem / restore).
class _BarPill extends StatelessWidget {
  const _BarPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = SeasonPalette.text;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: SeasonPalette.surface.withOpacity(0.85),
        shape: StadiumBorder(side: BorderSide(color: text.withOpacity(0.1))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17, color: text),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sticky checkout: what is selected, its price, and the buy button.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.pack,
    required this.busy,
    required this.onBuy,
  });

  final Pack? pack;
  final bool busy;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    final text = SeasonPalette.text;
    final muted = SeasonPalette.mutedText;
    final p = pack;

    return Container(
      decoration: BoxDecoration(
        color: SeasonPalette.surface,
        border: Border(top: BorderSide(color: text.withOpacity(0.08))),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p == null ? 'No pack selected' : p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                  Text(
                    p == null
                        ? 'Choose a pack'
                        : p.isPremium
                        ? '${p.realPrice} / month'
                        : p.realPrice,
                    style: TextStyle(
                      color: text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onBuy,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      p?.isPremium == true
                          ? Icons.workspace_premium_rounded
                          : Icons.local_fire_department_rounded,
                      size: 20,
                    ),
              label: Text(p?.isPremium == true ? 'Subscribe' : 'Buy now'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accent.withOpacity(0.4),
                disabledForegroundColor: Colors.white,
                minimumSize: const Size(150, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio-style mark: an empty ring that fills with a check when selected.
class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected, required this.color});
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? color : Colors.black26,
          border: Border.all(
            color: selected ? color : Colors.white70,
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)]
              : null,
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: selected ? 1 : 0,
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
