import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/seasons/season_palette.dart';

/// One bundled Image to Video example: the photo that went in and the clip
/// that came out. The still is the clip's first frame, so switching between
/// them shows exactly what changed.
class VideoSample {
  const VideoSample({
    required this.title,
    required this.still,
    required this.video,
    required this.motion,
  });

  final String title;
  final String still;
  final String video;

  /// The motion hint shown with the example and copied by "Use this example".
  final String motion;
}

const _dir = 'assets/images/haloween/image-to-video';

const videoSamples = <VideoSample>[
  VideoSample(
    title: 'Witch cat',
    still: '$_dir/blackcat.jpg',
    video: '$_dir/blackcat.mp4',
    motion: 'The witch cat hisses, then turns and wanders off',
  ),
  VideoSample(
    title: 'Late-night call',
    still: '$_dir/telephone.jpg',
    video: '$_dir/telephone.mp4',
    motion: 'Slow push-in while a dark figure moves in the doorway',
  ),
];

/// Compact "See examples" row for the Generate screen. Opens the examples
/// sheet; choosing one there calls [onTryExample].
class VideoExamplesButton extends StatelessWidget {
  const VideoExamplesButton({
    super.key,
    required this.onTryExample,
    this.samples = videoSamples,
  });

  final ValueChanged<VideoSample> onTryExample;
  final List<VideoSample> samples;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'See Image to Video examples',
      child: Material(
        color: SeasonPalette.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            HapticFeedback.selectionClick();
            final picked = await showVideoExamplesSheet(
              context,
              samples: samples,
            );
            if (picked != null) onTryExample(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SeasonPalette.text.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                _StackedThumbs(samples: samples),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'See examples',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: SeasonPalette.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Watch photos come to life',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: SeasonPalette.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SeasonPalette.accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: SeasonPalette.accent,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Watch',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: SeasonPalette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StackedThumbs extends StatelessWidget {
  const _StackedThumbs({required this.samples});
  final List<VideoSample> samples;

  @override
  Widget build(BuildContext context) {
    final shown = samples.take(2).toList();
    return SizedBox(
      width: 48.0 + (shown.length - 1) * 16,
      height: 48,
      child: Stack(
        children: [
          for (var i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: i * 16.0,
              top: i == 0 ? 0 : 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SeasonPalette.card, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    shown[i].still,
                    width: i == 0 ? 44 : 40,
                    height: i == 0 ? 44 : 40,
                    fit: BoxFit.cover,
                    cacheWidth: 132,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the examples sheet. Returns the example the user chose to use, or
/// null if they only looked.
Future<VideoSample?> showVideoExamplesSheet(
  BuildContext context, {
  List<VideoSample> samples = videoSamples,
}) {
  return showModalBottomSheet<VideoSample>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => VideoExamplesSheet(samples: samples),
  );
}

/// Swipe between examples. Each one shows its photo first, then turns into
/// the video; a Before/After switch and press-and-hold let the user compare.
class VideoExamplesSheet extends StatefulWidget {
  const VideoExamplesSheet({super.key, this.samples = videoSamples});

  final List<VideoSample> samples;

  @override
  State<VideoExamplesSheet> createState() => _VideoExamplesSheetState();
}

class _VideoExamplesSheetState extends State<VideoExamplesSheet> {
  final _pages = PageController(viewportFraction: 0.86);
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sample = widget.samples[_page];
    final size = MediaQuery.sizeOf(context);
    // Square media that never pushes the sheet past the screen.
    final mediaSide = (size.width * 0.86 - 12).clamp(200.0, size.height * 0.48);

    return Container(
      decoration: BoxDecoration(
        color: SeasonPalette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SeasonPalette.text.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Photo to Video',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: SeasonPalette.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'One photo in, a 5-second video out',
                          style: TextStyle(
                            fontSize: 13,
                            color: SeasonPalette.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: SeasonPalette.text.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: mediaSide + 56,
              child: PageView.builder(
                controller: _pages,
                itemCount: widget.samples.length,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _page = i);
                },
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Center(
                    child: SizedBox(
                      width: mediaSide,
                      child: ExamplePlayer(
                        sample: widget.samples[i],
                        active: i == _page,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.samples.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.samples.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? SeasonPalette.accent
                            : SeasonPalette.text.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(sample.motion),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SeasonPalette.text.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.gesture_rounded,
                        size: 18,
                        color: SeasonPalette.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MOTION',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: SeasonPalette.mutedText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sample.motion,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.3,
                                color: SeasonPalette.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop(sample);
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Use this example'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SeasonPalette.accent,
                    foregroundColor: SeasonPalette.onAccent,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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

enum _Side { before, after }

/// One example: shows the photo ("Before") for a moment, then fades into the
/// looping video ("After"). A Before/After switch flips between them, and
/// pressing and holding the media shows the photo until released.
class ExamplePlayer extends StatefulWidget {
  const ExamplePlayer({super.key, required this.sample, required this.active});

  final VideoSample sample;
  final bool active;

  @override
  State<ExamplePlayer> createState() => _ExamplePlayerState();
}

class _ExamplePlayerState extends State<ExamplePlayer> {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _failed = false;
  _Side _side = _Side.before;
  bool _holding = false;
  Timer? _intro;

  static const _introDelay = Duration(milliseconds: 1400);

  bool get _showPhoto => _holding || _side == _Side.before;

  @override
  void initState() {
    super.initState();
    _initVideo();
    if (widget.active) _startIntro();
  }

  Future<void> _initVideo() async {
    _failed = false;
    await _video?.dispose();
    final c = VideoPlayerController.asset(
      widget.sample.video,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _video = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      if (!mounted) return;
      setState(() => _ready = true);
      _syncPlayback();
    } catch (e) {
      // No video plugin (tests) or a decode error: the photo stays.
      debugPrint('ExamplePlayer: ${widget.sample.video} failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(ExamplePlayer old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _startIntro();
    if (!widget.active && old.active) {
      _intro?.cancel();
      _side = _Side.before;
    }
    _syncPlayback();
  }

  /// Photo first, then the video from its first frame: the "it moves" moment.
  void _startIntro() {
    _intro?.cancel();
    _side = _Side.before;
    if (_ready) _video?.seekTo(Duration.zero);
    _intro = Timer(_introDelay, () {
      if (!mounted || !widget.active) return;
      setState(() => _side = _Side.after);
      _syncPlayback();
    });
  }

  void _syncPlayback() {
    final c = _video;
    if (c == null || !_ready) return;
    if (widget.active && !_showPhoto) {
      c.play();
    } else {
      c.pause();
    }
  }

  void _select(_Side side) {
    _intro?.cancel();
    if (side == _side) return;
    HapticFeedback.selectionClick();
    if (side == _Side.after && _ready) _video?.seekTo(Duration.zero);
    if (side == _Side.after && _failed) _initVideo(); // try once more
    setState(() => _side = side);
    _syncPlayback();
  }

  void _hold(bool down) {
    if (down) _intro?.cancel();
    if (_holding == down) return;
    if (down) HapticFeedback.selectionClick();
    setState(() => _holding = down);
    _syncPlayback();
  }

  @override
  void dispose() {
    _intro?.cancel();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _video;
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onLongPressStart: (_) => _hold(true),
            onLongPressEnd: (_) => _hold(false),
            onLongPressCancel: () => _hold(false),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_ready && c != null)
                    FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: c.value.size.width,
                        height: c.value.size.height,
                        child: VideoPlayer(c),
                      ),
                    ),
                  AnimatedOpacity(
                    opacity: _showPhoto || !_ready ? 1 : 0,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    child: Image.asset(widget.sample.still, fit: BoxFit.cover),
                  ),
                  // Waiting for the clip: say so instead of a frozen photo.
                  if (!_showPhoto && !_ready && !_failed)
                    const Center(
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _Badge(
                      text: _showPhoto ? 'PHOTO' : 'VIDEO',
                      icon: _showPhoto
                          ? Icons.image_rounded
                          : Icons.play_arrow_rounded,
                      live: !_showPhoto,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _Badge(
                      text: widget.sample.title,
                      icon: Icons.auto_awesome_rounded,
                      live: false,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: AnimatedOpacity(
                      opacity: _showPhoto ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: Text(
                          'Hold to see the original',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _BeforeAfterSwitch(
          side: _holding ? _Side.before : _side,
          onChanged: _select,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.icon, required this.live});

  final String text;
  final IconData icon;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: live ? SeasonPalette.accent : Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeforeAfterSwitch extends StatelessWidget {
  const _BeforeAfterSwitch({required this.side, required this.onChanged});

  final _Side side;
  final ValueChanged<_Side> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (_Side.before, Icons.image_rounded, 'Before'),
      (_Side.after, Icons.movie_rounded, 'After'),
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SeasonPalette.text.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: side == _Side.before
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: SeasonPalette.accent,
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: side == item.$1,
                      label: item.$3,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(item.$1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              item.$2,
                              size: 16,
                              color: side == item.$1
                                  ? SeasonPalette.onAccent
                                  : SeasonPalette.text.withOpacity(0.55),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.$3,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: side == item.$1
                                    ? SeasonPalette.onAccent
                                    : SeasonPalette.text.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
