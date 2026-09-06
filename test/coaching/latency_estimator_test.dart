import 'package:drum_coach/features/coaching/services/latency_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 8 loopback clicks, 500 ms apart.
  final clicks = [for (var i = 0; i < 8; i++) i * 500.0];

  group('estimateLatencyOffset', () {
    test('recovers a constant output+input latency from clean loopback', () {
      final e = estimateLatencyOffset(
        plannedClickMs: clicks,
        onsetMs: clicks.map((c) => c + 120).toList(),
      );
      expect(e, isNotNull);
      expect(e!.offsetMs, closeTo(120, 0.001));
      expect(e.matchedClicks, 8);
      expect(e.totalClicks, 8);
    });

    test('survives one undetected click', () {
      final onsets = clicks.map((c) => c + 120).toList()..removeAt(3);
      final e = estimateLatencyOffset(plannedClickMs: clicks, onsetMs: onsets);
      expect(e!.offsetMs, closeTo(120, 0.001));
      expect(e.matchedClicks, 7);
    });

    test('is robust against a spurious extra onset (median)', () {
      final onsets = [...clicks.map((c) => c + 120), 1234.0]..sort();
      final e = estimateLatencyOffset(plannedClickMs: clicks, onsetMs: onsets);
      expect(e!.offsetMs, closeTo(120, 0.001));
    });

    test('averages out jitter around the true offset', () {
      final jitter = [3.0, -4, 1, -2, 5, -1, 2, -3];
      final onsets = [
        for (var i = 0; i < 8; i++) clicks[i] + 120 + jitter[i],
      ];
      final e = estimateLatencyOffset(plannedClickMs: clicks, onsetMs: onsets);
      expect(e!.offsetMs, closeTo(120, 3));
    });

    test('returns null when nothing was recorded', () {
      expect(estimateLatencyOffset(plannedClickMs: clicks, onsetMs: []), isNull);
    });
  });
}
