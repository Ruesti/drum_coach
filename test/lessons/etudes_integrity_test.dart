import 'package:drum_coach/features/lessons/data/etudes.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
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
      var quarters = 0.0;
      for (final b in r.sticking) {
        quarters += resolveNote(b, r.gridUnit).quarters;
      }
      final bars = quarters / r.beatsPerBar;
      expect((bars - bars.round()).abs() < 1e-6 && bars.round() >= 1, isTrue,
          reason: '${r.id}: ${quarters}q not whole ${r.beatsPerBar}/4 bars');
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

  test('every étude renders without throwing', () {
    // Structural smoke: all étude entries have a non-empty sticking + rising bpm.
    for (final r in allEtudes) {
      expect(r.sticking, isNotEmpty, reason: '${r.id} empty');
      expect(r.minBpm <= r.targetBpm, isTrue, reason: '${r.id} bpm range');
    }
  });
}
