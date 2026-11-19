import 'dart:async';
import '../../../../core/services/analytics_service.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/services/saved_videos_provider.dart';
import '../../../../core/services/token_costs.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/theme/seasons/season_ambient.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../widgets/image_to_video_flow.dart';
import '../widgets/result_rating_card.dart';
import 'generated_result_page.dart' show ResultActionButton;
import 'purchase_page.dart';

/// Opens the video detail screen with the same transition as the picture
/// result. [justMade] shows the rating card; a video reopened from the
/// gallery gets Delete in the menu instead.
Future<void> openVideoResultPage(
  BuildContext context, {
  required SavedVideo video,
  bool justMade = false,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) =>
          VideoResultPage(video: video, justMade: justMade),
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

/// The video counterpart of [GeneratedResultPage]: the clip first, then the
/// motion it was made with, then Share, Save and Make another.
class VideoResultPage extends StatefulWidget {
  const VideoResultPage({super.key, required this.video, this.justMade = false});

  final SavedVideo video;
  final bool justMade;

  @override
  State<VideoResultPage> createState() => _VideoResultPageState();
}

class _VideoResultPageState extends State<VideoResultPage>
    with SingleTickerProviderStateMixin {
  late final SavedVideosProvider _store = context.read<SavedVideosProvider>();
  late final VideoPlayerController _player;
  bool _saving = false;
  bool _exported = false;
  bool _sharing = false;

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
    _player = VideoPlayerController.file(File(_store.videoPath(widget.video)))
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _player.play();
      });
    _player.addListener(_onPlayer);
  }

  bool _wasPlaying = false;
  void _onPlayer() {
    final playing = _player.value.isPlaying;
    if (playing != _wasPlaying && mounted) {
      setState(() => _wasPlaying = playing);
    }
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayer);
    _player.dispose();
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

  void _togglePlay() {
    if (!_player.value.isInitialized) return;
    HapticFeedback.selectionClick();
    _player.value.isPlaying ? _player.pause() : _player.play();
  }

  void _openFullScreen() {
    if (!_player.value.isInitialized) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => _FullScreenVideo(player: _player),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  Future<void> _share() async {
    if (_sharing) return;
    HapticFeedback.selectionClick();
    setState(() => _sharing = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      unawaited(AnalyticsService.imageShared('video'));
      await Share.shareXFiles(
        [XFile(_store.videoPath(widget.video))],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) {
        NotificationService.error(
          context,
          message: 'Could not share the video. Please try again.',
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
    final ok = await _store.exportToGallery(widget.video);
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

  /// Makes a new video from the same picture, with a fresh motion hint.
  Future<void> _makeAnother(bool canAfford) async {
    HapticFeedback.mediumImpact();
    if (!canAfford) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PurchasePage()),
      );
      return;
    }
    _player.pause();
    final poster = await File(_store.posterPath(widget.video)).readAsBytes();
    if (!mounted) return;
    await startImageToVideo(
      context,
      null,
      imageBytes: poster,
      initialMotion: widget.video.motionPrompt,
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SeasonPalette.scaffold,
        title: const Text('Delete video?'),
        content: const Text('This video will be removed from the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _store.delete(widget.video.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    NotificationService.success(context, message: 'Video deleted');
  }

  @override
  Widget build(BuildContext context) {
    final season = SeasonPalette.current;
    final accent = SeasonPalette.accent;
    final motion = widget.video.motionPrompt.trim();
    final ready = _player.value.isInitialized;

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
          if (!widget.justMade)
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_horiz_rounded),
              color: SeasonPalette.inputFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (v) {
                if (v == 'delete') _confirmDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete')),
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
                        // The clip (the poster until it is ready).
                        _reveal(
                          _step(0.0, 0.55),
                          AspectRatio(
                            aspectRatio: ready
                                ? _player.value.aspectRatio.clamp(0.6, 1.4)
                                : 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
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
                                  child: GestureDetector(
                                    onTap: _togglePlay,
                                    child: ready
                                        ? FittedBox(
                                            fit: BoxFit.cover,
                                            clipBehavior: Clip.hardEdge,
                                            child: SizedBox(
                                              width: _player.value.size.width,
                                              height:
                                                  _player.value.size.height,
                                              child: VideoPlayer(_player),
                                            ),
                                          )
                                        : Image.file(
                                            File(
                                              _store.posterPath(widget.video),
                                            ),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox.shrink(),
                                          ),
                                  ),
                                ),
                                if (!ready)
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                if (ready && !_wasPlaying)
                                  IgnorePointer(
                                    child: Center(
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: _CircleButton(
                                    icon: Icons.fullscreen_rounded,
                                    label: 'Full screen',
                                    onTap: _openFullScreen,
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
                              Text(
                                widget.video.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 26,
                                  height: 1.15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.7,
                                ),
                              ),
                              if (widget.justMade) ...[
                                const SizedBox(height: 14),
                                ResultRatingCard(
                                  prompt: motion,
                                  mode: 'video',
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
                        ResultActionButton(
                          icon: Icons.ios_share_rounded,
                          label: 'Share video',
                          primary: true,
                          loading: _sharing,
                          onTap: _sharing ? null : _share,
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
                              child: Consumer<TokenProvider>(
                                builder: (context, tokens, _) {
                                  final canAfford =
                                      tokens.balance >= TokenCosts.imageToVideo;
                                  return ResultActionButton(
                                    icon: canAfford
                                        ? Icons.movie_creation_rounded
                                        : Icons.local_fire_department,
                                    label: canAfford
                                        ? 'Make another'
                                        : 'Get tokens',
                                    cost: canAfford
                                        ? TokenCosts.imageToVideo
                                        : null,
                                    onTap: () => _makeAnother(canAfford),
                                  );
                                },
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
      ),
    );
  }
}

/// The clip on black, sharing the detail screen's player.
class _FullScreenVideo extends StatelessWidget {
  const _FullScreenVideo({required this.player});
  final VideoPlayerController player;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: () =>
                  player.value.isPlaying ? player.pause() : player.play(),
              child: AspectRatio(
                aspectRatio: player.value.aspectRatio,
                child: VideoPlayer(player),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _CircleButton(
              icon: Icons.close_rounded,
              label: 'Close',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
