import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'season_registry.dart';
import 'season_splash_stage.dart';
import 'season_theme.dart';

/// Plays a full-screen, themed transition whenever [seasonId] changes:
/// the new season's color floods the screen, its emblem and name pop in,
/// then an iris opens to reveal the re-themed app.
///
/// Place it OUTSIDE the keyed MaterialApp so its state survives the rebuild.
class SeasonTransitionOverlay extends StatefulWidget {
  const SeasonTransitionOverlay({super.key, required this.seasonId});

  final SeasonId seasonId;

  @override
  State<SeasonTransitionOverlay> createState() =>
      _SeasonTransitionOverlayState();
}

class _SeasonTransitionOverlayState extends State<SeasonTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late SeasonTheme _season = SeasonRegistry.byId(widget.seasonId);

  @override
  void didUpdateWidget(covariant SeasonTransitionOverlay old) {
    super.didUpdateWidget(old);
    if (old.seasonId == widget.seasonId) return;
    _season = SeasonRegistry.byId(widget.seasonId);
    final reduce = SchedulerBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (!reduce) _c.forward(from: 0);
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
      builder: (context, _) {
        if (!_c.isAnimating) return const SizedBox.shrink();
        final t = _c.value;

        // 0.00–0.18 cover fades in, 0.18–0.62 emblem, 0.62–1.0 iris opens.
        final cover = Curves.easeOut.transform((t / 0.18).clamp(0.0, 1.0));
        final stageT = ((t - 0.08) / 0.55).clamp(0.0, 1.0);
        final iris = Curves.easeInOutCubic.transform(
          ((t - 0.62) / 0.38).clamp(0.0, 1.0),
        );
        final emblemFade = 1 - ((t - 0.58) / 0.2).clamp(0.0, 1.0);

        return Directionality(
          textDirection: TextDirection.ltr,
          child: LayoutBuilder(
            builder: (context, box) {
              final size = Size(box.maxWidth, box.maxHeight);
              final center = size.center(Offset.zero);
              final maxR =
                  math.sqrt(
                    size.width * size.width + size.height * size.height,
                  ) /
                  2;
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _IrisPainter(
                        color: _season.scaffoldBackground,
                        ring: _season.accent,
                        opacity: cover,
                        holeRadius: iris * maxR * 1.05,
                        center: center,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: emblemFade.clamp(0.0, 1.0),
                      child: SeasonSplashStage(season: _season, t: stageT),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _IrisPainter extends CustomPainter {
  _IrisPainter({
    required this.color,
    required this.ring,
    required this.opacity,
    required this.holeRadius,
    required this.center,
  });

  final Color color;
  final Color ring;
  final double opacity;
  final double holeRadius;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: holeRadius));
    final path = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(path, Paint()..color = color.withOpacity(opacity));

    if (holeRadius > 0) {
      canvas.drawCircle(
        center,
        holeRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = ring.withOpacity(
            (1 - holeRadius / (size.longestSide)).clamp(0.0, 1.0),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IrisPainter old) => true;
}
