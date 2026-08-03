import 'package:drum_coach/features/lessons/lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selecting the Ausdauer skill chip narrows the list', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LessonsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Single Stroke Roll'), findsOneWidget);

    await tester.tap(find.text('Ausdauer'));
    await tester.pumpAndSettle();

    expect(find.text('Single Stroke Roll'), findsNothing);
    expect(find.text('Sechzehntel-Dauerlauf'), findsOneWidget);
  });

  testWidgets('deselecting the chip restores the full list', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LessonsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ausdauer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausdauer'));
    await tester.pumpAndSettle();

    expect(find.text('Single Stroke Roll'), findsOneWidget);
  });
}
