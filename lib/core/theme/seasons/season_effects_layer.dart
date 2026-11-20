import 'dart:math';

import 'package:flutter/material.dart';

import 'season_decor.dart';
import 'season_palette.dart';

/// Draws the active season's ambient particles above the whole app.
/// Ignores touches and is disabled when the OS asks to reduce motion.
class SeasonEffectsLayer extends StatelessWidget {
  const SeasonEffectsLayer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;

  /// The user's "Theme effects" setting.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effect = SeasonPalette.current.decor.effect;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!enabled || effect == null || reduce) return child;

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: _Particles(effect: effect)),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  _Particle(Random r, SeasonEffect e)
    : x = r.nextDouble(),
      phase = r.nextDouble(),
      size = e.minSize + r.nextDouble() * (e.maxSize - e.minSize),
      speed = e.minSpeed + r.nextDouble() * (e.maxSpeed - e.minSpeed),
      wobble = r.nextDouble() * 2 * pi,
      glyph = e.glyphs[r.nextInt(e.glyphs.length)];

  final double x;
  final double phase;
  final double size;
  final double speed;
  final double wobble;
  final String glyph;
}

class _Particles extends StatefulWidget {
  const _Particles({required this.effect});
  final SeasonEffect effect;

  @override
  State<_Particles> createState() => _ParticlesState();
}

class _ParticlesState extends State<_Particles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late List<_Particle> _ps;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..repeat();
    _ps = _make();
  }

  List<_Particle> _make() {
    final r = Random(7);
    return List.generate(
      widget.effect.count,
      (_) => _Particle(r, widget.effect),
    );
  }

  @override
  void didUpdateWidget(covariant _Particles old) {
    super.didUpdateWidget(old);
    if (old.effect != widget.effect) _ps = _make();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(
          effect: widget.effect,
          particles: _ps,
          seconds: _c.lastElapsedDuration?.inMicroseconds == null
              ? 0
              : _c.lastElapsedDuration!.inMicroseconds / 1e6,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.effect,
    required this.particles,
    required this.seconds,
  });

  final SeasonEffect effect;
  final List<_Particle> particles;
  final double seconds;

  static final Map<String, TextPainter> _cache = {};

  TextPainter _painter(String glyph, double size) {
    final key =
        '$glyph@${size.round()}@${effect.color?.value}@${effect.opacity}';
    return _cache.putIfAbsent(key, () {
      final base = effect.color;
      return TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            fontSize: size,
            color: base?.withOpacity(effect.opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final travel = (p.phase + seconds * p.speed) % 1.0;
      final yFrac = effect.kind == SeasonEffectKind.fall ? travel : 1 - travel;
      final y = yFrac * (size.height + p.size * 2) - p.size;
      final x = p.x * size.width + sin(seconds * 0.8 + p.wobble) * effect.sway;
      final tp = _painter(p.glyph, p.size);
      if (effect.color == null) {
        canvas.saveLayer(
          Rect.fromLTWH(x, y, p.size * 2, p.size * 2),
          Paint()..color = Colors.white.withOpacity(effect.opacity),
        );
        tp.paint(canvas, Offset(x, y));
        canvas.restore();
      } else {
        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
