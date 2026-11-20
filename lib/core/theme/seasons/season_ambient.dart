import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'season_decor.dart';
import 'season_palette.dart';
import 'season_provider.dart';

/// Quiet seasonal particles (embers, snow...) drifting behind a screen,
/// drawn from the active season's own effect. Place it under the content
/// (for example `Positioned.fill(child: SeasonAmbient())` in a Stack); it
/// ignores touches and stops with "reduce motion".
class SeasonAmbient extends StatefulWidget {
  const SeasonAmbient({super.key, this.opacity = 0.28, this.maxCount = 16});

  final double opacity;
  final int maxCount;

  @override
  State<SeasonAmbient> createState() => _SeasonAmbientState();
}

class _SeasonAmbientState extends State<SeasonAmbient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );
  late final List<_Particle> _particles = _build();

  @override
  void initState() {
    super.initState();
    final reduce = SchedulerBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (!reduce) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  List<_Particle> _build() {
    final fx = SeasonPalette.current.decor.effect;
    if (fx == null || fx.glyphs.isEmpty) return const [];
    final r = math.Random(21);
    return [
      for (var i = 0; i < math.min(fx.count, widget.maxCount); i++)
        _Particle(
          painter: TextPainter(
            text: TextSpan(
              text: fx.glyphs[i % fx.glyphs.length],
              style: TextStyle(
                fontSize:
                    (fx.minSize + r.nextDouble() * (fx.maxSize - fx.minSize)) *
                    0.9,
                color: (fx.color ?? Colors.white).withOpacity(widget.opacity),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
          x: r.nextDouble(),
          phase: r.nextDouble(),
          speed: 0.6 + r.nextDouble() * 0.8,
          sway: r.nextDouble() * math.pi * 2,
          rise: fx.kind == SeasonEffectKind.rise,
          amp: fx.sway,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty || !context.watch<SeasonProvider>().effectsEnabled) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _AmbientPainter(_particles, _c.value),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.painter,
    required this.x,
    required this.phase,
    required this.speed,
    required this.sway,
    required this.rise,
    required this.amp,
  });

  final TextPainter painter;
  final double x;
  final double phase;
  final double speed;
  final double sway;
  final bool rise;
  final double amp;
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final f = (p.phase + t * p.speed) % 1.0;
      final y = (p.rise ? 1 - f : f) * (size.height + 40) - 20;
      final x =
          p.x * size.width +
          math.sin(t * math.pi * 2 * p.speed + p.sway) * p.amp;
      p.painter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) => old.t != t;
}
