import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoteValue / Tuplet duration', () {
    test('quarters per value', () {
      expect(NoteValue.whole.quarters, 4.0);
      expect(NoteValue.quarter.quarters, 1.0);
      expect(NoteValue.eighth.quarters, 0.5);
      expect(NoteValue.sixteenth.quarters, 0.25);
      expect(NoteValue.thirtySecond.quarters, 0.125);
    });

    test('ResolvedNote applies dot and tuplet', () {
      expect(const ResolvedNote(NoteValue.eighth, false, Tuplet.none).quarters, 0.5);
      expect(const ResolvedNote(NoteValue.eighth, true, Tuplet.none).quarters, 0.75);
      expect(const ResolvedNote(NoteValue.eighth, false, Tuplet.triplet).quarters,
          closeTo(1 / 3, 1e-9));
      expect(const ResolvedNote(NoteValue.sixteenth, false, Tuplet.sextuplet).quarters,
          closeTo(1 / 6, 1e-9));
    });
  });

  group('resolveNote backward-compat', () {
    test('null value resolves from gridUnit (uniform old data)', () {
      const beat = StrokeBeat(hand: Hand.right); // value == null
      expect(resolveNote(beat, NoteGrid.eighth).quarters, 0.5);
      expect(resolveNote(beat, NoteGrid.triplet).quarters, closeTo(1 / 3, 1e-9));
      expect(resolveNote(beat, NoteGrid.sixteenthTriplet).quarters,
          closeTo(1 / 6, 1e-9));
      expect(resolveNote(beat, NoteGrid.thirtySecond).quarters, 0.125);
    });

    test('explicit value overrides gridUnit', () {
      const beat = StrokeBeat(
          hand: Hand.left, value: NoteValue.quarter, tuplet: Tuplet.none);
      expect(resolveNote(beat, NoteGrid.sixteenth).quarters, 1.0);
    });

    test('rest keeps its resolved duration', () {
      const rest = StrokeBeat.rest();
      expect(resolveNote(rest, NoteGrid.eighth).quarters, 0.5);
    });
  });
}
