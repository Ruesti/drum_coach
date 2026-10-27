// Klang-Probe for the guided player (Optik-Runde 1, Task 3): renders the
// groove and the last variation of every kit exercise of the catalog (two
// bars each, so two-bar lines are whole) through the real bar renderer with
// the shipped recordings, plus one bar of a pad exercise, and prints peak /
// RMS per voice. Not part of `flutter test` (lives in tool/):
//   flutter test tool/render_guided_probe_test.dart [--dart-define=OUT=dir]
// Default output: ~/gefuehrt-klang-probe/
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drum_coach/features/guided/bar_render_backend.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/guided_player.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/models/voice_clip.dart';
import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:drum_coach/features/guided/sample_bank.dart';
import 'package:drum_coach/features/metronome/snare_sample.dart';
import 'package:flutter_test/flutter_test.dart';

const _bars = 2;

ClipManifest _clipsFor(GuidedExercise ex) => ClipManifest.fromJson({
      'clips': [
        for (final s in ex.sections) ...[
          if (s.speechClipId != null) {'id': s.speechClipId, 'ms': 3000},
          if (s.afterClipId != null) {'id': s.afterClipId, 'ms': 400},
        ],
        for (final id in [...countdownClipIds, ...countInClipIds])
          {'id': id, 'ms': 400},
      ]
    });

Uint8List _wav(List<double> pcm) {
  final b = BytesBuilder();
  final h = ByteData(44);
  void str(int o, String s) {
    for (var i = 0; i < 4; i++) {
      h.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  h.setUint32(4, 36 + pcm.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  h.setUint32(16, 16, Endian.little);
  h.setUint16(20, 1, Endian.little);
  h.setUint16(22, 1, Endian.little);
  h.setUint32(24, 44100, Endian.little);
  h.setUint32(28, 88200, Endian.little);
  h.setUint16(32, 2, Endian.little);
  h.setUint16(34, 16, Endian.little);
  str(36, 'data');
  h.setUint32(40, pcm.length * 2, Endian.little);
  b.add(h.buffer.asUint8List());
  final d = ByteData(pcm.length * 2);
  for (var i = 0; i < pcm.length; i++) {
    d.setInt16(i * 2, (pcm[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  b.add(d.buffer.asUint8List());
  return b.toBytes();
}

({double peak, double rms}) _stats(List<double> s) {
  var p = 0.0, sum = 0.0;
  for (final v in s) {
    p = math.max(p, v.abs());
    sum += v * v;
  }
  return (peak: p, rms: s.isEmpty ? 0 : math.sqrt(sum / s.length));
}

Future<List<double>> _render(
    Map<RunSound, List<double>> sounds, List<RunBar> bars,
    {required double crashGain, Set<RunSound>? only}) async {
  final backend = InlineBarRenderBackend();
  await backend.init(sounds);
  final out = <double>[];
  for (final bar in bars) {
    var job = barJobFor(bar, clips: const {}, crashGain: crashGain);
    if (only != null) {
      job = BarJob(bpm: job.bpm, tickVolumes: {
        for (final e in job.tickVolumes.entries)
          if (only.contains(e.key)) e.key: e.value
      }, hits: [
        for (final h in job.hits)
          if (h.sound != null && only.contains(h.sound)) h
      ]);
    }
    out.addAll(await backend.render(job));
  }
  out.addAll(await backend.flush());
  return out;
}

void main() {
  test('render guided Klang-Probe', () async {
    final outDir = Directory(const String.fromEnvironment('OUT').isNotEmpty
        ? const String.fromEnvironment('OUT')
        : '${Platform.environment['HOME']}/gefuehrt-klang-probe')
      ..createSync(recursive: true);
    final rec = {
      for (final e in SampleBank.assets.entries)
        e.key: decodeMonoWav16(File(e.value).readAsBytesSync()).toList(),
    };
    final sounds = SampleBank(recordings: rec).toSoundMap();
    final lines = <String>[];
    final exercises = [
      ...guidedCatalog.where((e) => e.package == GuidedPackage.kit),
      guidedCatalog.firstWhere((e) => e.package == GuidedPackage.pad),
    ];
    for (final ex in exercises) {
      final run = buildRun(ex,
          bpm: ex.defaultBpm,
          options: const RunOptions(teacher: false),
          clips: _clipsFor(ex));
      final groove =
          ex.sections.indexWhere((s) => s.kind == SectionKind.groove);
      final lastVar =
          ex.sections.lastIndexWhere((s) => s.kind == SectionKind.variation);
      for (final (name, si) in [('groove', groove), ('vlast', lastVar)]) {
        final bars = run
            .where((b) => b.sectionIndex == si && b.barInSection < _bars)
            .map((b) => RunBar(
                globalBar: b.globalBar,
                sectionIndex: b.sectionIndex,
                barInSection: b.barInSection,
                bpm: b.bpm,
                isCountIn: false,
                isCountdown: false,
                // no countdown clicks in the probe: only the kit
                tickVolumes: {
                  for (final e in b.tickVolumes.entries)
                    if (e.key != RunSound.click) e.key: e.value
                },
                events: b.events.whereType<CrashEvent>().toList()))
            .toList();
        final gain = crashGainFor(ex.package);
        final mix = await _render(sounds, bars, crashGain: gain);
        final file = '${ex.id}_$name.wav';
        File('${outDir.path}/$file').writeAsBytesSync(_wav(mix));
        final m = _stats(mix);
        lines.add('$file  mix peak ${m.peak.toStringAsFixed(2)} '
            'rms ${m.rms.toStringAsFixed(3)}');
        final used = {
          for (final b in bars) ...b.tickVolumes.keys,
          for (final b in bars)
            for (final e in b.events)
              if (e is CrashEvent) RunSound.crash,
        };
        for (final s in used) {
          final solo = await _render(sounds, bars, crashGain: gain, only: {s});
          final st = _stats(solo);
          lines.add('    ${s.name.padRight(12)} peak '
              '${st.peak.toStringAsFixed(2)} rms ${st.rms.toStringAsFixed(3)}');
        }
      }
    }
    File('${outDir.path}/balance.txt')
        .writeAsStringSync('${lines.join('\n')}\n');
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}
