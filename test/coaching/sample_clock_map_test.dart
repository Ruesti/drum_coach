import 'package:drum_coach/features/coaching/services/sample_clock_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sr = 16000;
  final t0 = DateTime.fromMicrosecondsSinceEpoch(7000000000);

  group('SampleClockMap', () {
    test('maps sample times linearly when delivery is clean', () {
      final m = SampleClockMap(sampleRate: sr);
      // 20 chunks of 100 ms, all delivered 3 ms after their nominal end.
      for (var i = 0; i < 20; i++) {
        m.addChunk(
          arrivedAt: t0.add(Duration(milliseconds: (i + 1) * 100 + 3)),
          samples: 1600,
        );
      }
      final at500 = m.timeAt(500)!;
      expect(at500.difference(t0).inMilliseconds, closeTo(503, 1));
    });

    test('an onset after a sample gap gets wall-clock time, not sample time',
        () {
      final m = SampleClockMap(sampleRate: sr);
      // 10 clean chunks (1 s of audio), then 200 ms of real time pass but
      // only 100 ms of samples arrive (100 ms lost in the pipeline), then
      // 10 more clean chunks.
      for (var i = 0; i < 10; i++) {
        m.addChunk(
            arrivedAt: t0.add(Duration(milliseconds: (i + 1) * 100)),
            samples: 1600);
      }
      m.addChunk(
          arrivedAt: t0.add(const Duration(milliseconds: 1200)),
          samples: 1600);
      // After the loss, real time runs 100 ms ahead of the sample clock:
      // chunk ends at sample-clock (1200 + (i+1)*100) ms arrive at
      // wall-clock (1300 + (i+1)*100) ms.
      for (var i = 0; i < 10; i++) {
        m.addChunk(
            arrivedAt: t0.add(Duration(milliseconds: 1200 + (i + 1) * 100)),
            samples: 1600);
      }
      // Sample index 1.5 s (24000 samples) sits after the gap: on the naive
      // global clock that is t0+1500ms, but in wall-clock reality those
      // samples were recorded ~100 ms later.
      final mapped = m.timeAt(1500)!;
      expect(mapped.difference(t0).inMilliseconds, closeTo(1600, 6));
      // An onset before the gap stays unaffected.
      final early = m.timeAt(500)!;
      expect(early.difference(t0).inMilliseconds, closeTo(500, 6));
    });

    test('local anchoring smooths per-chunk delivery jitter', () {
      final m = SampleClockMap(sampleRate: sr);
      final jitter = [9, 2, 7, 3, 8, 1, 6, 4, 9, 2, 8, 3, 7, 2, 9, 1];
      for (var i = 0; i < jitter.length; i++) {
        m.addChunk(
          arrivedAt:
              t0.add(Duration(milliseconds: (i + 1) * 100 + jitter[i])),
          samples: 1600,
        );
      }
      // With min-anchoring over the neighborhood, mapped times sit near the
      // least-delayed chunks (~+1..2 ms), not on each chunk's own jitter.
      final mapped = m.timeAt(750)!;
      expect(mapped.difference(t0).inMilliseconds - 750, lessThanOrEqualTo(4));
    });

    test('returns null before any chunk', () {
      expect(SampleClockMap(sampleRate: sr).timeAt(0), isNull);
    });

    test('reports accumulated drift between stream start and end', () {
      final m = SampleClockMap(sampleRate: sr);
      for (var i = 0; i < 10; i++) {
        m.addChunk(
            arrivedAt: t0.add(Duration(milliseconds: (i + 1) * 100)),
            samples: 1600);
      }
      m.addChunk(
          arrivedAt: t0.add(const Duration(milliseconds: 1200)),
          samples: 1600);
      expect(m.driftMs, closeTo(100, 6));
    });
  });
}
