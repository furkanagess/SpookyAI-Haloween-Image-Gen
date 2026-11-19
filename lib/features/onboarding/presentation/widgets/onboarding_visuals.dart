import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/theme/seasons/season_registry.dart';
import '../../../../core/theme/seasons/season_theme.dart';

const String _h = 'assets/images/haloween';
const String _x = 'assets/images/christmas/text-to-image';

/// Rounded asset image used by every onboarding visual.
class _Art extends StatelessWidget {
  const _Art(this.asset, {this.radius = 20, this.cacheWidth = 600});
  final String asset;
  final double radius;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(
      asset,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => ColoredBox(color: SeasonPalette.card),
    ),
  );
}

BoxDecoration _glow(Color c, {double radius = 22}) => BoxDecoration(
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: c.withValues(alpha: 0.35),
      blurRadius: 30,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ],
);

// ---------------------------------------------------------------------------
// 1. Welcome: a floating fan of finished artworks. Tap to shuffle.
// ---------------------------------------------------------------------------
class WelcomeVisual extends StatefulWidget {
  const WelcomeVisual({super.key, required this.active});
  final bool active;

  @override
  State<WelcomeVisual> createState() => _WelcomeVisualState();
}

class _WelcomeVisualState extends State<WelcomeVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  List<String> _cards = const [
    '$_h/text-to-image/raven_queen.jpg',
    '$_x/frost_queen.jpg',
    '$_h/text-to-image/pumpkin_king.png',
  ];

  void _shuffle() {
    HapticFeedback.lightImpact();
    setState(() => _cards = [..._cards.sublist(1), _cards.first]);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Example artworks. Tap to shuffle.',
      child: GestureDetector(
        onTap: _shuffle,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = math.min(c.maxWidth * 0.6, c.maxHeight * 0.68);
            return AnimatedBuilder(
              animation: _float,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_float.value);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int depth = _cards.length - 1; depth >= 0; depth--)
                      _card(_cards[depth], depth, w, t),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _card(String asset, int depth, double w, double t) {
    // depth 0 = front card.
    const angles = [0.0, -0.20, 0.20];
    const dx = [0.0, -0.42, 0.42];
    final bob = (depth == 0 ? -10 : 6) * (t - 0.5) * 2;
    final m = Matrix4.identity()
      ..translateByDouble(w * dx[depth], depth * 18.0 + bob, 0, 1)
      ..rotateZ(angles[depth] + (depth == 0 ? 0.03 * (t - 0.5) : 0))
      ..scaleByDouble(depth == 0 ? 1.0 : 0.86, depth == 0 ? 1.0 : 0.86, 1, 1);
    return AnimatedContainer(
      key: ValueKey(asset),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutBack,
      transform: m,
      transformAlignment: Alignment.center,
      width: w,
      height: w * 1.35,
      decoration: _glow(
        depth == 0 ? SeasonPalette.accent : Colors.black,
        radius: 24,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: depth == 0 ? 1 : 0.75,
        child: _Art(asset, radius: 24),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Text to image: a prompt types itself, then the artwork develops.
// ---------------------------------------------------------------------------
class TextToImageVisual extends StatefulWidget {
  const TextToImageVisual({super.key, required this.active});
  final bool active;

  @override
  State<TextToImageVisual> createState() => _TextToImageVisualState();
}

class _TextToImageVisualState extends State<TextToImageVisual>
    with SingleTickerProviderStateMixin {
  static const _demos = [
    (
      'A black cat on a moonlit fence, cinematic',
      '$_h/text-to-image/blackcat.jpg',
    ),
    ('A ghost bride in a candlelit manor', '$_h/text-to-image/ghost_bride.jpg'),
    ('A snowman holding a glowing lantern', '$_x/lantern_snowman.jpg'),
  ];

  late final AnimationController _c =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3600),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted && widget.active) {
          setState(() => _i = (_i + 1) % _demos.length);
          _c.forward(from: 0);
        }
      });
  int _i = 0;

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.forward();
  }

  @override
  void didUpdateWidget(TextToImageVisual old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.forward(from: 0);
    if (!widget.active) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _replay() {
    HapticFeedback.selectionClick();
    setState(() => _i = (_i + 1) % _demos.length);
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final (prompt, asset) = _demos[_i];
    return Semantics(
      button: true,
      label: 'Prompt demo: $prompt. Tap for another example.',
      child: GestureDetector(
        onTap: _replay,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = _c.value;
            final typed = (v / 0.25).clamp(0.0, 1.0);
            final press = v > 0.26 && v < 0.32;
            final loading = ((v - 0.30) / 0.15).clamp(0.0, 1.0);
            final reveal = Curves.easeOutCubic.transform(
              ((v - 0.42) / 0.13).clamp(0.0, 1.0),
            );
            final chars = (prompt.length * typed).round();
            return LayoutBuilder(
              builder: (context, c) {
                final side = math.min(c.maxWidth * 0.92, c.maxHeight - 84);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _promptBar(
                      prompt.substring(0, chars),
                      typed < 1,
                      press,
                      side,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: side,
                      height: side,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: _glow(
                              SeasonPalette.accent,
                            ).copyWith(color: SeasonPalette.card),
                          ),
                          if (loading > 0 && reveal < 1)
                            _Shimmer(progress: loading),
                          Opacity(
                            opacity: reveal,
                            child: Transform.scale(
                              scale: 0.92 + 0.08 * reveal,
                              child: _Art(asset, radius: 22),
                            ),
                          ),
                          if (loading == 0)
                            Center(
                              child: Icon(
                                Icons.auto_awesome,
                                size: 42,
                                color: SeasonPalette.mutedText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _promptBar(String text, bool caret, bool press, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: SeasonPalette.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SeasonPalette.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$text${caret ? '|' : ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SeasonPalette.text,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedScale(
            scale: press ? 0.85 : 1,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SeasonPalette.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: SeasonPalette.onAccent,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final x = -1.5 + 3 * ((progress * 2) % 1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(x - 1, -0.3),
            end: Alignment(x + 1, 0.3),
            colors: [
              SeasonPalette.card,
              SeasonPalette.accent.withValues(alpha: 0.35),
              SeasonPalette.card,
            ],
          ),
        ),
        child: Center(
          child: Text(
            'Creating…',
            style: TextStyle(
              color: SeasonPalette.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Photo to image: drag the divider to compare the selfie and the result.
// ---------------------------------------------------------------------------
class PhotoTransformVisual extends StatefulWidget {
  const PhotoTransformVisual({super.key, required this.active});
  final bool active;

  @override
  State<PhotoTransformVisual> createState() => _PhotoTransformVisualState();
}

class _PhotoTransformVisualState extends State<PhotoTransformVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  double _pos = 0.5;
  bool _touched = false;

  @override
  void didUpdateWidget(PhotoTransformVisual old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !_touched) _hint.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _hint.addListener(() {
      if (_touched) return;
      // Sweep 0.5 -> 0.15 -> 0.85 -> 0.5 to show the divider moves.
      final t = _hint.value;
      setState(() => _pos = 0.5 - 0.35 * math.sin(t * 2 * math.pi));
    });
    if (widget.active) _hint.forward();
  }

  @override
  void dispose() {
    _hint.dispose();
    super.dispose();
  }

  void _drag(double dx, double width) {
    if (!_touched) {
      _touched = true;
      _hint.stop();
    }
    setState(() => _pos = (_pos + dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = math.min(c.maxWidth * 0.92, c.maxHeight * 0.88);
        final h = math.min(w * 1.15, c.maxHeight);
        return Center(
          child: Semantics(
            slider: true,
            label: 'Before and after comparison',
            value: '${(_pos * 100).round()} percent original photo',
            child: GestureDetector(
              onHorizontalDragUpdate: (d) => _drag(d.delta.dx, w),
              child: Container(
                width: w,
                height: h,
                decoration: _glow(SeasonPalette.accent, radius: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const _Art(
                        '$_h/image-to-image/enchantedd_witch.png',
                        radius: 0,
                      ),
                      ClipRect(
                        clipper: _LeftClip(_pos),
                        child: const _Art('assets/images/girl.jpeg', radius: 0),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _Tag('Your photo', _pos > 0.2),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: _Tag('SpookyAI', _pos < 0.8),
                      ),
                      Positioned(
                        left: w * _pos - 22,
                        top: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(width: 3, color: Colors.white),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.compare_arrows,
                                  color: Colors.black87,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LeftClip extends CustomClipper<Rect> {
  _LeftClip(this.f);
  final double f;
  @override
  Rect getClip(Size s) => Rect.fromLTWH(0, 0, s.width * f, s.height);
  @override
  bool shouldReclip(_LeftClip old) => old.f != f;
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.visible);
  final String text;
  final bool visible;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: visible ? 1 : 0,
    duration: const Duration(milliseconds: 200),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 5. Season map: a trail of worlds. Open ones can be picked, the rest unlock
// later in the year. The app follows the calendar on its own.
// ---------------------------------------------------------------------------
class _World {
  const _World(
    this.name,
    this.emoji,
    this.accent,
    this.pos, {
    this.open = false,
  });
  final String name;
  final String emoji;
  final Color accent;
  final Offset pos; // relative (0..1) position of the node centre
  final bool open;
}

class SeasonMapVisual extends StatefulWidget {
  const SeasonMapVisual({super.key, required this.active});
  final bool active;

  @override
  State<SeasonMapVisual> createState() => _SeasonMapVisualState();
}

class _SeasonMapVisualState extends State<SeasonMapVisual>
    with SingleTickerProviderStateMixin {
  static const _worlds = [
    _World(
      'Halloween',
      '🎃',
      Color(0xFFFF6A00),
      Offset(0.24, 0.84),
      open: true,
    ),
    _World(
      'Christmas',
      '🎄',
      Color(0xFFE53935),
      Offset(0.74, 0.64),
      open: true,
    ),
    _World("New Year's Eve", '🎆', Color(0xFFFFD54F), Offset(0.28, 0.44)),
    _World('Lunar New Year', '🏮', Color(0xFFE8436E), Offset(0.72, 0.25)),
    _World('Spring', '🌸', Color(0xFFF48FB1), Offset(0.32, 0.07)),
  ];

  late int _selected =
      SeasonRegistry.forDate(DateTime.now()) == SeasonId.christmas ? 1 : 0;
  int? _locked; // locked world last tapped
  int _shake = 0;
  bool _touched = false;
  Timer? _demo;
  Timer? _lockReset;
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    if (widget.active) _startDemo();
  }

  @override
  void didUpdateWidget(SeasonMapVisual old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _startDemo();
    if (!widget.active) _demo?.cancel();
  }

  void _startDemo() {
    _demo?.cancel();
    if (_touched) return;
    _demo = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (mounted) setState(() => _selected = 1 - _selected);
    });
  }

  void _tap(int i) {
    _touched = true;
    _demo?.cancel();
    _lockReset?.cancel();
    if (_worlds[i].open) {
      HapticFeedback.selectionClick();
      setState(() {
        _selected = i;
        _locked = null;
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _locked = i;
        _shake++;
      });
      _lockReset = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _locked = null);
      });
    }
  }

  @override
  void dispose() {
    _demo?.cancel();
    _lockReset?.cancel();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = _worlds[_selected];
    return LayoutBuilder(
      builder: (context, c) {
        final w = math.min(c.maxWidth, 420.0);
        final h = c.maxHeight - 52; // room for the status pill
        final node = math.min(56.0, h / 6.5);
        Offset at(_World x) => Offset(x.pos.dx * w, x.pos.dy * h + node / 2);
        return Center(
          child: SizedBox(
            width: w,
            height: c.maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Season-tinted glow behind the map.
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: RadialGradient(
                        center: Alignment(
                          sel.pos.dx * 2 - 1,
                          sel.pos.dy * 2 - 1,
                        ),
                        radius: 1.0,
                        colors: [
                          sel.accent.withValues(alpha: 0.30),
                          sel.accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  width: w,
                  height: h + node,
                  child: CustomPaint(
                    painter: _TrailPainter(
                      points: [for (final x in _worlds) at(x)],
                      litUntil: 1,
                      lit: sel.accent,
                      dim: SeasonPalette.mutedText.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                for (int i = 0; i < _worlds.length; i++)
                  _nodeAt(i, at(_worlds[i]), node),
                // Bouncing marker above the selected world.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeInOutBack,
                  left: at(sel).dx - 16,
                  top: at(sel).dy - node / 2 - 36,
                  child: AnimatedBuilder(
                    animation: _bob,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        0,
                        -5 * Curves.easeInOut.transform(_bob.value),
                      ),
                      child: child,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 32,
                      color: Colors.white,
                      shadows: [Shadow(color: sel.accent, blurRadius: 12)],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(child: _status(sel)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _nodeAt(int i, Offset c, double size) {
    final x = _worlds[i];
    final selected = i == _selected;
    final shaking = i == _locked;
    return Positioned(
      left: c.dx - size / 2,
      top: c.dy - size / 2,
      child: Semantics(
        button: true,
        selected: selected,
        label: x.open ? '${x.name} world' : '${x.name}, coming soon',
        child: GestureDetector(
          onTap: () => _tap(i),
          child: TweenAnimationBuilder<double>(
            key: ValueKey('n$i-${shaking ? _shake : 0}'),
            tween: Tween(begin: shaking ? 1 : 0, end: 0),
            duration: const Duration(milliseconds: 450),
            builder: (context, v, child) => Transform.translate(
              offset: Offset(math.sin(v * math.pi * 6) * 6 * v, 0),
              child: child,
            ),
            child: AnimatedScale(
              scale: selected ? 1.15 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: x.open
                      ? x.accent.withValues(alpha: selected ? 0.95 : 0.55)
                      : SeasonPalette.card,
                  border: Border.all(
                    color: x.open
                        ? Colors.white.withValues(alpha: selected ? 0.9 : 0.4)
                        : x.accent.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: x.accent.withValues(alpha: 0.6),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: x.open ? 1 : 0.35,
                      child: Text(
                        x.emoji,
                        style: TextStyle(fontSize: size * 0.46),
                      ),
                    ),
                    if (!x.open)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Icon(
                          Icons.lock_rounded,
                          size: size * 0.3,
                          color: SeasonPalette.mutedText,
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

  Widget _status(_World sel) {
    final locked = _locked == null ? null : _worlds[_locked!];
    final text = locked != null
        ? '${locked.emoji}  ${locked.name} · coming soon'
        : '${sel.emoji}  ${sel.name} world is active';
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: SeasonPalette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (locked ?? sel).accent.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: SeasonPalette.text,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.points,
    required this.litUntil,
    required this.lit,
    required this.dim,
  });
  final List<Offset> points;
  final int litUntil; // segments up to this node index are lit
  final Color lit;
  final Color dim;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final ctrl = Offset(
        (a.dx + b.dx) / 2 + (i.isEven ? 40 : -40),
        (a.dy + b.dy) / 2,
      );
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      final on = i < litUntil;
      final paint = Paint()
        ..color = on ? lit.withValues(alpha: 0.85) : dim
        ..strokeWidth = on ? 4 : 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (on) {
        canvas.drawPath(path, paint);
      } else {
        // Dotted trail towards worlds that are still locked.
        for (final m in path.computeMetrics()) {
          for (double d = 0; d < m.length; d += 12) {
            final p = m.getTangentForOffset(d)!.position;
            canvas.drawCircle(p, 2, paint..style = PaintingStyle.fill);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.lit != lit || old.points != points;
}

// ---------------------------------------------------------------------------
// 4. Image to video: the photo "wakes up". It sits faded while a ring
// charges and sparks gather, then a shockwave hits and it starts to move.
// Tap to wake it now (or skip to the next example).
// ---------------------------------------------------------------------------
class ImageToVideoVisual extends StatefulWidget {
  const ImageToVideoVisual({super.key, required this.active});
  final bool active;

  @override
  State<ImageToVideoVisual> createState() => _ImageToVideoVisualState();
}

class _ImageToVideoVisualState extends State<ImageToVideoVisual>
    with SingleTickerProviderStateMixin {
  static const _dir = 'assets/images/haloween/image-to-video';
  static const _samples = ['blackcat', 'telephone'];

  // Cycle phases (fractions of one loop).
  static const _wake = 0.26; // charge ends, shockwave starts
  static const _live = 0.34; // video fully visible
  static const _fade = 0.94; // back to the next photo

  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7200),
  );
  final List<VideoPlayerController?> _videos = [null, null];
  final List<bool> _ready = [false, false];
  int _sample = 0;
  double _last = 0;

  @override
  void initState() {
    super.initState();
    _cycle.addListener(_onTick);
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(ImageToVideoVisual old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _start();
    if (!widget.active && old.active) {
      _cycle.stop();
      _cycle.value = 0;
      _video?.pause();
    }
  }

  VideoPlayerController? get _video => _videos[_sample];

  void _start() {
    for (var i = 0; i < _samples.length; i++) {
      if (_videos[i] == null) _load(i);
    }
    _last = 0;
    _cycle.repeat();
  }

  Future<void> _load(int i) async {
    final c = VideoPlayerController.asset(
      '$_dir/${_samples[i]}.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _videos[i] = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      if (mounted) setState(() => _ready[i] = true);
    } catch (e) {
      // No video plugin (tests) or a decode error: the photo animates instead.
      debugPrint('ImageToVideoVisual: ${_samples[i]} failed: $e');
    }
  }

  void _onTick() {
    final v = _cycle.value;
    if (v < _last) {
      // Wrapped: next example.
      _video?.pause();
      setState(() => _sample = (_sample + 1) % _samples.length);
    }
    if (_last < _wake && v >= _wake && _ready[_sample]) {
      _video!
        ..seekTo(Duration.zero)
        ..play();
      HapticFeedback.mediumImpact();
    }
    _last = v;
  }

  void _tap() {
    HapticFeedback.lightImpact();
    if (!_cycle.isAnimating) return;
    if (_cycle.value < _wake) {
      _cycle.value = _wake - 0.001;
      _cycle.repeat();
    } else {
      _cycle.value = 0.999;
      _cycle.repeat();
    }
  }

  @override
  void dispose() {
    _cycle.dispose();
    for (final v in _videos) {
      v?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    return Semantics(
      button: true,
      label: 'A photo turning into a video. Tap to bring it to life.',
      child: GestureDetector(
        onTap: _tap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, c) {
            final side = math.min(c.maxWidth * 0.92, (c.maxHeight - 8) / 1.22);
            return Center(
              child: AnimatedBuilder(
                animation: _cycle,
                builder: (context, _) {
                  final v = _cycle.value;
                  final charge = (v / _wake).clamp(0.0, 1.0);
                  final shock = ((v - _wake) / (_live - _wake)).clamp(0.0, 1.0);
                  final out = ((v - _fade) / (1 - _fade)).clamp(0.0, 1.0);
                  final live = v >= _wake && out < 1;
                  final videoOpacity = (shock * (1 - out)).clamp(0.0, 1.0);
                  final playT = ((v - _wake) / (_fade - _wake)).clamp(0.0, 1.0);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: side,
                        height: side * 1.22,
                        decoration: _glow(
                          Color.lerp(Colors.black, accent, 0.3 + 0.7 * shock)!,
                          radius: 26,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _still(charge, live, playT),
                              if (_ready[_sample] && videoOpacity > 0)
                                Opacity(
                                  opacity: videoOpacity,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _video!.value.size.width,
                                      height: _video!.value.size.height,
                                      child: VideoPlayer(_video!),
                                    ),
                                  ),
                                ),
                              CustomPaint(
                                painter: _WakePainter(
                                  charge: live ? 1 : charge,
                                  shock: shock,
                                  showCharge: !live,
                                  color: accent,
                                ),
                              ),
                              if (!live) Center(child: _playButton(charge)),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: _modeTag(live),
                              ),
                              if (live)
                                Positioned(
                                  left: 14,
                                  right: 14,
                                  bottom: 14,
                                  child: _timeline(playT, accent),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// The photo: faded and still while charging; slow push-in once alive
  /// (this is what shows when the video cannot play).
  Widget _still(double charge, bool live, double playT) {
    final sat = live ? 1.0 : 0.25 + 0.45 * charge;
    return Transform.scale(
      scale: live ? 1.0 + 0.08 * playT : 1.0,
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(_saturation(sat)),
        child: _Art('$_dir/${_samples[_sample]}.jpg', radius: 0),
      ),
    );
  }

  Widget _playButton(double charge) {
    return Transform.scale(
      scale: 0.9 + 0.2 * Curves.easeIn.transform(charge),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
          border: Border.all(color: Colors.white24),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _modeTag(bool live) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, a) => ScaleTransition(
        scale: a,
        child: FadeTransition(opacity: a, child: child),
      ),
      child: Container(
        key: ValueKey(live),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: live
              ? const Color(0xFFE53935)
              : Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              live ? Icons.videocam_rounded : Icons.photo_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              live ? 'Video' : 'Photo',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline(double t, Color accent) {
    final secs = (t * 5).floor();
    return Row(
      children: [
        Text(
          '0:0$secs',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
            shadows: [Shadow(blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: t,
              child: Container(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: accent, blurRadius: 6)],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '0:05',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

/// Color matrix that scales saturation (0 = gray, 1 = original).
List<double> _saturation(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  return [
    r * (1 - s) + s, g * (1 - s), b * (1 - s), 0, 0, //
    r * (1 - s), g * (1 - s) + s, b * (1 - s), 0, 0, //
    r * (1 - s), g * (1 - s), b * (1 - s) + s, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

/// Charge ring with sparks spiralling in, then an expanding shockwave.
class _WakePainter extends CustomPainter {
  _WakePainter({
    required this.charge,
    required this.shock,
    required this.showCharge,
    required this.color,
  });
  final double charge;
  final double shock;
  final bool showCharge;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (showCharge) {
      // Ring around the play button.
      canvas.drawCircle(
        c,
        40,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Colors.white.withValues(alpha: 0.18),
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 40),
        -math.pi / 2,
        2 * math.pi * charge,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
      // Sparks spiralling toward the center.
      final reach = size.shortestSide * 0.48;
      for (var i = 0; i < 16; i++) {
        final a = i / 16 * 2 * math.pi + charge * 2.4;
        final r =
            46 + (reach - 46) * (1 - charge) * (0.6 + 0.4 * ((i * 7) % 5) / 4);
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * r,
          1.6 + 1.6 * charge,
          Paint()
            ..color = Color.lerp(
              Colors.white,
              color,
              i.isEven ? 0.2 : 0.8,
            )!.withValues(alpha: 0.25 + 0.75 * charge)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
    if (shock > 0 && shock < 1) {
      final maxR = size.longestSide * 0.8;
      // White flash, then two rings racing outward.
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: 0.5 * (1 - shock)),
      );
      for (final lag in const [0.0, 0.18]) {
        final t = ((shock - lag) / (1 - lag)).clamp(0.0, 1.0);
        if (t <= 0) continue;
        canvas.drawCircle(
          c,
          40 + maxR * Curves.easeOut.transform(t),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10 * (1 - t) + 1
            ..color = color.withValues(alpha: 1 - t)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WakePainter old) =>
      old.charge != charge ||
      old.shock != shock ||
      old.showCharge != showCharge;
}

// ---------------------------------------------------------------------------
// 5. Trends: a vertical feed you flick through. Each look fills a phone-like
// screen with a side rail; it slides up to the next one on its own, and the
// user can swipe or double-tap to like.
// ---------------------------------------------------------------------------
class _TrendDrop {
  const _TrendDrop(this.asset, this.tag, this.title, this.color);
  final String asset;
  final String tag;
  final String title;
  final Color color;
}

class TrendsVisual extends StatefulWidget {
  const TrendsVisual({super.key, required this.active});
  final bool active;

  @override
  State<TrendsVisual> createState() => _TrendsVisualState();
}

class _TrendsVisualState extends State<TrendsVisual>
    with TickerProviderStateMixin {
  static const _t = 'assets/images/trends';
  static const _drops = [
    _TrendDrop(
      '$_t/snow_globe.jpg',
      '#ChristmasPhotobooth',
      'Inside a Snow Globe',
      Color(0xFFE53935),
    ),
    _TrendDrop(
      '$_t/chibi_sticker.jpg',
      '#ActionFigureBox',
      'Chibi Sticker',
      Color(0xFF7C4DFF),
    ),
    _TrendDrop(
      '$_t/film_flash.jpg',
      '#Y2KFilm',
      '90s Film Flash',
      Color(0xFFFF8A00),
    ),
    _TrendDrop(
      '$_t/collector_figure.jpg',
      '#ActionFigureBox',
      'Collector Figure',
      Color(0xFFFF2D95),
    ),
  ];
  static const _start = 400; // lets the feed run "forever" both ways

  final PageController _page = PageController(initialPage: _start);
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  late final AnimationController _heart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  final Set<int> _liked = {};
  Timer? _timer;
  int _index = _start;

  _TrendDrop get _drop => _drops[_index % _drops.length];

  @override
  void initState() {
    super.initState();
    if (widget.active) _startTimer();
  }

  @override
  void didUpdateWidget(TrendsVisual old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _startTimer();
    if (!widget.active) _timer?.cancel();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 2900), (_) {
      if (!mounted || !_page.hasClients) return;
      _page.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPage(int i) {
    setState(() => _index = i);
    // Every other look gets an automatic like, to show the gesture.
    if (widget.active && i.isOdd) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _index == i) _like(haptic: false);
      });
    }
  }

  void _like({bool haptic = true}) {
    if (haptic) HapticFeedback.lightImpact();
    setState(() => _liked.add(_index));
    _heart.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    _spin.dispose();
    _heart.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Laid out at a fixed phone size, then scaled to fit any screen.
        const w = 230.0, h = 400.0;
        final fit = math.min(c.maxWidth * 0.84 / w, c.maxHeight / h);
        return Center(
          child: SizedBox(
            width: w * fit,
            height: h * fit,
            child: FittedBox(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: w,
                height: h,
                decoration: _glow(_drop.color, radius: 24),
                child: AnimatedBuilder(
                  animation: _spin,
                  builder: (context, child) => CustomPaint(
                    foregroundPainter: _RunningLightPainter(
                      _spin.value * 1.5 % 1,
                      _drop.color,
                    ),
                    child: child,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        NotificationListener<ScrollStartNotification>(
                          onNotification: (n) {
                            // The user took over: restart the auto-advance.
                            if (n.dragDetails != null && widget.active) {
                              _startTimer();
                            }
                            return false;
                          },
                          child: Semantics(
                            label:
                                'Trend feed. Swipe up for the next trend, '
                                'double-tap to like.',
                            child: GestureDetector(
                              onDoubleTap: _like,
                              child: PageView.builder(
                                controller: _page,
                                scrollDirection: Axis.vertical,
                                onPageChanged: _onPage,
                                itemBuilder: (context, i) => _post(i, w),
                              ),
                            ),
                          ),
                        ),
                        _topBar(),
                        _heartBurst(w),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar() {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Saved',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Trending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 18,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _post(int i, double w) {
    final d = _drops[i % _drops.length];
    final liked = _liked.contains(i);
    return Stack(
      fit: StackFit.expand,
      children: [
        _Art(d.asset, radius: 0, cacheWidth: 500),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.18, 0.55, 1],
              colors: [
                Color(0x88000000),
                Colors.transparent,
                Colors.transparent,
                Color(0xEE000000),
              ],
            ),
          ),
        ),
        // Side rail.
        Positioned(
          right: 8,
          bottom: 56,
          child: Column(
            children: [
              _avatar(d.color),
              const SizedBox(height: 14),
              _railButton(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                'Like',
                color: liked ? const Color(0xFFFF2D55) : Colors.white,
                pop: liked,
              ),
              const SizedBox(height: 12),
              _railButton(Icons.auto_awesome_rounded, 'Try', fill: d.color),
              const SizedBox(height: 12),
              _railButton(Icons.ios_share_rounded, 'Share'),
            ],
          ),
        ),
        // Caption.
        Positioned(
          left: 12,
          right: 64,
          bottom: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                d.tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color.lerp(d.color, Colors.white, 0.35),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                d.title,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFFB300),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Trending now',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Spinning disc.
        Positioned(
          right: 12,
          bottom: 14,
          child: RotationTransition(
            turns: _spin,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    const Color(0xFF222222),
                    d.color,
                    const Color(0xFF222222),
                  ],
                ),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        // Swipe-up nudge.
        Positioned(
          left: 0,
          right: 0,
          bottom: 2,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _bounce,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -4 * _bounce.value),
                child: child,
              ),
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatar(Color c) {
    return SizedBox(
      width: 40,
      height: 46,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [SeasonPalette.accent, c]),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _railButton(
    IconData icon,
    String label, {
    Color color = Colors.white,
    Color? fill,
    bool pop = false,
  }) {
    return Column(
      children: [
        AnimatedScale(
          scale: pop ? 1.15 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: Container(
            width: 38,
            height: 38,
            decoration: fill == null
                ? null
                : BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                    boxShadow: [
                      BoxShadow(
                        color: fill.withValues(alpha: 0.6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
            child: Icon(
              icon,
              color: color,
              size: fill == null ? 30 : 20,
              shadows: const [Shadow(blurRadius: 8)],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(blurRadius: 6)],
          ),
        ),
      ],
    );
  }

  Widget _heartBurst(double w) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _heart,
        builder: (context, _) {
          final v = _heart.value;
          if (v == 0 || v == 1) return const SizedBox.shrink();
          final scale = Curves.elasticOut.transform(math.min(1, v * 1.8));
          final fade = v < 0.6 ? 1.0 : 1 - (v - 0.6) / 0.4;
          return Center(
            child: Opacity(
              opacity: fade,
              child: Transform.scale(
                scale: 0.4 + 0.8 * scale,
                child: Transform.rotate(
                  angle: -0.15,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: w * 0.38,
                    color: const Color(0xFFFF2D55),
                    shadows: const [
                      Shadow(color: Color(0x88FF2D55), blurRadius: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A bright arc of light running around a rounded card.
class _RunningLightPainter extends CustomPainter {
  _RunningLightPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final shader = SweepGradient(
      transform: GradientRotation(progress * 2 * math.pi),
      colors: [
        Colors.transparent,
        color.withValues(alpha: 0.2),
        color,
        Colors.white,
        Colors.transparent,
      ],
      stops: const [0, 0.55, 0.8, 0.86, 0.9],
    ).createShader(rect);
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(_RunningLightPainter old) =>
      old.progress != progress || old.color != color;
}
