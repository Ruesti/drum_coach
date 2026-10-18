// SPIKE (Plan 1 Task 0) — offline check of the bar-by-bar stream renderer.
//
//   dart run tool/spike_stream_render.dart <snare.wav> <clip.wav> <out.wav>
//
// Renders 150 bars with the automatic tempo plan exactly as the spike page
// pushes them (bar by bar), writes the concatenation as WAV, and compares it
// against an independent one-shot render of the whole timeline. Prints seam
// statistics at every bar boundary.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drum_coach/features/metronome/click_loop_renderer.dart'
    show softLimit;
import 'package:drum_coach/features/metronome/backing_sounds.dart';
import 'package:drum_coach/spike/stream_spike_renderer.dart';

void main(List<String> args) {
  final snare = decodeWav16(File(args[0]).readAsBytesSync());
  final clip = decodeWav16(File(args[1]).readAsBytesSync());
  // args[1] = clip.wav; countdown words expected next to it as
  // <clip>_three.wav, _two, _one, _go.
  final count = [
    for (final w in ['three', 'two', 'one', 'go'])
      decodeWav16(File(args[1].replaceAll('.wav', '_$w.wav')).readAsBytesSync())
  ];
  final r = SpikeStreamRenderer(
      snarePcm: snare.toList(), clipPcm: clip, countPcm: count);

  final bars = <SpikeBar>[];
  var bpm = spikeAutoTempo[0]!;
  for (var b = 0; b < 150; b++) {
    bpm = spikeAutoTempo[b] ?? bpm;
    bars.add(r.renderNext(bpm));
  }
  final total = bars.fold<int>(0, (s, b) => s + b.length);
  final stream = Float32List(total);
  for (final b in bars) {
    stream.setRange(b.start, b.start + b.length, b.pcm);
  }

  // Independent one-shot render: place every hit on the whole timeline.
  final ref = Float32List(total);
  final kick = kickSamples(), hat = hihatSamples(accent: false);
  final hatAcc = hihatSamples(accent: true);
  void put(List<double> s, int at, double g) {
    for (var i = 0; i < s.length && at + i < total; i++) {
      ref[at + i] += s[i] * g;
    }
  }

  for (final b in bars) {
    final eighth = b.length / 8.0;
    for (var e = 0; e < 8; e++) {
      final at = b.start + (e * eighth).round();
      put(e.isEven ? hatAcc : hat, at, 0.55);
      if (e == 0 || e == 4 || e == 5) put(kick, at, 0.9);
      if (e == 2 || e == 6) put(snare, at, 0.8);
    }
    if (b.clipStarts) put(clip, b.start, 0.9);
    if (b.index >= 7) {
      final k = (b.index - 7) % 8;
      if (k == 0) {
        for (var w = 0; w < 3; w++) {
          put(count[w], b.start + ((w + 1) * b.length / 4.0).round(), 0.9);
        }
      } else if (k == 1) {
        put(count[3], b.start, 0.9);
      }
    }
  }
  var maxDiff = 0.0;
  for (var i = 0; i < total; i++) {
    ref[i] = softLimit(ref[i]);
    maxDiff = math.max(maxDiff, (ref[i] - stream[i]).abs());
  }

  // Seam statistics: sample-to-sample step at each bar boundary vs. the
  // step one sample later / anywhere.
  var maxSeamStep = 0.0, maxStepAnywhere = 0.0;
  var seamsAtDownbeatOnly = 0;
  for (var i = 1; i < total; i++) {
    maxStepAnywhere =
        math.max(maxStepAnywhere, (stream[i] - stream[i - 1]).abs());
  }
  final seamSteps = <double>[];
  for (final b in bars.skip(1)) {
    // The step INTO the bar includes the downbeat attack; measure the step
    // between the last two samples of the previous bar and the first sample
    // computed without the new downbeat (ref without new hits is the same
    // timeline, so just report the raw step and the previous-bar tail step).
    final s = (stream[b.start] - stream[b.start - 1]).abs();
    seamSteps.add(s);
    maxSeamStep = math.max(maxSeamStep, s);
    seamsAtDownbeatOnly++;
  }
  seamSteps.sort();
  final tempoChanges = spikeAutoTempo.keys.where((k) => k > 0).toList();

  // 16-bit WAV for listening.
  final bd = ByteData(44 + total * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      bd.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  bd.setUint32(4, 36 + total * 2, Endian.little);
  str(8, 'WAVEfmt ');
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little);
  bd.setUint16(22, 1, Endian.little);
  bd.setUint32(24, spikeSampleRate, Endian.little);
  bd.setUint32(28, spikeSampleRate * 2, Endian.little);
  bd.setUint16(32, 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  str(36, 'data');
  bd.setUint32(40, total * 2, Endian.little);
  for (var i = 0; i < total; i++) {
    bd.setInt16(44 + i * 2, (stream[i] * 32767).round(), Endian.little);
  }
  File(args[2]).writeAsBytesSync(bd.buffer.asUint8List());

  print('bars=${bars.length} samples=$total '
      'duration=${(total / spikeSampleRate).toStringAsFixed(1)} s');
  print('tempo changes at bars $tempoChanges');
  print('max |bar-by-bar - one-shot| = $maxDiff');
  print('seam step at bar starts: max=${maxSeamStep.toStringAsFixed(4)} '
      'median=${seamSteps[seamSteps.length ~/ 2].toStringAsFixed(4)} '
      '(n=$seamsAtDownbeatOnly); max step anywhere='
      '${maxStepAnywhere.toStringAsFixed(4)}');
  final peak = stream.fold<double>(0, (m, v) => math.max(m, v.abs()));
  print('peak=${peak.toStringAsFixed(3)}; '
      'pcm bytes pushed (f32)=${total * 4} '
      '(${(total * 4 / 1048576).toStringAsFixed(1)} MiB)');
}
