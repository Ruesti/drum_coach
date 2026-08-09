import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
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
}
