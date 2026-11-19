import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/core/services/token_costs.dart';

void main() {
  // The numbers themselves are a pricing decision (see token_costs.dart);
  // these tests only guard invariants the app depends on.
  test('every generation costs a positive number of tokens', () {
    expect(TokenCosts.textToImage, greaterThan(0));
    expect(TokenCosts.imageToImage, greaterThan(0));
  });

  test('labels are pluralized', () {
    expect(TokenCosts.label(1), '1 token');
    expect(TokenCosts.label(2), '2 tokens');
    expect(TokenCosts.label(4), '4 tokens');
  });

  test(
    'the free welcome grant (3) covers at least one generation of each kind',
    () {
      // TokenService.initialTokens is 3.0; keep this link visible on change.
      expect(3.0 >= TokenCosts.textToImage, isTrue);
      expect(3.0 >= TokenCosts.imageToImage, isTrue);
    },
  );
}
