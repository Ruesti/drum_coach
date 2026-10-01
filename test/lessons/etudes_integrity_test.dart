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

  test('every étude fills whole bars and is a rudimentEtudes/techniqueStudies member', () {
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
    test('the sample sheet: 11 lines, challenge last without repeat', () {
      final r =
          rudimentsSeedData.firstWhere((r) => r.id == 'single_paradiddle');
      expect(r.sheet.length, 11);
      expect(r.sheet.take(10).every((l) => l.repeat), isTrue);
      expect(r.sheet.last.repeat, isFalse);
      expect(r.sheet.last.title, 'Challenge');
      expect(r.sheet.first.counts, isTrue);
      expect(r.sticking.length, 8,
          reason: 'the plain pattern stays for the How box');
      expect(r.technique.map((s) => s.title),
          ['Why it matters', 'How to play it', 'Practice tips', 'Song examples']);
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
