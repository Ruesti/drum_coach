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

    test('exposes per-click offsets in click order', () {
      final e = estimateLatencyOffset(
        plannedClickMs: clicks,
        onsetMs: clicks.map((c) => c + 120).toList(),
      );
      expect(e!.perClickOffsetsMs.length, 8);
      for (final r in e.perClickOffsetsMs) {
        expect(r, closeTo(120, 0.001));
      }
    });
  });

  group('blockOffsets', () {
    test('splits per-click offsets into block medians within one recording',
        () {
      // 12 clicks: first block sits at 100 ms, second at 102, third at 101.
      final planned = [for (var i = 0; i < 12; i++) i * 500.0];
      final offsets = [100.0, 100, 100, 100, 102, 102, 102, 102, 101, 101, 101, 101];
      final e = estimateLatencyOffset(
        plannedClickMs: planned,
        onsetMs: [for (var i = 0; i < 12; i++) planned[i] + offsets[i]],
      );
      final blocks = e!.blockOffsets(3);
      expect(blocks.length, 3);
      expect(blocks[0], closeTo(100, 0.001));
      expect(blocks[1], closeTo(102, 0.001));
      expect(blocks[2], closeTo(101, 0.001));
      expect(e.blockSpreadMs(3), closeTo(2, 0.001));
    });
  });
}
