import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';

void main() {
  group('NotationStaffWidget (5-line staff)', () {
    testWidgets('renders every seeded pattern without throwing', (tester) async {
      for (final rudiment in rudimentsSeedData) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: NotationStaffWidget(rudiment: rudiment),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull,
            reason: 'failed rendering ${rudiment.id}');
        expect(find.byType(NotationStaffWidget), findsOneWidget);

        final size = tester.getSize(find.byType(CustomPaint).first);
        expect(size.height, greaterThan(0));
      }
    });

    testWidgets('renders with an active cursor during playback', (tester) async {
      final rudiment = rudimentsSeedData.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: NotationStaffWidget(rudiment: rudiment, activeIndex: 2),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts playback params and settles without pending timers',
        (tester) async {
      final rudiment = rudimentsSeedData.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: NotationStaffWidget(
                rudiment: rudiment,
                activeIndex: 1,
                perCellDuration: const Duration(milliseconds: 200),
                isPlaying: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Stop playback -> controller must stop (no pending-timer failure on end).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: NotationStaffWidget(
                rudiment: rudiment,
                activeIndex: 1,
                isPlaying: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
