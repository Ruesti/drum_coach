// Renders every backing style as a WAV for the sound gate (spec §9):
//   dart run tool/render_backing_demo.dart <out-dir> [bpm] [bars]
// Each style twice: with an eighth-note R L click pattern and solo.
import 'dart:io';
import 'dart:typed_data';

import 'package:drum_coach/features/metronome/backing_sounds.dart';
import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:drum_coach/features/metronome/click_loop_renderer.dart';
import 'package:drum_coach/features/metronome/loop_voices.dart';
import 'package:drum_coach/features/metronome/stroke_sounds.dart';

void main(List<String> args) {
  final outDir = Directory(args.isNotEmpty ? args[0] : 'backing-demo')
    ..createSync(recursive: true);
  final bpm = args.length > 1 ? int.parse(args[1]) : 90;
  final bars = args.length > 2 ? int.parse(args[2]) : 8;
  const factor = 24;
  // One 4/4 bar of eighths, accent on the downbeat.
  final eighths = [
    for (var t = 0; t < 96; t++) t % 12 == 0 ? (t == 0 ? 2.0 : 0.85) : 0.0
  ];
  final silent = List<double>.filled(96, 0.0);
  final kick = kickSamples();
  final hhLoud = hihatSamples(accent: true);
  final hhSoft = hihatSamples(accent: false);
  for (final style in backingStyles) {
    for (final withPattern in [true, false]) {
      final plan = buildLoopPlan(
        patternVolumes: withPattern ? eighths : silent,
        patternLoud: clickSamples(accent: true),
        patternSoft: clickSamples(accent: false),
        factor: factor,
        backing: style,
        backingLevel: 0.7,
        beatsPerBar: 4,
        kickSound: kick,
        hihatLoud: hhLoud,
        hihatSoft: hhSoft,
      );
      final oneBar =
          buildLoopWav(bpm: bpm, factor: factor, voices: plan.voices);
      final name = '${style.id}${withPattern ? '' : '_solo'}.wav';
      File('${outDir.path}/$name').writeAsBytesSync(_repeat(oneBar, bars));
      stdout.writeln('wrote $name');
    }
  }
}

/// Repeats the data chunk of a 16-bit mono WAV [times] and fixes the header
/// sizes. The renderer wraps sound tails into the loop start, so the joins
/// are seamless.
Uint8List _repeat(Uint8List wav, int times) {
  final data = wav.sublist(44);
  final out = ByteData(44 + data.length * times);
  final bytes = out.buffer.asUint8List();
  bytes.setRange(0, 44, wav);
  for (var i = 0; i < times; i++) {
    bytes.setRange(44 + i * data.length, 44 + (i + 1) * data.length, data);
  }
  out.setUint32(4, 36 + data.length * times, Endian.little);
  out.setUint32(40, data.length * times, Endian.little);
  return bytes;
}
