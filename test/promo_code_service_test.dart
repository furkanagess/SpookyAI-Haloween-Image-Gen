import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/services/promo_code_service.dart';

void main() {
  final now = DateTime(2026, 11, 17, 12);
  Map<String, dynamic> code({
    int tokens = 50,
    int remaining = 3,
    DateTime? expires,
    bool? active,
  }) =>
      {
        'tokens': tokens,
        'maxUses': 10,
        'remainingUses': remaining,
        if (expires != null) 'expiresAt': Timestamp.fromDate(expires),
        if (active != null) 'active': active,
      };

  PromoRejection? check(Map<String, dynamic>? d, {bool used = false}) =>
      PromoCodeService.evaluate(d, now: now, alreadyUsed: used);

  test('valid code with uses left and future expiry passes', () {
    expect(check(code(expires: now.add(const Duration(days: 1)))), isNull);
    expect(check(code()), isNull);
  });

  test('rejects missing, inactive, zero-token, expired, exhausted, reused', () {
    expect(check(null), PromoRejection.notFound);
    expect(check(code(active: false)), PromoRejection.inactive);
    expect(check(code(tokens: 0)), PromoRejection.inactive);
    expect(check(code(expires: now)), PromoRejection.expired);
    expect(check(code(remaining: 0)), PromoRejection.exhausted);
    expect(check(code(), used: true), PromoRejection.alreadyUsed);
  });

  test('normalize upper-cases and strips spaces', () {
    expect(PromoCodeService.normalize('  hallo ween26 '), 'HALLOWEEN26');
  });
}
