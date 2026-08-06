// test/tempo_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/metronome/tempo.dart';

void main() {
  group('onsetFactorFor (no factor-4 cap — Bug 1)', () {
    test('dense grids keep their true cells-per-quarter', () {
      expect(onsetFactorFor(NoteGrid.eighth), 2);
      expect(onsetFactorFor(NoteGrid.sixteenth), 4);
      expect(onsetFactorFor(NoteGrid.sixteenthTriplet), 6); // was capped to 4
      expect(onsetFactorFor(NoteGrid.thirtySecond), 8);     // was capped to 4
    });
  });

  group('tempo reference is the quarter pulse for every grid', () {
    test('same BPM => same quarter pulse regardless of grid', () {
      expect(quarterPulseMicros(140), 428571);
      // eighth vs sixteenth exercise at 140 share the quarter pulse...
      expect(onsetIntervalMicros(140, 2) * 2, closeTo(428571, 3));
      expect(onsetIntervalMicros(140, 4) * 4, closeTo(428571, 4));
    });

    test('onset interval halves when the grid doubles', () {
      expect(onsetIntervalMicros(140, 2), 214285);
      expect(onsetIntervalMicros(140, 4), 107142);
    });

    test('cellDuration mirrors onsetIntervalMicros', () {
      expect(cellDuration(140, 2).inMicroseconds, 214285);
    });
  });

}
