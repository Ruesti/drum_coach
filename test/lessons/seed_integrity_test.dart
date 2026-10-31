import 'package:drum_coach/features/lessons/data/etudes.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/room/training_area.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all rudiment ids are unique', () {
    final seen = <String>{};
    final dupes = <String>{};
    for (final r in rudimentsSeedData) {
      if (!seen.add(r.id)) dupes.add(r.id);
    }
    expect(dupes, isEmpty, reason: 'duplicate ids: $dupes');
  });

  test('every note lands on an integer 24-tick (no fractional drift)', () {
    const ticksPerQuarter = 24;
    for (final r in rudimentsSeedData) {
      for (var i = 0; i < r.sticking.length; i++) {
        final ticks =
            resolveNote(r.sticking[i], r.gridUnit).quarters * ticksPerQuarter;
        expect((ticks - ticks.roundToDouble()).abs() < 1e-6, isTrue,
            reason: '${r.id} note $i = $ticks ticks is not an integer on the '
                '24/quarter grid');
      }
    }
  });

  test('every authored sheet has eight lines and no Challenge', () {
    for (final r in rudimentsSeedData) {
      if (r.lines.isEmpty) continue;
      expect(r.lines.length, 8, reason: r.id);
      expect(r.lines.any((l) => l.title == 'Challenge'), isFalse, reason: r.id);
      expect(r.lines.every((l) => l.repeat), isTrue, reason: r.id);
    }
  });

  test('every exercise has an area', () {
    final missing = [
      for (final r in [...rudimentsSeedData, ...allEtudes])
        if (r.area == null) r.id,
    ];
    expect(missing, isEmpty, reason: 'no area: $missing');
  });

  test(
      'area counts per cell: the six core areas have a beginner or '
      'intermediate exercise', () {
    final all = [...rudimentsSeedData, ...allEtudes];
    for (final a in [
      TrainingArea.handTechnique,
      TrainingArea.rudiments,
      TrainingArea.feet,
      TrainingArea.coordination,
      TrainingArea.groove,
      TrainingArea.fills,
    ]) {
      expect(
        all.any((r) =>
            r.area == a &&
            (r.difficulty == Difficulty.beginner ||
                r.difficulty == Difficulty.intermediate)),
        isTrue,
        reason: '$a has no beginner/intermediate exercise',
      );
    }
  });
}
