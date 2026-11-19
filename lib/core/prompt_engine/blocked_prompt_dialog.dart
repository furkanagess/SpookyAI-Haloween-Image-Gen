import 'package:flutter/material.dart';

import 'prompt_issue.dart';
import 'prompt_issue_sheet.dart';
import 'prompt_moderation.dart';

/// Kept for existing call sites: shows the modern issue sheet for a
/// moderation rejection. Returns true when the user chose the primary action.
Future<bool> showBlockedPromptDialog(
  BuildContext context,
  ModerationResult result,
) {
  return showPromptIssueSheet(context, PromptValidator.fromModeration(result));
}
