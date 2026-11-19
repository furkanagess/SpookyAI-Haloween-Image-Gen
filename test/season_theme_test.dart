import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spooky_ai/core/theme/seasons/season_palette.dart';
import 'package:spooky_ai/core/theme/seasons/season_provider.dart';
import 'package:spooky_ai/core/theme/seasons/season_registry.dart';
import 'package:spooky_ai/core/theme/seasons/season_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SeasonRegistry.forDate', () {
    test('picks Christmas from Nov 25 to Jan 15', () {
      expect(
        SeasonRegistry.forDate(DateTime(2026, 11, 25)),
        SeasonId.christmas,
      );
      expect(
        SeasonRegistry.forDate(DateTime(2026, 12, 24)),
        SeasonId.christmas,
      );
      expect(SeasonRegistry.forDate(DateTime(2027, 1, 15)), SeasonId.christmas);
    });

    test('falls back to Halloween otherwise', () {
      expect(
        SeasonRegistry.forDate(DateTime(2026, 11, 24)),
        SeasonId.halloween,
      );
      expect(SeasonRegistry.forDate(DateTime(2027, 1, 16)), SeasonId.halloween);
      expect(
        SeasonRegistry.forDate(DateTime(2026, 10, 31)),
        SeasonId.halloween,
      );
    });
  });

  group('SeasonProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('first launch opens in Christmas', () async {
      final p = SeasonProvider(clock: () => DateTime(2026, 7, 1));
      await p.load();
      expect(p.current.id, SeasonId.christmas);
    });

    test('follows the calendar in auto mode', () async {
      SharedPreferences.setMockInitialValues({'season_first_launch_set': true});
      final p = SeasonProvider(clock: () => DateTime(2026, 12, 10));
      await p.load();
      expect(p.isAuto, isTrue);
      expect(p.current.id, SeasonId.christmas);
    });

    test('override is applied and persisted', () async {
      final p = SeasonProvider(clock: () => DateTime(2026, 12, 10));
      await p.load();
      await p.setOverride(SeasonId.halloween);
      expect(p.current.id, SeasonId.halloween);

      final p2 = SeasonProvider(clock: () => DateTime(2026, 12, 10));
      await p2.load();
      expect(p2.current.id, SeasonId.halloween);

      await p2.setOverride(null);
      expect(p2.current.id, SeasonId.christmas);
    });
  });

  test('theme data exposes SeasonColors extension', () {
    final t = SeasonRegistry.christmas.toThemeData();
    expect(
      t.extension<SeasonColors>()!.accent,
      SeasonRegistry.christmas.accent,
    );
    expect(
      t.scaffoldBackgroundColor,
      SeasonRegistry.christmas.scaffoldBackground,
    );
  });

  group('SeasonDecor', () {
    tearDown(() => SeasonPalette.current = SeasonRegistry.halloween);

    test('Halloween leaves text untouched', () {
      SeasonPalette.current = SeasonRegistry.halloween;
      expect(SeasonPalette.t('Great 🎃 Halloween'), 'Great 🎃 Halloween');
      expect(SeasonPalette.hasEmojiArt('assets/images/pumpkin.png'), isFalse);
    });

    test('Christmas swaps glyphs, words and art', () {
      SeasonPalette.current = SeasonRegistry.christmas;
      expect(
        SeasonPalette.t('🎃 Halloween Prompt Selector'),
        '🎄 Christmas Prompt Selector',
      );
      expect(
        SeasonPalette.t('Generate spooky images'),
        'Generate festive images',
      );
      expect(SeasonPalette.hasEmojiArt('assets/images/pumpkin.png'), isTrue);
    });

    test('every season defines an ambient effect', () {
      for (final s in SeasonRegistry.all) {
        expect(s.decor.effect, isNotNull, reason: s.displayName);
      }
    });
  });
}
