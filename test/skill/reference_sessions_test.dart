import 'dart:io';

import 'package:drum_coach/content/analysis.dart';
import 'package:drum_coach/content/exercises.dart';
import 'package:drum_coach/measure/hit_matcher.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/session_record.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic.dart';

const _dir = 'test/fixtures/sessions';

Stroke _snareAt(double t) =>
    Stroke(timeMs: t, note: 38, velocity: 100, instrument: KitInstrument.snare);

SessionRecord _sloppyEntry() {
  final targets = entryExercise.targetTimes(firstBeatMs: 3000);
  final hats = [
    for (final t in targets)
      if (t.voice == Voice.hiHat) t
  ];
  final kicks = [
    for (final t in targets)
      if (t.voice == Voice.kick) t
  ];
  // hi-hat 26/32 and kick 13/16 hit, spread out so no gap exceeds one bar.
  final drop = <int>{
    for (final i in [2, 7, 12, 17, 22, 27]) hats[i].index,
    for (final i in [1, 6, 11]) kicks[i].index,
  };
  const mags = [40.0, 60.0, 50.0, 45.0, 55.0, 60.0];
  final shift = <int, double>{
    for (final t in targets)
      t.index: t.index.isEven ? mags[t.index % 6] : -mags[t.index % 6],
  };
  return syntheticSession(entryExercise,
      latencyMs: 12, shiftMs: shift, drop: drop);
}

Map<String, SessionRecord> _cases() {
  final rock = basicRockBeat.targetTimes(firstBeatMs: 3000);
  final snares = [
    for (final t in rock)
      if (t.voice == Voice.snare) t
  ];
  final hats = [
    for (final t in rock)
      if (t.voice == Voice.hiHat) t
  ];
  final entry = entryExercise.targetTimes(firstBeatMs: 3000);
  return {
    'rock_perfect': syntheticSession(basicRockBeat, latencyMs: 12),
    'rock_plus7ms': syntheticSession(basicRockBeat, latencyMs: 12, shiftMs: {
      for (final t in rock) t.index: 7.0,
    }),
    'rock_missing_snare': syntheticSession(basicRockBeat,
        latencyMs: 12, drop: {for (final t in snares) t.index}),
    'rock_one_missing_snare':
        syntheticSession(basicRockBeat, latencyMs: 12, drop: {snares[3].index}),
    'rock_one_crash_for_hihat': syntheticSession(basicRockBeat,
        latencyMs: 12, replaceNote: {hats[5].index: 49}),
    'rock_flam_snare': syntheticSession(basicRockBeat,
        latencyMs: 12, extra: [_snareAt(snares[7].timeMs + 12 + 25)]),
    'rock_crash_for_hihat': syntheticSession(basicRockBeat,
        latencyMs: 12,
        replaceNote: {for (final t in hats.take(40)) t.index: 49}),
    'rock_double_trigger': syntheticSession(basicRockBeat,
        latencyMs: 12,
        extra: [for (final t in snares.take(5)) _snareAt(t.timeMs + 12 + 3)]),
    'rock_countin_noise': syntheticSession(basicRockBeat,
        latencyMs: 12,
        extra: [for (var i = 0; i < 6; i++) _snareAt(300 + i * 375.0)]),
    'rock_uncalibrated':
        syntheticSession(basicRockBeat, latencyMs: 12, calibrated: false),
    'entry_pass_sloppy': _sloppyEntry(),
    'entry_stops_bar4': syntheticSession(entryExercise, latencyMs: 12, drop: {
      for (final t in entry)
        if (t.bar >= 4) t.index
    }),
  };
}

void main() {
  final update = Platform.environment['UPDATE_GOLDENS'] == '1';
  final cases = _cases();

  for (final entry in cases.entries) {
    test('every fixture: ${entry.key}', () {
      final jsonl = File('$_dir/${entry.key}.jsonl');
      final expected = File('$_dir/${entry.key}.expected.json');
      if (update) {
        Directory(_dir).createSync(recursive: true);
        jsonl.writeAsStringSync(encodeSessionJsonl(entry.value));
        expected.writeAsStringSync(analysisToJson(
            analyzeSession(decodeSessionJsonl(jsonl.readAsStringSync()))));
        return;
      }
      final text = jsonl.readAsStringSync();
      final actual = analysisToJson(analyzeSession(decodeSessionJsonl(text)));
      expect(actual, expected.readAsStringSync());
      // The fixture is still what the builder produces.
      expect(text, encodeSessionJsonl(entry.value));
      // Analyzing the same file twice gives identical JSON.
      expect(analysisToJson(analyzeSession(decodeSessionJsonl(text))), actual);
    });
  }

  test('single-defect cases pin exactly one outcome', () {
    final rock = basicRockBeat.targetTimes(firstBeatMs: 3000);
    int idx(Voice v, int n) => [
          for (final t in rock)
            if (t.voice == v) t
        ][n]
            .index;
    SessionAnalysis run(String name) => analyzeSession(cases[name]!);

    final missing = run('rock_one_missing_snare');
    final mi = idx(Voice.snare, 3);
    for (final o in missing.match.targets) {
      expect(o.kind, o.target.index == mi ? HitKind.missed : HitKind.hit);
      if (o.kind == HitKind.hit) expect(o.deviationMs, closeTo(0, 0.01));
    }
    expect(missing.match.extraStrokeIndices, isEmpty);

    final crash = run('rock_one_crash_for_hihat');
    final ci = idx(Voice.hiHat, 5);
    for (final o in crash.match.targets) {
      expect(
          o.kind, o.target.index == ci ? HitKind.wrongInstrument : HitKind.hit);
    }
    expect(crash.match.extraStrokeIndices, isEmpty);

    final flam = run('rock_flam_snare');
    final fi = idx(Voice.snare, 7);
    for (final o in flam.match.targets) {
      expect(o.kind, HitKind.hit);
      expect(o.deviationMs, closeTo(0, 0.01));
    }
    final second = cases['rock_flam_snare']!
        .strokes
        .indexWhere((s) => (s.timeMs - (rock[fi].timeMs + 37)).abs() < 0.01);
    expect(flam.match.extraStrokeIndices, [second]);
  });

  test('every fixture file belongs to a case', () {
    final files = Directory(_dir)
        .listSync()
        .map((f) => f.path.split('/').last)
        .where((n) => n.endsWith('.jsonl'))
        .map((n) => n.replaceAll('.jsonl', ''))
        .toSet();
    expect(files, cases.keys.toSet());
  });
}
