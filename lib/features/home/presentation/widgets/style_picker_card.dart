import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/seasons/season_palette.dart';
import '../../data/models/prompt_category.dart';
import 'prompt_preview.dart';

/// Shows the style the user picked on the Prompts screen: a thumbnail and a
/// title. The style's prompt text is never displayed.
class SelectedStyleCard extends StatelessWidget {
  const SelectedStyleCard({
    super.key,
    required this.style,
    required this.onChange,
    required this.onRemove,
  });

  final PromptItem style;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isPhoto = style.promptType == PromptType.imageToImage;
    final accent = SeasonPalette.accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sample picture with a "selected" tick.
          SizedBox(
            width: 84,
            height: 108,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: PromptPreview(
                    id: style.id,
                    tags: style.tags,
                    isImageToImage: isPhoto,
                    imageUrl: style.imageUrl,
                    borderRadius: 18,
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SeasonPalette.scaffold,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECTED STYLE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  style.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                if (style.tagline.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    style.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: SeasonPalette.text.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    _pill(
                      label: 'Change',
                      icon: Icons.swap_horiz_rounded,
                      filled: true,
                      onTap: onChange,
                    ),
                    const SizedBox(width: 8),
                    _pill(
                      label: 'Remove',
                      icon: Icons.close_rounded,
                      filled: false,
                      onTap: onRemove,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final accent = SeasonPalette.accent;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: filled ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled ? accent : SeasonPalette.text.withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: filled
                    ? Colors.white
                    : SeasonPalette.text.withOpacity(0.75),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: filled
                      ? Colors.white
                      : SeasonPalette.text.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entry shown when no style is selected: jump to the Prompts screen.
class ChooseStyleCard extends StatelessWidget {
  const ChooseStyleCard({
    super.key,
    required this.isPhoto,
    required this.previewStyles,
    required this.onTap,
  });

  final bool isPhoto;
  final List<PromptItem> previewStyles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SeasonPalette.text.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SeasonPalette.text.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 82,
                height: 54,
                child: Stack(
                  children: [
                    for (var i = 0; i < previewStyles.take(3).length; i++)
                      Positioned(
                        left: i * 25,
                        child: Container(
                          width: 40,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: SeasonPalette.inputFill,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: PromptPreview(
                            id: previewStyles[i].id,
                            tags: previewStyles[i].tags,
                            isImageToImage: isPhoto,
                            imageUrl: previewStyles[i].imageUrl,
                            borderRadius: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPhoto
                      ? SeasonPalette.current.copy.choosePhotoStyle
                      : SeasonPalette.current.copy.chooseTextStyle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: SeasonPalette.text.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
