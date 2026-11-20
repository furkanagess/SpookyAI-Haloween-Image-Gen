import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'season_palette.dart';

/// DLC-style season tag that sits under the app name in the app bar.
/// A left-aligned ribbon whose right end has a 45° swallow-tail notch.
/// It waves like a flag: the left edge is the "pole" (still), the wave grows
/// toward the free end, and a soft light band travels across the cloth.
class SeasonBadge extends StatefulWidget {
  const SeasonBadge({super.key, this.showEmoji = true});

  /// Season emoji before the name. Off in app bars, on in the splash.
  final bool showEmoji;

  @override
  State<SeasonBadge> createState() => _SeasonBadgeState();
}

class _SeasonBadgeState extends State<SeasonBadge>
    with SingleTickerProviderStateMixin {
  static const double _height = 19;

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _wave.stop();
      _wave.value = 0;
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final season = SeasonPalette.current;

    return Semantics(
      label: '${season.displayName} season',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(season.id),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(-8 * (1 - t), 0),
              child: child,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: SeasonPalette.accent.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _wave,
              builder: (context, child) {
                final phase = _wave.value * 2 * math.pi;
                return ClipPath(
                  clipper: _RibbonClipper(phase),
                  child: Stack(
                    children: [
                      child!,
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1 + 3 * _wave.value - 1, 0),
                                end: Alignment(3 * _wave.value - 1, 0),
                                colors: [
                                  Colors.black.withOpacity(0.0),
                                  Colors.white.withOpacity(0.18),
                                  Colors.black.withOpacity(0.10),
                                  Colors.black.withOpacity(0.0),
                                ],
                                stops: const [0, 0.4, 0.7, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                height: _height,
                color: SeasonPalette.accent,
                padding: const EdgeInsets.only(left: 7, right: _height / 2 + 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showEmoji) ...[
                      Text(
                        season.emoji,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      season.displayName.toUpperCase(),
                      maxLines: 1,
                      style: TextStyle(
                        color: SeasonPalette.onAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        height: 1.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  const _RibbonClipper(this.phase);

  final double phase;

  static const double _amp = 1.6; // max inward ripple at the free end, px

  /// Inward offset of the cloth edge at [x]; zero at the pole (x = 0).
  double _dy(double x, double w) {
    final t = x / w;
    return _amp * t * (1 + math.sin(t * 2.4 * math.pi - phase)) / 2;
  }

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final notch = h / 2; // equal run and rise = 45°
    const steps = 24;
    final path = Path()..moveTo(0, 0);
    for (var i = 1; i <= steps; i++) {
      final x = w * i / steps;
      path.lineTo(x, _dy(x, w));
    }
    final tip = _dy(w, w);
    path
      ..lineTo(w - notch, h / 2 + tip * 0.3)
      ..lineTo(w, h - tip);
    for (var i = steps - 1; i >= 0; i--) {
      final x = w * i / steps;
      path.lineTo(x, h - _dy(x, w));
    }
    return path..close();
  }

  @override
  bool shouldReclip(_RibbonClipper oldClipper) => oldClipper.phase != phase;
}
