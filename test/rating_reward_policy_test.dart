import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/services/rating_service.dart';

void main() {
  final now = DateTime(2026, 11, 14);
  bool grant(RatingHistory h, int stars, {double roll = 0}) =>
      RatingRewardPolicy.grantsApology(h, stars, now: now, roll: roll);

  test('first 1 or 2 star rating always gets the apology', () {
    expect(grant(const RatingHistory(), 1, roll: 0.99), isTrue);
    expect(grant(const RatingHistory(), 2, roll: 0.99), isTrue);
  });

  test('3+ stars never pay', () {
    for (final s in [3, 4, 5]) {
      expect(grant(const RatingHistory(), s), isFalse);
    }
  });

  final eligible = RatingHistory(
    totalRatings: 10,
    lowRatings: 2,
    apologiesGranted: 1,
    lastApologyAt: now.subtract(const Duration(days: 30)),
    ratingsSinceApology: 6,
  );

  test('a later apology needs luck', () {
    expect(grant(eligible, 1, roll: 0.1), isTrue);
    expect(grant(eligible, 1, roll: 0.5), isFalse);
  });

  test('cooldown, rating gap, low share and lifetime cap block it', () {
    RatingHistory w({int? a, DateTime? at, int? since, int? total, int? low}) =>
        RatingHistory(
          totalRatings: total ?? eligible.totalRatings,
          lowRatings: low ?? eligible.lowRatings,
          apologiesGranted: a ?? eligible.apologiesGranted,
          lastApologyAt: at ?? eligible.lastApologyAt,
          ratingsSinceApology: since ?? eligible.ratingsSinceApology,
        );
    expect(grant(w(at: now.subtract(const Duration(days: 3))), 1), isFalse);
    expect(grant(w(since: 2), 1), isFalse);
    expect(grant(w(total: 10, low: 8), 1), isFalse);
    expect(grant(w(a: RatingRewardPolicy.maxApologies), 1), isFalse);
  });

  test('history round-trips through json', () {
    final h = RatingHistory.fromJson(eligible.toJson());
    expect(h.apologiesGranted, 1);
    expect(h.lastApologyAt, eligible.lastApologyAt);
    expect(h.ratingsSinceApology, 6);
  });

  test('promptKey: style id, else a stable hash of the text', () {
    expect(
      RatingService.promptKey(styleId: 'ghost_face', prompt: 'x'),
      'style_ghost_face',
    );
    final a = RatingService.promptKey(prompt: ' A Witch ');
    expect(a, RatingService.promptKey(prompt: 'a witch'));
    expect(a, startsWith('custom_'));
    expect(a, isNot(RatingService.promptKey(prompt: 'a wizard')));
  });
}
