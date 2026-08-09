import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeNextBeatDelayUs', () {
    test('schedules the remaining gap to the next on-time beat', () {
      // 100 BPM, quarter notes: 600,000 µs per beat. idx=5 is due at
      // 3,000,000 µs; we're at 2,900,000 µs, so 100,000 µs remain.
      final delay = computeNextBeatDelayUs(
        bpm: 100,
        factor: 1,
        idx: 5,
        anchorUs: 0,
        anchorIdx: 0,
        elapsedUs: 2900000,
      );
      expect(delay, 100000);
    });

    test('clamps to a 100 µs minimum when running behind schedule', () {
      final delay = computeNextBeatDelayUs(
        bpm: 100,
        factor: 1,
        idx: 5,
        anchorUs: 0,
        anchorIdx: 0,
        elapsedUs: 4000000, // way past the 3,000,000 µs due time
      );
      expect(delay, 100);
    });

    test('clamps to at most one interval when running far ahead', () {
      final delay = computeNextBeatDelayUs(
        bpm: 100,
        factor: 1,
        idx: 5,
        anchorUs: 0,
        anchorIdx: 0,
        elapsedUs: 0, // nothing elapsed yet, but idx=5 "should" be far out
      );
      expect(delay, 600000); // one interval at 100 BPM, not 3,000,000
    });

    test(
        'a live BPM change does not retroactively rewrite already-elapsed '
        'beat timing (the original bug)', () {
      // 10 beats already played at the OLD tempo (100 BPM -> 600,000 µs/beat),
      // so real elapsed time is 6,000,000 µs. The BPM change to 200 re-anchors
      // at (idx=10, elapsedUs=6,000,000) — exactly what the engine does at the
      // moment it receives the new BPM while playing.
      final delay = computeNextBeatDelayUs(
        bpm: 200,
        factor: 1,
        idx: 11,
        anchorUs: 6000000,
        anchorIdx: 10,
        elapsedUs: 6000000,
      );
      // One full interval at the NEW tempo (200 BPM -> 300,000 µs/beat) from
      // the anchor point — not `idx * newInterval` (11 * 300,000 = 3,300,000,
      // which is *before* elapsedUs and would clamp to the 100 µs minimum,
      // firing a burst of beats to "catch up").
      expect(delay, 300000);
    });

    test('a live subdivision (factor) change re-anchors the same way', () {
      // 5 quarter-note beats at 120 BPM (factor 1) = 2,500,000 µs elapsed.
      // Switching to eighth notes (factor 2) at that instant re-anchors.
      final delay = computeNextBeatDelayUs(
        bpm: 120,
        factor: 2,
        idx: 6,
        anchorUs: 2500000,
        anchorIdx: 5,
        elapsedUs: 2500000,
      );
      // 60,000,000 / 120 / 2 = 250,000 µs per beat at the new subdivision.
      expect(delay, 250000);
    });
  });

  group('fine-grid factor', () {
    test('computeNextBeatDelayUs works at 24 ticks/quarter', () {
      // 120 bpm, factor 24 => 500000us/quarter / 24 = 20833.33us/tick.
      final d = computeNextBeatDelayUs(
        bpm: 120,
        factor: 24,
        idx: 1,
        anchorUs: 0,
        anchorIdx: 0,
        elapsedUs: 0,
      );
      expect(d, closeTo(20833, 2));
    });
  });
}
