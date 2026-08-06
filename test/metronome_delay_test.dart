import 'package:flutter_test/flutter_test.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';

void main() {
  group('computeNextBeatDelayUs handles dense grids (factor 6 & 8)', () {
    int delay(int factor) => computeNextBeatDelayUs(
          bpm: 140,
          factor: factor,
          idx: 1,
          anchorUs: 0,
          anchorIdx: 0,
          elapsedUs: 0,
        );

    test('factor 6 => one sixteenth-triplet interval', () {
      // 60_000_000 / 140 / 6 = 71428.57 -> rounded 71429
      expect(delay(6), 71429);
    });

    test('factor 8 => one thirty-second interval', () {
      // 60_000_000 / 140 / 8 = 53571.4 -> rounded 53571
      expect(delay(8), 53571);
    });
  });
}
