import 'package:flutter/material.dart';

import 'season_badge.dart';
import 'season_theme.dart';

/// The single splash layout used everywhere (app launch and season change):
/// one centered column — hero, title, season ribbon — with staggered rings
/// radiating from the hero. Callers only supply the progress [t] (0..1).
class SeasonSplashStage extends StatelessWidget {
  const SeasonSplashStage({
    super.key,
    required this.season,
    required this.t,
    this.hero,
  });

  final SeasonTheme season;

  /// Choreography progress, 0..1.
  final double t;

  /// Custom hero (e.g. a Lottie). Defaults to the season emoji.
  final Widget? hero;

  static const double heroBox = 220;

  double _seg(double a, double b, Curve c) =>
      c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final pop = _seg(0.05, 0.40, Curves.elasticOut);
    final title = _seg(0.35, 0.58, Curves.easeOutCubic);
    final badge = _seg(0.55, 0.78, Curves.easeOutBack);
    final bob = _bob(t);
    final customHero = hero != null;

    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.white,
        decoration: TextDecoration.none,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: heroBox,
              height: heroBox,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RingsPainter(t: t, color: season.accent),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, bob),
                    child: Transform.scale(
                      scale: customHero ? 1 : pop,
                      child: Transform.rotate(
                        angle: customHero ? 0 : (1 - pop) * -0.5,
                        child:
                            hero ??
                            Text(
                              season.emoji,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 120,
                                decoration: TextDecoration.none,
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: title,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - title)),
                child: Text(
                  season.appTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: badge.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.6 + 0.4 * badge,
                child: const SeasonBadge(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _bob(double t) => 4 * _sin(t * 2 * 3.14159265 * 1.5);

  static double _sin(double x) {
    // dart:math-free sine to keep imports minimal.
    x = x % (2 * 3.14159265);
    if (x > 3.14159265) x -= 2 * 3.14159265;
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.longestSide * 1.6;
    for (var i = 0; i < 3; i++) {
      final local = ((t * 1.6) - i * 0.22).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final r = 60 + (maxR - 60) * Curves.easeOutCubic.transform(local);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = color.withOpacity((1 - local) * 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.t != t || old.color != color;
}
