import 'dart:io';

import 'package:drum_coach/content/analysis.dart';
import 'package:drum_coach/content/exercises.dart';
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
  final shift = <int, double>{};
  final drop = <int>{};
  for (final t in targets) {
    final mag = 40.0 + (t.index * 7) % 21;
    shift[t.index] = t.index.isEven ? mag : -mag;
    if (t.voice == Voice.hiHat && t.index % 9 == 4) drop.add(t.index);
    if (t.voice == Voice.kick && t.index % 13 == 5) drop.add(t.index);
  }
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
    'rock_crash_for_hihat': syntheticSession(basicRockBeat,
        latencyMs: 12,
        replaceNote: {for (final t in hats.take(40)) t.index: 49}),
    'rock_double_trigger': syntheticSession(basicRockBeat,
        latencyMs: 12,
        extra: [for (final t in snares.take(5)) _snareAt(t.timeMs + 12 + 18)]),
    'rock_countin_noise': syntheticSession(basicRockBeat,
        latencyMs: 12,
        extra: [for (var i = 0; i < 6; i++) _snareAt(300 + i * 375.0)]),
    'rock_uncalibrated': syntheticSession(basicRockBeat, calibrated: false),
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
