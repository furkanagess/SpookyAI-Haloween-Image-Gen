/// Client-side content safety gate for user prompts.
///
/// This runs BEFORE any tokens are spent and before the prompt reaches the
/// image API (which additionally runs its own server-side safety checker).
/// Genre-typical spooky vocabulary (ghost, zombie, blood, skull, vampire,
/// "killer clown" costumes...) is deliberately allowed; what is blocked is
/// sexual content, sexual content involving minors, realistic/extreme
/// violence against people, suicide & self-harm, and hate content.
library;

enum ModerationCategory { sexual, minors, violence, selfHarm, hate }

class ModerationResult {
  const ModerationResult.allowed() : allowed = true, category = null;

  const ModerationResult.blocked(this.category) : allowed = false;

  final bool allowed;
  final ModerationCategory? category;

  /// Short, friendly message shown to the user when blocked.
  String get message => switch (category) {
    ModerationCategory.sexual =>
      'Adult or sexual content can\'t be generated. Try a spooky or festive idea instead.',
    ModerationCategory.minors =>
      'This request isn\'t allowed. Content sexualizing minors is strictly blocked.',
    ModerationCategory.violence =>
      'Realistic violence or gore against people can\'t be generated. Costume-style spooky themes are fine.',
    ModerationCategory.selfHarm =>
      'Content about suicide or self-harm can\'t be generated. If you\'re struggling, please reach out to someone you trust or a local helpline.',
    ModerationCategory.hate =>
      'Hateful or extremist content can\'t be generated.',
    null => '',
  };
}

class PromptModeration {
  PromptModeration._();

  // ---- category word lists (checked with word boundaries on a normalized
  // ---- string: lowercased, Turkish letters ascii-folded, basic leetspeak
  // ---- undone, and once more with separator characters removed).

  static const _sexual = [
    'nude', 'naked', 'nsfw', 'porn', 'porno', 'sex', 'sexual', 'sexy',
    'erotic', 'erotik', 'hentai', 'topless', 'nipple', 'nipples', 'genital',
    'genitals', 'penis', 'vagina', 'boobs', 'breasts', 'blowjob',
    'intercourse', 'orgasm', 'fetish', 'bdsm', 'stripper', 'striptease',
    'lingerie', 'onlyfans', 'xxx',
    // Turkish (ascii-folded)
    'ciplak', 'seks', 'cinsel', 'tecavuz', 'rape',
  ];

  static const _minorWords = [
    'child', 'children', 'kid', 'kids', 'minor', 'minors', 'teen', 'teens',
    'teenager', 'underage', 'baby', 'toddler', 'schoolgirl', 'schoolboy',
    // Turkish
    'cocuk', 'bebek', 'resit olmayan',
  ];

  // Standalone CSAM terms: blocked outright.
  static const _csam = ['loli', 'lolicon', 'shota', 'shotacon', 'cp'];

  static const _violence = [
    'murder', 'murdered', 'murdering', 'behead', 'beheading', 'beheaded',
    'decapitate', 'decapitated', 'decapitation', 'dismember', 'dismembered',
    'dismemberment', 'torture', 'tortured', 'torturing', 'massacre',
    'genocide', 'execution', 'executed', 'lynch', 'lynching',
    'school shooting', 'mass shooting', 'shooting people', 'terrorist attack',
    'terrorism', 'suicide bombing', 'mutilate', 'mutilated', 'mutilation',
    // Turkish
    'cinayet', 'katliam', 'infaz', 'iskence', 'soykirim', 'teror saldirisi',
  ];

  static const _selfHarm = [
    'suicide', 'suicidal', 'self-harm', 'self harm', 'kill myself',
    'killing myself', 'hang myself', 'cut myself', 'cutting myself',
    'overdose', 'end my life',
    // Turkish
    'intihar', 'kendimi oldur', 'kendime zarar', 'bilek kesme',
  ];

  static const _hate = [
    'nazi', 'swastika', 'kkk', 'white power', 'ethnic cleansing',
    'heil hitler', 'hitler',
    // Turkish
    'etnik temizlik',
  ];

  /// Checks [raw] and returns whether it may be sent to generation.
  static ModerationResult check(String raw) {
    final n = _normalize(raw);
    // Second pass with in-word separators removed catches "s.e.x", "n-u-d-e".
    final tight = n.replaceAll(RegExp(r'(?<=\w)[.\-_*+|]+(?=\w)'), '');

    bool hitAny(List<String> words) => _hits(n, words) || _hits(tight, words);

    if (hitAny(_csam)) {
      return const ModerationResult.blocked(ModerationCategory.minors);
    }
    final sexual = hitAny(_sexual);
    if (sexual && hitAny(_minorWords)) {
      return const ModerationResult.blocked(ModerationCategory.minors);
    }
    if (sexual) {
      return const ModerationResult.blocked(ModerationCategory.sexual);
    }
    if (hitAny(_selfHarm)) {
      return const ModerationResult.blocked(ModerationCategory.selfHarm);
    }
    if (hitAny(_violence)) {
      return const ModerationResult.blocked(ModerationCategory.violence);
    }
    if (hitAny(_hate)) {
      return const ModerationResult.blocked(ModerationCategory.hate);
    }
    return const ModerationResult.allowed();
  }

  static bool _hits(String text, List<String> words) {
    for (final w in words) {
      if (RegExp('\\b${RegExp.escape(w)}\\b').hasMatch(text)) return true;
    }
    return false;
  }

  /// Lowercase, fold Turkish characters to ascii, undo basic leetspeak and
  /// collapse whitespace, so blocklists match common evasions too.
  static String _normalize(String input) {
    var s = input.toLowerCase();
    const turkish = {
      'ç': 'c',
      'ş': 's',
      'ğ': 'g',
      'ü': 'u',
      'ö': 'o',
      'ı': 'i',
      'i̇': 'i',
      'â': 'a',
      'î': 'i',
      'û': 'u',
    };
    const leet = {
      '0': 'o',
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '5': 's',
      '7': 't',
      '@': 'a',
      r'$': 's',
      '!': 'i',
    };
    turkish.forEach((k, v) => s = s.replaceAll(k, v));
    leet.forEach((k, v) => s = s.replaceAll(k, v));
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
