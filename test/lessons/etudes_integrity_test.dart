import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/data/etudes.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('étude ids are unique across the whole catalog', () {
    final all = [...rudimentsSeedData, ...allEtudes];
    final seen = <String>{};
    final dupes = <String>{};
    for (final r in all) {
      if (!seen.add(r.id)) dupes.add(r.id);
    }
    expect(dupes, isEmpty, reason: 'duplicate ids: $dupes');
  });

  test(
      'every étude fills whole bars and is a rudimentEtudes/techniqueStudies member',
      () {
    for (final r in allEtudes) {
      expect(r.collection, isNotNull, reason: '${r.id} has no collection');
      expect(
        () => barCountOrThrow(r.sticking,
            beatsPerBar: r.beatsPerBar, grid: r.gridUnit),
        returnsNormally,
        reason: '${r.id} does not fill whole bars',
      );
    }
  });

  test('every étude note lands on an integer 24-tick', () {
    for (final r in allEtudes) {
      for (var i = 0; i < r.sticking.length; i++) {
        final ticks = resolveNote(r.sticking[i], r.gridUnit).quarters * 24;
        expect((ticks - ticks.round()).abs() < 1e-6, isTrue,
            reason: '${r.id} note $i = $ticks ticks not integer');
      }
    }
  });

  group('sheets (Blattform)', () {
    final all = [...rudimentsSeedData, ...allEtudes];
    test('every authored line is 1..8 whole bars; every sheet ≤ 64 bars', () {
      // Legacy one-line sheets (the plain sticking) may be shorter than a
      // bar — 19 basic rudiments are, and the loop tiles them — so the
      // whole-bars rule binds authored lines only.
      for (final r in all) {
        for (var i = 0; i < r.lines.length; i++) {
          final l = r.lines[i];
          expect(l.beats, isNotEmpty, reason: '${r.id} line ${i + 1} empty');
          final bars = barCountOrThrow(l.beats,
              beatsPerBar: r.beatsPerBar, grid: r.gridUnit);
          expect(bars, inInclusiveRange(1, 8),
              reason: '${r.id} line ${i + 1} has $bars bars');
        }
        expect(r.sheet.every((l) => l.beats.isNotEmpty), isTrue,
            reason: '${r.id} has an empty line');
        expect(sheetBars(r), lessThanOrEqualTo(64),
            reason: '${r.id} sheet too long');
      }
    });
    test('the twelve rudiment sheets: 8 lines + Challenge, lesson sections',
        () {
      // Katalog 3a: the twelve rudiments composed as sheets.
      const ids = [
        'single_stroke_roll',
        'double_stroke_roll',
        'single_paradiddle',
        'double_paradiddle',
        'paradiddle_diddle',
        'flam',
        'flam_accent',
        'flam_tap',
        'single_drag',
        'five_stroke_roll',
        'seven_stroke_roll',
        'swiss_army_triplet',
      ];
      const beginner = [
        'single_stroke_roll',
        'double_stroke_roll',
        'single_paradiddle'
      ];
      for (final id in ids) {
        final r = rudimentsSeedData.firstWhere((r) => r.id == id);
        expect(r.sheet.length, 9, reason: id);
        expect(r.sheet.take(8).every((l) => l.repeat), isTrue, reason: id);
        expect(r.sheet.take(8).every((l) => l.beats.isNotEmpty), isTrue);
        expect(r.sheet.last.repeat, isFalse, reason: id);
        expect(r.sheet.last.title, 'Challenge', reason: id);
        expect(sheetBars(r), 24, reason: id);
        // The plain pattern is one whole bar — the PATTERN box.
        expect(
            barCountOrThrow(r.sticking,
                beatsPerBar: r.beatsPerBar, grid: r.gridUnit),
            1,
            reason: id);
        expect(
            r.technique.map((s) => s.title),
            [
              'Why it matters',
              'How to play it',
              'Practice tips',
              'Where you hear it'
            ],
            reason: id);
        final counts = r.sheet.take(2).every((l) => l.counts);
        expect(counts, beginner.contains(id), reason: '$id count hints');
      }
    });
    test(
        'the eight fill sheets: 3 bars of time + 1 bar of fill per line, '
        'Challenge 8 bars, the one after the fill accented, fill tag', () {
      // Katalog 3b, Brief §3.2: four-bar phrases looped, the band runs on
      // through the fill bar, success = the fill and the one after it.
      const ids = [
        'fill_sixteenth_singles',
        'fill_doubles',
        'fill_paradiddle',
        'fill_triplets',
        'fill_flams',
        'fill_sextuplets',
        'fill_six_groups',
        'fill_roll',
      ];
      const beginner = ['fill_sixteenth_singles', 'fill_doubles'];
      for (final id in ids) {
        final r = rudimentsSeedData.firstWhere((r) => r.id == id);
        expect(r.skills, contains(Skill.fill), reason: id);
        expect(r.sheet.length, 9, reason: id);
        for (var i = 0; i < 8; i++) {
          final l = r.sheet[i];
          expect(l.repeat, isTrue, reason: '$id line ${i + 1}');
          expect(
              barCountOrThrow(l.beats,
                  beatsPerBar: r.beatsPerBar, grid: r.gridUnit),
              4,
              reason: '$id line ${i + 1} is not a four-bar phrase');
          expect(l.beats.first.isAccent, isTrue,
              reason: '$id line ${i + 1} lands without an accent on the one');
        }
        expect(r.sheet.last.repeat, isFalse, reason: id);
        expect(r.sheet.last.title, 'Challenge', reason: id);
        expect(
            barCountOrThrow(r.sheet.last.beats,
                beatsPerBar: r.beatsPerBar, grid: r.gridUnit),
            8,
            reason: id);
        expect(sheetBars(r), 40, reason: id);
        // The PATTERN box shows the fill bar of line 1 — one whole bar.
        expect(
            barCountOrThrow(r.sticking,
                beatsPerBar: r.beatsPerBar, grid: r.gridUnit),
            1,
            reason: id);
        expect(
            r.technique.map((s) => s.title),
            [
              'Why it matters',
              'How to play it',
              'Practice tips',
              'Where you hear it'
            ],
            reason: id);
        final counts = r.sheet.take(2).every((l) => l.counts);
        expect(counts, beginner.contains(id), reason: '$id count hints');
      }
    });
  });

  test('every étude renders without throwing', () {
    // Structural smoke: all étude entries have a non-empty sticking + rising bpm.
    for (final r in allEtudes) {
      expect(r.sticking, isNotEmpty, reason: '${r.id} empty');
      expect(r.minBpm <= r.targetBpm, isTrue, reason: '${r.id} bpm range');
    }
  });
}
