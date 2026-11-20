import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/seasons/season_palette.dart';

/// Anchors the tour points at. Each is attached to exactly one widget.
class ProductTourKeys {
  ProductTourKeys._();
  static final style = GlobalKey(debugLabel: 'tour-style');
  static final prompt = GlobalKey(debugLabel: 'tour-prompt');
  static final promptsTab = GlobalKey(debugLabel: 'tour-prompts-tab');
  static final trendsTab = GlobalKey(debugLabel: 'tour-trends-tab');
  static final trendsHero = GlobalKey(debugLabel: 'tour-trends-hero');
  static final generate = GlobalKey(debugLabel: 'tour-generate');
  static final worldMap = GlobalKey(debugLabel: 'tour-world-map');
  static final themeMode = GlobalKey(debugLabel: 'tour-theme-mode');
  static final effects = GlobalKey(debugLabel: 'tour-effects');
  static final sound = GlobalKey(debugLabel: 'tour-sound');
  static final appIcon = GlobalKey(debugLabel: 'tour-app-icon');
  static final mapHere = GlobalKey(debugLabel: 'tour-map-here');
  static final mapAuto = GlobalKey(debugLabel: 'tour-map-auto');
}

class ProductTourService {
  ProductTourService._();
  static const _key = 'product_tour_done_v1';

  /// Bumped by "Replay app tour" in Profile; the main screen listens.
  static final replayRequests = ValueNotifier<int>(0);

  static Future<bool> isDone() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  static Future<void> markDone() async =>
      (await SharedPreferences.getInstance()).setBool(_key, true);
}

class TourStep {
  const TourStep({
    required this.target,
    this.alsoHighlight = const [],
    required this.icon,
    required this.title,
    required this.body,
    this.before,
    this.onTargetTap,
    this.actionLabel,
    this.padding = 8,
    this.radius = 20,
  });

  final GlobalKey target;

  /// More widgets lit together with [target]; the spotlight covers them all.
  final List<GlobalKey> alsoHighlight;
  final IconData icon;
  final String title;
  final String body;

  /// Runs before the step is measured (e.g. switch tab).
  final Future<void> Function()? before;

  /// Tapping the highlighted area. Defaults to "next".
  final VoidCallback? onTargetTap;

  /// Primary button label; defaults to Next / Done.
  final String? actionLabel;
  final double padding;
  final double radius;
}

/// Spotlight coach marks: dims the screen, cuts a hole around each target and
/// glides between them with a card that explains what to do.
class ProductTour {
  ProductTour._();
  static bool _running = false;
  static void Function(bool finished)? _closer;

  /// Ends the running tour (e.g. a step's action navigated away).
  static void close({bool finished = true}) => _closer?.call(finished);

  /// Returns true when the tour was finished, false when skipped.
  static Future<bool> show(BuildContext context, List<TourStep> steps) async {
    if (_running || steps.isEmpty) return false;
    _running = true;
    final done = Completer<bool>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TourOverlay(
        steps: steps,
        onClose: (finished) {
          entry.remove();
          _running = false;
          _closer = null;
          ProductTourService.markDone();
          done.complete(finished);
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return done.future;
  }
}

class _TourOverlay extends StatefulWidget {
  const _TourOverlay({required this.steps, required this.onClose});
  final List<TourStep> steps;
  final void Function(bool finished) onClose;

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  late final AnimationController _fadeIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  int _index = 0;
  Rect? _from;
  Rect? _to;
  bool _busy = false;
  bool _closing = false;

  TourStep get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    ProductTour._closer = _close;
    _goTo(0);
  }

  @override
  void dispose() {
    _move.dispose();
    _pulse.dispose();
    _fadeIn.dispose();
    super.dispose();
  }

  Rect? get _hole {
    if (_to == null) return null;
    final t = Curves.easeInOutCubic.transform(_move.value);
    return Rect.lerp(_from ?? _to, _to, t);
  }

  Future<void> _goTo(int i) async {
    if (_busy) return;
    _busy = true;
    for (; i < widget.steps.length; i++) {
      final step = widget.steps[i];
      await step.before?.call();
      await Future.delayed(const Duration(milliseconds: 280));
      final ctx = step.target.currentContext;
      if (ctx == null || !ctx.mounted) continue; // target not on screen: skip
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.25,
        duration: const Duration(milliseconds: 300),
      );
      if (!ctx.mounted) continue;
      Rect? bounds;
      for (final key in [step.target, ...step.alsoHighlight]) {
        final box = key.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize || !box.attached) continue;
        final r = box.localToGlobal(Offset.zero) & box.size;
        bounds = bounds == null ? r : bounds.expandToInclude(r);
      }
      if (bounds == null) continue;
      final rect = bounds.inflate(step.padding);
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _from = _hole ?? rect.deflate(rect.shortestSide / 2 - 1);
        _to = rect;
        _index = i;
      });
      _move.forward(from: 0);
      _busy = false;
      return;
    }
    _busy = false;
    _close(true); // ran out of reachable steps
  }

  void _next() {
    if (_isLast) {
      _close(true);
    } else {
      _goTo(_index + 1);
    }
  }

  Future<void> _close(bool finished) async {
    if (_closing) return;
    _closing = true;
    await _fadeIn.reverse();
    widget.onClose(finished);
  }

  void _onTapUp(TapUpDetails d) {
    final hole = _hole;
    if (_busy || hole == null || !hole.contains(d.globalPosition)) return;
    HapticFeedback.lightImpact();
    final custom = _step.onTargetTap;
    if (custom != null) {
      custom();
    } else {
      _next();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;
    return FadeTransition(
      opacity: _fadeIn,
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _onTapUp,
          child: AnimatedBuilder(
            animation: Listenable.merge([_move, _pulse]),
            builder: (context, _) {
              final hole = _hole;
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SpotlightPainter(
                        hole: hole,
                        radius: _step.radius,
                        pulse: _pulse.value,
                        ring: SeasonPalette.accent,
                      ),
                    ),
                  ),
                  if (hole != null) _card(hole, size, pad),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _card(Rect hole, Size size, EdgeInsets pad) {
    // Card goes where there is more room.
    final below = hole.center.dy < size.height / 2;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      left: 16,
      right: 16,
      top: below ? hole.bottom + 18 : null,
      bottom: below ? null : size.height - hole.top + 18,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: Offset(0, below ? -0.08 : 0.08),
              end: Offset.zero,
            ).animate(a),
            child: child,
          ),
        ),
        child: _TourCard(
          key: ValueKey(_index),
          step: _step,
          index: _index,
          total: widget.steps.length,
          isLast: _isLast,
          onNext: () {
            HapticFeedback.lightImpact();
            if (_isLast && _step.onTargetTap != null) {
              _step.onTargetTap!();
            } else {
              _next();
            }
          },
          onSkip: () => _close(false),
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final TourStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        decoration: BoxDecoration(
          color: SeasonPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: SeasonPalette.accent.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SeasonPalette.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    step.icon,
                    color: SeasonPalette.onAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(
                      color: SeasonPalette.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${index + 1}/$total',
                  style: TextStyle(
                    color: SeasonPalette.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              step.body,
              style: TextStyle(
                color: SeasonPalette.mutedText,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: (index + 1) / total),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 3,
                  color: SeasonPalette.accent,
                  backgroundColor: SeasonPalette.mutedText.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    isLast ? 'Maybe later' : 'Skip tour',
                    style: TextStyle(
                      color: SeasonPalette.mutedText,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: SeasonPalette.accent,
                    foregroundColor: SeasonPalette.onAccent,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    step.actionLabel ?? (isLast ? 'Done' : 'Next'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.pulse,
    required this.ring,
  });

  final Rect? hole;
  final double radius;
  final double pulse;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.74);
    if (hole == null) {
      canvas.drawPath(screen, dim);
      return;
    }
    final r = Radius.circular(radius);
    final cut = Path()..addRRect(RRect.fromRectAndRadius(hole!, r));
    canvas.drawPath(Path.combine(PathOperation.difference, screen, cut), dim);

    // Solid ring + a soft pulse that grows outward.
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole!, r),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );
    final grow = 4 + 12 * pulse;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        hole!.inflate(grow),
        Radius.circular(radius + grow),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring.withValues(alpha: 0.6 * (1 - pulse)),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.pulse != pulse || old.ring != ring;
}
