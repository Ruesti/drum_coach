// test/shared/staff_layout_test.dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/staff_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeStaffLayout — bars, rows, x', () {
    // Two 4/4 bars of quarter notes (8 notes). Wide canvas => one row.
    final beats =
        List.generate(8, (_) => const StrokeBeat(hand: Hand.right, value: NoteValue.quarter));
    final layout = computeStaffLayout(
      beats: beats, grid: NoteGrid.quarter, beatsPerBar: 4, maxWidth: 2000,
    );

    test('assigns notes to correct bars', () {
      expect(layout.placements[0].bar, 0);
      expect(layout.placements[3].bar, 0);
      expect(layout.placements[4].bar, 1);
      expect(layout.placements[7].bar, 1);
    });

    test('x increases within a bar by pxPerQuarter', () {
      final p0 = layout.placements[0];
      final p1 = layout.placements[1];
      expect(p1.xCenter - p0.xCenter, closeTo(layout.pxPerQuarter, 0.001));
    });

    test('single row when everything fits', () {
      expect(layout.rowCount, 1);
      expect(layout.placements.every((p) => p.row == 0), isTrue);
    });
  });

  group('computeStaffLayout — wrapping', () {
    // 4 bars of quarters on a narrow canvas => multiple rows, whole bars only.
    final beats =
        List.generate(16, (_) => const StrokeBeat(hand: Hand.right, value: NoteValue.quarter));

    test('wraps at bar boundaries', () {
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.quarter, beatsPerBar: 4, maxWidth: 360,
      );
      expect(layout.barsPerRow, greaterThanOrEqualTo(1));
      // every note's row == its bar ~/ barsPerRow
      for (final p in layout.placements) {
        expect(p.row, p.bar ~/ layout.barsPerRow);
      }
    });
  });
}
