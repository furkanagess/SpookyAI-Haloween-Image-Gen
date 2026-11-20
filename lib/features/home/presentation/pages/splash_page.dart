import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:spooky_ai/features/home/presentation/pages/main_navigation_page_refactored.dart';

import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../../core/models/onboarding_data.dart';
import '../../../../core/services/quick_actions_service.dart';
import 'dont_delete_page.dart';
import '../../../../core/theme/seasons/season_splash_stage.dart';
import '../../../../core/theme/seasons/season_palette.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  /// Drives the whole choreography (rings, hero pop, title, badge).
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// Only used for seasons that ship a Lottie hero.
  late final AnimationController _lottie = AnimationController(vsync: this);

  bool _introDone = false;
  bool _lottieDone = false;
  bool _navigated = false;

  String? get _lottieAsset => SeasonPalette.current.decor.splashLottie;

  @override
  void initState() {
    super.initState();
    _lottieDone = _lottieAsset == null;
    _intro.forward().whenComplete(() {
      _introDone = true;
      _maybeNavigate();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _lottie.dispose();
    super.dispose();
  }

  void _maybeNavigate() {
    if (_navigated || !_introDone || !_lottieDone) return;
    _navigated = true;
    _checkOnboardingAndNavigate();
  }

  Future<void> _checkOnboardingAndNavigate() async {
    if (!mounted) return;

    // Check if app was launched via quick action
    if (QuickActionsService.shouldShowDontDeleteMessage) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DontDeletePage()),
      );
      return;
    }

    final bool isOnboardingCompleted =
        await OnboardingService.isOnboardingCompleted();
    if (!mounted) return;

    final Widget next = isOnboardingCompleted
        ? const MainNavigationPageRefactored()
        : const OnboardingPage();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 1.04, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final season = SeasonPalette.current;
    final lottieAsset = _lottieAsset;

    return Scaffold(
      backgroundColor: SeasonPalette.scaffold,
      body: AnimatedBuilder(
        animation: _intro,
        builder: (context, _) => SeasonSplashStage(
          season: season,
          t: _intro.value,
          hero: lottieAsset == null
              ? null
              : SizedBox(
                  width: SeasonSplashStage.heroBox,
                  height: SeasonSplashStage.heroBox,
                  child: Lottie.asset(
                    lottieAsset,
                    controller: _lottie,
                    fit: BoxFit.contain,
                    onLoaded: (comp) {
                      _lottie
                        ..duration = comp.duration
                        ..forward().whenComplete(() {
                          _lottieDone = true;
                          _maybeNavigate();
                        });
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
