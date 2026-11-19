import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  for (final size in const [Size(375, 667), Size(430, 932)]) {
    testWidgets('onboarding walks through 6 pages at $size', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
      await tester.pump(const Duration(milliseconds: 500));

      const titles = [
        'Spooky art in seconds',
        'Describe it. See it.',
        'Transform your selfie',
        'Bring photos to life',
        'Jump on the trend',
        'A new world every season',
      ];
      for (var i = 0; i < titles.length; i++) {
        expect(find.text(titles[i]), findsOneWidget);
        if (i < titles.length - 1) {
          await tester.tap(find.text('Continue'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        }
      }
      expect(find.text('Start creating'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
