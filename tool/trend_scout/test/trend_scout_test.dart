import 'dart:convert';

import 'package:test/test.dart';
import 'package:trend_scout/trend_scout.dart';

TrendSignal sig(
  String title, {
  double eng = 100,
  String source = 'reddit:r/x',
  bool trusted = false,
  int ageDays = 1,
  String? note,
}) => TrendSignal(
  source: source,
  title: title,
  url: 'https://example.com',
  rawEngagement: eng,
  publishedAt: DateTime.now().subtract(Duration(days: ageDays)),
  trusted: trusted,
  note: note,
);

class FakeSource implements TrendSource {
  FakeSource(this.name, this.signals, {this.fail = false});
  @override
  final String name;
  final List<TrendSignal> signals;
  final bool fail;
  @override
  Future<List<TrendSignal>> fetch(
    SeasonSpec s, {
    required int windowDays,
  }) async {
    if (fail) throw SourceException(name, 'boom');
    return signals;
  }
}

void main() {
  final xmas = SeasonSpec.byId('christmas');

  group('SeasonSpec', () {
    test('auto-selects by month', () {
      expect(SeasonSpec.forDate(DateTime(2026, 12, 5)).id, 'christmas');
      expect(SeasonSpec.forDate(DateTime(2026, 10, 5)).id, 'halloween');
      expect(SeasonSpec.forDate(DateTime(2026, 7, 5)).id, 'summer');
    });
    test('relevance uses keywords case-insensitively', () {
      expect(xmas.isRelevant('My SANTA portrait'), isTrue);
      expect(xmas.isRelevant('random cat video'), isFalse);
    });
  });

  group('SignalScorer', () {
    test('drops irrelevant untrusted, keeps trusted, orders by score', () {
      final scored = const SignalScorer().score(
        [
          sig('snow globe portrait trend', eng: 900),
          sig('cat does a backflip', eng: 99999),
          sig('from seed', source: 'seed', trusted: true, eng: 1),
          sig('old christmas thing', eng: 900, ageDays: 40),
        ],
        xmas,
        windowDays: 14,
      );
      final titles = scored.map((s) => s.title).toList();
      expect(titles, isNot(contains('cat does a backflip')));
      expect(titles, contains('from seed'));
      expect(titles.first, 'snow globe portrait trend');
      expect(scored.every((s) => s.score > 0 && s.score <= 1), isTrue);
    });
    test('dedupes near-identical titles', () {
      final scored = const SignalScorer().score(
        [
          sig('Christmas Snow Globe!!', eng: 10),
          sig('christmas snow globe', eng: 500),
        ],
        xmas,
        windowDays: 14,
      );
      expect(scored.length, 1);
      expect(scored.first.rawEngagement, 500);
    });
  });

  group('ConceptExtractor', () {
    test('finds repeated phrases and drops season/stop words', () {
      final signals = const SignalScorer().score(
        [
          sig('AI christmas snow globe portrait', eng: 300),
          sig('snow globe portrait with my dog, christmas', eng: 200),
          sig('made a snow globe portrait of my family', eng: 150),
          sig('ugly sweater party polaroid christmas', eng: 400),
          sig('ugly sweater party pics for xmas', eng: 100),
        ],
        xmas,
        windowDays: 14,
      );
      final concepts = const ConceptExtractor().extract(signals, xmas);
      final names = concepts.map((c) => c.name).toList();
      expect(names, contains('snow globe portrait'));
      expect(names.any((n) => n.contains('ugly sweater')), isTrue);
      expect(names.any((n) => n.contains('christmas')), isFalse);
      expect(concepts.first.strength, 100);
    });
  });

  group('CandidateFilter', () {
    PromptCandidate cand(String title, String prompt) => PromptCandidate(
      id: 'x',
      title: title,
      mode: PromptMode.text,
      prompt: prompt,
      tags: const [],
      concept: 'c',
      trendScore: 50,
      origin: 'llm',
    );

    test('blocks disallowed content via the app moderation', () {
      final out = const CandidateFilter().apply([
        cand(
          'Nude Elf',
          'a nude elf by the tree, warm light, props everywhere',
        ),
      ]);
      expect(out.single.blocked, isTrue);
      expect(out.single.blockedReason, 'moderation:sexual');
    });
    test('flags brands by default, drops them in strict mode', () {
      const c = 'Grinch style green fur portrait in a cozy living room scene';
      expect(
        const CandidateFilter().apply([cand('Green Grump', c)]).single.warnings,
        anyElement(contains('grinch')),
      );
      expect(
        const CandidateFilter(
          strict: true,
        ).apply([cand('Green Grump', c)]).single.blockedReason,
        startsWith('brand:'),
      );
    });
  });

  group('sources: parsers', () {
    test('reddit listing skips NSFW and maps fields', () {
      final body = jsonEncode({
        'data': {
          'children': [
            {
              'data': {
                'title': 'Snowy portrait',
                'ups': 10,
                'num_comments': 2,
                'created_utc': 1700000000,
                'permalink': '/r/x/1',
                'over_18': false,
              },
            },
            {
              'data': {'title': 'nope', 'ups': 999, 'over_18': true},
            },
          ],
        },
      });
      final out = RedditSource.parseListing(body, 'reddit:r/x', trusted: false);
      expect(out.length, 1);
      expect(out.single.rawEngagement, 14);
      expect(out.single.url, endsWith('/r/x/1'));
    });
    test('google trends rss parses items', () {
      const xml = '''<rss><channel>
        <item><title>christmas tree lighting</title><ht:approx_traffic>200,000+</ht:approx_traffic>
        <link>https://t/1</link><pubDate>Mon, 01 Dec 2026 00:00:00 -0800</pubDate></item>
        </channel></rss>''';
      final out = GoogleTrendsRssSource.parseRss(xml, 'US');
      expect(out.single.rawEngagement, 200000);
      expect(out.single.publishedAt.month, 12);
    });
    test('seed file parses pipes and comments', () {
      final out = SeedFileSource.parse(
        '# c\nsnow globe | note | https://u\n\nplain line',
      );
      expect(out.length, 2);
      expect(out.first.note, 'note');
      expect(out.first.url, 'https://u');
      expect(out.every((s) => s.trusted), isTrue);
    });
  });

  group('pipeline (offline)', () {
    test('end to end with a failing source still produces a report', () async {
      final p = ScoutPipeline(
        sources: [
          FakeSource('a', [
            sig('snow globe portrait trend', eng: 500),
            sig('snow globe portrait of my cat', eng: 200),
          ]),
          FakeSource('b', [], fail: true),
        ],
        writer: CandidateWriter(),
        maxConcepts: 5,
      );
      final r = await p.run(xmas, windowDays: 14);
      expect(r.sourceErrors.keys, ['b']);
      expect(r.sourcesUsed, ['a']);
      expect(r.llmUsed, isFalse);
      expect(r.concepts, isNotEmpty);
      expect(r.approved.where((c) => c.mode == PromptMode.text), isNotEmpty);
      expect(r.approved.where((c) => c.mode == PromptMode.image), isNotEmpty);
      expect(r.approved.every((c) => c.origin == 'template'), isTrue);
      final md = ReportWriter.markdown(r);
      expect(md, contains('## Concepts'));
      expect(md, contains('Image to Image candidates'));
      expect(jsonDecode(jsonEncode(r.toJson()))['stats']['signals'], 2);
    });
  });
}
