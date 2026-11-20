import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/in_app_purchase_service.dart';
import '../../../../core/services/purchase_provider.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import 'purchase_failed_dialog.dart';
import 'purchase_success_dialog.dart';

/// Full-screen token packs offer shown after onboarding (and from Profile).
/// A moving wall of app-made artwork sells the result before the price.
///
/// Lists the real token packs from [PurchaseProvider] with store-localized
/// prices, preselects the recommended pack and buys it in place.
class PaywallDialog extends StatefulWidget {
  const PaywallDialog({
    super.key,
    this.onBuy,
    this.onRestore,
    this.outOfTokens = false,
  });

  /// Shown when the balance ran out: same packs, header speaks to that moment.
  final bool outOfTokens;

  final VoidCallback? onBuy;
  final VoidCallback? onRestore;

  static Future<void> show(BuildContext context, {bool outOfTokens = false}) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        transitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 420),
        reverseTransitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => PaywallDialog(outOfTokens: outOfTokens),
        transitionsBuilder: (_, anim, _, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<PaywallDialog> createState() => _PaywallDialogState();
}

class _PaywallDialogState extends State<PaywallDialog> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    // The first paywall (after onboarding) opens before anything else has
    // loaded the packs, so fetch them from the store here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PurchaseProvider>().ensurePacksLoaded();
    });
  }

  List<Pack> _tokenPacks(PurchaseProvider p) =>
      p.packs.where((e) => !e.isPremium).toList();

  Pack? _selected(List<Pack> packs) {
    if (packs.isEmpty) return null;
    return packs.firstWhere(
      (e) => e.productId == _selectedId,
      orElse: () =>
          packs.firstWhere((e) => e.isPopular, orElse: () => packs.first),
    );
  }

  Future<void> _buy(Pack pack) async {
    final provider = context.read<PurchaseProvider>();
    if (provider.isLoading) return;
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    try {
      final ok = await provider.buyPack(pack);
      if (!mounted) return;
      if (ok) {
        await context.read<TokenProvider>().refreshBalance();
        if (!mounted) return;
        widget.onBuy?.call();
        if (navigator.canPop()) navigator.pop();
        if (navigator.context.mounted) {
          await showPurchaseSuccessDialog(
            navigator.context,
            tokensAdded: pack.tokens,
          );
        }
        return;
      }
      final cancelled =
          InAppPurchaseService.lastPurchaseCancelled ||
          (InAppPurchaseService.queryProductError?.contains('cancelled') ??
              false);
      if (!cancelled) {
        await PurchaseFailedDialog.show(
          context,
          reason: 'Purchase was not completed. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('PaywallDialog: purchase error: $e');
      if (mounted) {
        await PurchaseFailedDialog.show(
          context,
          reason: 'Something went wrong. Please try again.',
        );
      }
    }
  }

  Future<void> _restore() async {
    HapticFeedback.selectionClick();
    await context.read<PurchaseProvider>().restorePurchases();
    if (!mounted) return;
    await context.read<TokenProvider>().refreshBalance();
    widget.onRestore?.call();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final packs = provider.storeReady ? _tokenPacks(provider) : const <Pack>[];
    final selected = _selected(packs);
    final busy = provider.isLoading;
    final accent = SeasonPalette.accent;
    final text = SeasonPalette.text;
    final muted = SeasonPalette.mutedText;
    final screen = MediaQuery.sizeOf(context);
    final heroH = (screen.height * 0.30).clamp(150.0, 320.0);

    return Scaffold(
      backgroundColor: SeasonPalette.scaffold,
      body: Stack(
        children: [
          // Wall of artwork made with the app.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroH + 120,
            child: const _ArtWall(),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroH + 121,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.35, 0.8, 1],
                    colors: [
                      SeasonPalette.scaffold.withOpacity(0.55),
                      SeasonPalette.scaffold.withOpacity(0.05),
                      SeasonPalette.scaffold.withOpacity(0.85),
                      SeasonPalette.scaffold,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                        child: IconButton(
                          tooltip: 'Close',
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.45),
                          ),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: box.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(height: heroH * 0.25),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: accent.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          widget.outOfTokens
                                              ? 'OUT OF TOKENS'
                                              : 'ALL CREATED WITH SPOOKYAI',
                                          style: TextStyle(
                                            color: accent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Semantics(
                                        header: true,
                                        child: Text(
                                          widget.outOfTokens
                                              ? 'Keep the magic going'
                                              : 'Bring your ideas to life',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: text,
                                            fontSize: 26,
                                            height: 1.15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.outOfTokens
                                            ? 'You have used all your tokens. Pick a pack and continue right where you left off.'
                                            : 'Tokens power every creation. Pick a pack and start making art like this.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Packs
                                Padding(
                                  padding: EdgeInsets.zero,
                                  child: packs.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: provider.packsLoading
                                              ? Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            color: accent,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Loading packs…',
                                                      style: TextStyle(
                                                        color: muted,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Couldn\'t load packs. Check your connection and try again.',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: muted,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextButton.icon(
                                                      onPressed: () => provider
                                                          .ensurePacksLoaded(
                                                            force: true,
                                                          ),
                                                      icon: Icon(
                                                        Icons.refresh_rounded,
                                                        color: accent,
                                                      ),
                                                      label: Text(
                                                        'Retry',
                                                        style: TextStyle(
                                                          color: accent,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        )
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          itemCount: packs.length,
                                          separatorBuilder: (_, _) =>
                                              const SizedBox(height: 10),
                                          itemBuilder: (_, i) => _PackTile(
                                            pack: packs[i],
                                            selected:
                                                packs[i].productId ==
                                                selected?.productId,
                                            enabled: !busy,
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setState(
                                                () => _selectedId =
                                                    packs[i].productId,
                                              );
                                            },
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: selected == null || busy
                              ? null
                              : () => _buy(selected),
                          icon: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 20,
                                ),
                          label: Text(
                            selected == null
                                ? 'Continue'
                                : 'Buy ${selected.tokens} tokens · ${selected.realPrice}',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: accent.withOpacity(0.5),
                            disabledForegroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: TextButton(
                              onPressed: busy ? null : _restore,
                              style: TextButton.styleFrom(
                                foregroundColor: muted,
                                minimumSize: const Size(48, 48),
                              ),
                              child: const Text(
                                'Restore purchases',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({
    required this.pack,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Pack pack;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    final text = SeasonPalette.text;
    final muted = SeasonPalette.mutedText;

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${pack.tokens} tokens, ${pack.realPrice}${pack.isPopular ? ', most popular' : ''}',
      excludeSemantics: true,
      child: Material(
        color: selected ? accent.withOpacity(0.10) : SeasonPalette.inputFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? accent : text.withOpacity(0.08),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? accent : muted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${pack.tokens} tokens',
                              style: TextStyle(
                                color: text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (pack.isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Most popular',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Up to ${pack.tokens} images',
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pack.realPrice,
                    style: TextStyle(
                      color: text,
                      fontSize: 16,
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

/// Three columns of artwork drifting up and down at different speeds,
/// slightly tilted. Pauses when the system asks for reduced motion.
class _ArtWall extends StatefulWidget {
  const _ArtWall();

  @override
  State<_ArtWall> createState() => _ArtWallState();
}

class _ArtWallState extends State<_ArtWall>
    with SingleTickerProviderStateMixin {
  static const _h = 'assets/images/haloween';
  static const _x = 'assets/images/christmas/text-to-image';
  static const _columns = [
    [
      '$_h/image-to-image/vampire_noble.png',
      '$_h/text-to-image/raven_queen.jpg',
      '$_x/frost_queen.jpg',
      '$_h/image-to-image/fortune_teller.png',
      '$_h/text-to-image/pumpkin_king.png',
    ],
    [
      '$_h/image-to-image/enchantedd_witch.png',
      '$_x/santa_workshop.jpg',
      '$_h/text-to-image/blackcat.jpg',
      '$_h/image-to-image/gothic_royal.png',
      '$_h/text-to-image/ghost_bride.jpg',
    ],
    [
      '$_h/image-to-image/werewolf.png',
      '$_h/text-to-image/moonlit_witch.png',
      '$_x/frost_dragon.jpg',
      '$_h/image-to-image/haunted_carnival.png',
      '$_x/lantern_snowman.jpg',
    ],
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = 10.0;
          final colW = (box.maxWidth * 1.15 - gap * 4) / 3;
          final tileH = colW * 1.3;
          final setH = _columns.first.length * (tileH + gap);
          return OverflowBox(
            maxWidth: box.maxWidth * 1.15,
            maxHeight: double.infinity,
            alignment: Alignment.topCenter,
            child: Transform.rotate(
              angle: -0.06,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _columns.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: gap / 2,
                        ),
                        child: _column(i, colW, tileH, gap, setH),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _column(int i, double w, double h, double gap, double setH) {
    // Middle column runs the other way and a bit faster.
    final speed = i == 1 ? 1.25 : 1.0;
    final t = (_c.value * speed) % 1.0;
    final dy = i == 1 ? -setH + t * setH : -t * setH;
    final items = [..._columns[i], ..._columns[i], ..._columns[i]];
    return Transform.translate(
      offset: Offset(0, dy - (i == 1 ? 0 : h * 0.4)),
      child: Column(
        children: [
          for (final a in items)
            Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  a,
                  width: w,
                  height: h,
                  fit: BoxFit.cover,
                  cacheWidth: 360,
                  gaplessPlayback: true,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => SizedBox(width: w, height: h),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
