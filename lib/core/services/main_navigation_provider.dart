import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/home/data/models/prompt_category.dart';
import '../../features/home/domain/generation_mode.dart';
import '../../features/home/domain/generated_image_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/seasons/season_palette.dart';
import '../theme/seasons/season_theme.dart';
import '../../features/home/data/services/prompt_service.dart';
import 'premium_service.dart';

class MainNavigationProvider extends ChangeNotifier {
  // Navigation state
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // Onboarding state
  int _onboardingPageIndex = 0;
  int get onboardingPageIndex => _onboardingPageIndex;

  // Premium status
  bool _isPremium = false;
  bool get isPremium => _isPremium;
  StreamSubscription<bool>? _premiumStatusSubscription;

  // Generation data
  String _prompt = '';
  String get prompt => _prompt;

  // A ready-made style picked on the Prompts screen. Its prompt text stays
  // inside the app: the user only ever sees the style's title and preview.
  //
  // Each mode remembers its own style until the user picks another one or
  // removes it: switching modes, generating or restarting the app keeps it.
  PromptItem? _textStyle;
  PromptItem? _imageStyle;
  PromptItem? get style {
    _dropStylesOfOtherSeason();
    return _activeMode == GenerationMode.image ? _imageStyle : _textStyle;
  }

  /// The season the remembered styles were picked in. A style only exists in
  /// its own season's library, so when the theme changes both are reset.
  SeasonId? _styleSeason;

  void _dropStylesOfOtherSeason() {
    final now = SeasonPalette.current.id;
    if (_styleSeason != null && _styleSeason != now) {
      _textStyle = null;
      _imageStyle = null;
      _styleSeason = null;
      _persistStyles();
    }
  }

  static const _kTextStyle = 'selected_style_text';
  static const _kImageStyle = 'selected_style_image';

  Future<void> _persistStyles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in {
        _kTextStyle: _textStyle?.id,
        _kImageStyle: _imageStyle?.id,
      }.entries) {
        final id = entry.value;
        if (id == null) {
          await prefs.remove(entry.key);
        } else {
          await prefs.setString(entry.key, id);
        }
      }
    } catch (_) {}
  }

  /// Restores the saved styles. A style that is not part of the current
  /// season's library (the season changed) is dropped.
  Future<void> _restoreStyles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      PromptItem? find(List<PromptItem> pool, String? id) {
        if (id == null) return null;
        for (final p in pool) {
          if (p.id == id) return p;
        }
        return null;
      }

      _textStyle = find(
        PromptService.getTextToImagePrompts(),
        prefs.getString(_kTextStyle),
      );
      _imageStyle = find(
        PromptService.getImageToImagePrompts(),
        prefs.getString(_kImageStyle),
      );
      if (_textStyle != null || _imageStyle != null) {
        _styleSeason = SeasonPalette.current.id;
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Text safe to show anywhere (confirmations, gallery, sharing): the style
  /// title for ready-made styles, otherwise what the user typed.
  String get promptLabel => style?.title ?? _prompt;

  /// True when there is something to generate from.
  bool get hasPromptInput => style != null || _prompt.trim().isNotEmpty;

  void setStyle(PromptItem item) {
    _dropStylesOfOtherSeason();
    _styleSeason = SeasonPalette.current.id;
    if (item.promptType == PromptType.imageToImage) {
      _imageStyle = item;
    } else {
      _textStyle = item;
    }
    _persistStyles();
    _activeMode = item.promptType == PromptType.imageToImage
        ? GenerationMode.image
        : GenerationMode.text;
    if (_activeMode == GenerationMode.text) _uploadedImage = null;
    _prompt = ''; // extra details start empty for a new style
    notifyListeners();
  }

  void clearStyle() {
    if (style == null) return;
    if (_activeMode == GenerationMode.image) {
      _imageStyle = null;
    } else {
      _textStyle = null;
    }
    _persistStyles();
    notifyListeners();
  }

  Uint8List? _uploadedImage;
  Uint8List? get uploadedImage => _uploadedImage;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  final List<GeneratedImageResult> _generatedImages = <GeneratedImageResult>[];
  List<GeneratedImageResult> get generatedImages =>
      List.unmodifiable(_generatedImages);
  GeneratedImageResult? get latestGeneratedImage =>
      _generatedImages.isNotEmpty ? _generatedImages.first : null;

  GenerationMode _activeMode = GenerationMode.text;
  GenerationMode get activeMode => _activeMode;

  // Animation controllers state
  bool _isFadeAnimationActive = false;
  bool get isFadeAnimationActive => _isFadeAnimationActive;

  bool _isPremiumBannerAnimationActive = false;
  bool get isPremiumBannerAnimationActive => _isPremiumBannerAnimationActive;

  MainNavigationProvider() {
    _initializePremiumStatus();
    _restoreStyles();
  }

  @override
  void dispose() {
    _premiumStatusSubscription?.cancel();
    super.dispose();
  }

  // Navigation methods
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _navHidden = false; // always show the bar on a new tab
      notifyListeners();
    }
  }

  // Scroll-driven visibility of the bottom navigation bar.
  bool _navHidden = false;
  bool get navHidden => _navHidden;

  void setNavHidden(bool hidden) {
    if (_navHidden != hidden) {
      _navHidden = hidden;
      notifyListeners();
    }
  }

  // Onboarding methods
  void setOnboardingPageIndex(int index) {
    if (_onboardingPageIndex != index) {
      _onboardingPageIndex = index;
      notifyListeners();
    }
  }

  // Premium status methods
  Future<void> _initializePremiumStatus() async {
    try {
      // Import here to avoid circular dependency
      final premiumService = await _getPremiumService();
      final isPremium = await premiumService.isPremiumUser();
      if (_isPremium != isPremium) {
        _isPremium = isPremium;
        notifyListeners();
      }
      _listenToPremiumStatusChanges();
    } catch (e) {
      if (_isPremium != false) {
        _isPremium = false;
        notifyListeners();
      }
    }
  }

  void _listenToPremiumStatusChanges() {
    _premiumStatusSubscription?.cancel();
    _premiumStatusSubscription = _getPremiumStatusStream().listen(
      (isPremium) {
        if (_isPremium != isPremium) {
          _isPremium = isPremium;
          notifyListeners();

          // Start banner animation when premium status changes to true
          if (isPremium) {
            _startPremiumBannerAnimation();
          } else {
            _stopPremiumBannerAnimation();
          }
        }
      },
      onError: (error) {
        debugPrint(
          'MainNavigationProvider: Error listening to premium status: $error',
        );
      },
    );
  }

  // Public method to force-refresh premium status (useful after test toggles)
  Future<void> refreshPremiumStatus() async {
    try {
      final premiumService = await _getPremiumService();
      final bool isPremiumNow = await premiumService.isPremiumUser();
      if (_isPremium != isPremiumNow) {
        _isPremium = isPremiumNow;
        notifyListeners();
      }
    } catch (_) {}
  }

  void _startPremiumBannerAnimation() {
    if (!_isPremiumBannerAnimationActive) {
      _isPremiumBannerAnimationActive = true;
      notifyListeners();
    }
  }

  void _stopPremiumBannerAnimation() {
    if (_isPremiumBannerAnimationActive) {
      _isPremiumBannerAnimationActive = false;
      notifyListeners();
    }
  }

  // Prompt methods
  void updatePrompt(String prompt) {
    if (_prompt != prompt) {
      _prompt = prompt;
      notifyListeners();
    }
  }

  // Image methods
  void setUploadedImage(Uint8List? imageBytes) {
    if (_uploadedImage != imageBytes) {
      _uploadedImage = imageBytes;
      // Image-to-image functionality disabled - coming soon
      // Pre-fill prompt to instruct using the uploaded image
      // if (_activeMode == GenerationMode.image && _prompt.trim().isEmpty) {
      //   _prompt =
      //       'use this image: detailed transformation to spooky cinematic style';
      // }
      notifyListeners();
    }
  }

  void removeUploadedImage() {
    if (_uploadedImage != null) {
      _uploadedImage = null;
      notifyListeners();
    }
  }

  // Generation mode methods
  void switchMode(GenerationMode newMode) {
    // Enable image-to-image mode

    if (_activeMode != newMode) {
      _activeMode = newMode;
      if (_activeMode == GenerationMode.text) {
        _uploadedImage = null;
      }
      notifyListeners();
    }
  }

  // Generation methods
  void setGenerating(bool isGenerating) {
    if (_isGenerating != isGenerating) {
      _isGenerating = isGenerating;
      notifyListeners();
    }
  }

  void addGeneratedImage(GeneratedImageResult result) {
    _generatedImages.insert(0, result);
    if (_generatedImages.length > 10) {
      _generatedImages.removeRange(10, _generatedImages.length);
    }
    notifyListeners();
  }

  GeneratedImageResult markImagePersisted(GeneratedImageResult result) {
    final index = _generatedImages.indexOf(result);
    if (index != -1) {
      final updated = result.copyWith(isPersisted: true);
      _generatedImages[index] = updated;
      notifyListeners();
      return updated;
    }
    return result;
  }

  void clearGeneratedImages() {
    if (_generatedImages.isNotEmpty) {
      _generatedImages.clear();
      notifyListeners();
    }
  }

  // Animation methods
  void setFadeAnimationActive(bool isActive) {
    if (_isFadeAnimationActive != isActive) {
      _isFadeAnimationActive = isActive;
      notifyListeners();
    }
  }

  // Helper methods for dependency injection
  Future<dynamic> _getPremiumService() async {
    return PremiumService;
  }

  Stream<bool> _getPremiumStatusStream() {
    return PremiumService.premiumStatusStream;
  }
}
