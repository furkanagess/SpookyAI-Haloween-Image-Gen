import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/seasons/season_palette.dart';
import '../../domain/generation_mode.dart';

/// iOS-style segmented control with a sliding thumb, for choosing between
/// Text to Image, Image to Image and Image to Video.
class GenerationModeSwitcher extends StatelessWidget {
  const GenerationModeSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final GenerationMode mode;
  final ValueChanged<GenerationMode> onChanged;

  /// Short labels so three segments fit a phone; the full name is read out
  /// by screen readers.
  static const _items = <(GenerationMode, IconData, String, String)>[
    (GenerationMode.text, Icons.notes_rounded, 'Text', 'Text to Image'),
    (
      GenerationMode.image,
      Icons.add_photo_alternate_rounded,
      'Photo',
      'Image to Image',
    ),
    (
      GenerationMode.video,
      Icons.movie_filter_rounded,
      'Video',
      'Image to Video',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _items.indexWhere((e) => e.$1 == mode);

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SeasonPalette.text.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SeasonPalette.text.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment(-1 + 2 * selected / (_items.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / _items.length,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: SeasonPalette.accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: SeasonPalette.accent.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final item in _items)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: item.$1 == mode,
                    label: item.$4,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (item.$1 == mode) return;
                        HapticFeedback.selectionClick();
                        onChanged(item.$1);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: item.$1 == mode
                                ? Colors.white
                                : SeasonPalette.text.withOpacity(0.55),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.$2,
                                size: 18,
                                color: item.$1 == mode
                                    ? Colors.white
                                    : SeasonPalette.text.withOpacity(0.55),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  item.$3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
