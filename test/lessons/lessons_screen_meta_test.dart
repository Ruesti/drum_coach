import 'package:drum_coach/features/lessons/lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a sheet tile names its lines and bars; a one-line tile only '
      'the tempo range', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LessonsScreen())));
    await tester.pumpAndSettle();
    // Single Stroke Roll is the first tile and a sheet since Katalog 3a.
    expect(find.text('60–200 BPM · 9 lines · 24 bars'), findsOneWidget);
    // The filter chip rows scroll too — drag the list itself.
    final list = find.descendant(
        of: find.byType(ListView), matching: find.byType(Scrollable));
    // Multiple Bounce Roll stays a one-line exercise: tempo only.
    await tester.scrollUntilVisible(find.text('Multiple Bounce Roll'), 200,
        scrollable: list);
    expect(find.text('40–100 BPM'), findsWidgets);
    await tester.scrollUntilVisible(
        find.text('60–120 BPM · 9 lines · 24 bars'), 200,
        scrollable: list);
    expect(find.text('60–120 BPM · 9 lines · 24 bars'), findsOneWidget);
  });
}
