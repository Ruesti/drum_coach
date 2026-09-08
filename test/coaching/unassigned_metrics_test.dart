import 'package:drum_coach/features/coaching/services/unassigned_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeUnassignedMetrics', () {
    test('perfect run: zero deviation, zero spreads, counts match', () {
      final m = computeUnassignedMetrics(
        clickMs: [0, 500, 1000, 1500],
        onsetMs: [0, 500, 1000, 1500],
        amplitudes: [0.5, 0.5, 0.5, 0.5],
      );
      expect(m.timingMedianMs, closeTo(0, 0.001));
      expect(m.timingSpreadMs, closeTo(0, 0.001));
      expect(m.intervalSpreadMs, closeTo(0, 0.001));
      expect(m.dynamicsSpread, closeTo(0, 0.001));
      expect(m.playedCount, 4);
      expect(m.expectedCount, 4);
    });

    test('constant offset shows up as median, not hidden (§1.3)', () {
      final m = computeUnassignedMetrics(
        clickMs: [0, 500, 1000, 1500],
        onsetMs: [20, 520, 1020, 1520],
        amplitudes: [0.5, 0.5, 0.5, 0.5],
      );
      expect(m.timingMedianMs, closeTo(20, 0.001));
      expect(m.timingSpreadMs, closeTo(0, 0.001));
    });

    test('deviation is signed toward the nearest click', () {
      final m = computeUnassignedMetrics(
        clickMs: [0, 500],
        onsetMs: [-10, 530], // 10 early, 30 late
        amplitudes: [0.5, 0.5],
      );
      expect(m.timingMedianMs, closeTo(10, 0.001)); // median of [-10, 30]
      expect(m.timingSpreadMs, greaterThan(0));
    });

    test('uneven strokes raise the interval spread', () {
      final even = computeUnassignedMetrics(
        clickMs: [0, 500, 1000, 1500],
        onsetMs: [0, 500, 1000, 1500],
        amplitudes: [0.5, 0.5, 0.5, 0.5],
      );
      final uneven = computeUnassignedMetrics(
        clickMs: [0, 500, 1000, 1500],
        onsetMs: [0, 450, 1050, 1500],
        amplitudes: [0.5, 0.5, 0.5, 0.5],
      );
      expect(uneven.intervalSpreadMs, greaterThan(even.intervalSpreadMs));
    });

    test('dynamics spread is the coefficient of variation of peak levels', () {
      final m = computeUnassignedMetrics(
        clickMs: [0, 500],
        onsetMs: [0, 500],
        amplitudes: [0.5, 1.0],
      );
      // population std of [0.5, 1.0] = 0.25, mean = 0.75 → CV = 1/3
      expect(m.dynamicsSpread, closeTo(0.25 / 0.75, 0.001));
    });

    test('played vs expected counts disagree when strokes are missing', () {
      final m = computeUnassignedMetrics(
        clickMs: [0, 500, 1000, 1500],
        onsetMs: [0, 500],
        amplitudes: [0.5, 0.5],
      );
      expect(m.playedCount, 2);
      expect(m.expectedCount, 4);
    });

    test('empty onsets yield zeroed metrics without crashing', () {
      final m = computeUnassignedMetrics(
        clickMs: [0, 500],
        onsetMs: [],
        amplitudes: [],
      );
      expect(m.timingMedianMs, 0);
      expect(m.timingSpreadMs, 0);
      expect(m.intervalSpreadMs, 0);
      expect(m.dynamicsSpread, isNull);
      expect(m.playedCount, 0);
      expect(m.expectedCount, 2);
    });
  });
}
