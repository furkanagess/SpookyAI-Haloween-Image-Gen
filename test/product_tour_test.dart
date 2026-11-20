import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spooky_ai/features/tour/product_tour.dart';

void main() {
  final a = GlobalKey(),
      b = GlobalKey(),
      missing = GlobalKey(),
      c = GlobalKey();

  Future<BuildContext> pumpScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return Scaffold(
              body: Column(
                children: [
                  SizedBox(key: a, width: 200, height: 60),
                  const SizedBox(height: 200),
                  SizedBox(key: b, width: 200, height: 60),
                  const Spacer(),
                  SizedBox(key: c, width: 80, height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
    return ctx;
  }

  List<TourStep> steps() => [
    TourStep(target: a, icon: Icons.star, title: 'Step A', body: 'a'),
    TourStep(target: b, icon: Icons.star, title: 'Step B', body: 'b'),
    TourStep(target: missing, icon: Icons.star, title: 'Gone', body: 'x'),
    TourStep(target: c, icon: Icons.star, title: 'Step C', body: 'c'),
  ];

  testWidgets('walks steps, skips missing targets, finishes', (tester) async {
    final ctx = await pumpScreen(tester);
    bool? result;
    ProductTour.show(ctx, steps()).then((v) => result = v);
    await settle(tester);
    expect(find.text('Step A'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);

    // Tapping the highlighted target advances too.
    await tester.tapAt(tester.getCenter(find.byKey(a)));
    await settle(tester);
    expect(find.text('Step B'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Gone'), findsNothing);
    expect(find.text('Step C'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('Step C'), findsNothing);
    expect(result, isTrue);
    expect(await ProductTourService.isDone(), isTrue);
  });

  testWidgets('one step can light several widgets', (tester) async {
    final ctx = await pumpScreen(tester);
    ProductTour.show(ctx, [
      TourStep(
        target: a,
        alsoHighlight: [b],
        icon: Icons.star,
        title: 'A and B',
        body: 'ab',
      ),
      TourStep(target: c, icon: Icons.star, title: 'Step C', body: 'c'),
    ]);
    await settle(tester);
    expect(find.text('A and B'), findsOneWidget);
    // B is inside the combined spotlight, so tapping it advances.
    await tester.tapAt(tester.getCenter(find.byKey(b)));
    await settle(tester);
    expect(find.text('Step C'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await settle(tester);
  });

  testWidgets('skip closes the tour', (tester) async {
    final ctx = await pumpScreen(tester);
    bool? result;
    ProductTour.show(ctx, steps()).then((v) => result = v);
    await settle(tester);
    await tester.tap(find.text('Skip tour'));
    await settle(tester);
    expect(find.text('Step A'), findsNothing);
    expect(result, isFalse);
    expect(await ProductTourService.isDone(), isTrue);
  });
}

/// The spotlight pulses forever, so settle with fixed frames instead.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
