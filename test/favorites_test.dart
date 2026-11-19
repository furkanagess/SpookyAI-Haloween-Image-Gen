import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spooky_ai/core/services/prompts_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('toggleFavorite adds, removes and persists', () async {
    final p = PromptsProvider();
    await p.toggleFavorite('spooky_forest');
    await p.toggleFavorite('haunted_house');
    expect(p.isFavorite('spooky_forest'), isTrue);
    expect(p.favoriteIds, ['spooky_forest', 'haunted_house']);

    await p.toggleFavorite('spooky_forest');
    expect(p.isFavorite('spooky_forest'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_prompt_ids'), ['haunted_house']);
  });

  test('favorites are restored on startup', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_prompt_ids': ['a', 'b'],
    });
    final p = PromptsProvider();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(p.favoriteIds, ['a', 'b']);
  });
}
