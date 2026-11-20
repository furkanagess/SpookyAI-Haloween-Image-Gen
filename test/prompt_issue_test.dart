import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/prompt_engine/prompt_engine.dart';
import 'package:spooky_ai/features/home/domain/generation_mode.dart';

PromptIssue? v(
  String text, {
  GenerationMode mode = GenerationMode.text,
  bool photo = false,
}) => PromptValidator.validate(text, mode: mode, hasPhoto: photo);

void main() {
  group('PromptValidator', () {
    test('valid prompts pass', () {
      expect(v('a friendly ghost holding a lantern'), isNull);
      expect(
        v('the person as a witch', mode: GenerationMode.image, photo: true),
        isNull,
      );
    });

    test('empty and whitespace-only', () {
      expect(v('')!.kind, PromptIssueKind.empty);
      expect(v('   \n ')!.kind, PromptIssueKind.empty);
    });

    test('too short, symbols only, too long', () {
      expect(v('ghost')!.kind, PromptIssueKind.tooShort);
      expect(v('!!!???...###')!.kind, PromptIssueKind.noLetters);
      expect(v('12345 67890 111')!.kind, PromptIssueKind.noLetters);
      expect(v('a' * 501)!.kind, PromptIssueKind.tooLong);
    });

    test('image mode without a photo asks for one before judging the text', () {
      final i = v('', mode: GenerationMode.image, photo: false)!;
      expect(i.kind, PromptIssueKind.missingPhoto);
      expect(i.isInline, isFalse);
    });

    test('inline problems are inline, others are sheets', () {
      expect(v('')!.isInline, isTrue);
      expect(v('ghost')!.isInline, isTrue);
      expect(v('a nude woman in a graveyard')!.isInline, isFalse);
    });

    test('moderation maps to a friendly blocked issue', () {
      final i = v('a nude woman in a graveyard')!;
      expect(i.kind, PromptIssueKind.blocked);
      expect(i.primaryLabel, 'Edit prompt');
      expect(i.message, isNotEmpty);
    });

    test('self-harm gets a supportive tone, not a scolding one', () {
      final i = v('a person committing suicide')!;
      expect(i.tone, PromptIssueTone.info);
      expect(i.title.toLowerCase(), isNot(contains('can\'t create')));
    });

    test('non-English letters count as letters', () {
      expect(v('şirin bir hayalet elinde fener tutuyor'), isNull);
    });
  });

  group('GenerationFailure.classify', () {
    test('user cancellation is silent', () {
      expect(
        GenerationFailure.classify(Exception('Generation cancelled by user')),
        isNull,
      );
    });

    test('network, timeout, busy, filtered, config, unknown', () {
      expect(
        GenerationFailure.classify('SocketException: Failed host lookup')!.kind,
        PromptIssueKind.offline,
      );
      expect(
        GenerationFailure.classify(
          'FalAiException: Generation timeout - took too long',
        )!.kind,
        PromptIssueKind.timeout,
      );
      expect(
        GenerationFailure.classify(
          'Failed to submit generation: 429 - rate limit',
        )!.kind,
        PromptIssueKind.busy,
      );
      expect(
        GenerationFailure.classify(
          'submit: 422 - content_policy_violation',
        )!.kind,
        PromptIssueKind.serverFiltered,
      );
      expect(
        GenerationFailure.classify('Missing FAL AI API key')!.kind,
        PromptIssueKind.config,
      );
      expect(
        GenerationFailure.classify('weird thing')!.kind,
        PromptIssueKind.unknown,
      );
    });

    test('retryable failures promise no tokens were used', () {
      for (final e in ['SocketException', 'timeout', '429', 'weird']) {
        final i = GenerationFailure.classify(e)!;
        if (i.retryable) {
          expect(i.noTokensCharged, isTrue, reason: e);
          expect(i.primaryLabel, 'Try again', reason: e);
        }
      }
    });

    test('raw exception text never reaches the user', () {
      final i = GenerationFailure.classify(
        'FalAiException: Failed to submit generation: 500 - {"detail":"boom"}',
      )!;
      expect('${i.title} ${i.message}'.contains('{'), isFalse);
      expect('${i.title} ${i.message}'.contains('Exception'), isFalse);
    });
  });
}
