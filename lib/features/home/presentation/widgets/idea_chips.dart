import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/theme/seasons/season_theme.dart';

/// A horizontal row of tappable ideas that runs edge to edge: the list scrolls
/// under the screen's sides and only its first and last chips are inset, so
/// the parent's side padding never clips it.
class IdeaChips extends StatelessWidget {
  const IdeaChips({
    super.key,
    required this.ideas,
    required this.onPick,
    this.horizontalPadding = 22,
  });

  final List<String> ideas;
  final ValueChanged<String> onPick;
  final double horizontalPadding;

  /// Ideas for editing a picture: two in the season's voice, three generic.
  /// Exhaustive on purpose: a new season writes its own.
  static List<String> editIdeas() => [
    ...switch (SeasonPalette.current.id) {
      SeasonId.halloween => const ['Add fog and moonlight', 'Make it spookier'],
      SeasonId.christmas => const [
        'Add falling snow',
        'Add a warm fireplace glow',
      ],
    },
    'Change the background',
    'Make the colors richer',
    'Add soft lighting',
  ];

  /// Ideas for the motion of a video.
  static List<String> videoIdeas() => [
    ...switch (SeasonPalette.current.id) {
      SeasonId.halloween => const [
        'Fog drifting slowly',
        'Flickering candlelight',
      ],
      SeasonId.christmas => const ['Snow falling gently', 'Twinkling lights'],
    },
    'Slow zoom in',
    'Gentle camera pan',
    'Soft wind and movement',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: ideas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onPick(ideas[i]);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SeasonPalette.text.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SeasonPalette.text.withOpacity(0.12)),
            ),
            child: Text(
              ideas[i],
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
