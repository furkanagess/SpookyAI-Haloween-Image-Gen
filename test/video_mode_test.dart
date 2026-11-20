import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spooky_ai/features/home/domain/generation_mode.dart';
import 'package:spooky_ai/features/home/presentation/widgets/generation_mode_switcher.dart';
import 'package:spooky_ai/features/home/presentation/widgets/video_showcase_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  testWidgets('switcher offers Text, Photo and Video', (tester) async {
    GenerationMode? picked;
    await tester.pumpWidget(
      _wrap(
        GenerationModeSwitcher(
          mode: GenerationMode.text,
          onChanged: (m) => picked = m,
        ),
      ),
    );
    expect(find.text('Text'), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);

    await tester.tap(find.text('Video'));
    expect(picked, GenerationMode.video);
  });

  test('every showcase sample ships its still and clip', () {
    expect(videoSamples, isNotEmpty);
    for (final s in videoSamples) {
      expect(File(s.still).existsSync(), isTrue, reason: s.still);
      expect(File(s.video).existsSync(), isTrue, reason: s.video);
      expect(s.motion.trim(), isNotEmpty);
    }
  });

  testWidgets('See examples opens the sheet and returns the chosen one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    VideoSample? tried;
    await tester.pumpWidget(
      _wrap(VideoExamplesButton(onTryExample: (s) => tried = s)),
    );
    expect(find.text('See examples'), findsOneWidget);

    await tester.tap(find.text('See examples'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Photo to Video'), findsOneWidget);
    expect(find.text(videoSamples.first.motion), findsOneWidget);

    // Photo first, then it turns into the video on its own. (The next
    // example peeks in from the side and stays on its photo.)
    expect(find.text('VIDEO'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('VIDEO'), findsOneWidget);

    // Before/After switch flips back to the photo.
    await tester.tap(find.text('Before').first);
    await tester.pump();
    expect(find.text('VIDEO'), findsNothing);

    // Swipe to the next example.
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(videoSamples[1].motion), findsOneWidget);

    await tester.tap(find.text('Use this example'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tried, videoSamples[1]);
    expect(find.text('Photo to Video'), findsNothing);
  });
}
