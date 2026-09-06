import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drum_coach/features/coaching/services/onset_detector.dart';
import 'package:flutter_test/flutter_test.dart';

const _sampleRate = 16000;

/// Synthesizes mono PCM16: a low noise floor plus exponentially decaying
/// noise bursts (drum-hit surrogates) at [hitTimesSec].
Int16List _synth({
  required double seconds,
  required List<double> hitTimesSec,
  double hitAmp = 0.4,
  double noiseAmp = 0.004,
  int seed = 7,
}) {
  final rng = math.Random(seed);
  final n = (seconds * _sampleRate).round();
  final out = Float64List(n);
  for (var i = 0; i < n; i++) {
    out[i] = (rng.nextDouble() * 2 - 1) * noiseAmp;
  }
  final burstLen = (0.045 * _sampleRate).round();
  final decaySamples = 0.010 * _sampleRate;
  for (final t in hitTimesSec) {
    final start = (t * _sampleRate).round();
    for (var i = 0; i < burstLen && start + i < n; i++) {
      final env = math.exp(-i / decaySamples);
      out[start + i] += (rng.nextDouble() * 2 - 1) * hitAmp * env;
    }
  }
  return Int16List.fromList(
      [for (final v in out) (v.clamp(-1.0, 1.0) * 32767).round()]);
}

List<OnsetHit> _run(Int16List pcm, {int chunkSamples = 1600}) {
  final d = OnsetDetector();
  for (var i = 0; i < pcm.length; i += chunkSamples) {
    d.addSamples(
        Int16List.sublistView(pcm, i, math.min(i + chunkSamples, pcm.length)));
  }
  return d.hits;
}

void main() {
  group('OnsetDetector', () {
    test('erkennt einen dichten Schlagteppich (11 Hits/s) nahezu vollständig',
        () {
      // 30 Hits im 91-ms-Raster — schneller als die alte 100-ms-Sperre.
      final times = [for (var k = 0; k < 30; k++) 0.2 + k * 0.091];
      final pcm = _synth(seconds: 3.2, hitTimesSec: times);
      final hits = _run(pcm);
      expect(hits.length, greaterThanOrEqualTo(28));
      expect(hits.length, lessThanOrEqualTo(31));
    });

    test('Erkennung ist unabhängig von der Audio-Chunk-Größe', () {
      final times = [for (var k = 0; k < 20; k++) 0.25 + k * 0.093];
      final pcm = _synth(seconds: 2.5, hitTimesSec: times);
      final small = _run(pcm, chunkSamples: 320); // 20 ms
      final large = _run(pcm, chunkSamples: 4000); // 250 ms
      expect(small.length, large.length);
      for (var i = 0; i < small.length; i++) {
        expect(small[i].timeMs, closeTo(large[i].timeMs, 0.001));
      }
    });

    test('einzelner Schlag löst genau eine Erkennung aus', () {
      final pcm = _synth(seconds: 1.5, hitTimesSec: [0.7]);
      expect(_run(pcm).length, 1);
    });

    test('Stille erzeugt keine Erkennungen', () {
      final pcm = _synth(seconds: 2.0, hitTimesSec: []);
      expect(_run(pcm), isEmpty);
    });

    test('Zeitstempel liegen nah an den echten Schlagzeiten', () {
      final times = [0.3, 0.55, 0.947, 1.5];
      final pcm = _synth(seconds: 2.0, hitTimesSec: times);
      final hits = _run(pcm);
      expect(hits.length, times.length);
      for (var i = 0; i < times.length; i++) {
        expect(hits[i].timeMs, closeTo(times[i] * 1000, 25));
      }
    });

    test('leise Schläge (pp) werden erkannt', () {
      final times = [for (var k = 0; k < 8; k++) 0.3 + k * 0.2];
      final pcm = _synth(seconds: 2.2, hitTimesSec: times, hitAmp: 0.05);
      expect(_run(pcm).length, greaterThanOrEqualTo(7));
    });

    test('laute Schläge tragen höhere Amplituden als leise', () {
      final loud = _run(_synth(seconds: 1.0, hitTimesSec: [0.5]));
      final quiet =
          _run(_synth(seconds: 1.0, hitTimesSec: [0.5], hitAmp: 0.05));
      expect(loud.single.amplitude, greaterThan(quiet.single.amplitude * 2));
    });
  });
}
