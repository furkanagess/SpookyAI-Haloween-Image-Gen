import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/seasons/season_palette.dart';
import 'prompt_issue.dart';

/// Modern bottom sheet for a [PromptIssue]. Resolves to true when the user
/// pressed the primary action (e.g. "Try again", "Edit prompt").
Future<bool> showPromptIssueSheet(
  BuildContext context,
  PromptIssue issue,
) async {
  HapticFeedback.mediumImpact();
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _IssueSheet(issue: issue),
  );
  return result ?? false;
}

class _IssueSheet extends StatelessWidget {
  const _IssueSheet({required this.issue});

  final PromptIssue issue;

  Color get _tint => switch (issue.tone) {
    PromptIssueTone.danger => const Color(0xFFFF5A5F),
    PromptIssueTone.info => const Color(0xFF7DD3FC),
    PromptIssueTone.warning => SeasonPalette.secondaryAccent,
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Container(
        color: SeasonPalette.scaffold,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SeasonPalette.text.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  builder: (_, t, child) =>
                      Transform.scale(scale: t, child: child),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: _tint.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(issue.icon, size: 40, color: _tint),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  issue.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  issue.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: SeasonPalette.text.withOpacity(0.7),
                  ),
                ),
                if (issue.tips.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  for (final tip in issue.tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: _tint,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: SeasonPalette.text.withOpacity(0.78),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (issue.noTokensCharged) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.toll_rounded,
                          size: 16,
                          color: Color(0xFF4ADE80),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'No tokens were used',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: SeasonPalette.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      issue.primaryLabel,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (issue.retryable || issue.kind == PromptIssueKind.blocked)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Close',
                      style: TextStyle(color: SeasonPalette.text.withOpacity(0.55)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
