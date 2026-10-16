import 'package:drum_coach/features/learning/routine_provider.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/kit_fixtures.dart';

void main() {
  test('the new-rudiment pick never lands on a kit exercise', () {
    final catalog = [...rudimentsSeedData, kitShowcase()];
    final started = {
      for (final r in catalog)
        if (!r.isKit) r.id,
    };
    // Only kit exercises are left: nothing to suggest.
    expect(pickNewRudiment(catalog, started), isNull);
    // One pad exercise left: that one, not the kit.
    final lastPad = rudimentsSeedData.lastWhere((r) => !r.isKit);
    started.remove(lastPad.id);
    expect(pickNewRudiment(catalog, started)?.id, lastPad.id);
    // A kit exercise ahead in the catalog is skipped, too.
    expect(pickNewRudiment([kitShowcase(), ...rudimentsSeedData], {})?.isKit,
        isFalse);
  });

  test('ties in difficulty fall back to seed order', () {
    final first = rudimentsSeedData
        .where((r) => r.difficulty == Difficulty.beginner && !r.isKit)
        .first;
    expect(pickNewRudiment(rudimentsSeedData, {})?.id, first.id);
    final started = {first.id};
    final second = rudimentsSeedData
        .where((r) =>
            r.difficulty == Difficulty.beginner &&
            !r.isKit &&
            !started.contains(r.id))
        .first;
    expect(pickNewRudiment(rudimentsSeedData, started)?.id, second.id);
    // Repeatable.
    expect(pickNewRudiment(rudimentsSeedData, started)?.id, second.id);
  });
}
