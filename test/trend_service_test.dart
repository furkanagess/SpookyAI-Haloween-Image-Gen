import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/services/trend_service.dart';
import 'package:spooky_ai/features/home/data/models/prompt_category.dart';

void main() {
  final now = DateTime(2026, 11, 20);

  Map<String, dynamic> section({Map<String, dynamic> extra = const {}}) => {
        'title': 'GTA 6 Vibes',
        'emoji': '🌴',
        'accent': '#FF2D95',
        'order': 2,
        'items': [
          {
            'id': 'poster',
            'title': 'Loading Screen',
            'prompt': 'Illustrated poster of the person.',
            'type': 'image',
            'isHot': true,
            'isPremium': true,
          },
          {'title': 'No prompt'}, // dropped
          {'title': 'Hidden', 'prompt': 'x', 'active': false}, // dropped
        ],
        ...extra,
      };

  test('parses a section and its valid items', () {
    final s = TrendSection.fromMap('gta6', section(), now)!;
    expect(s.title, 'GTA 6 Vibes');
    expect(s.accent, const Color(0xFFFF2D95));
    expect(s.items, hasLength(1));
    final p = s.items.single;
    expect(p.id, 'trend_gta6_poster');
    expect(p.promptType, PromptType.imageToImage);
    expect(p.isPopular, isTrue);
    expect(p.isPremium, isTrue);
  });

  test('hides inactive, out-of-window, untitled or empty sections', () {
    expect(TrendSection.fromMap('a', section(extra: {'active': false}), now), isNull);
    expect(
      TrendSection.fromMap('a', section(extra: {'endsAt': DateTime(2026, 11, 1)}), now),
      isNull,
    );
    expect(
      TrendSection.fromMap('a', section(extra: {'startsAt': DateTime(2026, 12, 1)}), now),
      isNull,
    );
    expect(TrendSection.fromMap('a', section(extra: {'title': ''}), now), isNull);
    expect(TrendSection.fromMap('a', section(extra: {'items': []}), now), isNull);
  });

  test('parseHexColor rejects malformed input', () {
    expect(parseHexColor('#12'), isNull);
    expect(parseHexColor('zzzzzz'), isNull);
    expect(parseHexColor('80FF0000'), const Color(0x80FF0000));
  });

  test('custom item badge and showCount are read', () {
    final s = TrendSection.fromMap(
      'gta6',
      section(extra: {
        'showCount': false,
        'items': [
          {'id': 'a', 'title': 'A', 'prompt': 'p', 'badge': 'NEW', 'badgeColor': '#00C2A8'},
        ],
      }),
      now,
    )!;
    expect(s.showCount, isFalse);
    expect(s.badges['trend_gta6_a']?.text, 'NEW');
    expect(s.badges['trend_gta6_a']?.color, const Color(0xFF00C2A8));
  });

  test('screen config keeps defaults for missing or bad fields', () {
    final c = TrendScreenConfig.fromMap({
      'tabLabel': 'Hot',
      'headline': r'Line one\nline two',
      'liveColor': 'nope',
      'headlineColors': ['#FF0000', 'bad', '#00FF00'],
      'glow': false,
      'glowSeconds': 999,
      'showHero': 'yes',
    });
    expect(c.tabLabel, 'Hot');
    expect(c.headline, 'Line one\nline two');
    expect(c.liveColor, const TrendScreenConfig().liveColor);
    expect(c.headlineColors, [const Color(0xFFFF0000), const Color(0xFF00FF00)]);
    expect(c.glow, isFalse);
    expect(c.glowSeconds, 4);
    expect(c.showHero, isTrue);
    expect(c.tryText, 'Try it now');
  });

  test('preview images accept Storage paths, gs:// and https', () {
    const b = 'spookyai-app-ratings.firebasestorage.app';
    expect(
      resolveTrendImage('trends/gta6/poster.jpg'),
      'https://firebasestorage.googleapis.com/v0/b/$b/o/'
      'trends%2Fgta6%2Fposter.jpg?alt=media',
    );
    expect(
      resolveTrendImage('gs://other-bucket/trends/a b.png'),
      'https://firebasestorage.googleapis.com/v0/b/other-bucket/o/'
      'trends%2Fa%20b.png?alt=media',
    );
    expect(resolveTrendImage('https://x.com/a.jpg'), 'https://x.com/a.jpg');
    expect(resolveTrendImage('  '), isNull);
    expect(resolveTrendImage('gs://nobucket'), isNull);
  });

  test('sample trend file parses fully with short, single-face prompts', () {
    final data = jsonDecode(
      File('docs/trend_sections.sample.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final e in data.entries) {
      final raw = (e.value['items'] as List).length;
      final s = TrendSection.fromMap(e.key, e.value, now);
      expect(s, isNotNull, reason: e.key);
      expect(s!.items, hasLength(raw), reason: e.key);
      for (final p in s.items) {
        expect(p.prompt.length, lessThan(320), reason: p.id);
        if (p.promptType == PromptType.imageToImage) {
          expect('Keep the same face'.allMatches(p.prompt), hasLength(1),
              reason: p.id);
        }
      }
    }
  });

  test('hero carousel follows heroItems, else HOT items', () {
    final a = TrendSection.fromMap('gta6', section(), now)!;
    final b = TrendSection.fromMap(
      'xmas',
      section(extra: {
        'items': [
          {'id': 'booth', 'title': 'Booth', 'prompt': 'p'},
        ],
      }),
      now,
    )!;
    final picked = pickHeroItems([a, b], ['xmas/booth', 'nope/x', 'bad', 'gta6/poster']);
    expect(picked.map((e) => e.$1.id), ['trend_xmas_booth', 'trend_gta6_poster']);
    expect(pickHeroItems([a, b], const []).map((e) => e.$1.id), ['trend_gta6_poster']);
    expect(pickHeroItems([a, b], ['nope/x']).single.$1.id, 'trend_gta6_poster');
    expect(
      TrendScreenConfig.fromMap({'heroItems': ['gta6/poster', 3, ' ']}).heroItems,
      ['gta6/poster'],
    );
  });
}
