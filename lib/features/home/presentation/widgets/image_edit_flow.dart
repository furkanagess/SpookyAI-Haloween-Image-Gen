import 'dart:async';
import '../../../../core/services/analytics_service.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/prompt_engine/blocked_prompt_dialog.dart';
import '../../../../core/prompt_engine/prompt_engine.dart';
import '../../../../core/prompt_engine/prompt_issue.dart';
import '../../../../core/prompt_engine/prompt_issue_sheet.dart';
import '../../../../core/services/fal_ai_service.dart';
import '../../../../core/services/main_navigation_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/saved_images_provider.dart';
import '../../../../core/services/token_costs.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../../domain/generated_image_result.dart';
import '../../domain/generation_mode.dart';
import '../pages/generated_result_page.dart';
import '../pages/purchase_page.dart';
import 'generation_progress_dialog.dart';
import 'idea_chips.dart';

/// Edit a finished picture with a new instruction (image to image): a bottom
/// sheet takes the instruction, the usual waiting screen runs, and the edited
/// picture opens on its own result screen. The original is never changed.
Future<void> startImageEdit(BuildContext context, Uint8List imageBytes) async {
  final tokens = context.read<TokenProvider>();
  final instruction = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => const _EditSheet(),
  );
  if (instruction == null || !context.mounted) return;

  // Safety first: never spend tokens on a disallowed instruction.
  final moderation = PromptEngine.moderate(instruction);
  if (!moderation.allowed) {
    await showBlockedPromptDialog(context, moderation);
    return;
  }

  await tokens.loadBalance();
  if (tokens.balance < TokenCosts.imageToImage) {
    if (!context.mounted) return;
    NotificationService.warning(
      context,
      message: NotificationService.outOfTokens,
    );
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
    return;
  }

  final nav = context.read<MainNavigationProvider>();
  var cancelled = false;
  final progress = showGenerationProgressDialog(
    context,
    photo: imageBytes,
    onCancel: () => cancelled = true,
  );

  try {
    final built = PromptEngine.editImage(instruction);
    final result = await FalAiService.generateImageFromImage(
      prompt: built.prompt,
      imageBytes: imageBytes,
      isCancelled: () => cancelled,
    );
    if (cancelled) return;
    if (result.images.isEmpty) {
      throw FalAiException(
        'Generation returned no image (filtered by the safety system)',
      );
    }
    final bytes = await FalAiService.fetchImageBytes(result.images.first.url);
    if (cancelled) return;

    // Charged only after the edited picture exists.
    await tokens.consumeTokens(TokenCosts.imageToImage);
    final edited = GeneratedImageResult(
      imageBytes: bytes,
      prompt: instruction,
      source: GeneratedImageSource.fal,
      generatedAt: DateTime.now(),
    );
    progress.setProgress(1.0);
    progress.close();

    // Kept in the Photos tab right away, like every other result.
    final kept = await _keep(context, edited);
    nav.addGeneratedImage(kept);

    if (!context.mounted) return;
    await openGeneratedResultPage(
      context,
      result: kept,
      mode: GenerationMode.image,
      onShare: (r) => _share(context, r),
    );
  } catch (e) {
    progress.close();
    final text = e.toString();
    if (cancelled || text.contains('cancelled by user')) return;
    final issue = GenerationFailure.classify(e);
    if (issue != null && context.mounted) {
      await showPromptIssueSheet(context, issue);
    }
  } finally {
    progress.close(); // no-op when it is already closed
  }
}

/// Saves inside the app (no photo-library export, no permission prompt).
Future<GeneratedImageResult> _keep(
  BuildContext context,
  GeneratedImageResult result,
) async {
  if (!context.mounted) return result;
  final nav = context.read<MainNavigationProvider>();
  try {
    await context.read<SavedImagesProvider>().addSavedImage(
      imageBytes: result.imageBytes,
      prompt: result.prompt,
      isImageToImage: true,
      originalImagePath: null,
      exportToGallery: false,
    );
    return nav.markImagePersisted(result);
  } catch (_) {
    return result;
  }
}

/// Writes the picture to a temp file and opens the share sheet. [context]
/// is only used to anchor the sheet on iPad (`sharePositionOrigin`); without
/// it the share sheet can fail to appear there.
Future<void> _share(BuildContext context, GeneratedImageResult result) async {
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/spookyai_${result.generatedAt.millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(result.imageBytes, flush: true);
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  unawaited(AnalyticsService.imageShared('edit'));
  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Created with SpookyAI',
    sharePositionOrigin: origin,
  );
}

class _EditSheet extends StatefulWidget {
  const _EditSheet();

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  bool get _ready => _controller.text.trim().length >= 3;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _useIdea(String idea) {
    HapticFeedback.selectionClick();
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

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    final canAfford =
        context.watch<TokenProvider>().balance >= TokenCosts.imageToImage;
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
                      'What should change?',
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
                maxLength: 300,
                textInputAction: TextInputAction.done,
                cursorColor: accent,
                style: const TextStyle(fontSize: 17, height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Describe the change in your own words',
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
              ideas: IdeaChips.editIdeas(),
              horizontalPadding: 22,
              onPick: _useIdea,
            ),
            const SizedBox(height: 16),

            _side(
              SizedBox(
                height: 60,
                child: FilledButton(
                  onPressed: canAfford
                      ? _ready
                            ? () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(
                                  context,
                                ).pop(_controller.text.trim());
                              }
                            : null
                      : () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PurchasePage(),
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: SeasonPalette.text.withOpacity(
                      0.08,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        canAfford
                            ? Icons.auto_fix_high_rounded
                            : Icons.local_fire_department,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        canAfford ? 'Edit image' : 'Get tokens',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (canAfford) ...[
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
                                _fmt(TokenCosts.imageToImage),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
