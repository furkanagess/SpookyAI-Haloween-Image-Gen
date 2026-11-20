import 'package:flutter/material.dart';

import '../theme/seasons/season_badge.dart';
import '../theme/seasons/season_palette.dart';

/// Tab-root app bar title — use ONLY on the 4 main tabs (Generate, Prompts,
/// Photos, Profile); inner pages use a plain Text title.
/// accent rounded-square icon + title, so every tab's
/// header lines up the same way.
class AppBarTitle extends StatelessWidget {
  const AppBarTitle({
    super.key,
    this.icon,
    required this.title,
    this.showSeasonBadge = true,
  });

  /// Square icon before the title; null shows the title alone.
  final IconData? icon;
  final String title;

  /// Waving season flag under the title (shared by every tab).
  final bool showSeasonBadge;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );
    // IntrinsicHeight + stretch: the icon square is exactly as tall as the
    // title block (title + flag), and AspectRatio keeps it square.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null) ...[
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: SeasonPalette.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (!showSeasonBadge)
            Flexible(child: text)
          else
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  const SizedBox(height: 3),
                  const SeasonBadge(showEmoji: false),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
