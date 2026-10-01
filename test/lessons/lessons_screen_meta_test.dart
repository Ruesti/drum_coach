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
    // Single Stroke Roll is the first tile: one line, tempo only.
    expect(find.text('60–200 BPM'), findsWidgets);
    expect(find.textContaining('lines ·'), findsNothing);
    // The filter chip rows scroll too — drag the list itself.
    await tester.scrollUntilVisible(
        find.text('60–120 BPM · 11 lines · 28 bars'), 200,
        scrollable: find.descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable)));
    expect(find.text('60–120 BPM · 11 lines · 28 bars'), findsOneWidget);
  });
}
