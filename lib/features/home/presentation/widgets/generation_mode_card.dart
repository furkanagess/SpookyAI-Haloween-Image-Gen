import 'package:flutter/material.dart';
import '../../domain/generation_mode.dart';
import '../../../../core/theme/seasons/season_palette.dart';

class GenerationModeCard extends StatelessWidget {
  const GenerationModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.mode,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final GenerationMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: SeasonPalette.cardGradientStart,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SeasonPalette.text.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SeasonPalette.highlight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SeasonPalette.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: SeasonPalette.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
