import 'dart:io';

import 'package:args/args.dart';
import 'package:trend_scout/trend_scout.dart';

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption(
      'season',
      abbr: 's',
      help:
          'Season id (${SeasonSpec.all.map((s) => s.id).join(', ')}). '
          'Default: the season for today\'s date.',
    )
    ..addOption(
      'days',
      abbr: 'd',
      defaultsTo: '14',
      help: 'Look-back window in days.',
    )
    ..addOption(
      'concepts',
      abbr: 'c',
      defaultsTo: '20',
      help: 'Max concepts to keep.',
    )
    ..addOption('text-per-concept', defaultsTo: '1')
    ..addOption('image-per-concept', defaultsTo: '1')
    ..addOption(
      'out',
      abbr: 'o',
      defaultsTo: 'output',
      help: 'Output directory.',
    )
    ..addOption('model', defaultsTo: 'claude-opus-5-5')
    ..addOption(
      'effort',
      defaultsTo: 'medium',
      allowed: ['low', 'medium', 'high', 'xhigh', 'max'],
    )
    ..addMultiOption(
      'source',
      defaultsTo: ['reddit', 'youtube', 'google-trends', 'seed'],
      allowed: ['reddit', 'youtube', 'google-trends', 'seed'],
      help: 'Sources to query (repeatable).',
    )
    ..addFlag(
      'no-llm',
      negatable: false,
      help: 'Force offline mode even if ANTHROPIC_API_KEY is set.',
    )
    ..addFlag(
      'strict',
      negatable: false,
      help: 'Drop brand/real-person flagged candidates instead of warning.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    exit(64);
  }
  if (args['help'] as bool) {
    stdout.writeln(
      'Trend Scout — seasonal trend → prompt candidates for SpookyAI\n',
    );
    stdout.writeln(parser.usage);
    return;
  }

  final env = Env.load();
  final season = args['season'] == null
      ? SeasonSpec.forDate(DateTime.now())
      : SeasonSpec.byId(args['season'] as String);
  final days = int.parse(args['days'] as String);
  final wanted = (args['source'] as List<String>).toSet();

  final sources = <TrendSource>[];
  if (wanted.contains('seed')) sources.add(SeedFileSource());
  if (wanted.contains('reddit')) {
    final id = env['REDDIT_CLIENT_ID'];
    final secret = env['REDDIT_CLIENT_SECRET'];
    if (id == null || secret == null) {
      stderr.writeln(
        '• REDDIT_CLIENT_ID/REDDIT_CLIENT_SECRET not set — skipping Reddit',
      );
    } else {
      sources.add(RedditSource(clientId: id, clientSecret: secret));
    }
  }
  if (wanted.contains('google-trends')) sources.add(GoogleTrendsRssSource());
  if (wanted.contains('youtube')) {
    final key = env.youtubeKey;
    if (key == null) {
      stderr.writeln('• YOUTUBE_API_KEY not set — skipping YouTube');
    } else {
      sources.add(YouTubeSource(key));
    }
  }

  ClaudeClient? claude;
  if (!(args['no-llm'] as bool)) {
    final key = env.anthropicKey;
    if (key == null) {
      stderr.writeln(
        '• ANTHROPIC_API_KEY not set — offline mode (template prompts)',
      );
    } else {
      claude = ClaudeClient(
        key,
        model: args['model'] as String,
        effort: args['effort'] as String,
      );
    }
  }

  final pipeline = ScoutPipeline(
    sources: sources,
    writer: CandidateWriter(
      claude: claude,
      textPerConcept: int.parse(args['text-per-concept'] as String),
      imagePerConcept: int.parse(args['image-per-concept'] as String),
    ),
    filter: CandidateFilter(strict: args['strict'] as bool),
    maxConcepts: int.parse(args['concepts'] as String),
    log: stdout.writeln,
  );

  stdout.writeln(
    'Trend Scout · season=${season.id} · window=${days}d · '
    'sources=${sources.map((s) => s.name).join(',')} · '
    'llm=${claude?.model ?? 'off'}',
  );
  final report = await pipeline.run(season, windowDays: days);
  final (json, md) = await ReportWriter(
    directory: args['out'] as String,
  ).write(report);

  stdout
    ..writeln()
    ..writeln(
      'Signals ${report.signals.length} → concepts ${report.concepts.length} → '
      'candidates ${report.approved.length} approved / ${report.blocked.length} blocked',
    )
    ..writeln('JSON: ${json.path}')
    ..writeln('MD:   ${md.path}');
  if (report.sourceErrors.isNotEmpty) {
    stdout.writeln('Source errors: ${report.sourceErrors}');
  }
  if (report.signals.isEmpty) {
    stderr.writeln(
      'No signals collected — check network/keys or add seeds/${season.id}.txt',
    );
    exit(2);
  }
}
