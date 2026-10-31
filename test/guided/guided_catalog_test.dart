import 'dart:convert';
import 'dart:io';

import 'package:drum_coach/features/guided/data/demo_exercise.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/models/voice_clip.dart';
import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _manifestJson() =>
    jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
        as Map<String, dynamic>;

ClipManifest _manifest() => ClipManifest.fromJson(_manifestJson());

double _runMs(GuidedExercise ex, int bpm) =>
    buildRun(ex, bpm: bpm, options: const RunOptions(), clips: _manifest())
        .fold<double>(0, (t, b) => t + guidedBeatsPerBar * 60000 / b.bpm);

void main() {
  test('every catalog exercise validates', () {
    expect(guidedCatalog, isNotEmpty);
    for (final ex in guidedCatalog) {
      expect(ex.validate, returnsNormally, reason: ex.id);
      expect(ex.variationCount, inInclusiveRange(3, 5), reason: ex.id);
    }
  });

  test('every catalog section is a whole phrase', () {
    for (final ex in guidedCatalog) {
      for (final s in ex.sections) {
        if (s.kind != SectionKind.groove && s.kind != SectionKind.variation) {
          continue;
        }
        expect(s.bars % guidedPhraseBars, 0, reason: '${ex.id}: ${s.kind}');
      }
    }
  });

  test('every variation has a short title of 2-5 words', () {
    for (final ex in guidedCatalog) {
      for (final s in ex.sections) {
        if (s.kind != SectionKind.variation) continue;
        final words = s.titleEn!.trim().split(RegExp(r'\s+')).length;
        expect(words, inInclusiveRange(2, 5), reason: '${ex.id}: ${s.titleEn}');
      }
    }
  });

  test('ids are unique and not demo ids', () {
    final ids = guidedCatalog.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(id, startsWith('guided_'));
      expect(id, isNot(anyOf(demoKitExercise.id, demoPadExercise.id)));
    }
  });

  test('about five minutes at default bpm', () {
    for (final ex in guidedCatalog) {
      final ms = _runMs(ex, ex.defaultBpm);
      expect(ms, inInclusiveRange(4 * 60000, 6 * 60000), reason: ex.id);
    }
  });

  test('catalog plays at min and max bpm', () {
    for (final ex in guidedCatalog) {
      expect(_runMs(ex, ex.minBpm), lessThanOrEqualTo(9 * 60000),
          reason: ex.id);
      expect(_runMs(ex, ex.maxBpm), greaterThanOrEqualTo(2.5 * 60000),
          reason: ex.id);
    }
  });

  test('demos still validate and are not in the catalog', () {
    final ids = guidedCatalog.map((e) => e.id).toSet();
    for (final demo in [demoKitExercise, demoPadExercise]) {
      expect(demo.validate, returnsNormally, reason: demo.id);
      expect(ids, isNot(contains(demo.id)));
    }
  });

  test('round 1: one exercise per package and difficulty', () {
    expect(guidedCatalog, hasLength(8));
    for (final p in GuidedPackage.values) {
      final ds =
          guidedCatalog.where((e) => e.package == p).map((e) => e.difficulty);
      expect(ds.toSet(), hasLength(4), reason: '$p');
    }
  });

  test('variation clips follow the id scheme', () {
    for (final ex in guidedCatalog) {
      final clips = ex.sections
          .where((s) => s.kind == SectionKind.variation)
          .map((s) => s.speechClipId)
          .toList();
      expect(clips, [
        for (var n = 1; n <= clips.length; n++) 'g_${ex.id}_v$n',
      ]);
    }
  });

  test('every catalog clip exists in the manifest', () {
    final m = _manifest();
    for (final ex in guidedCatalog) {
      for (final s in ex.sections) {
        for (final id in [s.speechClipId, s.afterClipId]) {
          if (id == null) continue;
          expect(m.ids, contains(id), reason: '${ex.id}: $id');
        }
      }
    }
  });

  test('catalog textEn equals manifest text', () {
    final texts = {
      for (final c in _manifestJson()['clips'] as List)
        (c as Map)['id'] as String: c['text'] as String?,
    };
    for (final ex in guidedCatalog) {
      for (final s in ex.sections) {
        final id = s.speechClipId;
        if (id == null) continue;
        expect(s.textEn, texts[id], reason: '${ex.id}: $id');
      }
    }
  });

  test('explanations are at most 4500 ms', () {
    final m = _manifest();
    for (final ex in guidedCatalog) {
      for (final s in ex.sections) {
        final id = s.speechClipId;
        if (id == null) continue;
        expect(m.durationMs(id), lessThanOrEqualTo(4500),
            reason: '${ex.id}: $id');
      }
      // The planner may stretch a groove to fit the explanation, but by
      // no more than 2 bars at the default tempo.
      final run = buildRun(ex,
          bpm: ex.defaultBpm, options: const RunOptions(), clips: m);
      final perSection = <int, int>{};
      for (final b in run) {
        perSection[b.sectionIndex] = (perSection[b.sectionIndex] ?? 0) + 1;
      }
      for (final e in perSection.entries) {
        if (e.key < 0) continue;
        final s = ex.sections[e.key];
        if (s.kind == SectionKind.variation) continue;
        expect(e.value, lessThanOrEqualTo(s.bars + 2),
            reason: '${ex.id}: section ${e.key} (${s.kind})');
      }
    }
  });
}
