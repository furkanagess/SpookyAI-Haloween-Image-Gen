import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/seasons/season_provider.dart';
import 'core/services/ambient_sound_service.dart';
import 'core/theme/seasons/season_transition_overlay.dart';
import 'core/config/environment_config.dart';
import 'features/home/presentation/pages/splash_page.dart';
import 'package:provider/provider.dart';
import 'core/services/saved_images_provider.dart';
import 'core/services/saved_videos_provider.dart';
import 'core/services/token_provider.dart';
import 'core/services/main_navigation_provider.dart';
import 'core/services/profile_provider.dart';
import 'core/services/prompts_provider.dart';
import 'core/services/purchase_provider.dart';
import 'core/services/add_prompt_provider.dart';
import 'core/services/halloween_prompt_provider.dart';
import 'core/services/prompt_input_provider.dart';
import 'core/services/in_app_purchase_service.dart';
import 'core/services/quick_actions_service.dart';
import 'core/services/version_service.dart';
import 'core/services/analytics_service.dart';
import 'core/theme/seasons/season_effects_layer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env", isOptional: true);

    // No secret is bundled with the app anymore. See EnvironmentConfig.
    EnvironmentConfig.debugReport();
  } catch (e) {
    // .env file not found, continue without it
    // In production, API key should be provided via other means
    print('Warning: .env file not found. API key may not be available.');
  }

  // Firebase (Firestore holds the result ratings). Never block startup.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // Crash reporting + funnel analytics (no-op if Firebase failed).
  await AnalyticsService.init();

  // Initialize in-app purchase service
  await InAppPurchaseService.initialize();

  // Initialize quick actions
  await QuickActionsService.initialize();

  // Initialize version service
  await VersionService.getVersionInfo();

  runApp(const GhostfaceApp());
}

class GhostfaceApp extends StatelessWidget {
  const GhostfaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SeasonProvider()..load()),
        ChangeNotifierProxyProvider<SeasonProvider, AmbientSoundController>(
          lazy: false,
          create: (_) => AmbientSoundController()..load(),
          update: (_, season, sound) {
            if (season.isLoaded) sound!.setSeason(season.current.id);
            return sound!;
          },
        ),
        ChangeNotifierProvider(create: (_) => SavedImagesProvider()..load()),
        ChangeNotifierProvider(create: (_) => SavedVideosProvider()..load()),
        ChangeNotifierProvider(create: (_) => TokenProvider()..loadBalance()),
        ChangeNotifierProvider(create: (_) => MainNavigationProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PromptsProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => AddPromptProvider()),
        ChangeNotifierProvider(create: (_) => HalloweenPromptProvider()),
        ChangeNotifierProvider(create: (_) => PromptInputProvider()),
      ],
      child: Consumer<SeasonProvider>(
        builder: (context, season, _) {
          final isDark = season.isDark;
          return Stack(
            textDirection: TextDirection.ltr,
            children: [
              MaterialApp(
                key: ValueKey('${season.current.id}-$isDark'),
                title: season.current.appTitle,
                debugShowCheckedModeBanner: false,
                navigatorObservers: [
                  if (AnalyticsService.observer != null)
                    AnalyticsService.observer!,
                ],
                theme: season.current.toThemeData(isDark: isDark),
                builder: (context, child) => SeasonEffectsLayer(
                  enabled: season.effectsEnabled,
                  child: child ?? const SizedBox.shrink(),
                ),
                home: const SplashPage(),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: SeasonTransitionOverlay(seasonId: season.current.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
