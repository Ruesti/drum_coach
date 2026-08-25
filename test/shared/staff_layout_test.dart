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

    test('always fits 2 bars per row on a realistic phone width, shrinking '
        'note width rather than dropping to 1 bar/row', () {
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.quarter, beatsPerBar: 4, maxWidth: 360,
      );
      expect(layout.barsPerRow, 2);
      expect(layout.pxPerQuarter, lessThan(56));
    });

    test('falls back to 1 bar per row only when even the minimum note '
        'width would not fit 2 bars', () {
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.quarter, beatsPerBar: 4, maxWidth: 90,
      );
      expect(layout.barsPerRow, 1);
    });

    test('splits bars across rows when barsPerRow > 1', () {
      final beats = List.generate(
          16, (_) => const StrokeBeat(hand: Hand.right, value: NoteValue.quarter));
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.quarter, beatsPerBar: 4, maxWidth: 560,
      );
      expect(layout.barsPerRow, 2);
      expect(layout.placements[0].row, 0); // bar 0
      expect(layout.placements[4].row, 0); // bar 1
      expect(layout.placements[8].row, 1); // bar 2
      final dx = layout.placements[4].xCenter - layout.placements[0].xCenter;
      expect(dx, closeTo(4 * layout.pxPerQuarter + 14, 0.001)); // one bar width
    });
  });

  group('computeStaffLayout — beams & tuplets', () {
    test('groups four sixteenths in a beat into one 2-beam run', () {
      final beats = List.generate(
          4, (_) => const StrokeBeat(hand: Hand.right, value: NoteValue.sixteenth));
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.sixteenth, beatsPerBar: 4, maxWidth: 2000,
      );
      final runs = layout.beams.where((b) => b.beamCount == 2).toList();
      expect(runs.length, 1);
      expect(runs.first.startIndex, 0);
      expect(runs.first.endIndex, 3);
    });

    test('emits a triplet group for an eighth-triplet beat', () {
      const beats = [
        StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
        StrokeBeat(hand: Hand.left, value: NoteValue.eighth, tuplet: Tuplet.triplet),
        StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
      ];
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.eighth, beatsPerBar: 4, maxWidth: 2000,
      );
      expect(layout.beams.any((b) => b.tuplet == Tuplet.triplet
          && b.startIndex == 0 && b.endIndex == 2), isTrue);
    });

    test('emits a sextuplet group for a sixteenth-sextuplet beat', () {
      final beats = List.generate(
          6,
          (_) => const StrokeBeat(
              hand: Hand.right,
              value: NoteValue.sixteenth,
              tuplet: Tuplet.sextuplet));
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.sixteenth, beatsPerBar: 4, maxWidth: 2000,
      );
      expect(
          layout.beams.any((b) =>
              b.tuplet == Tuplet.sextuplet && b.startIndex == 0 && b.endIndex == 5),
          isTrue);
    });

    test('a rest breaks a beam run', () {
      const beats = [
        StrokeBeat(hand: Hand.right, value: NoteValue.sixteenth),
        StrokeBeat.rest(value: NoteValue.sixteenth),
        StrokeBeat(hand: Hand.left, value: NoteValue.sixteenth),
        StrokeBeat(hand: Hand.right, value: NoteValue.sixteenth),
      ];
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.sixteenth, beatsPerBar: 4, maxWidth: 2000,
      );
      // only the last two sixteenths form a >=2 beam run
      final runs = layout.beams.where((b) => b.beamCount == 2).toList();
      expect(runs.length, 1);
      expect(runs.first.startIndex, 2);
      expect(runs.first.endIndex, 3);
    });
  });
}
