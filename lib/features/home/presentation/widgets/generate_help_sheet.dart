import 'package:flutter/material.dart';

import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/services/token_costs.dart';

/// "How it works" bottom sheet for the Generate tab: a 3-step walkthrough,
/// token costs at a glance and one concrete prompt-writing tip.
Future<void> showGenerateHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    builder: (_) => const _HelpSheet(),
  );
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SeasonPalette.scaffold,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: SeasonPalette.text.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SeasonPalette.text.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create your first image in 3 steps',
                      style: TextStyle(
                        fontSize: 14,
                        color: SeasonPalette.text.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _Timeline(
                      steps: [
                        _StepData(
                          Icons.tune_rounded,
                          'Choose a mode',
                          'Text to Image creates from your words. Image to Image transforms a photo you add.',
                        ),
                        _StepData(
                          Icons.edit_rounded,
                          'Describe it',
                          'Write what you imagine, or tap Surprise me for a ready-made idea.',
                        ),
                        _StepData(
                          Icons.auto_awesome_rounded,
                          'Tap Generate',
                          'Your image is ready in a few seconds and is saved to Photos.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Token cost'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _CostCard(
                            icon: Icons.notes_rounded,
                            label: 'Text to Image',
                            cost: TokenCosts.label(TokenCosts.textToImage),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CostCard(
                            icon: Icons.add_photo_alternate_rounded,
                            label: 'Image to Image',
                            cost: TokenCosts.label(TokenCosts.imageToImage),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _Note(
                      icon: Icons.card_giftcard_rounded,
                      text: 'Out of tokens? Tap your balance below to top up.',
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Write better prompts'),
                    const SizedBox(height: 10),
                    _PromptTip(
                      bad: 'scary house',
                      good: SeasonPalette.t(
                        'spooky haunted mansion at night, glowing windows, thick fog, cinematic lighting',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mention the subject, setting, lighting and mood.',
                      style: TextStyle(
                        fontSize: 13,
                        color: SeasonPalette.text.withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: SeasonPalette.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    ),
  );
}

class _StepData {
  const _StepData(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

/// Numbered steps joined by a vertical line.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});
  final List<_StepData> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: SeasonPalette.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (i != steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: SeasonPalette.accent.withOpacity(0.3),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == steps.length - 1 ? 0 : 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          steps[i].title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          steps[i].body,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: SeasonPalette.text.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CostCard extends StatelessWidget {
  const _CostCard({
    required this.icon,
    required this.label,
    required this.cost,
  });

  final IconData icon;
  final String label;
  final String cost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SeasonPalette.text.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SeasonPalette.text.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: SeasonPalette.accent),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: SeasonPalette.text.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cost,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: SeasonPalette.secondaryAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: SeasonPalette.text.withOpacity(0.65),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptTip extends StatelessWidget {
  const _PromptTip({required this.bad, required this.good});
  final String bad;
  final String good;

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, Color color, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SeasonPalette.text.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SeasonPalette.text.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          row(Icons.close_rounded, Colors.redAccent, bad),
          const SizedBox(height: 10),
          row(Icons.check_circle_rounded, const Color(0xFF4ADE80), good),
        ],
      ),
    );
  }
}
