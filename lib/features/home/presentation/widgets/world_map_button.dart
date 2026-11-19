import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/seasons/season_palette.dart';

/// App-bar entry to the world map: a small glowing medallion that shows the
/// current season's emblem, with a slow pulsing ring so
/// it reads as "something to explore". The ring stops with reduced motion.
class WorldMapButton extends StatefulWidget {
  const WorldMapButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<WorldMapButton> createState() => _WorldMapButtonState();
}

class _WorldMapButtonState extends State<WorldMapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = SchedulerBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduce) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final season = SeasonPalette.current;
    return Semantics(
      button: true,
      label: 'World map',
      child: Tooltip(
        message: 'World map',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onPressed();
          },
          child: SizedBox(
            width: 52,
            height: 52,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Expanding ring.
                    Container(
                      width: 38 + 14 * t,
                      height: 38 + 14 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: season.accent.withOpacity(0.55 * (1 - t)),
                          width: 2,
                        ),
                      ),
                    ),
                    // Medallion.
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.4, -0.5),
                          colors: [
                            Color.lerp(
                              season.secondaryAccent,
                              Colors.white,
                              0.3,
                            )!,
                            season.accent,
                            Color.lerp(season.accent, Colors.black, 0.45)!,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: season.accent.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      // Emoji glyphs carry extra line padding; a fixed strut and no
                      // ascent/descent padding put the glyph on the true center.
                      child: Transform.translate(
                        // Emoji glyphs sit a little left of center in the circle.
                        offset: const Offset(0.5, 0),
                        child: Text(
                          season.emoji,
                          textAlign: TextAlign.center,
                          strutStyle: const StrutStyle(
                            fontSize: 19,
                            height: 1,
                            forceStrutHeight: true,
                            leading: 0,
                          ),
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                            applyHeightToLastDescent: false,
                          ),
                          style: const TextStyle(fontSize: 19, height: 1),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
