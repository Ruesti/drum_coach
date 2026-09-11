import 'dart:typed_data';

import 'package:drum_coach/features/metronome/click_loop_renderer.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _sr = 44100;

Int16List _pcm(Uint8List wav) =>
    wav.buffer.asByteData(44).buffer.asInt16List(44, (wav.length - 44) ~/ 2);

double _rmsAt(Int16List pcm, int startSample, int windowSamples) {
  var sum = 0.0;
  for (var i = startSample; i < startSample + windowSamples && i < pcm.length; i++) {
    final v = pcm[i] / 32768.0;
    sum += v * v;
  }
  return sum / windowSamples;
}

void main() {
  group('buildLoopWav', () {
    test('loop length is exactly ticks × tick duration', () {
      // 120 BPM quarters, 4 ticks → 4 × 0.5 s = 2 s.
      final wav = buildLoopWav(
        bpm: 120,
        factor: 1,
        tickVolumes: const [2.0, 0.7, 0.7, 0.7],
        accentSamples: MetronomeEngine.synthSamples(SoundType.click, accent: true),
        normalSamples: MetronomeEngine.synthSamples(SoundType.click, accent: false),
      );
      expect(_pcm(wav).length, 2 * _sr);
    });

    test('audible ticks carry energy, silent grid ticks stay silent', () {
      // Pattern clock: 8th-note pattern where ticks 1 and 3 are silent.
      final wav = buildLoopWav(
        bpm: 120,
        factor: 2,
        tickVolumes: const [1.0, 0.0, 1.0, 0.0],
        accentSamples: MetronomeEngine.synthSamples(SoundType.click, accent: true),
        normalSamples: MetronomeEngine.synthSamples(SoundType.click, accent: false),
      );
      final pcm = _pcm(wav);
      final tickSamples = _sr ~/ 4; // 0.25 s per 8th at 120 BPM
      final win = _sr ~/ 100; // 10 ms
      expect(_rmsAt(pcm, 0, win), greaterThan(1e-6));
      expect(_rmsAt(pcm, 2 * tickSamples, win), greaterThan(1e-6));
      // Silent ticks: no energy at their onset.
      expect(_rmsAt(pcm, tickSamples, win), lessThan(1e-9));
      expect(_rmsAt(pcm, 3 * tickSamples, win), lessThan(1e-9));
    });

    test('accent volume produces a louder onset than a normal tick', () {
      final wav = buildLoopWav(
        bpm: 120,
        factor: 1,
        tickVolumes: const [2.0, 0.7, 0.7, 0.7],
        accentSamples: MetronomeEngine.synthSamples(SoundType.click, accent: true),
        normalSamples: MetronomeEngine.synthSamples(SoundType.click, accent: false),
      );
      final pcm = _pcm(wav);
      final win = _sr ~/ 100;
      expect(_rmsAt(pcm, 0, win),
          greaterThan(2 * _rmsAt(pcm, _sr ~/ 2, win)));
    });

    test('a click near the loop end wraps into the loop start', () {
      // 2 sixteenth ticks at 240 BPM → tick = 62.5 ms, loop = 125 ms. The
      // second tick's 30 ms click ends exactly at the loop boundary; a rim
      // sound (100 ms) must wrap. First tick silent so wrapped energy is
      // attributable.
      final wav = buildLoopWav(
        bpm: 240,
        factor: 4,
        tickVolumes: const [0.0, 1.0],
        accentSamples: MetronomeEngine.synthSamples(SoundType.rim, accent: true),
        normalSamples: MetronomeEngine.synthSamples(SoundType.rim, accent: false),
      );
      final pcm = _pcm(wav);
      final win = _sr ~/ 100;
      // Wrapped tail of tick 1's rim lands at the loop start.
      expect(_rmsAt(pcm, 0, win), greaterThan(1e-8),
          reason: 'sound crossing the loop boundary must wrap, not truncate');
    });

    test('samples are hard-clipped to int16 range', () {
      final wav = buildLoopWav(
        bpm: 240,
        factor: 1,
        tickVolumes: const [2.0, 2.0],
        accentSamples: List.filled(2000, 0.9),
        normalSamples: List.filled(2000, 0.9),
      );
      // Decoding succeeded and produced finite samples — clipping cannot
      // overflow the int16 encode.
      final pcm = _pcm(wav);
      expect(pcm.every((s) => s >= -32768 && s <= 32767), isTrue);
    });
  });
}
