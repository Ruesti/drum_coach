import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
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

    testWidgets('renders a mixed-value multi-bar étude without throwing',
        (tester) async {
      const etude = Rudiment(
        id: 'etude_mixed', name: 'Mixed', description: 'x',
        minBpm: 60, targetBpm: 120, difficulty: Difficulty.intermediate,
        gridUnit: NoteGrid.eighth, beatsPerBar: 4,
        sticking: [
          StrokeBeat(hand: Hand.right, value: NoteValue.quarter, isAccent: true),
          StrokeBeat(hand: Hand.left, value: NoteValue.eighth),
          StrokeBeat(hand: Hand.right, value: NoteValue.eighth),
          StrokeBeat(hand: Hand.left, value: NoteValue.sixteenth),
          StrokeBeat(hand: Hand.right, value: NoteValue.sixteenth),
          StrokeBeat(hand: Hand.left, value: NoteValue.eighth),
          StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
          StrokeBeat(hand: Hand.left, value: NoteValue.eighth, tuplet: Tuplet.triplet),
          StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
          StrokeBeat(hand: Hand.left, value: NoteValue.quarter),
        ],
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 360, child: NotationStaffWidget(rudiment: etude)),
        ),
      ));
      expect(tester.takeException(), isNull);
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
  });
}
