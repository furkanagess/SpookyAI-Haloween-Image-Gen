import '../../../../core/services/analytics_service.dart';
import 'dart:async';
import '../widgets/style_picker_card.dart';
import '../../../../core/services/prompts_provider.dart';
import 'dart:math';
import '../../../../core/services/prompt_input_provider.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/saved_images_provider.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/services/main_navigation_provider.dart';
import '../../../../core/widgets/token_display_widget.dart';

import '../../../../core/services/fal_ai_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/app_bar_title.dart';
import '../../../../core/theme/app_metrics.dart';
import '../../../../core/prompt_engine/blocked_prompt_dialog.dart';
import '../../../../core/prompt_engine/prompt_engine.dart';
import 'purchase_page.dart';
import 'season_map_page.dart';
import '../widgets/world_map_button.dart';
import '../widgets/generate_confirm_sheet.dart';
import 'generated_result_page.dart';
import '../../data/models/prompt_category.dart';
import 'photos_page.dart';
import 'prompts_page.dart';
import 'trend_page.dart';
import '../../../../core/services/trend_service.dart';
import 'profile_page.dart';
import '../../domain/generation_mode.dart';
import '../../domain/generated_image_result.dart';
import '../widgets/prompt_input_widget.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/generation_progress_dialog.dart';
import '../widgets/paywall_dialog.dart';
import '../../../tour/product_tour.dart';
import '../widgets/low_balance_dialog.dart';
import '../../../../core/models/paywall_service.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../widgets/generation_mode_switcher.dart';
import '../widgets/generate_action_bar.dart';
import '../widgets/prompt_suggestions.dart';
import '../widgets/app_bottom_nav.dart';
import '../../../../core/services/token_costs.dart';
import '../widgets/idea_chips.dart';
import '../widgets/image_to_video_flow.dart';
import '../widgets/video_showcase_card.dart';

class MainNavigationPageRefactored extends StatefulWidget {
  const MainNavigationPageRefactored({
    super.key,
    this.showPaywallOnEnter = false,
  });

  /// True when arriving straight from onboarding: show the paywall on entry.
  final bool showPaywallOnEnter;

  @override
  State<MainNavigationPageRefactored> createState() =>
      _MainNavigationPageRefactoredState();
}

class _MainNavigationPageRefactoredState
    extends State<MainNavigationPageRefactored>
    with TickerProviderStateMixin {
  final ValueNotifier<GenerationMode?> _promptsFilterRequest =
      ValueNotifier<GenerationMode?>(null);

  void _openStyles(MainNavigationProvider provider) {
    _promptsFilterRequest.value = provider.activeMode;
    provider.setCurrentIndex(1);
  }

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _premiumBannerController;
  late Animation<double> _premiumBannerAnimation;

  // Page controller for better performance
  final PageController _pageController = PageController();
  late Animation<Offset> _slideAnimation;

  // Page keys for better performance
  final List<GlobalKey<State<StatefulWidget>>> _pageKeys = [
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _premiumBannerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _premiumBannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _premiumBannerController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();

    // Show one-time paywall after first main screen frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Ensure premium status is up-to-date so the premium banner can appear
      try {
        await context.read<MainNavigationProvider>().refreshPremiumStatus();
      } catch (_) {}
      if (!mounted) return;
      final isPremium = context.read<MainNavigationProvider>().isPremium;
      final shown = await PaywallService.isPaywallShown();
      if (!mounted) return;
      if (!isPremium && (widget.showPaywallOnEnter || !shown)) {
        await PaywallDialog.show(context);
        await PaywallService.markPaywallShown();
      }
      // Guided tour right after onboarding (and its paywall).
      if (mounted &&
          widget.showPaywallOnEnter &&
          !await ProductTourService.isDone()) {
        await _startTour();
      }
    });
    ProductTourService.replayRequests.addListener(_startTour);
  }

  Future<void> _startTour() async {
    if (!mounted) return;
    final nav = context.read<MainNavigationProvider>();
    Future<void> showTab(int i) async {
      FocusManager.instance.primaryFocus?.unfocus();
      nav.setNavHidden(false);
      nav.setCurrentIndex(i);
      // The style card is not shown in Video mode.
      if (nav.activeMode == GenerationMode.video) {
        nav.switchMode(GenerationMode.text);
      }
    }

    var mapOpened = false;
    await ProductTour.show(context, [
      TourStep(
        target: ProductTourKeys.style,
        alsoHighlight: [ProductTourKeys.prompt],
        icon: Icons.palette_rounded,
        title: 'Pick a style or describe it',
        body:
            'Start from a ready-made look, type your own idea, or both. '
            'Stuck? Tap the dice for a surprise.',
        before: () => showTab(0),
      ),
      TourStep(
        target: ProductTourKeys.promptsTab,
        icon: Icons.lightbulb_rounded,
        title: 'Explore the style library',
        body:
            'Prompts holds every style for this season. Tap a card to '
            'preview it and use it. PRO styles unlock with Premium.',
        radius: 22,
        padding: 2,
      ),
      TourStep(
        target: ProductTourKeys.trendsTab,
        icon: Icons.local_fire_department_rounded,
        title: 'Catch the trends',
        body:
            'Trends shows the looks going viral right now, and new ones '
            'drop here all the time.',
        radius: 22,
        padding: 2,
      ),
      TourStep(
        target: ProductTourKeys.trendsHero,
        icon: Icons.whatshot_rounded,
        title: 'Hop on one',
        body:
            'Swipe the top cards for the hottest looks. Tap Try it now and '
            'the style is ready on the Generate screen.',
        radius: 24,
        padding: 4,
        before: () async {
          await showTab(2); // Trends
          // Let the tab switch and the trends load.
          await Future.delayed(const Duration(milliseconds: 500));
        },
      ),
      TourStep(
        before: () => showTab(0),
        target: ProductTourKeys.generate,
        icon: Icons.auto_awesome_rounded,
        title: 'Create your image',
        body:
            'Tap Generate. The button shows the token cost, and every '
            'result is saved to My Photos.',
        radius: 18,
        padding: 4,
      ),
      TourStep(
        target: ProductTourKeys.themeMode,
        alsoHighlight: [
          ProductTourKeys.effects,
          ProductTourKeys.sound,
          ProductTourKeys.appIcon,
        ],
        icon: Icons.tune_rounded,
        title: 'Make it yours',
        body:
            'In Profile, choose light or dark, toggle falling snow and '
            'embers, play seasonal music and switch the app icon.',
        radius: 16,
        padding: 2,
        before: () => showTab(4), // Profile
      ),
      TourStep(
        target: ProductTourKeys.worldMap,
        icon: Icons.public_rounded,
        title: 'Travel through seasons',
        body:
            'The app changes with the calendar: new looks, styles and art '
            'each season. Let\'s open the world map.',
        actionLabel: 'Open world map',
        radius: 14,
        padding: 6,
        before: () => showTab(0),
      ),
      TourStep(
        target: ProductTourKeys.mapHere,
        icon: Icons.location_on_rounded,
        title: 'You are here',
        body:
            'Tap an open world to travel there; colors, styles and art '
            'switch with it. Locked worlds open later in the year.',
        padding: -12,
        radius: 60,
        before: () async {
          if (!mapOpened) {
            mapOpened = true;
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SeasonMapPage()));
            // Let the route slide in and the map settle on the marker.
            await Future.delayed(const Duration(milliseconds: 900));
          }
        },
      ),
      TourStep(
        target: ProductTourKeys.mapAuto,
        icon: Icons.event_rounded,
        title: 'Follow the calendar',
        body:
            'Keep this on and the app switches worlds when a new season '
            'starts. Turn it off to stay in the world you picked.',
        radius: 30,
        padding: 4,
      ),
    ]);
  }

  @override
  void dispose() {
    ProductTourService.replayRequests.removeListener(_startTour);
    _fadeController.dispose();
    _premiumBannerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// "Surprise me": pick a random unlocked style for the current mode. Its
  /// prompt stays hidden; the user just sees the style card.
  void _surpriseStyle(MainNavigationProvider provider) {
    final prompts = context.read<PromptsProvider>();
    final pool = PromptSuggestions.styles(
      provider.activeMode,
    ).where((p) => !prompts.isPromptLocked(p)).toList();
    if (pool.isEmpty) return;
    HapticFeedback.selectionClick();
    provider.setStyle(pool[Random().nextInt(pool.length)]);
  }

  /// Validates the prompt (and photo) before anything is charged or shown.
  /// Inline problems shake the prompt field; the rest open the issue sheet.
  bool _preflight(MainNavigationProvider provider) {
    final issue = PromptValidator.validate(
      provider.prompt,
      mode: provider.activeMode,
      hasPhoto: provider.uploadedImage != null,
      hasStyle: provider.style != null,
    );
    if (issue == null) return true;

    if (issue.isInline) {
      HapticFeedback.mediumImpact();
      context.read<PromptInputProvider>().flagIssue(issue.inlineMessage);
    } else {
      showPromptIssueSheet(context, issue);
    }
    return false;
  }

  /// Shows a friendly sheet for a failed generation and, if the user taps
  /// the primary action on a retryable one, runs [retry].
  Future<void> _showFailure(Object error, Future<void> Function() retry) async {
    final issue = GenerationFailure.classify(error);
    if (issue == null || !mounted) return;
    final primary = await showPromptIssueSheet(context, issue);
    if (primary && issue.retryable && mounted) {
      await retry();
    }
  }

  Future<void> _showGenerationConfirmationDialog() async {
    final provider = context.read<MainNavigationProvider>();

    if (!_preflight(provider)) return;

    final nav = context.read<MainNavigationProvider>();
    final confirmed = await showGenerateConfirmSheet(
      context,
      mode: GenerationMode.text,
      cost: TokenCosts.textToImage,
      balance: context.read<TokenProvider>().balance,
      style: nav.style,
      promptText: nav.prompt,
      photo: null,
    );

    if (confirmed) {
      await _generateImage();
    }
  }

  Future<void> _showFalAiGenerationConfirmationDialog() async {
    final provider = context.read<MainNavigationProvider>();

    if (!_preflight(provider)) return;

    final nav = context.read<MainNavigationProvider>();
    final confirmed = await showGenerateConfirmSheet(
      context,
      mode: GenerationMode.image,
      cost: TokenCosts.imageToImage,
      balance: context.read<TokenProvider>().balance,
      style: nav.style,
      promptText: nav.prompt,
      photo: nav.uploadedImage,
    );

    if (confirmed) {
      await _generateFalAiImage();
    }
  }

  Future<void> _generateImage() async {
    final tokenProvider = context.read<TokenProvider>();

    // Safety gate: never spend tokens on a disallowed prompt.
    final moderation = PromptEngine.moderate(
      context.read<MainNavigationProvider>().prompt,
    );
    if (!moderation.allowed) {
      await showBlockedPromptDialog(context, moderation);
      return;
    }

    // Check if user has tokens before starting
    await tokenProvider.loadBalance();
    if (tokenProvider.balance < TokenCosts.textToImage) {
      if (!mounted) return;
      NotificationService.warning(
        context,
        message: NotificationService.outOfTokens,
      );
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
      return;
    }

    final provider = context.read<MainNavigationProvider>();
    provider.setGenerating(true);

    bool isCancelled = false;
    final progress = showGenerationProgressDialog(
      context,
      style: provider.style,
      photo: provider.uploadedImage,
      onCancel: () {
        isCancelled = true;
        provider.setGenerating(false);
      },
    );

    try {
      Uint8List resultBytes;

      // Use FAL AI FLUX Schnell for text-to-image generation with enhanced configuration
      final built = PromptEngine.textToImage(
        provider.prompt,
        style: provider.style,
      );
      final result = await FalAiService.generateImage(
        prompt: built.prompt,
        isCancelled: () => isCancelled,
      );

      if (result.images.isEmpty) {
        throw Exception('No images generated');
      }

      // Download the image from URL
      final imageUrl = result.images.first.url;
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        throw Exception('Failed to download generated image');
      }
      resultBytes = imageResponse.bodyBytes;

      // Check if generation was cancelled
      if (isCancelled) {
        try {
          progress.close();
        } catch (_) {}
        provider.setGenerating(false);
        return;
      }

      // Consume 1 token for text-to-image generation
      await tokenProvider.consumeTokens(TokenCosts.textToImage);

      // Check for low balance after token consumption
      if (tokenProvider.isLowBalance) {
        if (!mounted) return;
        await LowBalanceDialog.show(context);
      }

      var generatedResult = GeneratedImageResult(
        imageBytes: resultBytes,
        prompt: provider.promptLabel,
        source: GeneratedImageSource.fal,
        generatedAt: DateTime.now(),
      );

      if (!mounted) return;
      provider.addGeneratedImage(generatedResult);

      try {
        progress.setProgress(1.0);
        progress.close();
      } catch (_) {}

      await _showResultDialog(generatedResult, style: provider.style);

      // Clear prompt after successful generation
      provider.updatePrompt('');

      if (mounted) {
        NotificationService.success(
          context,
          message: NotificationService.imageGenerated,
        );
      }
    } catch (e) {
      if (!mounted) return;
      try {
        progress.close();
      } catch (_) {}

      // Only show error if not cancelled
      if (!isCancelled &&
          e.toString() != 'Exception: Generation cancelled by user' &&
          !e.toString().contains('Generation cancelled by user')) {
        _showFailure(e, _generateImage);
      }
    } finally {
      if (mounted && !isCancelled) {
        provider.setGenerating(false);
      }
    }
  }

  Future<void> _generateFalAiImage() async {
    await _generateFalAiNewFlow();
  }

  // New, isolated FAL flow: minimal errors, always try to show the image
  Future<void> _generateFalAiNewFlow() async {
    // Safety gate: never spend tokens on a disallowed prompt.
    final moderationResult = PromptEngine.moderate(
      context.read<MainNavigationProvider>().prompt,
    );
    if (!moderationResult.allowed) {
      await showBlockedPromptDialog(context, moderationResult);
      return;
    }

    print('🎃 FAL: Starting generation flow');
    final tokenProvider = context.read<TokenProvider>();
    final provider = context.read<MainNavigationProvider>();

    await tokenProvider.loadBalance();

    // Check token requirements based on generation mode
    final bool useImg2Img =
        provider.activeMode == GenerationMode.image &&
        provider.uploadedImage != null;
    final double requiredTokens = useImg2Img
        ? TokenCosts.imageToImage
        : TokenCosts.textToImage;

    if (tokenProvider.balance < requiredTokens) {
      if (!mounted) return;
      NotificationService.warning(
        context,
        message: NotificationService.outOfTokens,
      );
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
      return;
    }

    provider.setGenerating(true);

    bool isCancelled = false;
    final progress = showGenerationProgressDialog(
      context,
      style: provider.style,
      photo: provider.uploadedImage,
      onCancel: () {
        isCancelled = true;
        provider.setGenerating(false);
      },
    );

    try {
      final bool useImg2Img =
          provider.activeMode == GenerationMode.image &&
          provider.uploadedImage != null;
      print(
        '🎃 FAL: Mode => ' +
            (useImg2Img ? 'image-to-image' : 'text-to-image') +
            ', prompt: ${provider.prompt}',
      );

      final builtI2I = useImg2Img
          ? PromptEngine.imageToImage(provider.prompt, style: provider.style)
          : null;
      final builtT2I = useImg2Img
          ? null
          : PromptEngine.textToImage(provider.prompt, style: provider.style);
      final result = useImg2Img
          ? await FalAiService.generateImageFromImage(
              prompt: builtI2I!.prompt,
              imageBytes: provider.uploadedImage!,
              isCancelled: () => isCancelled,
            )
          : await FalAiService.generateImage(
              prompt: builtT2I!.prompt,
              isCancelled: () => isCancelled,
            );
      print('🎃 FAL: API returned ${result.images.length} images');

      if (isCancelled) {
        try {
          progress.close();
        } catch (_) {}
        provider.setGenerating(false);
        return;
      }

      if (result.images.isEmpty) {
        // Graceful: just end silently
        print('🎃 FAL: No images returned, ending');
        try {
          progress.close();
        } catch (_) {}
        provider.setGenerating(false);
        return;
      }

      final String imageUrl = result.images.first.url;
      print('🎃 FAL: Image URL: $imageUrl');
      Uint8List? bytes;
      try {
        // Prefer bytes for uniform UI
        print('🎃 FAL: Attempting to fetch bytes from URL');
        bytes = await FalAiService.fetchImageBytes(imageUrl);
        print('🎃 FAL: Successfully fetched ${bytes.length} bytes');
      } catch (e) {
        print('🎃 FAL: fetchImageBytes failed: $e');
      }
      // Secondary attempt: download to file then read bytes
      if (bytes == null) {
        try {
          print('🎃 FAL: Attempting downloadAndSaveImage fallback');
          final imagePath = await FalAiService.downloadAndSaveImage(imageUrl);
          final imageFile = File(imagePath);
          bytes = await imageFile.readAsBytes();
          print('🎃 FAL: Successfully got bytes from file: ${bytes.length}');
        } catch (e) {
          print('🎃 FAL: downloadAndSaveImage failed: $e');
        }
      }

      GeneratedImageResult? generationResult;
      if (bytes != null) {
        generationResult = GeneratedImageResult(
          imageBytes: bytes,
          prompt: provider.promptLabel,
          source: GeneratedImageSource.fal,
          generatedAt: DateTime.now(),
          remoteUrl: imageUrl,
        );
      }

      if (!mounted) return;

      try {
        progress.setProgress(1.0);
        progress.close();
      } catch (_) {}

      GeneratedImageResult? finalizedResult = generationResult;
      if (finalizedResult != null) {
        print('🎃 FAL: Displaying image with bytes');
        // Consume tokens based on generation mode
        final double tokensToConsume = useImg2Img
            ? TokenCosts.imageToImage
            : TokenCosts.textToImage;
        await tokenProvider.consumeTokens(tokensToConsume);

        // Check for low balance after token consumption
        if (tokenProvider.isLowBalance) {
          if (!mounted) return;
          await LowBalanceDialog.show(context);
        }

        provider.addGeneratedImage(finalizedResult);
        await _showResultDialog(
          finalizedResult,
          style: provider.style,
          isImageToImage: useImg2Img,
        );

        // Clear prompt and uploaded image after successful generation
        provider.updatePrompt('');
        provider.removeUploadedImage();

        if (mounted) {
          NotificationService.success(
            context,
            message: NotificationService.imageGenerated,
          );
        }
      } else {
        print('🎃 FAL: Could not get bytes, showing network image as fallback');
        // Final fallback: show network image in dialog
        // Consume tokens based on generation mode
        final double tokensToConsume = useImg2Img
            ? TokenCosts.imageToImage
            : TokenCosts.textToImage;
        await tokenProvider.consumeTokens(tokensToConsume);

        // Check for low balance after token consumption
        if (tokenProvider.isLowBalance) {
          if (!mounted) return;
          await LowBalanceDialog.show(context);
        }

        await showDialog<void>(
          context: context,
          builder: (context) {
            return Dialog(
              backgroundColor: SeasonPalette.inputFill,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      width: 280,
                      height: 280,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: 280,
                        height: 280,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 280,
                            height: 280,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 280,
                            height: 280,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.red),
                                  Text('Failed to load image'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );

        // Clear prompt and uploaded image after successful generation
        provider.updatePrompt('');
        provider.removeUploadedImage();

        if (mounted) {
          NotificationService.success(
            context,
            message: NotificationService.imageGenerated,
          );
        }
      }
    } catch (e) {
      print('🎃 FAL: Generation failed: $e');
      try {
        progress.close();
      } catch (_) {}
      if (!isCancelled) {
        // Tell the user what happened instead of failing silently.
        _showFailure(e, _generateFalAiNewFlow);
      }
    } finally {
      if (mounted && !isCancelled) {
        provider.setGenerating(false);
      }
    }
  }

  /// Opens the result as its own screen (not a dialog): picture, style and
  /// description, with Save, Share and Make video.
  Future<void> _showResultDialog(
    GeneratedImageResult result, {
    PromptItem? style,
    bool isImageToImage = false,
  }) async {
    // Keep every finished picture: it is saved inside the app right away, so
    // it is in the Photos tab even if the app is closed before the user does
    // anything. (Save on the result screen copies it to the phone's photos.)
    final kept =
        await _persistGeneratedImage(
          result,
          showSuccessNotification: false,
          isImageToImage: isImageToImage,
          exportToGallery: false,
        ) ??
        result;
    if (!mounted) return;
    return openGeneratedResultPage(
      context,
      result: kept,
      style: style,
      mode: isImageToImage ? GenerationMode.image : GenerationMode.text,
      onShare: _shareGeneratedImage,
    );
  }

  Future<GeneratedImageResult?> _persistGeneratedImage(
    GeneratedImageResult result, {
    bool showSuccessNotification = true,
    bool isImageToImage = false,
    bool exportToGallery = true,
  }) async {
    if (!mounted) return null;
    final navigationProvider = context.read<MainNavigationProvider>();

    if (result.isPersisted) {
      if (showSuccessNotification) {
        NotificationService.info(
          context,
          message: 'Image is already saved in your gallery.',
        );
      }
      return result;
    }

    try {
      await context.read<SavedImagesProvider>().addSavedImage(
        imageBytes: result.imageBytes,
        prompt: result.prompt,
        isImageToImage: isImageToImage,
        originalImagePath: null,
        exportToGallery: exportToGallery,
      );
      final updated = navigationProvider.markImagePersisted(result);
      if (showSuccessNotification) {
        NotificationService.success(
          context,
          message: NotificationService.imageSaved,
        );
      }
      return updated;
    } catch (e) {
      debugPrint('Failed to persist generated image: $e');
      if (showSuccessNotification) {
        NotificationService.error(
          context,
          message: NotificationService.saveFailed,
        );
      }
    }
    return null;
  }

  Future<void> _shareGeneratedImage(GeneratedImageResult result) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName =
          'ghostface_${result.generatedAt.millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(result.imageBytes, flush: true);
      // Anchors the share sheet on iPad; without it the sheet can fail to
      // appear there.
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      unawaited(AnalyticsService.imageShared('image'));
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Created with SpookyAI',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        context,
        message: 'Failed to share image. Please try again.',
      );
    }
  }

  // _buildGeneratedImageCard removed

  @override
  Widget build(BuildContext context) {
    return Consumer<MainNavigationProvider>(
      builder: (context, provider, child) {
        // Start/stop premium banner animation based on premium status
        if (provider.isPremium) {
          if (!_premiumBannerController.isAnimating) {
            _premiumBannerController.repeat(period: const Duration(seconds: 3));
          }
        } else {
          if (_premiumBannerController.isAnimating) {
            _premiumBannerController.stop();
            _premiumBannerController.reset();
          }
        }
        return Scaffold(
          resizeToAvoidBottomInset: false,
          extendBody: true,
          body: IndexedStack(
            index: provider.currentIndex,
            children: [
              _buildGenerateTab(provider),
              PromptsPage(
                key: _pageKeys[2],
                filterRequest: _promptsFilterRequest,
                onUseStyle: (style) {
                  provider.setStyle(style);
                  provider.setCurrentIndex(0); // back to Generate
                },
              ),
              TrendPage(
                key: _pageKeys[4],
                onUseStyle: (style) {
                  provider.setStyle(style);
                  provider.setCurrentIndex(0); // back to Generate
                },
              ),
              PhotosPage(
                key: _pageKeys[1],
                onNavigateToGenerate: () {
                  provider.setCurrentIndex(0);
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              ProfilePage(key: _pageKeys[3]),
            ],
          ),
          bottomNavigationBar: AnimatedSlide(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            offset: provider.navHidden ? const Offset(0, 1.6) : Offset.zero,
            child: ValueListenableBuilder<TrendScreenConfig>(
              valueListenable: TrendService.config,
              builder: (context, trendCfg, _) => AppBottomNav(
                currentIndex: provider.currentIndex,
                onChanged: provider.setCurrentIndex,
                itemKeys: {
                  1: ProductTourKeys.promptsTab,
                  2: ProductTourKeys.trendsTab,
                },
                items: [
                  const AppNavItem(
                    icon: Icons.auto_awesome_outlined,
                    activeIcon: Icons.auto_awesome_rounded,
                    label: 'Generate',
                  ),
                  const AppNavItem(
                    icon: Icons.lightbulb_outline_rounded,
                    activeIcon: Icons.lightbulb_rounded,
                    label: 'Prompts',
                  ),
                  AppNavItem(
                    icon: Icons.local_fire_department_outlined,
                    activeIcon: Icons.local_fire_department_rounded,
                    label: trendCfg.tabLabel,
                  featured: true,
                  featuredColors: trendCfg.tabColors,
                  ),
                  const AppNavItem(
                    icon: Icons.photo_library_outlined,
                    activeIcon: Icons.photo_library_rounded,
                    label: 'Photos',
                  ),
                  const AppNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      key: const ValueKey('premium_banner'),
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: SeasonPalette.accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: SeasonPalette.accent.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Premium star icon with animation
          AnimatedBuilder(
            animation: _premiumBannerAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _premiumBannerAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.2 + (_premiumBannerAnimation.value * 0.1),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 12),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Premium text
          const Text(
            'Premium Member',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          // Sparkle effect with animation
          AnimatedBuilder(
            animation: _premiumBannerAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_premiumBannerAnimation.value * 0.4),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.2 + (_premiumBannerAnimation.value * 0.2),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Loads a showcase example (its photo and motion hint) so the user can
  /// make the same video with one more tap.
  Future<void> _tryVideoExample(
    MainNavigationProvider provider,
    VideoSample sample,
  ) async {
    final data = await rootBundle.load(sample.still);
    if (!mounted) return;
    provider.setUploadedImage(data.buffer.asUint8List());
    provider.updatePrompt(sample.motion);
    NotificationService.success(
      context,
      message: 'Example loaded. Tap Generate to make your video.',
    );
  }

  void _surpriseMotion(MainNavigationProvider provider) {
    final ideas = IdeaChips.videoIdeas();
    HapticFeedback.selectionClick();
    provider.updatePrompt(ideas[Random().nextInt(ideas.length)]);
  }

  Widget _buildGenerateTab(MainNavigationProvider provider) {
    final isVideo = provider.activeMode == GenerationMode.video;
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(
          icon: Icons.auto_fix_high_rounded,
          title: 'SpookyAI',
        ),
        backgroundColor: SeasonPalette.scaffold,
        elevation: 0,
        toolbarHeight: AppMetrics.toolbarHeight,
        actions: [
          // Token Purchase Button
          TokenDisplayWidget(
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
            },
          ),
          const SizedBox(width: 2),
          // World map: pick the season theme
          WorldMapButton(
            key: ProductTourKeys.worldMap,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SeasonMapPage())),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          // banner 40 + vertical margin 2×8 — must match or the title row is squeezed.
          preferredSize: Size.fromHeight(provider.isPremium ? 56 : 0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: provider.isPremium
                ? _buildPremiumBanner()
                : const SizedBox.shrink(),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: 24,
                  left: -8,
                  child: Opacity(
                    opacity: 0.07,
                    child: Text(
                      SeasonPalette.t('🕸️'),
                      style: const TextStyle(fontSize: 72),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: Opacity(
                    opacity: 0.07,
                    child: Text(
                      SeasonPalette.t('🎃'),
                      style: const TextStyle(fontSize: 72),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCompactModeSelector(provider),
                            const SizedBox(height: 16),
                            if (isVideo)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: VideoExamplesButton(
                                  onTryExample: (s) =>
                                      _tryVideoExample(provider, s),
                                ),
                              ),
                            if (!isVideo)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: KeyedSubtree(
                                  key: ProductTourKeys.style,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    child: provider.style != null
                                        ? Padding(
                                            key: ValueKey(provider.style!.id),
                                            padding: const EdgeInsets.only(
                                              bottom: 0,
                                            ),
                                            child: SelectedStyleCard(
                                              style: provider.style!,
                                              onChange: () =>
                                                  _openStyles(provider),
                                              onRemove: provider.clearStyle,
                                            ),
                                          )
                                        : Padding(
                                            key: const ValueKey('choose-style'),
                                            padding: const EdgeInsets.only(
                                              bottom: 0,
                                            ),
                                            child: ChooseStyleCard(
                                              isPhoto:
                                                  provider.activeMode ==
                                                  GenerationMode.image,
                                              previewStyles:
                                                  PromptSuggestions.styles(
                                                    provider.activeMode,
                                                  ).take(3).toList(),
                                              onTap: () =>
                                                  _openStyles(provider),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: provider.activeMode != GenerationMode.text
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: ImageUploadWidget(
                                        uploadedImage: provider.uploadedImage,
                                        onImageSelected:
                                            provider.setUploadedImage,
                                        onImageRemoved:
                                            provider.removeUploadedImage,
                                      ),
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            KeyedSubtree(
                              key: ProductTourKeys.prompt,
                              child: PromptInputWidget(
                                onPromptChanged: provider.updatePrompt,
                                title: isVideo
                                    ? 'How should it move? (optional)'
                                    : provider.style != null
                                    ? 'Add details (optional)'
                                    : provider.activeMode ==
                                          GenerationMode.image
                                    ? SeasonPalette.current.copy.imageTitle
                                    : SeasonPalette.current.copy.textTitle,
                                hintText: isVideo
                                    ? 'e.g. fog drifting slowly, slow zoom in'
                                    : provider.style != null
                                    ? SeasonPalette
                                          .current
                                          .copy
                                          .styleDetailsHint
                                    : provider.activeMode ==
                                          GenerationMode.image
                                    ? SeasonPalette.current.copy.imageHint
                                    : SeasonPalette.current.copy.textHint,
                                initialText: provider.prompt,
                                onSurprise: isVideo
                                    ? () => _surpriseMotion(provider)
                                    : () => _surpriseStyle(provider),
                                minLines: isVideo || provider.style != null
                                    ? 2
                                    : 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Consumer<TokenProvider>(
            builder: (context, tokens, _) {
              final isImage = provider.activeMode == GenerationMode.image;
              return GenerateActionBar(
                key: ProductTourKeys.generate,
                mode: provider.activeMode,
                // The motion hint is optional for a video.
                hasPrompt: isVideo || provider.hasPromptInput,
                hasImage: provider.uploadedImage != null,
                balance: tokens.balance,
                cost: isVideo
                    ? TokenCosts.imageToVideo
                    : isImage
                    ? TokenCosts.imageToImage
                    : TokenCosts.textToImage,
                isGenerating: provider.isGenerating,
                onGenerate: isVideo
                    ? () => startImageToVideo(
                        context,
                        null,
                        imageBytes: provider.uploadedImage,
                        initialMotion: provider.prompt,
                      )
                    : isImage
                    ? _showFalAiGenerationConfirmationDialog
                    : _showGenerationConfirmationDialog,
                onGetTokens: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const PurchasePage())),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactModeSelector(MainNavigationProvider provider) {
    return GenerationModeSwitcher(
      mode: provider.activeMode,
      onChanged: provider.switchMode,
    );
  }
}
