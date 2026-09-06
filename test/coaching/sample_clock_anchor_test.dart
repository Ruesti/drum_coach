import 'package:drum_coach/features/coaching/services/sample_clock_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sr = 16000;
  final t0 = DateTime.fromMicrosecondsSinceEpoch(5000000000);

  // Chunks of 100 ms (1600 samples); chunk i covers samples up to (i+1)*1600
  // and would arrive at t0 + (i+1)*100ms with zero delivery delay.
  DateTime arrival(int i, int delayMs) =>
      t0.add(Duration(milliseconds: (i + 1) * 100 + delayMs));

  group('SampleClockAnchor', () {
    test('uses the least-delayed chunk, not the first one (§1.3 spread)', () {
      // First chunk is late by 12 ms (pipeline warm-up); later chunks arrive
      // with only 2 ms delivery delay. Anchoring on the first chunk would be
      // 12 ms off and vary run-to-run — the minimum converges to 2 ms.
      final a = SampleClockAnchor(sampleRate: sr);
      final delays = [12, 2, 5, 2, 7, 3];
      for (var i = 0; i < delays.length; i++) {
        a.addChunk(arrivedAt: arrival(i, delays[i]), samples: 1600);
      }
      expect(a.anchor, t0.add(const Duration(milliseconds: 2)));
    });

    test('is null before any chunk arrived', () {
      expect(SampleClockAnchor(sampleRate: sr).anchor, isNull);
    });

    test('single chunk behaves like the old first-chunk estimate', () {
      final a = SampleClockAnchor(sampleRate: sr)
        ..addChunk(arrivedAt: arrival(0, 12), samples: 1600);
      expect(a.anchor, t0.add(const Duration(milliseconds: 12)));
    });
  });
}
