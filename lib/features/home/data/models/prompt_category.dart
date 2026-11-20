class PromptCategory {
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<PromptItem> prompts;

  const PromptCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.prompts,
  });
}

enum PromptType { textToImage, imageToImage }

/// Photo styles come in two kinds: everyday, true-to-life looks and
/// imaginative fantasy looks. Text styles keep the default.
enum StyleKind { realistic, fantasy }

class PromptItem {
  final String id;
  final String title;
  final String prompt;
  final String? imageUrl;
  final int usageCount;
  final bool isPopular;
  final List<String> tags;
  final PromptType promptType;

  /// True when the prompt already describes its own environment and
  /// lighting; the PromptEngine then skips its random setting/lighting so
  /// the two never contradict each other.
  final bool ownsScene;

  /// Realistic (everyday, nothing imaginary) or fantasy photo style.
  final StyleKind kind;

  /// Locked for non-premium users. Explicit (not derived from a hash) so the
  /// free/premium split of the library is a deliberate product decision.
  final bool isPremium;

  /// Short, catchy line shown on cards (never the prompt).
  final String tagline;

  /// One or two sentences about the look, shown on the style detail.
  final String description;

  const PromptItem({
    required this.id,
    required this.title,
    required this.prompt,
    this.imageUrl,
    this.usageCount = 0,
    this.isPopular = false,
    this.tags = const [],
    this.promptType = PromptType.textToImage,
    this.ownsScene = false,
    this.kind = StyleKind.realistic,
    this.isPremium = false,
    this.tagline = '',
    this.description = '',
  });

  PromptItem copyWith({
    String? id,
    String? title,
    String? prompt,
    String? imageUrl,
    int? usageCount,
    bool? isPopular,
    List<String>? tags,
    PromptType? promptType,
    bool? ownsScene,
    StyleKind? kind,
    bool? isPremium,
    String? tagline,
    String? description,
  }) {
    return PromptItem(
      id: id ?? this.id,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      imageUrl: imageUrl ?? this.imageUrl,
      usageCount: usageCount ?? this.usageCount,
      isPopular: isPopular ?? this.isPopular,
      tags: tags ?? this.tags,
      promptType: promptType ?? this.promptType,
      ownsScene: ownsScene ?? this.ownsScene,
      kind: kind ?? this.kind,
      isPremium: isPremium ?? this.isPremium,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
    );
  }
}
