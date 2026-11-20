import 'package:flutter/foundation.dart';
import '../../features/home/data/models/prompt_category.dart';
import '../../features/home/data/services/prompt_service.dart';
import '../theme/seasons/season_palette.dart';
import 'prompt_moderation.dart';
import 'scene_kits.dart';

export 'prompt_issue.dart';
export 'prompt_issue_sheet.dart';
export 'prompt_moderation.dart';

/// The final, API-ready pair of prompts for one generation.
class BuiltPrompt {
  const BuiltPrompt({required this.prompt, required this.negativePrompt});

  final String prompt;
  final String negativePrompt;
}

/// Central prompt architecture for SpookyAI.
///
/// Every generation goes through the same pipeline:
///
///   raw user text
///     → [moderate]  content safety gate (block before any token is spent)
///     → [_sanitize] cleanup + prompt-injection stripping + length cap
///     → mode template (text-to-image / image-to-image)
///     → [BuiltPrompt] final prompt + negative prompt
///
/// Templates are deliberately short: only what the picture needs (subject,
/// place, light, "realistic photo"), plus one face sentence for photo edits.
/// Long rule lists and "Avoid:" sentences were removed; they crowded out the
/// subject and made results worse.
class PromptEngine {
  PromptEngine._();

  /// Upper bound for a built prompt. Both models accept far more (Nano Banana
  /// Pro 50,000 chars, GPT Image 2 edit 32,000), but longer prompts cost a
  /// little more and dilute instructions, so the engine stays well below.
  static const int maxPromptLength = 2000;

  // ------------------------------------------------------------ moderation

  /// Safety gate. Call this FIRST, before charging tokens or showing the
  /// progress dialog; a blocked result carries a user-friendly [message].
  static ModerationResult moderate(String rawPrompt) =>
      PromptModeration.check(rawPrompt);

  // ------------------------------------------------------------- building

  /// Builds the text-to-image prompt (FLUX Schnell).
  static BuiltPrompt textToImage(
    String rawPrompt, {
    SceneKit? scene,
    PromptItem? style,
  }) {
    final cleaned = _sanitize(_compose(rawPrompt, style));
    final lib = style ?? _libraryEntry(cleaned);
    final ownsScene = (lib?.ownsScene ?? false) || _namesPlace(rawPrompt);
    final kit =
        scene ??
        SceneKits.pick(
          season: SeasonPalette.current.id,
          tags: _tagsFor(cleaned, lib),
          forFace: false,
        );

    // Short and descriptive: subject first, then place and light, then the
    // look. No rule lists; they dilute the subject.
    String build(String subject) => ownsScene
        ? '$subject, $photoTail'
        : '$subject, set in ${kit.setting}, lit by ${kit.lighting}, '
              'with ${kit.effect}, $photoTail';

    final built = BuiltPrompt(
      prompt: _fitSubject(build, _subjectOrDefault(cleaned)),
      negativePrompt: _t2iNegative,
    );
    _log('T2I', built);
    return built;
  }

  /// Builds the image-to-image prompt (GPT Image 2 edit).
  ///
  /// The description is followed by one short face sentence ([faceLock]):
  /// the face stays unchanged and natural, lit to match the new scene.
  static BuiltPrompt imageToImage(
    String rawPrompt, {
    SceneKit? scene,
    PromptItem? style,
  }) {
    final cleaned = _stripLegacyIdentityBoilerplate(
      _sanitize(_compose(rawPrompt, style)),
    );
    final lib = style ?? _libraryEntry(cleaned);
    final ownsScene = (lib?.ownsScene ?? false) || _namesPlace(rawPrompt);
    final subject = cleaned.isEmpty
        ? SeasonPalette.t(
            'the person as a spooky Halloween character with a fitting costume and makeup',
          )
        : cleaned;
    // Face-flattering light only: colored light would tint skin and hurt the likeness.
    final kit =
        scene ??
        SceneKits.pick(
          season: SeasonPalette.current.id,
          tags: _tagsFor(cleaned, lib),
          forFace: true,
        );

    String build(String s) =>
        'Edit this photo: $s'
        '${ownsScene ? '' : ', set in ${kit.setting}, lit by ${kit.lighting}'}'
        '. $faceLock ${lib?.kind == StyleKind.fantasy ? fantasyTail : 'Realistic photo.'}';

    final built = BuiltPrompt(
      prompt: _fitSubject(build, subject),
      negativePrompt: _i2iNegative,
    );
    _log('I2I', built);
    return built;
  }

  /// Builds the prompt for a free-form edit of an existing picture
  /// ("make the sky pink"). No scene or style is added: only the
  /// instruction, plus a note to leave the rest, face included, as it is.
  static BuiltPrompt editImage(String instruction) {
    final cleaned = _sanitize(instruction);
    final built = BuiltPrompt(
      prompt: cleaned.isEmpty
          ? 'Make a small natural improvement to this photo. $_editTail'
          : '$cleaned. $_editTail',
      negativePrompt: _i2iNegative,
    );
    _log('EDIT', built);
    return built;
  }

  /// Closing words of every text-to-image prompt.
  static const String photoTail = 'realistic photo';

  /// Closing words of a fantasy photo style: imaginative scene, real face.
  static const String fantasyTail = 'Photorealistic fantasy scene.';

  /// The single face sentence of every image-to-image prompt.
  static const String faceLock =
      'Keep the same face, natural and unchanged, lit to match the scene.';

  static const String _editTail =
      "Keep everything else the same, including the person's face.";

  /// A ready-made [style] supplies the hidden prompt; [extra] is whatever
  /// the user typed on top of it (may be empty). Without a style, [extra] is
  /// simply the prompt.
  static void _log(String kind, BuiltPrompt p) {
    if (!kDebugMode) return;
    debugPrint('🎃 PROMPT [$kind]: ${p.prompt}', wrapWidth: 1024);
    debugPrint('🎃 NEGATIVE [$kind]: ${p.negativePrompt}', wrapWidth: 1024);
  }

  /// Whether the user's own text names a place. Then their place wins and
  /// the engine adds no scene of its own (it would contradict them, e.g. a
  /// "sunny beach" request landing in a moonlit forest).
  static bool _namesPlace(String raw) => _placePattern.hasMatch(raw);

  static final RegExp _placePattern = RegExp(
    r'\b(beach|sea|ocean|lake|river|island|desert|mountains?|hill|valley|'
    r'forest|woods|jungle|field|farm|garden|park|meadow|cave|'
    r'city|street|alley|road|town|village|rooftop|'
    r'room|bedroom|kitchen|bathroom|office|classroom|school|library|'
    r'church|cathedral|chapel|castle|palace|mansion|manor|house|cabin|'
    r'cottage|attic|basement|hallway|corridor|ballroom|stage|theater|'
    r'theatre|studio|cafe|restaurant|pub|nightclub|market|shop|store|'
    r'mall|station|train|airport|ship|boat|graveyard|cemetery|crypt|tomb|'
    r'ruins|temple|space|planet|underwater)\b',
    caseSensitive: false,
  );

  static String _compose(String extra, PromptItem? style) {
    if (style == null) return extra;
    final base = style.prompt.replaceAll(RegExp(r'[,.;:!\s]+$'), '');
    final more = extra.trim();
    return more.isEmpty ? base : '$base, $more';
  }

  /// Best-fitting scenes for [rawPrompt] (library tags + keywords), best
  /// first. Used by docs/previews; generation itself picks from this list
  /// with a weighted draw.
  static List<SceneKit> rankedScenes(
    String rawPrompt, {
    required bool forFace,
  }) {
    final cleaned = _sanitize(rawPrompt);
    return [
      for (final e in SceneKits.ranked(
        season: SeasonPalette.current.id,
        tags: _tagsFor(cleaned, _libraryEntry(cleaned)),
        forFace: forFace,
      ))
        e.$1,
    ];
  }

  /// The shipped library entry whose text is exactly [cleaned] (user-edited
  /// text yields null and falls back to keyword matching).
  static PromptItem? _libraryEntry(String cleaned) {
    try {
      return PromptService.findByPrompt(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Concepts that decide which scene suits this prompt: the library
  /// entry's tags plus keywords found in the text itself.
  static Set<String> _tagsFor(String cleaned, PromptItem? lib) => {
    ...?lib?.tags,
    ...SceneKits.tagsFromText(cleaned),
  };

  // -------------------------------------------------------------- details

  static const String _t2iNegative =
      'text, watermark, signature, logo, plastic skin, waxy skin, airbrushed, '
      'over-sharpened, HDR look, oversaturated, CGI, 3D render, uncanny, '
      'deformed anatomy, extra limbs, extra fingers, duplicated face, '
      'low quality, blurry';

  static const String _i2iNegative =
      'different person, altered facial identity, face swap, changed age, '
      'changed ethnicity, reshaped or slimmer face, enlarged eyes, beautified, '
      'plastic skin, waxy skin, over-smoothed, airbrushed, beauty filter, HDR, '
      'oversaturated, harsh shadows, CGI, 3D render, uncanny valley, doll-like, '
      'cut-out edges, pasted look, mismatched lighting on face, floating head, '
      'double face, distorted hands, extra fingers, extra limbs, low quality, '
      'blurry, text, watermark';

  /// Phrases that try to redirect the model rather than describe an image.
  static final List<RegExp> _injectionPatterns = [
    RegExp(
      r'ignore\s+(all\s+)?(previous|prior|above)\s+instructions?',
      caseSensitive: false,
    ),
    RegExp(
      r'disregard\s+(all\s+)?(previous|prior|above)\s+instructions?',
      caseSensitive: false,
    ),
    RegExp(r'\bsystem\s+prompt\b', caseSensitive: false),
    RegExp(r'\bjailbreak\b', caseSensitive: false),
    RegExp(r'\byou\s+are\s+now\b', caseSensitive: false),
    RegExp(r'\bdo\s+anything\s+now\b|\bDAN\s+mode\b', caseSensitive: false),
  ];

  /// Identity boilerplate that older library prompts carried inline; the
  /// engine now owns a single, better-phrased identity block, so inline
  /// copies are removed to save budget and avoid contradictions.
  static final List<RegExp> _legacyIdentityPhrases = [
    RegExp(
      r',?\s*(keep\s+exact\s+same\s+face|preserve\s+facial\s+features|'
      r'maintain\s+face\s+identity|same\s+person|identical\s+face|'
      r'keep\s+original\s+face|exact\s+same\s+person|'
      r'preserve\s+face\s+identity|maintain\s+facial\s+features)\s*',
      caseSensitive: false,
    ),
  ];

  static String _sanitize(String input) {
    var s = input
        // control chars out
        .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
        .trim();
    for (final p in _injectionPatterns) {
      s = s.replaceAll(p, ' ');
    }
    // surrounding quotes, collapsed whitespace, stray leading punctuation
    s = s
        .replaceAll(RegExp(r'''^["'`]+|["'`]+$'''), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[,.;:\s]+'), '')
        .trim();
    if (s.length > 500) {
      final cut = s.substring(0, 500);
      final lastSpace = cut.lastIndexOf(' ');
      s = (lastSpace > 300 ? cut.substring(0, lastSpace) : cut).trim();
    }
    // Drop trailing punctuation: the templates add their own ". ".
    return s.replaceAll(RegExp(r'[,.;:!\s]+$'), '');
  }

  static String _stripLegacyIdentityBoilerplate(String input) {
    var s = input;
    for (final p in _legacyIdentityPhrases) {
      s = s.replaceAll(p, ' ');
    }
    return s
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\s+,'), ',')
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r'[,\s]+$'), '')
        .trim();
  }

  static String _subjectOrDefault(String cleaned) {
    if (cleaned.length >= 3) return cleaned;
    return SeasonPalette.t('a spooky Halloween scene full of atmosphere');
  }

  /// Fits only the user's [subject] into the length budget. The fixed
  /// template parts (identity lock, integration, constraints) are never cut:
  /// the subject is trimmed at a word boundary to whatever room is left.
  static String _fitSubject(
    String Function(String subject) build,
    String subject,
  ) {
    final full = build(subject);
    if (full.length <= maxPromptLength) return full;
    final room = maxPromptLength - build('').length;
    if (room <= 0) return build('');
    var cut = subject.length > room ? subject.substring(0, room) : subject;
    final space = cut.lastIndexOf(' ');
    if (cut.length < subject.length && space > room ~/ 2) {
      cut = cut.substring(0, space);
    }
    cut = cut.replaceAll(RegExp(r'[,\s]+$'), '');
    return build(cut);
  }
}
