import 'dart:typed_data';

import 'package:drum_coach/features/metronome/click_loop_renderer.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _sr = 44100;

Int16List _pcm(Uint8List wav) =>
    wav.buffer.asByteData(44).buffer.asInt16List(44, (wav.length - 44) ~/ 2);

double _rmsAt(Int16List pcm, int startSample, int windowSamples) {
  var sum = 0.0;
  for (var i = startSample;
      i < startSample + windowSamples && i < pcm.length;
      i++) {
    final v = pcm[i] / 32768.0;
    sum += v * v;
  }
  return sum / windowSamples;
}

LoopVoice _click(List<double> vols) => LoopVoice(
      tickVolumes: vols,
      loudSamples: MetronomeEngine.synthSamples(SoundType.click, accent: true),
      softSamples: MetronomeEngine.synthSamples(SoundType.click, accent: false),
      loudFrom: 1.2,
    );

LoopVoice _pulse(int ticks, int every) => LoopVoice(
      tickVolumes: [for (var t = 0; t < ticks; t++) t % every == 0 ? 1.0 : 0.0],
      loudSamples: MetronomeEngine.pulseSamples(),
      softSamples: MetronomeEngine.pulseSamples(),
    );

void main() {
  group('pulse voice (click track next to the exercise)', () {
    const tickSamples = _sr ~/ 4; // 120 BPM, factor 2 → tick = 0.25 s
    final win = _sr ~/ 100;

    test('adds a click on every quarter tick next to a silent pattern', () {
      final wav = buildLoopWav(bpm: 120, factor: 2, voices: [
        _click(const [0.0, 0.0, 0.0, 0.0]),
        _pulse(4, 2),
      ]);
      final pcm = _pcm(wav);
      expect(_rmsAt(pcm, 0, win), greaterThan(1e-6));
      expect(_rmsAt(pcm, 2 * tickSamples, win), greaterThan(1e-6));
      expect(_rmsAt(pcm, tickSamples, win), lessThan(1e-9));
      expect(_rmsAt(pcm, 3 * tickSamples, win), lessThan(1e-9));
    });

    test('without a pulse voice the silent pattern stays silent', () {
      final wav = buildLoopWav(
          bpm: 120, factor: 2, voices: [_click(const [0.0, 0.0, 0.0, 0.0])]);
      final pcm = _pcm(wav);
      for (var t = 0; t < 4; t++) {
        expect(_rmsAt(pcm, t * tickSamples, win), lessThan(1e-9));
      }
    });

    test('the pulse is a shorter, quieter sound than the exercise click', () {
      final pulse = MetronomeEngine.pulseSamples();
      final click =
          MetronomeEngine.synthSamples(SoundType.click, accent: false);
      expect(pulse.length, lessThan(click.length));
      final peak = pulse.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
      expect(peak, lessThan(0.55));
    });
  });

  group('buildLoopWav', () {
    final win = _sr ~/ 100;

    test('loop length is exactly ticks × tick duration', () {
      final wav = buildLoopWav(
          bpm: 120, factor: 1, voices: [_click(const [2.0, 0.7, 0.7, 0.7])]);
      expect(_pcm(wav).length, 2 * _sr);
    });

    test('audible ticks carry energy, silent grid ticks stay silent', () {
      final wav = buildLoopWav(
          bpm: 120, factor: 2, voices: [_click(const [1.0, 0.0, 1.0, 0.0])]);
      final pcm = _pcm(wav);
      const tickSamples = _sr ~/ 4;
      expect(_rmsAt(pcm, 0, win), greaterThan(1e-6));
      expect(_rmsAt(pcm, 2 * tickSamples, win), greaterThan(1e-6));
      expect(_rmsAt(pcm, tickSamples, win), lessThan(1e-9));
      expect(_rmsAt(pcm, 3 * tickSamples, win), lessThan(1e-9));
    });

    test('accent volume produces a louder onset than a normal tick', () {
      final wav = buildLoopWav(
          bpm: 120, factor: 1, voices: [_click(const [2.0, 0.7, 0.7, 0.7])]);
      final pcm = _pcm(wav);
      expect(_rmsAt(pcm, 0, win), greaterThan(2 * _rmsAt(pcm, _sr ~/ 2, win)));
    });

    test('a sound near the loop end wraps into the loop start', () {
      final rim = LoopVoice(
        tickVolumes: const [0.0, 1.0],
        loudSamples: MetronomeEngine.synthSamples(SoundType.rim, accent: true),
        softSamples: MetronomeEngine.synthSamples(SoundType.rim, accent: false),
        loudFrom: 1.2,
      );
      final wav = buildLoopWav(bpm: 240, factor: 4, voices: [rim]);
      expect(_rmsAt(_pcm(wav), 0, win), greaterThan(1e-8),
          reason: 'sound crossing the loop boundary must wrap, not truncate');
    });

    test('voices mix additively and gain scales a voice', () {
      final flat = List.filled(2000, 0.5);
      LoopVoice v(double gain) => LoopVoice(
          tickVolumes: const [1.0],
          loudSamples: flat,
          softSamples: flat,
          gain: gain);
      final one = _pcm(buildLoopWav(bpm: 120, factor: 1, voices: [v(1.0)]));
      final two =
          _pcm(buildLoopWav(bpm: 120, factor: 1, voices: [v(1.0), v(0.5)]));
      final muted = _pcm(buildLoopWav(bpm: 120, factor: 1, voices: [v(0.0)]));
      expect(two[100] / one[100], closeTo(1.5, 0.02));
      expect(muted.every((s) => s == 0), isTrue);
    });

    test('voices of different cycle lengths are rejected', () {
      expect(
          () => buildLoopWav(bpm: 120, factor: 1, voices: [
                _click(const [1.0, 0.0]),
                _pulse(4, 2),
              ]),
          throwsArgumentError);
      expect(() => buildLoopWav(bpm: 120, factor: 1, voices: const []),
          throwsArgumentError);
    });

    test('soft limiter: quiet signals pass unchanged, loud sums never flat-top',
        () {
      expect(softLimit(0.5), 0.5);
      expect(softLimit(-0.8), -0.8);
      expect(softLimit(1.9), lessThan(1.0));
      expect(softLimit(1.9), greaterThan(0.95));
      expect(softLimit(-3.0), greaterThan(-1.0));
      // Four full-scale voices on the same tick: no two consecutive samples
      // at the ceiling.
      final loud = List.filled(3000, 0.9);
      LoopVoice v() => LoopVoice(
          tickVolumes: const [2.0], loudSamples: loud, softSamples: loud);
      final pcm =
          _pcm(buildLoopWav(bpm: 120, factor: 1, voices: [v(), v(), v(), v()]));
      for (var i = 1; i < 3000; i++) {
        expect(pcm[i - 1] >= 32700 && pcm[i] >= 32700, isFalse,
            reason: 'flat top at $i');
      }
      expect(pcm.every((s) => s >= -32768 && s <= 32767), isTrue);
    });
  });

  group('loopCycleTicks', () {
    test('is the least common multiple of pattern and bar', () {
      expect(loopCycleTicks(patternTicks: 96, barTicks: 96), 96);
      expect(loopCycleTicks(patternTicks: 24, barTicks: 96), 96);
      expect(loopCycleTicks(patternTicks: 144, barTicks: 96), 288);
      expect(loopCycleTicks(patternTicks: 96, barTicks: 48), 96);
    });
  });
}
