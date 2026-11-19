import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/seasons/season_palette.dart';
import '../../domain/generation_mode.dart';

/// Everything the detail sheet needs, independent of built-in vs user prompt.
class PromptDetail {
  const PromptDetail({
    required this.title,
    required this.tags,
    this.tagline = '',
    this.description = '',
    required this.mode,
    required this.preview,
    this.isPopular = false,
    this.isLocked = false,
    this.isFavorite = false,
    this.onFavoriteChanged,
  });

  final String title;
  final List<String> tags;
  final String tagline;
  final String description;
  final GenerationMode mode;
  final Widget preview;
  final bool isPopular;
  final bool isLocked;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;
}

/// Style detail: large sample, what to expect, and a primary "Use this
/// style" button. The style's prompt text is deliberately never shown.
Future<void> showPromptDetailSheet(
  BuildContext context, {
  required PromptDetail detail,
  required VoidCallback onUse,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.94,
    ),
    builder: (sheetContext) => _DetailSheet(
      detail: detail,
      onUse: () {
        Navigator.of(sheetContext).pop();
        onUse();
      },
    ),
  );
}

const _proGold = Color(0xFFFFC107);
const _proInk = Color(0xFF3B2300);

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({required this.detail, required this.onUse});

  final PromptDetail detail;
  final VoidCallback onUse;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  late bool _fav = widget.detail.isFavorite;

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Container(
        color: SeasonPalette.scaffold,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full-bleed hero with floating grabber and close button.
                    Stack(
                      children: [
                        AspectRatio(aspectRatio: 5 / 4, child: d.preview),
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        if (d.onFavoriteChanged != null)
                          Positioned(
                            top: 18,
                            left: 14,
                            child: Semantics(
                              button: true,
                              label: _fav
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _fav = !_fav);
                                  d.onFavoriteChanged!(_fav);
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _fav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 20,
                                    color: _fav
                                        ? SeasonPalette.accent
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 18,
                          right: 14,
                          child: Semantics(
                            button: true,
                            label: 'Close',
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (d.isLocked)
                          Positioned(
                            left: 16,
                            bottom: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _proGold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 14,
                                    color: _proInk,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'PRO',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                      color: _proInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.title,
                            style: const TextStyle(
                              fontSize: 28,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                          if (d.tagline.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              d.tagline,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                                color: SeasonPalette.accent,
                              ),
                            ),
                          ],
                          if (d.description.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              d.description,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.55,
                                color: SeasonPalette.text.withOpacity(0.82),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final t in d.tags.take(5))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SeasonPalette.text.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    t[0].toUpperCase() + t.substring(1),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: SeasonPalette.text.withOpacity(
                                        0.7,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sticky actions.
            Container(
              color: SeasonPalette.scaffold,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: widget.onUse,
                          style: FilledButton.styleFrom(
                            backgroundColor: d.isLocked
                                ? _proGold
                                : SeasonPalette.accent,
                            foregroundColor: d.isLocked
                                ? _proInk
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                d.isLocked
                                    ? Icons.workspace_premium_rounded
                                    : Icons.auto_awesome_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                d.isLocked ? 'Go Pro' : 'Use this style',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
