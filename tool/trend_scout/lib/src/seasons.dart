/// Per-season configuration: what to search for and where.
///
/// Mirrors the app's season plan (see SeasonRegistry); the robot does not
/// import the Flutter registry because it only needs search vocabulary.
class SeasonSpec {
  const SeasonSpec({
    required this.id,
    required this.displayName,
    required this.months,
    required this.keywords,
    required this.nameWords,
    required this.communitySubreddits,
    required this.aiArtQueries,
    required this.youtubeQueries,
  });

  final String id;
  final String displayName;

  /// Months (1-12) in which this season is auto-selected.
  final List<int> months;

  /// A signal must contain at least one of these to count as seasonal.
  final List<String> keywords;

  /// Words that only name the season ("christmas", "xmas"). These are
  /// removed from concept phrases; other keywords ("snow", "pumpkin") are
  /// content and stay.
  final List<String> nameWords;

  /// Season-specific communities: everything there is relevant (trusted).
  final List<String> communitySubreddits;

  /// Queries run inside general AI-art communities.
  final List<String> aiArtQueries;
  final List<String> youtubeQueries;

  static const aiArtSubreddits = [
    'StableDiffusion',
    'midjourney',
    'aiArt',
    'FluxAI',
    'dalle2',
  ];

  static const all = <SeasonSpec>[
    SeasonSpec(
      id: 'halloween',
      displayName: 'Halloween',
      months: [9, 10],
      keywords: [
        'halloween',
        'spooky',
        'haunted',
        'pumpkin',
        'ghost',
        'witch',
        'vampire',
        'zombie',
        'skeleton',
        'costume',
        'trick or treat',
        'jack-o-lantern',
        'horror',
        'cadılar bayramı',
      ],
      nameWords: [
        'halloween',
        'spooky',
        'cadılar',
        'bayramı',
        'trick',
        'treat',
      ],
      communitySubreddits: ['halloween', 'HalloweenCostumes', 'horror'],
      aiArtQueries: ['halloween', 'spooky portrait', 'horror costume'],
      youtubeQueries: [
        'halloween ai photo trend',
        'ai halloween portrait filter',
        'halloween costume ideas 2026',
      ],
    ),
    SeasonSpec(
      id: 'christmas',
      displayName: 'Christmas',
      months: [11, 12, 1],
      keywords: [
        'christmas',
        'xmas',
        'santa',
        'snow',
        'winter',
        'holiday',
        'reindeer',
        'elf',
        'gingerbread',
        'nutcracker',
        'noel',
        'yılbaşı',
        'new year',
        'festive',
        'cozy',
        'snow globe',
      ],
      nameWords: [
        'christmas',
        'xmas',
        'noel',
        'yılbaşı',
        'holiday',
        'festive',
        'merry',
      ],
      communitySubreddits: ['christmas', 'ChristmasDecorating', 'winter'],
      aiArtQueries: ['christmas', 'festive portrait', 'winter wonderland'],
      youtubeQueries: [
        'christmas ai photo trend',
        'ai christmas portrait',
        'christmas card photo ideas 2026',
      ],
    ),
    SeasonSpec(
      id: 'valentines',
      displayName: "Valentine's",
      months: [2],
      keywords: [
        'valentine',
        'valentines',
        'romantic',
        'love',
        'couple',
        'heart',
        'sevgililer günü',
        'date night',
        'rose',
      ],
      nameWords: ['valentine', 'valentines', 'sevgililer', 'günü'],
      communitySubreddits: ['valentines', 'Romance'],
      aiArtQueries: ['valentine', 'romantic portrait', 'couple photo'],
      youtubeQueries: ['valentines ai photo trend', 'ai couple portrait'],
    ),
    SeasonSpec(
      id: 'ramadan',
      displayName: 'Ramadan',
      months: [3],
      keywords: [
        'ramadan',
        'ramazan',
        'iftar',
        'eid',
        'bayram',
        'lantern',
        'kandil',
        'mosque',
        'crescent',
      ],
      nameWords: ['ramadan', 'ramazan', 'bayram', 'eid'],
      communitySubreddits: ['islam', 'ramadan'],
      aiArtQueries: ['ramadan', 'eid portrait', 'lantern night'],
      youtubeQueries: ['ramadan ai photo trend', 'eid photo ideas'],
    ),
    SeasonSpec(
      id: 'spring',
      displayName: 'Spring',
      months: [4, 5],
      keywords: [
        'easter',
        'spring',
        'blossom',
        'flower',
        'pastel',
        'bunny',
        'mother\'s day',
        'anneler günü',
        'garden',
      ],
      nameWords: ['spring', 'easter'],
      communitySubreddits: ['easter', 'gardening'],
      aiArtQueries: ['spring portrait', 'easter', 'cherry blossom'],
      youtubeQueries: ['spring ai photo trend', 'easter photo ideas'],
    ),
    SeasonSpec(
      id: 'summer',
      displayName: 'Summer',
      months: [6, 7, 8],
      keywords: [
        'summer',
        'beach',
        'vacation',
        'tropical',
        'sunset',
        'pool',
        'festival',
        'yaz',
        'tatil',
        'retro summer',
        'synthwave',
      ],
      nameWords: ['summer', 'yaz', 'tatil'],
      communitySubreddits: ['summer', 'travel'],
      aiArtQueries: ['summer portrait', 'beach', 'vaporwave'],
      youtubeQueries: ['summer ai photo trend', 'ai beach portrait'],
    ),
  ];

  static SeasonSpec byId(String id) => all.firstWhere(
    (s) => s.id == id,
    orElse: () => throw ArgumentError(
      'Unknown season "$id". Known: ${all.map((s) => s.id).join(', ')}',
    ),
  );

  static SeasonSpec forDate(DateTime d) => all.firstWhere(
    (s) => s.months.contains(d.month),
    orElse: () => all.first,
  );

  bool isRelevant(String text) {
    final t = text.toLowerCase();
    return keywords.any((k) => t.contains(k.toLowerCase()));
  }
}
