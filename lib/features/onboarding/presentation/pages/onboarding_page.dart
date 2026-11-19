import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/onboarding_data.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../../../home/presentation/pages/main_navigation_page_refactored.dart';
import '../widgets/onboarding_visuals.dart';

class _Step {
  const _Step(
    this.eyebrow,
    this.title,
    this.body,
    this.hint,
    this.visual, {
    this.fullBleed = false,
  });
  final String eyebrow;
  final String title;
  final String body;
  final String hint;
  final Widget Function(bool active) visual;

  /// Visual spans the full screen width (no side padding).
  final bool fullBleed;
}

/// First-launch walkthrough. Six interactive pages explain what the app
/// does; finishing (or skipping) opens the app with the paywall on top.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();
  int _index = 0;
  bool _leaving = false;

  static final List<_Step> _steps = [
    _Step(
      'WELCOME TO SPOOKYAI',
      'Spooky art in seconds',
      'Turn a few words or a selfie into cinematic Halloween and Christmas artwork with AI.',
      'Tap the cards',
      (a) => WelcomeVisual(active: a),
    ),
    _Step(
      'TEXT TO IMAGE',
      'Describe it. See it.',
      'Type any idea, from haunted castles to frosty dragons, and SpookyAI paints it for you.',
      'Tap for another example',
      (a) => TextToImageVisual(active: a),
    ),
    _Step(
      'PHOTO TO IMAGE',
      'Transform your selfie',
      'Upload a photo and become a witch, a vampire or a winter queen. Your face, a whole new world.',
      'Drag the slider',
      (a) => PhotoTransformVisual(active: a),
    ),
    _Step(
      'IMAGE TO VIDEO',
      'Bring photos to life',
      'Turn any photo into a short moving clip with AI.',
      'Tap to wake it up',
      (a) => ImageToVideoVisual(active: a),
    ),
    _Step(
      'TRENDS',
      'Jump on the trend',
      'Scroll the Trends tab like your favorite feed. The looks everyone is posting land there as they go viral; tap Try and star in one.',
      'Swipe up · double-tap to like',
      (a) => TrendsVisual(active: a),
    ),
    _Step(
      'SEASON MAP',
      'A new world every season',
      'SpookyAI changes its look, styles and art with the calendar. Open the world map to switch seasons, and new worlds unlock throughout the year.',
      'Tap a world',
      (a) => SeasonMapVisual(active: a),
    ),
  ];

  bool get _isLast => _index == _steps.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    if (_leaving) return;
    _leaving = true;
    await OnboardingService.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) =>
            const MainNavigationPageRefactored(showPaywallOnEnter: true),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeasonPalette.scaffold,
      body: Stack(
        children: [
          Positioned.fill(
            child: _AmbientBackground(page: _controller, ambient: _ambient),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _steps.length,
                    onPageChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _index = i);
                    },
                    itemBuilder: (context, i) => _page(i),
                  ),
                ),
                _bottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        children: [
          Text(
            'SpookyAI',
            style: TextStyle(
              color: SeasonPalette.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: _isLast ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: TextButton(
              onPressed: _isLast ? null : _finish,
              child: Text(
                'Skip',
                style: TextStyle(color: SeasonPalette.mutedText, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _page(int i) {
    final step = _steps[i];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final page =
            _controller.hasClients && _controller.position.haveDimensions
            ? _controller.page ?? 0
            : 0.0;
        final delta = (i - page).clamp(-1.0, 1.0);
        final fade = 1 - delta.abs();
        return Column(
          children: [
            // Visual: slight parallax + scale while swiping.
            Expanded(
              child: Opacity(
                opacity: (0.3 + 0.7 * fade).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(delta * 60, 0),
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * fade,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        step.fullBleed ? 0 : 16,
                        4,
                        step.fullBleed ? 0 : 16,
                        4,
                      ),
                      child: step.visual(i == _index),
                    ),
                  ),
                ),
              ),
            ),
            // Copy: moves faster than the visual for depth.
            Opacity(
              opacity: fade.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(delta * 140, 0),
                child: child,
              ),
            ),
          ],
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
        child: Column(
          children: [
            Text(
              step.eyebrow,
              style: TextStyle(
                color: SeasonPalette.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SeasonPalette.text,
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              child: step.hint.isEmpty
                  ? null
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 16,
                          color: SeasonPalette.mutedText,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            step.hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: SeasonPalette.mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        children: [
          Semantics(
            label: 'Page ${_index + 1} of ${_steps.length}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _steps.length; i++)
                  GestureDetector(
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      width: i == _index ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? SeasonPalette.accent
                            : SeasonPalette.mutedText.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: SeasonPalette.accent,
                foregroundColor: SeasonPalette.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Row(
                  key: ValueKey(_isLast),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLast ? 'Start creating' : 'Continue',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isLast
                          ? Icons.auto_awesome
                          : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft glows that drift slowly and slide with the page, plus floating motes.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.page, required this.ambient});
  final PageController page;
  final AnimationController ambient;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([page, ambient]),
        builder: (context, _) {
          final p = page.hasClients && page.position.haveDimensions
              ? page.page ?? 0
              : 0.0;
          return CustomPaint(
            painter: _AmbientPainter(
              page: p,
              t: still ? 0 : ambient.value,
              a: SeasonPalette.accent,
              b: SeasonPalette.secondaryAccent,
            ),
          );
        },
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.page,
    required this.t,
    required this.a,
    required this.b,
  });
  final double page;
  final double t;
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size s) {
    final w = 2 * math.pi * t;
    void glow(Offset c, double r, Color color) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    glow(
      Offset(s.width * (0.2 + 0.15 * math.sin(w)) - page * 40, s.height * 0.25),
      s.width * 0.75,
      a,
    );
    glow(
      Offset(
        s.width * (0.85 + 0.1 * math.cos(w)) - page * 25,
        s.height * (0.6 + 0.05 * math.sin(w)),
      ),
      s.width * 0.65,
      b,
    );

    // Floating motes.
    final rnd = math.Random(7);
    final mote = Paint();
    for (int i = 0; i < 26; i++) {
      final x0 = rnd.nextDouble();
      final speed = 0.3 + rnd.nextDouble() * 0.7;
      final r = 1 + rnd.nextDouble() * 2.2;
      final y = (rnd.nextDouble() - t * speed) % 1.0;
      final x = (x0 + 0.02 * math.sin(w * 2 + i) - page * 0.02 * speed) % 1.0;
      mote.color = Colors.white.withValues(
        alpha: 0.10 + 0.25 * speed * (1 - y),
      );
      canvas.drawCircle(Offset(x * s.width, y * s.height), r, mote);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.page != page || old.t != t || old.a != a || old.b != b;
}
