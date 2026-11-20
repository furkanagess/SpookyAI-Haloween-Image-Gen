import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/seasons/season_palette.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.featured = false,
    this.featuredColors = const [],
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Same size as the others, with a fire glow that draws the eye.
  final bool featured;

  /// Gradient of a featured tile (2+ colors; empty = hot pink to orange).
  final List<Color> featuredColors;

  int get flex => 10;
}

/// Bottom navigation: a floating rounded bar with a sliding pill behind the
/// selected tab, filled/outlined icon swap, always-visible labels, haptics and
/// screen-reader semantics.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    this.itemKeys = const {},
  });

  /// Optional keys per item index (used by the product tour).
  final Map<int, GlobalKey> itemKeys;

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const double _barHeight = 68;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: Container(
          height: _barHeight,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: SeasonPalette.inputFill,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: SeasonPalette.text.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final total = items.fold<int>(0, (a, e) => a + e.flex);
              final unit = box.maxWidth / total;
              var left = 0.0;
              for (var i = 0; i < currentIndex && i < items.length; i++) {
                left += items[i].flex * unit;
              }
              final current = currentIndex < items.length
                  ? items[currentIndex]
                  : null;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: left,
                    top: 0,
                    bottom: 0,
                    width: (current?.flex ?? 10) * unit,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      // A featured tile draws its own selected look.
                      opacity: current == null || current.featured ? 0 : 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: SeasonPalette.accent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: SeasonPalette.accent.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          key: itemKeys[i],
                          flex: items[i].flex,
                          child: items[i].featured
                              ? _FeaturedTile(
                                  item: items[i],
                                  selected: i == currentIndex,
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    onChanged(i);
                                  },
                                )
                              : _NavTile(
                                  item: items[i],
                                  selected: i == currentIndex,
                                  onTap: () {
                                    if (i != currentIndex)
                                      HapticFeedback.selectionClick();
                                    onChanged(i);
                                  },
                                ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? SeasonPalette.accent
        : SeasonPalette.text.withOpacity(0.5);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              scale: selected ? 1.12 : 1.0,
              child: Icon(
                selected ? item.activeIcon : item.icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.1,
                color: color,
              ),
              child: Text(item.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same size as the other tabs, but alive: a fire-colored light runs around
/// its border, the flame icon flickers and glows, and a shine sweeps over it.
class _FeaturedTile extends StatefulWidget {
  const _FeaturedTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FeaturedTile> createState() => _FeaturedTileState();
}

class _FeaturedTileState extends State<_FeaturedTile>
    with SingleTickerProviderStateMixin {
  // One controller drives everything (border lap, flicker, shine).
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final selected = widget.selected;
    final colors = item.featuredColors.length >= 2
        ? item.featuredColors
        : const [Color(0xFFFF2D95), Color(0xFFFF8A00)];
    final hot = colors.first;
    final warm = colors.last;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final v = _t.value;
            // Irregular flicker from two out-of-phase waves.
            final flicker =
                0.5 +
                0.3 * math.sin(v * 2 * math.pi * 3) +
                0.2 * math.sin(v * 2 * math.pi * 7 + 1.3);
            final iconColor = Color.lerp(
              warm,
              const Color(0xFFFFE08A),
              flicker * 0.6,
            )!;
            return CustomPaint(
              painter: _FireBorderPainter(
                progress: v,
                hot: hot,
                warm: warm,
                selected: selected,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: (selected ? 1.12 : 1.0) + 0.06 * flicker,
                    alignment: Alignment.bottomCenter,
                    child: Icon(
                      item.activeIcon,
                      size: 24,
                      color: iconColor,
                      shadows: [
                        Shadow(
                          color: hot.withOpacity(0.5 + 0.4 * flicker),
                          blurRadius: 8 + 8 * flicker,
                        ),
                        Shadow(color: warm.withOpacity(0.6), blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => LinearGradient(
                      colors: [hot, warm, Colors.white, warm, hot],
                      stops: const [0, 0.35, 0.5, 0.65, 1],
                      // Shine sweeps across the label.
                      transform: _SlideGradient(v * 2 - 1),
                    ).createShader(r),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);

  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * dx, 0, 0);
}

/// Warm tinted pill with a bright spark running around its edge and a soft
/// pulsing glow behind it.
class _FireBorderPainter extends CustomPainter {
  _FireBorderPainter({
    required this.progress,
    required this.hot,
    required this.warm,
    required this.selected,
  });

  final double progress;
  final Color hot;
  final Color warm;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    // Unselected: no area, only the flickering icon and label shine.
    if (!selected) return;
    final rect = (Offset.zero & size).deflate(1);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    final pulse = 0.5 + 0.5 * math.sin(progress * 2 * math.pi * 2);

    // Ember fill.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.6),
          radius: 1.1,
          colors: [
            warm.withOpacity((selected ? 0.38 : 0.22) + 0.1 * pulse),
            hot.withOpacity(selected ? 0.18 : 0.08),
          ],
        ).createShader(rect),
    );

    final sweep = SweepGradient(
      colors: [
        hot.withOpacity(0.15),
        hot,
        Colors.white,
        warm,
        hot.withOpacity(0.15),
        hot.withOpacity(0.15),
      ],
      stops: const [0, 0.14, 0.2, 0.28, 0.42, 1],
      transform: GradientRotation(progress * 2 * math.pi),
    ).createShader(rect);

    // Soft outer glow, then the crisp running line.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = sweep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 3 * pulse),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = sweep
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2 : 1.5,
    );
  }

  @override
  bool shouldRepaint(_FireBorderPainter old) =>
      old.progress != progress ||
      old.selected != selected ||
      old.hot != hot ||
      old.warm != warm;
}
