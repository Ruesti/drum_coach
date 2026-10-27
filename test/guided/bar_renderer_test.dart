import 'dart:typed_data';

import 'package:drum_coach/features/guided/bar_render_backend.dart';
import 'package:drum_coach/features/guided/bar_renderer.dart';
import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:drum_coach/features/metronome/click_loop_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

const _sr = 44100;

LoopVoice _voice(List<double> vols, List<double> snd) => LoopVoice(
      tickVolumes: vols,
      loudSamples: snd,
      softSamples: snd,
    );

List<double> _silent16() => List<double>.filled(16, 0.0);

void main() {
  test('bar length matches tempo', () {
    final r = BarRenderer();
    final bar = r.renderBar(bpm: 120, factor: 4, voices: [
      _voice(_silent16(), [0.5])
    ]);
    expect(bar.samples, 88200);
    expect(bar.pcm.length, 88200);
  });

  test('mixed tempo has no drift', () {
    final r = BarRenderer();
    final v = [
      _voice(_silent16(), [0.5])
    ];
    var total = 0;
    for (var i = 0; i < 3; i++) {
      total += r.renderBar(bpm: 120, factor: 4, voices: v).samples;
    }
    for (var i = 0; i < 7; i++) {
      total += r.renderBar(bpm: 97, factor: 4, voices: v).samples;
    }
    expect(total, ((3 * 2.0 + 7 * 4 * 60 / 97) * _sr).round());
  });

  test('carry spans several bars', () {
    final r = BarRenderer();
    final hit = SampleHit(tick: 0, samples: List<double>.filled(3 * _sr, 0.5));
    final b1 = r.renderBar(bpm: 120, factor: 4, voices: [
      _voice(_silent16(), [0.1])
    ], hits: [
      hit
    ]);
    final b2 = r.renderBar(bpm: 120, factor: 4, voices: [
      _voice(_silent16(), [0.1])
    ]);
    expect(b1.pcm.every((x) => (x - 0.5).abs() < 1e-6), isTrue);
    expect(b2.pcm[0], closeTo(0.5, 1e-6));
    expect(b2.pcm[_sr].abs(), lessThan(1e-6));
    expect(b2.pcm[_sr - 1], closeTo(0.5, 1e-6));
  });

  test('carry is not wrapped', () {
    final r = BarRenderer();
    final hit = SampleHit(tick: 15, samples: List<double>.filled(20000, 0.5));
    final b1 = r.renderBar(bpm: 120, factor: 4, voices: [
      _voice(_silent16(), [0.1])
    ], hits: [
      hit
    ]);
    for (var i = 0; i < 100; i++) {
      expect(b1.pcm[i], 0.0);
    }
    expect(b1.pcm.last, closeTo(0.5, 1e-6));
    final b2 = r.renderBar(bpm: 120, factor: 4, voices: [
      _voice(_silent16(), [0.1])
    ]);
    expect(b2.pcm[0], closeTo(0.5, 1e-6));
  });

  test('reset drops carry', () {
    final r = BarRenderer();
    final v = [
      _voice(_silent16(), [0.1])
    ];
    r.renderBar(
        bpm: 120,
        factor: 4,
        voices: v,
        hits: [SampleHit(tick: 0, samples: List<double>.filled(3 * _sr, 0.5))]);
    r.reset();
    final b = r.renderBar(bpm: 120, factor: 4, voices: v);
    expect(b.pcm.every((x) => x == 0.0), isTrue);
  });

  test('identical to buildLoopWav for a single bar', () {
    final snd = List<double>.generate(2000, (i) => 0.9 * (1 - i / 2000));
    final vols = List<double>.filled(16, 0.0);
    vols[0] = 1.0;
    vols[4] = 0.6;
    vols[8] = 1.0;
    vols[13] = 0.3;
    final voices = [_voice(vols, snd)];
    final wav = buildLoopWav(bpm: 100, factor: 4, voices: voices);
    final body = ByteData.sublistView(wav, 44);
    final bar = BarRenderer().renderBar(bpm: 100, factor: 4, voices: voices);
    expect(bar.samples, body.lengthInBytes ~/ 2);
    for (var i = 0; i < bar.samples; i++) {
      expect((bar.pcm[i] * 32767).round(), body.getInt16(i * 2, Endian.little),
          reason: 'sample $i');
    }
  });

  test('flush returns the carry past the last bar with a short fade', () {
    final r = BarRenderer();
    final v = [
      _voice(_silent16(), [0.1])
    ];
    // 3 s at 120 bpm: 2 s in the bar, 1 s carried.
    r.renderBar(
        bpm: 120,
        factor: 4,
        voices: v,
        hits: [SampleHit(tick: 0, samples: List<double>.filled(3 * _sr, 0.5))]);
    final tail = r.flush();
    expect(tail.length, _sr);
    expect(tail[0], closeTo(0.5, 1e-6));
    final fade = (BarRenderer.flushFadeMs * _sr / 1000).round();
    expect(tail[_sr - fade - 1], closeTo(0.5, 1e-6)); // before the fade
    expect(tail[_sr - fade], lessThan(0.5)); // fading ...
    expect(tail.last, lessThan(0.5 / fade + 1e-6)); // ... to almost 0
    for (var i = _sr - fade + 1; i < _sr; i++) {
      expect(tail[i], lessThanOrEqualTo(tail[i - 1]));
    }
    expect(r.flush(), isEmpty, reason: 'flush empties the carry');
  });

  test('flush soft-limits the carry', () {
    final r = BarRenderer();
    r.renderBar(bpm: 120, factor: 4, voices: [
      _voice(_silent16(), [0.1])
    ], hits: [
      SampleHit(tick: 0, samples: List<double>.filled(3 * _sr, 3))
    ]);
    expect(r.flush().every((x) => x.abs() <= 0.98 + 1e-6), isTrue);
  });

  test('snare: ghost strokes use the ghost recording, others the accent one',
      () {
    final vols = List<double>.filled(96, 0.0)
      ..[0] = 2.0 // accent
      ..[24] = 0.85 // normal
      ..[48] = 0.25; // ghost
    final pcm = renderBarJob(
      BarRenderer(),
      {
        RunSound.snare: [0.5],
        RunSound.snareGhost: [-0.5],
      },
      BarJob(bpm: 120, tickVolumes: {RunSound.snare: vols}),
    ).pcm;
    int at(int tick) => (tick * 60 / 120 / 24 * _sr).round();
    expect(pcm[at(0)], greaterThan(0));
    expect(pcm[at(24)], greaterThan(0));
    expect(pcm[at(48)], lessThan(0));
  });

  test('every playable RunSound has a mix spec', () {
    for (final s in RunSound.values) {
      if (s == RunSound.snareGhost) continue; // soft sample of the snare only
      final pcm = renderBarJob(
        BarRenderer(),
        {
          s: [0.5]
        },
        BarJob(
            bpm: 120,
            tickVolumes: {s: List<double>.filled(96, 0.0)..[0] = 1.0}),
      ).pcm;
      expect(pcm[0], isNot(0), reason: '$s is silent');
    }
  });
}
