import 'dart:convert';
import 'dart:io';

import 'package:drum_coach/features/guided/data/demo_exercise.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/models/voice_clip.dart';
import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:flutter_test/flutter_test.dart';

ClipManifest _manifest() => ClipManifest.fromJson(
    jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
        as Map<String, dynamic>);

double _runMs(GuidedExercise ex, int bpm) =>
    buildRun(ex, bpm: bpm, options: const RunOptions(), clips: _manifest())
        .fold<double>(0, (t, b) => t + guidedBeatsPerBar * 60000 / b.bpm);

void main() {
  final demos = [demoKitExercise, demoPadExercise];

  test('demo exercises validate', () {
    for (final ex in demos) {
      expect(ex.validate, returnsNormally, reason: ex.id);
      expect(ex.variationCount, 3, reason: ex.id);
    }
    expect(demoKitExercise.package, GuidedPackage.kit);
    expect(demoPadExercise.package, GuidedPackage.pad);
  });

  test('demo kit ~5 min at default bpm', () {
    final ms = _runMs(demoKitExercise, demoKitExercise.defaultBpm);
    expect(ms, inInclusiveRange(4 * 60000, 6 * 60000));
  });

  test('demo pad ~5 min at default bpm', () {
    final ms = _runMs(demoPadExercise, demoPadExercise.defaultBpm);
    expect(ms, inInclusiveRange(4 * 60000, 6 * 60000));
  });

  test('every clip the demos use is in the voice manifest', () {
    final ids = _manifest().ids.toSet();
    for (final ex in demos) {
      for (final s in ex.sections) {
        for (final id in [s.speechClipId, s.afterClipId]) {
          if (id != null) expect(ids, contains(id), reason: '${ex.id}: $id');
        }
      }
    }
  });

  test('textEn is the spoken sentence of tool/stimme/saetze.py', () {
    // Python may split a long sentence over two string literals.
    final py = File('tool/stimme/saetze.py')
        .readAsStringSync()
        .replaceAll(RegExp(r'"\s*\n\s*"'), '');
    for (final ex in demos) {
      for (final s
          in ex.sections.where((s) => s.kind == SectionKind.variation)) {
        final m =
            RegExp('"${s.speechClipId}":\\s*\\(?"([^"]*)"').firstMatch(py);
        expect(m?.group(1), s.textEn, reason: s.speechClipId);
      }
    }
  });
}
