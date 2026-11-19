import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/rating_service.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/theme/seasons/season_palette.dart';

/// "How happy are you with this result?" — five stars and a Send button,
/// shown above "Make it a video" on a freshly generated picture.
class ResultRatingCard extends StatefulWidget {
  const ResultRatingCard({
    super.key,
    required this.prompt,
    required this.mode,
    this.styleId,
    this.styleTitle,
  });

  final String prompt;
  final String mode;
  final String? styleId;
  final String? styleTitle;

  @override
  State<ResultRatingCard> createState() => _ResultRatingCardState();
}

class _ResultRatingCardState extends State<ResultRatingCard> {
  int _stars = 0;
  bool _sending = false;
  bool _sent = false;
  bool _apology = false;

  Future<void> _send() async {
    if (_stars == 0 || _sending || _sent) return;
    HapticFeedback.mediumImpact();
    setState(() => _sending = true);
    final apology = await RatingService.submit(
      stars: _stars,
      prompt: widget.prompt,
      mode: widget.mode,
      styleId: widget.styleId,
      styleTitle: widget.styleTitle,
    );
    if (apology && mounted) {
      await context.read<TokenProvider>().refreshBalance();
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
      _apology = apology;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: SeasonPalette.text.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SeasonPalette.text.withOpacity(0.1)),
        ),
        child: _sent ? _thanks(accent) : _ask(accent),
      ),
    );
  }

  Widget _thanks(Color accent) {
    return Row(
      children: [
        Icon(
          _apology ? Icons.local_fire_department : Icons.favorite_rounded,
          color: accent,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _apology
                ? "Sorry it missed the mark. We've added 1 token so you can try again."
                : 'Thanks for your feedback!',
            style: TextStyle(
              color: SeasonPalette.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _ask(Color accent) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How happy are you with this result?',
                style: TextStyle(
                  color: SeasonPalette.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final n = i + 1;
                  final on = n <= _stars;
                  return Semantics(
                    button: true,
                    selected: on,
                    label: '$n star${n == 1 ? '' : 's'}',
                    child: InkResponse(
                      radius: 22,
                      onTap: _sending
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() => _stars = n);
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 2,
                        ),
                        child: AnimatedScale(
                          scale: on ? 1.08 : 1,
                          duration: const Duration(milliseconds: 140),
                          child: Icon(
                            on
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 30,
                            color: on
                                ? const Color(0xFFFFC94A)
                                : SeasonPalette.text.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        AnimatedOpacity(
          opacity: _stars == 0 ? 0.4 : 1,
          duration: const Duration(milliseconds: 160),
          child: FilledButton(
            onPressed: _stars == 0 || _sending ? null : _send,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: SeasonPalette.onAccent,
              disabledBackgroundColor: accent.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: _sending
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SeasonPalette.onAccent,
                    ),
                  )
                : const Text('Send'),
          ),
        ),
      ],
    );
  }
}
