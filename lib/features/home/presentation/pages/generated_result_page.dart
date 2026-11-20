import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/image_storage_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/theme/seasons/season_ambient.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/services/token_costs.dart';
import '../../data/models/prompt_category.dart';
import '../../domain/generated_image_result.dart';
import '../../domain/generation_mode.dart';
import '../widgets/image_edit_flow.dart';
import '../widgets/image_to_video_flow.dart';
import '../widgets/result_rating_card.dart';
import 'purchase_page.dart';

/// Opens the result screen with the app's soft fade-and-rise transition.
Future<void> openGeneratedResultPage(
  BuildContext context, {
  required GeneratedImageResult result,
  required GenerationMode mode,
  required Future<void> Function(GeneratedImageResult) onShare,
  PromptItem? style,
  VoidCallback? onDelete,
  VoidCallback? onReport,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => GeneratedResultPage(
        result: result,
        style: style,
        mode: mode,
        onShare: onShare,
        onDelete: onDelete,
        onReport: onReport,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// The screen that opens when an image is ready: the picture first, then what
/// it was made with (style and description), then three actions: save, share
/// and make it a video.
class GeneratedResultPage extends StatefulWidget {
  const GeneratedResultPage({
    super.key,
    required this.result,
    required this.mode,
    required this.onShare,
    this.style,
    this.onDelete,
    this.onReport,
  });

  final GeneratedImageResult result;
  final GenerationMode mode;
  final PromptItem? style;

  final Future<void> Function(GeneratedImageResult) onShare;

  /// Only for pictures that are already in the gallery.
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  @override
  State<GeneratedResultPage> createState() => _GeneratedResultPageState();
}

class _GeneratedResultPageState extends State<GeneratedResultPage>
    with SingleTickerProviderStateMixin {
  // Every picture is already kept inside the app (the Photos tab). "Save"
  // copies it to the phone's photo library.
  late final GeneratedImageResult _result = widget.result;
  bool _saving = false;
  bool _exported = false;
  bool _sharing = false;

  String get _heroTag =>
      'result-image-${widget.result.generatedAt.microsecondsSinceEpoch}';

  void _openFullScreen() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) =>
            _FullScreenImage(bytes: _result.imageBytes, tag: _heroTag),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  /// Staggered entrance: picture, then text, then actions.
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    final reduce = SchedulerBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    reduce ? _in.value = 1 : _in.forward();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  Animation<double> _step(double from, double to) => CurvedAnimation(
    parent: _in,
    curve: Interval(from, to, curve: Curves.easeOutCubic),
  );

  Widget _reveal(Animation<double> a, Widget child, {double dy = 22}) =>
      AnimatedBuilder(
        animation: a,
        builder: (context, c) => Opacity(
          opacity: a.value,
          child: Transform.translate(
            offset: Offset(0, (1 - a.value) * dy),
            child: c,
          ),
        ),
        child: child,
      );

  /// Edit: a bottom sheet takes a new instruction and runs image to image on
  /// this picture; the edited picture opens as its own result.
  void _edit() {
    HapticFeedback.mediumImpact();
    startImageEdit(context, _result.imageBytes);
  }

  /// Awaits the share sheet (rather than firing it and forgetting it), so a
  /// failure is caught here instead of becoming an unhandled async error,
  /// and the button shows that something is happening.
  Future<void> _share() async {
    if (_sharing) return;
    HapticFeedback.selectionClick();
    setState(() => _sharing = true);
    try {
      await widget.onShare(_result);
    } catch (_) {
      if (mounted) {
        NotificationService.error(
          context,
          message: 'Could not share the image. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _exported) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final ok = await ImageStorageService.exportToGallery(_result.imageBytes);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _exported = ok;
    });
    if (ok) {
      NotificationService.success(context, message: 'Saved to your photos');
    } else {
      NotificationService.error(
        context,
        message: 'Could not save. Check photo permissions.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final season = SeasonPalette.current;
    final accent = SeasonPalette.accent;
    final style = widget.style;
    final title = style?.title ?? _result.prompt;

    return Scaffold(
      backgroundColor: SeasonPalette.scaffold,
      appBar: AppBar(
        backgroundColor: SeasonPalette.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (widget.onDelete != null || widget.onReport != null)
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_horiz_rounded),
              color: SeasonPalette.inputFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (v) {
                // Leave this screen first: the actions confirm on the gallery.
                Navigator.of(context).pop();
                if (v == 'delete') widget.onDelete?.call();
                if (v == 'report') widget.onReport?.call();
              },
              itemBuilder: (_) => [
                if (widget.onReport != null)
                  const PopupMenuItem(value: 'report', child: Text('Report')),
                if (widget.onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.16),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(season.emoji, style: const TextStyle(fontSize: 14)),
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
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: SeasonAmbient()),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The picture.
                        _reveal(
                          _step(0.0, 0.55),
                          AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Hero(
                                  tag: _heroTag,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 32,
                                          offset: const Offset(0, 14),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.memory(
                                      _result.imageBytes,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Semantics(
                                    button: true,
                                    label: 'Full screen',
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: _openFullScreen,
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.25,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.fullscreen_rounded,
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          dy: 30,
                        ),
                        const SizedBox(height: 22),

                        // What it was made with.
                        _reveal(
                          _step(0.2, 0.8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description only when reopened from Photos.
                              if (widget.onDelete != null)
                                Text(
                                  title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    height: 1.15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                              if (widget.onDelete != null &&
                                  (widget.style?.description ?? '')
                                      .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  widget.style!.description,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    color: SeasonPalette.text.withOpacity(0.7),
                                  ),
                                ),
                              ],
                              // Rating, only for a picture that was just
                              // made (not one reopened from the gallery).
                              if (widget.onDelete == null) ...[
                                ResultRatingCard(
                                  prompt: _result.prompt,
                                  mode: widget.mode.name,
                                  styleId: widget.style?.id,
                                  styleTitle: widget.style?.title,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions, pinned at the bottom.
                _reveal(
                  _step(0.4, 1.0),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    decoration: BoxDecoration(
                      color: SeasonPalette.scaffold,
                      border: Border(
                        top: BorderSide(
                          color: SeasonPalette.text.withOpacity(0.07),
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer<TokenProvider>(
                          builder: (context, tokens, _) {
                            final canAfford =
                                tokens.balance >= TokenCosts.imageToVideo;
                            return ResultActionButton(
                              icon: canAfford
                                  ? Icons.movie_creation_rounded
                                  : Icons.local_fire_department,
                              label: canAfford
                                  ? 'Make it a video'
                                  : 'Get tokens',
                              cost: canAfford ? TokenCosts.imageToVideo : null,
                              primary: true,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                if (canAfford) {
                                  startImageToVideo(
                                    context,
                                    null,
                                    imageBytes: _result.imageBytes,
                                  );
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const PurchasePage(),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ResultActionButton(
                                icon: _exported
                                    ? Icons.check_rounded
                                    : Icons.download_rounded,
                                label: _exported ? 'Saved' : 'Save',
                                loading: _saving,
                                highlighted: _exported,
                                onTap: _exported ? null : _save,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ResultActionButton(
                                icon: Icons.ios_share_rounded,
                                label: 'Share',
                                loading: _sharing,
                                onTap: _sharing ? null : _share,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ResultActionButton(
                                icon: Icons.auto_fix_high_rounded,
                                label: 'Edit',
                                onTap: _edit,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  dy: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResultActionButton extends StatefulWidget {
  const ResultActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.highlighted = false,
    this.loading = false,
    this.cost,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool highlighted;
  final bool loading;
  final double? cost;

  @override
  State<ResultActionButton> createState() => _ResultActionButtonState();
}

class _ResultActionButtonState extends State<ResultActionButton> {
  bool _down = false;

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    final primary = widget.primary;
    final fg = primary
        ? Colors.white
        : (widget.highlighted ? accent : SeasonPalette.text);
    final enabled = widget.onTap != null && !widget.loading;
    final height = primary ? 62.0 : 54.0;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: primary ? 18 : 8),
            decoration: BoxDecoration(
              color: primary
                  ? accent
                  : (widget.highlighted
                        ? accent.withOpacity(0.14)
                        : SeasonPalette.text.withOpacity(0.07)),
              borderRadius: BorderRadius.circular(primary ? 22 : 18),
              border: primary
                  ? null
                  : Border.all(
                      color: widget.highlighted
                          ? accent.withOpacity(0.6)
                          : SeasonPalette.text.withOpacity(0.12),
                    ),
              boxShadow: primary
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(_down ? 0.2 : 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: widget.loading
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: fg,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: primary ? 24 : 21, color: fg),
                      SizedBox(width: primary ? 10 : 6),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: primary ? 17 : 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                            color: fg,
                          ),
                        ),
                      ),
                      if (widget.cost != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _fmt(widget.cost!),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The picture on its own, edge to edge, with pinch zoom.
class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.bytes, required this.tag});

  final Uint8List bytes;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            button: true,
            label: 'Close',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Hero(
                  tag: tag,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Semantics(
                  button: true,
                  label: 'Close',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen_exit_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
