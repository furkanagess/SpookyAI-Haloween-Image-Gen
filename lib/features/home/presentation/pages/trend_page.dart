import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../tour/product_tour.dart';
import '../../../../core/services/prompts_provider.dart';
import '../../../../core/services/trend_service.dart';
import '../../../../core/theme/app_metrics.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/widgets/app_bar_title.dart';
import '../../../../core/widgets/token_display_widget.dart';
import '../../data/models/prompt_category.dart';
import '../../domain/generation_mode.dart';
import '../widgets/prompt_detail_sheet.dart';
import 'purchase_page.dart';

/// Remote texts, colors and switches (Firestore `trend_config/screen`).
TrendScreenConfig get _cfg => TrendService.config.value;
Color get _second => _cfg.secondaryAccent ?? SeasonPalette.secondaryAccent;
Color get _defaultAccent => _cfg.accent ?? SeasonPalette.accent;

/// Trends tab: hot, time-limited styles (e.g. "GTA 6", "Thanksgiving") in
/// sections loaded from Firestore, so new trends need no app update.
///
/// Only titles, taglines and previews are shown; prompt text stays hidden.
///
/// Performance: a single rotating controller drives every glowing border
/// (painters repaint from it directly, no widget rebuilds per frame).
class TrendPage extends StatefulWidget {
  const TrendPage({super.key, this.onUseStyle, this.loader});

  final void Function(PromptItem style)? onUseStyle;

  /// Injectable for tests; defaults to [TrendService.load].
  final Future<List<TrendSection>> Function()? loader;

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  final PageController _hero = PageController(viewportFraction: 0.84);

  List<TrendSection>? _sections;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await (widget.loader ?? TrendService.load)();
      if (!mounted) return;
      _applyGlow();
      setState(() {
        _sections = s;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sections ??= const [];
        _failed = true;
      });
    }
  }

  void _applyGlow() {
    final ms = (_cfg.glowSeconds * 1000).round();
    if (!_cfg.glow) {
      _spin.stop();
    } else if (_spin.duration?.inMilliseconds != ms || !_spin.isAnimating) {
      _spin.duration = Duration(milliseconds: ms);
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _hero.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- actions

  bool _locked(PromptItem item) {
    try {
      return context.read<PromptsProvider>().isPromptLocked(item);
    } catch (_) {
      return item.isPremium;
    }
  }

  void _use(PromptItem item) {
    if (_locked(item)) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onUseStyle?.call(item);
  }

  void _open(PromptItem item, Color accent) {
    HapticFeedback.selectionClick();
    showPromptDetailSheet(
      context,
      detail: PromptDetail(
        title: item.title,
        tags: item.tags,
        tagline: item.tagline,
        description: item.description,
        mode: item.promptType == PromptType.imageToImage
            ? GenerationMode.image
            : GenerationMode.text,
        preview: _TrendImage(item: item, accent: accent),
        isPopular: item.isPopular,
        isLocked: _locked(item),
      ),
      onUse: () => _use(item),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: SeasonPalette.scaffold,
      body: RefreshIndicator(
        color: SeasonPalette.accent,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: SeasonPalette.scaffold,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: AppMetrics.toolbarHeight,
              title: AppBarTitle(
                icon: Icons.local_fire_department_rounded,
                title: _cfg.appBarTitle,
              ),
              actions: [
                TokenDisplayWidget(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PurchasePage()),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            if (_cfg.showHeader)
              SliverToBoxAdapter(
                child: _Header(spin: _spin, pulse: _pulse),
              ),
            if (sections == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (sections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(failed: _failed, onRetry: _load),
              )
            else ...[
              if (_cfg.showHero) ...[
                if (_cfg.heroTitle.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: Text(
                        _cfg.heroTitle,
                        style: TextStyle(
                          color: SeasonPalette.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: _buildHero(sections)),
              ],
              for (final s in sections)
                SliverToBoxAdapter(child: _buildSection(s)),
            ],
            SliverToBoxAdapter(child: SizedBox(height: 110 + bottom)),
          ],
        ),
      ),
    );
  }

  Color _accentOf(TrendSection s) => s.accent ?? _defaultAccent;

  Widget _buildHero(List<TrendSection> sections) {
    final hot = pickHeroItems(sections, _cfg.heroItems);
    return SizedBox(
      key: ProductTourKeys.trendsHero,
      height: 320,
      child: PageView.builder(
        controller: _hero,
        padEnds: hot.length == 1,
        itemCount: hot.length,
        itemBuilder: (context, i) {
          final (item, section) = hot[i];
          final accent = _accentOf(section);
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: _TrendCard(
              item: item,
              badge: section.badges[item.id],
              accent: accent,
              spin: _spin,
              big: true,
              sectionLabel: section.title,
              locked: _locked(item),
              onTap: () => _open(item, accent),
              onUse: () => _use(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(TrendSection s) {
    final accent = _accentOf(s);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionHeader(section: s, accent: accent, pulse: _pulse),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: s.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final item = s.items[i];
                return SizedBox(
                  width: 168,
                  child: _TrendCard(
                    item: item,
                    badge: s.badges[item.id],
                    accent: accent,
                    spin: _spin,
                    locked: _locked(item),
                    onTap: () => _open(item, accent),
                    onUse: () => _use(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================== widgets

class _Header extends StatelessWidget {
  const _Header({required this.spin, required this.pulse});

  final Animation<double> spin;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final a = _defaultAccent;
    final b = _second;
    final custom = _cfg.headlineColors;
    final colors = custom.length >= 2
        ? [...custom, custom.first]
        : [a, b, Colors.white, a];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: spin,
                  builder: (context, child) => ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => LinearGradient(
                      colors: colors,
                      stops: custom.length >= 2
                          ? null
                          : const [0, 0.4, 0.55, 1],
                      transform: GradientRotation(spin.value * 2 * math.pi),
                    ).createShader(r),
                    child: child,
                  ),
                  child: Text(
                    _cfg.headline,
                    style: const TextStyle(
                      fontSize: 26,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _cfg.subheadline,
                  style: TextStyle(
                    color: SeasonPalette.mutedText,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_cfg.showLive) _LiveBadge(pulse: pulse),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _cfg.liveColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _cfg.liveColor.withOpacity(0.5 + 0.5 * t),
            ),
            boxShadow: [
              BoxShadow(
                color: _cfg.liveColor.withOpacity(0.45 * t),
                blurRadius: 14,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(_cfg.liveColor, Colors.white, t * 0.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _cfg.liveText,
                style: TextStyle(
                  color: _cfg.liveColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.section,
    required this.accent,
    required this.pulse,
  });

  final TrendSection section;
  final Color accent;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SeasonPalette.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (section.subtitle.isNotEmpty)
                Text(
                  section.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SeasonPalette.mutedText,
                    fontSize: 12.5,
                  ),
                ),
            ],
          ),
        ),
        if (section.showCount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Text(
              _cfg.countText.replaceAll('{n}', '${section.items.length}'),
              style: TextStyle(
                color: SeasonPalette.text,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

/// A card with a neon light running around its border.
class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.item,
    required this.accent,
    required this.spin,
    required this.onTap,
    required this.onUse,
    required this.locked,
    this.big = false,
    this.sectionLabel,
    this.badge,
  });

  /// Custom badge from Firestore (e.g. "NEW"), shown first.
  final ({String text, Color? color})? badge;

  final PromptItem item;
  final Color accent;
  final Animation<double> spin;
  final VoidCallback onTap;
  final VoidCallback onUse;
  final bool locked;
  final bool big;
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    final radius = big ? 26.0 : 20.0;
    return Semantics(
      button: true,
      label: '${item.title} trend style',
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _GlowBorderPainter(
            spin: spin,
            color: accent,
            second: _second,
            animated: _cfg.glow,
            radius: radius,
            stroke: big ? 3 : 2.2,
          ),
          child: Padding(
            padding: EdgeInsets.all(big ? 3 : 2.2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _TrendImage(item: item, accent: accent),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x22000000),
                          Color(0xDD000000),
                        ],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                  ),
                  if (_cfg.showBadges)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (badge != null)
                            _Badge(
                              text: badge!.text,
                              color: badge!.color ?? accent,
                            ),
                          if (item.isPopular && _cfg.hotText.isNotEmpty)
                            _Badge(text: _cfg.hotText, color: _cfg.hotColor),
                          if (item.promptType == PromptType.imageToImage &&
                              _cfg.showPhotoBadge &&
                              _cfg.photoText.isNotEmpty)
                            _Badge(
                              text: _cfg.photoText,
                              color: _cfg.photoColor,
                            ),
                          if (locked && _cfg.proText.isNotEmpty)
                            _Badge(text: _cfg.proText, color: _cfg.proColor),
                        ],
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_cfg.showSectionLabel &&
                            sectionLabel != null &&
                            sectionLabel!.isNotEmpty)
                          Text(
                            sectionLabel!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: big ? 24 : 15.5,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (_cfg.showTagline && item.tagline.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.tagline,
                            maxLines: big ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: big ? 13.5 : 11.5,
                            ),
                          ),
                        ],
                        SizedBox(height: big ? 12 : 8),
                        _TryButton(
                          accent: accent,
                          big: big,
                          locked: locked,
                          onTap: onUse,
                        ),
                      ],
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

class _TryButton extends StatelessWidget {
  const _TryButton({
    required this.accent,
    required this.big,
    required this.locked,
    required this.onTap,
  });

  final Color accent;
  final bool big;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = SeasonPalette.onColor(accent);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: big ? 44 : 34,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(big ? 14 : 11),
          gradient: LinearGradient(
            colors: [accent, Color.lerp(accent, Colors.white, 0.25)!],
          ),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.55), blurRadius: 14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              locked ? Icons.lock_rounded : Icons.auto_awesome_rounded,
              size: big ? 18 : 15,
              color: fg,
            ),
            const SizedBox(width: 6),
            Text(
              locked ? _cfg.unlockText : _cfg.tryText,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: big ? 15 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _TrendImage extends StatelessWidget {
  const _TrendImage({required this.item, required this.accent});

  final PromptItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.85),
            _second.withOpacity(0.6),
            Colors.black,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          size: 48,
          color: Colors.white70,
        ),
      ),
    );
    final url = item.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    final image = url.startsWith('assets/')
        ? Image.asset(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          )
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : fallback,
          );
    return SizedBox.expand(child: image);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.failed, required this.onRetry});

  final bool failed;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            failed ? _cfg.errorTitle : _cfg.emptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SeasonPalette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            failed ? _cfg.errorBody : _cfg.emptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: SeasonPalette.mutedText),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_cfg.refreshText),
          ),
        ],
      ),
    );
  }
}

/// Paints a rounded border with a bright light sweeping around it, plus a
/// soft outer glow. Repaints straight from [spin] (no rebuilds).
class _GlowBorderPainter extends CustomPainter {
  _GlowBorderPainter({
    required this.spin,
    required this.color,
    required this.second,
    required this.radius,
    required this.stroke,
    this.animated = true,
  }) : super(repaint: animated ? spin : null);

  /// False = a still border at a fixed angle (glow turned off remotely).
  final bool animated;

  final Animation<double> spin;
  final Color color;
  final Color second;
  final double radius;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(stroke / 2),
      Radius.circular(radius),
    );
    final shader = SweepGradient(
      colors: [
        color.withOpacity(0.15),
        color,
        Colors.white,
        second,
        color.withOpacity(0.15),
        color.withOpacity(0.15),
      ],
      stops: const [0, 0.12, 0.18, 0.26, 0.4, 1],
      transform: GradientRotation(
        animated ? spin.value * 2 * math.pi : math.pi / 4,
      ),
    ).createShader(rect);

    // Outer glow.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Crisp line.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_GlowBorderPainter old) =>
      old.color != color ||
      old.second != second ||
      old.radius != radius ||
      old.stroke != stroke ||
      old.animated != animated;
}
