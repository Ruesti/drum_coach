import 'package:flutter_test/flutter_test.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';

void main() {
  group('beatNumbersInRow (absolute position — Task 4 fix)', () {
    test('row starting on a bar boundary labels 1..4', () {
      // sixteenth grid: cellsPerBeat 4, beatsPerBar 4; a full bar = 16 cells.
      expect(beatNumbersInRow(0, 16, 4, 4), [(0, 1), (4, 2), (8, 3), (12, 4)]);
    });

    test('row starting mid-bar (pos 9) keeps true quarter pulses', () {
      // Row-relative i would wrongly mark abs 9,13,17.
      // Correct: only abs 12 (beat 4) and abs 16 (beat 1 of next bar).
      expect(beatNumbersInRow(9, 9, 4, 4), [(3, 4), (7, 1)]);
    });
  });
}
