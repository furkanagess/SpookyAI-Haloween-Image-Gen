import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/seasons/season_palette.dart';
import '../../domain/generation_mode.dart';

/// Sticky bottom bar of the Generate tab. It always tells the user the one
/// thing that stands between them and an image, and turns into a "Get tokens"
/// shortcut when they cannot afford the generation.
class GenerateActionBar extends StatelessWidget {
  const GenerateActionBar({
    super.key,
    required this.mode,
    required this.hasPrompt,
    required this.hasImage,
    required this.balance,
    required this.cost,
    required this.isGenerating,
    required this.onGenerate,
    required this.onGetTokens,
  });

  final GenerationMode mode;
  final bool hasPrompt;
  final bool hasImage;
  final double balance;
  final double cost;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final VoidCallback onGetTokens;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final needsImage = mode == GenerationMode.image && !hasImage;
    final needsPrompt = !hasPrompt;
    final needsTokens = balance < cost;

    final ready = !isGenerating && !needsImage && !needsPrompt;
    final buyMode = ready && needsTokens;
    final enabled = ready;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                color: enabled
                    ? SeasonPalette.accent
                    : SeasonPalette.text.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: SeasonPalette.accent.withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: enabled
                      ? () {
                          HapticFeedback.mediumImpact();
                          buyMode ? onGetTokens() : onGenerate();
                        }
                      : null,
                  child: Center(
                    child: isGenerating
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('Generating…', style: _label(Colors.white)),
                            ],
                          )
                        : buyMode
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text('Get tokens', style: _label(Colors.white)),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 20,
                                color: enabled
                                    ? Colors.white
                                    : SeasonPalette.text.withOpacity(0.35),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Generate',
                                style: _label(
                                  enabled
                                      ? Colors.white
                                      : SeasonPalette.text.withOpacity(0.35),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(
                                    enabled ? 0.22 : 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_fmt(cost)} token${cost == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: enabled
                                        ? Colors.white
                                        : SeasonPalette.text.withOpacity(0.35),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _label(Color c) => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: c,
  );
}
