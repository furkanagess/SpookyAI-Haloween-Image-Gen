import '../prompt_engine/prompt_engine.dart';

/// Legacy facade kept for old call sites and tests.
///
/// The real prompt architecture now lives in [PromptEngine]
/// (lib/core/prompt_engine/). See PROMPT_ARCHITECTURE.md.
@Deprecated('Use PromptEngine instead')
class PromptBuilder {
  static String buildTextToImagePrompt(String userPrompt) =>
      PromptEngine.textToImage(userPrompt).prompt;

  static String buildImageToImagePrompt(String userPrompt) =>
      PromptEngine.imageToImage(userPrompt).prompt;

  static String getNegativePrompt() => '';

  static Map<String, String> buildTextToImagePromptStructure(
    String userPrompt,
  ) {
    final built = PromptEngine.textToImage(userPrompt);
    return {'prompt': built.prompt, 'negative_prompt': built.negativePrompt};
  }

  static Map<String, String> buildImageToImagePromptStructure(
    String userPrompt,
  ) {
    final built = PromptEngine.imageToImage(userPrompt);
    return {'prompt': built.prompt, 'negative_prompt': built.negativePrompt};
  }
}
