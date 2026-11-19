import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/theme/seasons/season_ambient.dart';
import '../../../../core/theme/seasons/season_theme.dart';
import '../../data/models/prompt_category.dart';
import 'prompt_preview.dart';

class GenerationProgressController {
  GenerationProgressController(this._progress, this._close, this._onCancel);
  final ValueNotifier<double> _progress;
  final VoidCallback _close;
  final VoidCallback _onCancel;

  void setProgress(double value) {
    if (value.isNaN) return;
    final clamped = value.clamp(0.0, 1.0);
    _progress.value = clamped;
  }

  void close() => _close();
  void cancel() => _onCancel();
}

/// The waiting screen while an image is being created. It works on the
/// chosen style's own picture (or the uploaded photo): the picture starts
/// out soft and sharpens as the work advances, a scan line sweeps over it
/// and the status line says what is happening. With [video] it is paced and
/// worded for image to video, which takes a minute or two.
GenerationProgressController showGenerationProgressDialog(
  BuildContext context, {
  VoidCallback? onCancel,
  PromptItem? style,
  Uint8List? photo,
  bool video = false,
}) {
  final progress = ValueNotifier<double>(0.0);

  // Pop only while this dialog is still open, so a late close (timeout, demo
  // timer) can never pop an unrelated screen.
  var open = true;
  void closeDialog() {
    if (!open) return;
    open = false;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void cancelGeneration() {
    onCancel?.call();
    closeDialog();
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.72),
    builder: (ctx) => _ProgressView(
      progress: progress,
      style: style,
      photo: photo,
      video: video,
      onCancel: cancelGeneration,
    ),
  );

  // Paced for a 30-50 second wait (a video: about 90 s): reach 92%, then a
  // very slow creep that never freezes. The real result jumps it to 100%.
  final ramp = video ? 90.0 : 40.0;
  final started = DateTime.now();
  Future<void> tick() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!open || progress.value >= 1) return;
    final t = DateTime.now().difference(started).inMilliseconds / 1000.0;
    final target = t < ramp
        ? 0.92 * (1 - math.pow(1 - t / ramp, 1.25))
        : math.min(0.92 + (t - ramp) * (video ? 0.0005 : 0.0015), 0.98);
    if (target > progress.value) progress.value = target;
    tick();
  }

  Future<void>.delayed(const Duration(milliseconds: 700), tick);

  // Safety net against an endless wait (video generation times out at 6).
  Future<void>.delayed(Duration(minutes: video ? 7 : 3), closeDialog);

  return GenerationProgressController(progress, closeDialog, cancelGeneration);
}

class _ProgressView extends StatefulWidget {
  const _ProgressView({
    required this.progress,
    required this.onCancel,
    this.style,
    this.photo,
    this.video = false,
  });

  final bool video;
  final ValueNotifier<double> progress;
  final VoidCallback onCancel;
  final PromptItem? style;
  final Uint8List? photo;

  @override
  State<_ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<_ProgressView>
    with TickerProviderStateMixin {
  /// What is happening, by how far along the work is.
  List<(double, String)> get _phases => widget.video ? _videoPhases : _imagePhases;

  static const _videoPhases = <(double, String)>[
    (0.0, "We're working on your video"),
    (0.12, 'Reading your picture'),
    (0.28, 'Planning the motion'),
    (0.46, 'Animating frame by frame'),
    (0.64, 'Smoothing the movement'),
    (0.82, 'Rendering the final clip'),
    (0.94, 'Almost there'),
  ];

  static const _imagePhases = <(double, String)>[
    (0.0, "We're working on your image"),
    (0.12, 'Setting the scene'),
    (0.28, 'Building the composition'),
    (0.46, 'Adding colors and tones'),
    (0.64, 'Refining light and detail'),
    (0.82, 'Adding the finishing touches'),
    (0.94, 'Almost there'),
  ];

  /// Short, calm lines that rotate underneath, in the voice of the season.
  /// Exhaustive on purpose: a new season must write its own.
  static List<String> _tipsFor(SeasonId id) => switch (id) {
    SeasonId.halloween => const [
      'Stirring the cauldron',
      'Summoning every last detail',
      'The shadows are taking shape',
      'Worth the wait, we promise',
    ],
    SeasonId.christmas => const [
      'Wrapping it with care',
      'Adding a little sparkle',
      'Warm lights and soft snow',
      'Worth the wait, we promise',
    ],
  };

  late final List<String> _tips = _tipsFor(SeasonPalette.current.id);

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _shown = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late Animation<double> _shownAnim = const AlwaysStoppedAnimation(0);
  Timer? _tipTimer;
  int _tip = 0;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    final reduce = SchedulerBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (!reduce) {
      _drift.repeat(reverse: true);
      _scan.repeat();
    }
    widget.progress.addListener(_onProgress);
    _tipTimer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (mounted) setState(() => _tip = (_tip + 1) % _tips.length);
    });
  }

  /// Smooths every jump of the target into a short glide.
  void _onProgress() {
    _from = _shownAnim.value;
    _shownAnim = Tween<double>(
      begin: _from,
      end: widget.progress.value,
    ).animate(CurvedAnimation(parent: _shown, curve: Curves.easeOutCubic));
    _shown.forward(from: 0);
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgress);
    _tipTimer?.cancel();
    _drift.dispose();
    _scan.dispose();
    _shown.dispose();
    super.dispose();
  }

  String _phase(double v) {
    var text = _phases.first.$2;
    for (final p in _phases) {
      if (v >= p.$1) text = p.$2;
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    final season = SeasonPalette.current;
    // The picture takes the full width of the card: dialog inset (14 each
    // side) and card padding (16 each side).
    final previewW = MediaQuery.of(context).size.width - 28 - 32;
    final previewH = math.min(previewW * 1.15, 420.0);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: SeasonPalette.scaffold,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Season atmosphere behind everything.
            const Positioned.fill(child: SeasonAmbient()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: AnimatedBuilder(
                animation: _shown,
                builder: (context, _) {
                  final value = _shownAnim.value;
                  final percent = (value * 100).clamp(0, 100).round();
                  final tips = _tips;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Which world this is being made in.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              season.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              season.displayName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _preview(value, accent, previewW, previewH),
                      const SizedBox(height: 22),

                      // Status: what is happening now, then a calm line.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.35),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _phase(value),
                          key: ValueKey(_phase(value)),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          tips[_tip % tips.length],
                          key: ValueKey(_tip),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: SeasonPalette.text.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Progress with its percentage.
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: value.clamp(0.0, 1.0),
                                backgroundColor: SeasonPalette.text.withOpacity(
                                  0.08,
                                ),
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 46,
                            child: Text(
                              '$percent%',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: accent,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // How long it takes, said once and plainly.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: SeasonPalette.mutedText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Usually takes 30–50 seconds',
                            style: TextStyle(
                              fontSize: 14,
                              color: SeasonPalette.mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: widget.onCancel,
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: SeasonPalette.text.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The style's own picture: soft at first, sharper with every step, with
  /// a slow drift, a scan line and viewfinder corners.
  Widget _preview(double value, Color accent, double w, double h) {
    final style = widget.style;
    final Widget picture;
    if (style != null) {
      picture = PromptPreview(
        id: style.id,
        tags: style.tags,
        isImageToImage: style.promptType == PromptType.imageToImage,
        imageUrl: style.imageUrl,
        borderRadius: 0,
      );
    } else if (widget.photo != null) {
      picture = Image.memory(widget.photo!, fit: BoxFit.cover);
    } else {
      picture = Container(
        color: accent.withOpacity(0.22),
        alignment: Alignment.center,
        child: Text(
          SeasonPalette.current.emoji,
          style: const TextStyle(fontSize: 64),
        ),
      );
    }

    // Only a light softness at the start; it clears as the work advances.
    final sigma = (1 - value.clamp(0.0, 1.0)) * 5;

    return SizedBox(
      width: w,
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Slow drift (a gentle zoom), blur that clears as work advances.
            AnimatedBuilder(
              animation: _drift,
              builder: (context, child) => Transform.scale(
                scale: 1.04 + 0.06 * Curves.easeInOut.transform(_drift.value),
                child: child,
              ),
              child: sigma < 0.3
                  ? picture
                  : ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: sigma,
                        sigmaY: sigma,
                        tileMode: TileMode.decal,
                      ),
                      child: picture,
                    ),
            ),
            ColoredBox(color: Colors.black.withOpacity(0.16)),

            // Scan line.
            AnimatedBuilder(
              animation: _scan,
              builder: (context, _) {
                final y = Curves.easeInOut.transform(_scan.value);
                return Positioned(
                  left: 0,
                  right: 0,
                  top: y * (h - 2),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Color.lerp(accent, Colors.white, 0.55)!,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.7),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Viewfinder corners.
            Positioned.fill(
              child: CustomPaint(
                painter: _CornersPainter(
                  Color.lerp(accent, Colors.white, 0.5)!,
                ),
              ),
            ),

            // Style name.
            if (style != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  padding: const EdgeInsets.fromLTRB(16, 9, 16, 11),
                  child: Text(
                    style.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Four thin corner marks, like a camera viewfinder.
class _CornersPainter extends CustomPainter {
  const _CornersPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const inset = 14.0;
    const len = 20.0;
    final l = inset;
    final t = inset;
    final r = size.width - inset;
    final b = size.height - inset;
    canvas
      ..drawLine(Offset(l, t + len), Offset(l, t), paint)
      ..drawLine(Offset(l, t), Offset(l + len, t), paint)
      ..drawLine(Offset(r - len, t), Offset(r, t), paint)
      ..drawLine(Offset(r, t), Offset(r, t + len), paint)
      ..drawLine(Offset(l, b - len), Offset(l, b), paint)
      ..drawLine(Offset(l, b), Offset(l + len, b), paint)
      ..drawLine(Offset(r - len, b), Offset(r, b), paint)
      ..drawLine(Offset(r, b), Offset(r, b - len), paint);
  }

  @override
  bool shouldRepaint(covariant _CornersPainter old) => old.color != color;
}
