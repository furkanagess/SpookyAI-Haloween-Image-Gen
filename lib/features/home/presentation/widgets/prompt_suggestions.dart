import '../../data/models/prompt_category.dart';
import '../../data/services/prompt_service.dart';
import '../../domain/generation_mode.dart';

/// Source of ready-made styles for "Surprise me".
class PromptSuggestions {
  PromptSuggestions._();

  /// All ready-made styles that belong to [mode].
  static List<PromptItem> styles(GenerationMode mode) {
    try {
      return mode == GenerationMode.image
          ? PromptService.getImageToImagePrompts()
          : PromptService.getTextToImagePrompts();
    } catch (_) {
      return const [];
    }
  }
}
