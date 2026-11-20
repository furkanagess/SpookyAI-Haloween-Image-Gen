import 'package:flutter/material.dart';

import '../../features/home/domain/generation_mode.dart';
import 'prompt_moderation.dart';

enum PromptIssueKind {
  // Input problems (caught before any token is spent)
  empty,
  tooShort,
  tooLong,
  noLetters,
  missingPhoto,
  blocked,
  // Generation problems (nothing was charged)
  offline,
  timeout,
  busy,
  serverFiltered,
  config,
  unknown,
}

/// A user-facing problem with a prompt or a generation, with copy written
/// for people (what happened, what to do) instead of exception text.
class PromptIssue {
  const PromptIssue({
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
    this.tips = const [],
    this.primaryLabel = 'Got it',
    this.retryable = false,
    this.noTokensCharged = false,
    this.tone = PromptIssueTone.warning,
  });

  final PromptIssueKind kind;
  final String title;
  final String message;
  final IconData icon;
  final List<String> tips;
  final String primaryLabel;

  /// Primary button re-runs the generation.
  final bool retryable;
  final bool noTokensCharged;
  final PromptIssueTone tone;

  /// Input problems that are best shown inline on the prompt field.
  bool get isInline =>
      kind == PromptIssueKind.empty ||
      kind == PromptIssueKind.tooShort ||
      kind == PromptIssueKind.tooLong ||
      kind == PromptIssueKind.noLetters;

  /// One short line for the inline footer under the prompt field.
  String get inlineMessage => switch (kind) {
    PromptIssueKind.empty => 'Describe what you want to see first',
    PromptIssueKind.tooShort => 'Add a bit more detail (a few words)',
    PromptIssueKind.tooLong => 'Too long — shorten your prompt',
    PromptIssueKind.noLetters => 'Use words to describe your idea',
    _ => message,
  };
}

enum PromptIssueTone { warning, danger, info }

/// Pre-flight check run before the confirmation dialog.
class PromptValidator {
  PromptValidator._();

  static const int minLength = 8;
  static const int maxLength = 500;

  static PromptIssue? validate(
    String raw, {
    required GenerationMode mode,
    required bool hasPhoto,
    bool hasStyle = false,
  }) {
    final text = raw.trim();

    if (mode == GenerationMode.image && !hasPhoto) {
      return const PromptIssue(
        kind: PromptIssueKind.missingPhoto,
        title: 'Add a photo first',
        message:
            'Image to Image transforms your own photo, so we need one to start.',
        icon: Icons.add_photo_alternate_rounded,
        tips: [
          'A clear, front-facing photo works best',
          'Good light and no sunglasses keep the likeness',
        ],
        primaryLabel: 'Got it',
      );
    }

    // A ready-made style is a complete prompt: the text box then only holds
    // optional extra details, so it may be empty or short.
    if (hasStyle && text.isEmpty) return null;

    if (text.isEmpty) {
      return const PromptIssue(
        kind: PromptIssueKind.empty,
        title: 'What should we create?',
        message: 'Describe your idea, or tap “Surprise me” for inspiration.',
        icon: Icons.edit_note_rounded,
      );
    }

    if (text.length > maxLength) {
      return PromptIssue(
        kind: PromptIssueKind.tooLong,
        title: 'That prompt is a bit long',
        message:
            'Prompts can be up to $maxLength characters. Yours is ${text.length}.',
        icon: Icons.short_text_rounded,
      );
    }

    final letters = RegExp(r'\p{L}', unicode: true).allMatches(text).length;
    if (letters < 3 || letters / text.length < 0.4) {
      return const PromptIssue(
        kind: PromptIssueKind.noLetters,
        title: 'We couldn\'t read that',
        message: 'Use a few words to describe what you want to see.',
        icon: Icons.translate_rounded,
      );
    }

    if (!hasStyle && text.length < minLength) {
      return const PromptIssue(
        kind: PromptIssueKind.tooShort,
        title: 'Add a little more detail',
        message: 'A few more words give much better results.',
        icon: Icons.auto_awesome_rounded,
        tips: ['Try: who or what, what they wear, and the mood'],
      );
    }

    final mod = PromptModeration.check(text);
    if (!mod.allowed) return fromModeration(mod);

    return null;
  }

  /// Friendly version of a moderation rejection.
  static PromptIssue fromModeration(ModerationResult mod) {
    final selfHarm = mod.category == ModerationCategory.selfHarm;
    return PromptIssue(
      kind: PromptIssueKind.blocked,
      title: selfHarm ? 'We\'re here for you' : 'We can\'t create that',
      message: mod.message,
      icon: selfHarm ? Icons.favorite_rounded : Icons.shield_outlined,
      tone: selfHarm ? PromptIssueTone.info : PromptIssueTone.danger,
      tips: selfHarm
          ? const []
          : const [
              'Spooky and festive ideas are always welcome',
              'Try a character, costume or atmosphere instead',
            ],
      primaryLabel: 'Edit prompt',
    );
  }
}

/// Maps a failed generation to something a person can act on.
class GenerationFailure {
  GenerationFailure._();

  /// Returns null for a user cancellation (nothing to show).
  static PromptIssue? classify(Object error) {
    final e = error.toString().toLowerCase();

    if (e.contains('cancelled by user') || e.contains('canceled by user')) {
      return null;
    }

    if (e.contains('socketexception') ||
        e.contains('failed host lookup') ||
        e.contains('network is unreachable') ||
        e.contains('connection closed') ||
        e.contains('clientexception') ||
        e.contains('connection refused')) {
      return const PromptIssue(
        kind: PromptIssueKind.offline,
        title: 'You\'re offline',
        message:
            'We couldn\'t reach the server. Check your connection and try again.',
        icon: Icons.wifi_off_rounded,
        primaryLabel: 'Try again',
        retryable: true,
        noTokensCharged: true,
      );
    }

    if (e.contains('timeout') || e.contains('took too long')) {
      return const PromptIssue(
        kind: PromptIssueKind.timeout,
        title: 'That took too long',
        message: 'The image is taking longer than expected.',
        icon: Icons.hourglass_empty_rounded,
        tips: ['Try again in a moment', 'A shorter prompt can be faster'],
        primaryLabel: 'Try again',
        retryable: true,
        noTokensCharged: true,
      );
    }

    if (e.contains('429') ||
        e.contains('rate limit') ||
        e.contains('too many')) {
      return const PromptIssue(
        kind: PromptIssueKind.busy,
        title: 'We\'re a little busy',
        message:
            'Lots of people are creating right now. Give it a few seconds.',
        icon: Icons.local_fire_department_rounded,
        primaryLabel: 'Try again',
        retryable: true,
        noTokensCharged: true,
      );
    }

    if (e.contains('422') &&
            (e.contains('safety') ||
                e.contains('content') ||
                e.contains('nsfw') ||
                e.contains('policy')) ||
        e.contains('content_policy') ||
        e.contains('moderation_blocked') ||
        e.contains('filtered by the safety system') ||
        e.contains('safety checker') ||
        e.contains('nsfw')) {
      return const PromptIssue(
        kind: PromptIssueKind.serverFiltered,
        title: 'That one didn\'t pass our safety check',
        message: 'The image couldn\'t be created with that idea.',
        icon: Icons.shield_outlined,
        tone: PromptIssueTone.danger,
        tips: [
          'Rephrase it with a different look or mood',
          'Costumes and spooky characters work great',
        ],
        primaryLabel: 'Edit prompt',
        noTokensCharged: true,
      );
    }

    if (e.contains('api key') ||
        e.contains('401') ||
        e.contains('403') ||
        e.contains('unauthorized') ||
        e.contains('not configured') ||
        e.contains('missing fal')) {
      return const PromptIssue(
        kind: PromptIssueKind.config,
        title: 'Service unavailable',
        message:
            'Image creation is temporarily unavailable. Please try again later.',
        icon: Icons.cloud_off_rounded,
        noTokensCharged: true,
      );
    }

    return const PromptIssue(
      kind: PromptIssueKind.unknown,
      title: 'Something went wrong',
      message: 'We couldn\'t create your image this time.',
      icon: Icons.refresh_rounded,
      tips: ['Try again — it usually works on the second go'],
      primaryLabel: 'Try again',
      retryable: true,
      noTokensCharged: true,
    );
  }
}
