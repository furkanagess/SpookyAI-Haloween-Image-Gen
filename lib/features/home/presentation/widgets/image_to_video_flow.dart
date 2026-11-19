import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/fal_ai_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/saved_videos_provider.dart';
import '../../../../core/services/token_costs.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../pages/purchase_page.dart';
import '../pages/video_result_page.dart';
import 'generation_progress_dialog.dart';
import 'idea_chips.dart';

/// Turns a saved image into a short video: confirm (with cost and an optional
/// motion hint) → the shared progress screen → the video detail screen,
/// with the clip kept in My Videos. Tokens are charged only
/// after the video was produced.
Future<void> startImageToVideo(
  BuildContext context,
  String? imagePath, {
  Uint8List? imageBytes,
  String? initialMotion,
}) async {
  final tokens = context.read<TokenProvider>();
  final motion = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => _VideoConfirmSheet(
      balance: tokens.balance,
      initialMotion: initialMotion,
    ),
  );
  if (motion == null || !context.mounted) return;

  if (tokens.balance < TokenCosts.imageToVideo) {
    NotificationService.warning(
      context,
      message: NotificationService.outOfTokens,
    );
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
    return;
  }

  final store = context.read<SavedVideosProvider>();
  var cancelled = false;
  Uint8List bytes;
  try {
    bytes = imageBytes ?? await File(imagePath!).readAsBytes();
  } catch (_) {
    if (context.mounted) {
      NotificationService.error(
        context,
        message: 'This picture could not be opened.',
      );
    }
    return;
  }
  if (!context.mounted) return;

  // Same waiting screen as pictures, paced and worded for a video.
  final progress = showGenerationProgressDialog(
    context,
    photo: bytes,
    video: true,
    onCancel: () => cancelled = true,
  );

  SavedVideo? saved;
  String? error;
  try {
    final url = await FalAiService.generateVideo(
      imageBytes: bytes,
      motionPrompt: motion,
      isCancelled: () => cancelled,
    );
    if (!cancelled) {
      final videoBytes = await FalAiService.downloadVideoBytes(url);
      if (!cancelled) {
        // Kept in My Videos right away; charged only after it exists.
        saved = await store.add(
          videoBytes: videoBytes,
          posterBytes: bytes,
          motionPrompt: motion,
        );
        await tokens.consumeTokens(TokenCosts.imageToVideo);
        progress.setProgress(1.0);
      }
    }
  } catch (e) {
    final text = e.toString();
    error = cancelled || text.contains('cancelled by user')
        ? null
        : e is FalAiException
        ? e.message
        : 'Something went wrong. Please try again.';
  } finally {
    progress.close(); // no-op when it is already closed
  }

  if (!context.mounted) return;
  if (error != null) {
    NotificationService.error(
      context,
      message: 'Video failed: $error. You were not charged.',
    );
    return;
  }
  if (saved == null) return;
  await openVideoResultPage(context, video: saved, justMade: true);
}

class _VideoConfirmSheet extends StatefulWidget {
  const _VideoConfirmSheet({required this.balance, this.initialMotion});
  final double balance;
  final String? initialMotion;

  @override
  State<_VideoConfirmSheet> createState() => _VideoConfirmSheetState();
}

class _VideoConfirmSheetState extends State<_VideoConfirmSheet> {
  late final _controller = TextEditingController(
    text: widget.initialMotion?.trim() ?? '',
  );
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _useIdea(String idea) {
    _controller.value = TextEditingValue(
      text: idea,
      selection: TextSelection.collapsed(offset: idea.length),
    );
    _focus.requestFocus();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _side(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: child,
  );

  /// Same look as the edit sheet: handle, title with a close button, a big
  /// field, edge-to-edge ideas and one tall button with its cost.
  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    return Container(
      decoration: BoxDecoration(
        color: SeasonPalette.scaffold,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        0,
        12,
        0,
        18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: SeasonPalette.text.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title and close.
            _side(
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'How should it move?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: SeasonPalette.text.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: SeasonPalette.text.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _side(
              TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: 200,
                textInputAction: TextInputAction.done,
                cursorColor: accent,
                style: const TextStyle(fontSize: 17, height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Describe the motion, or leave it empty',
                  hintStyle: TextStyle(
                    color: SeasonPalette.text.withOpacity(0.35),
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: SeasonPalette.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(18),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tap an idea to fill the field (edge to edge).
            IdeaChips(
              ideas: IdeaChips.videoIdeas(),
              horizontalPadding: 22,
              onPick: _useIdea,
            ),
            const SizedBox(height: 16),

            _side(
              SizedBox(
                height: 60,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(_controller.text.trim());
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.movie_creation_rounded, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Create video',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _fmt(TokenCosts.imageToVideo),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
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
    );
  }
}
