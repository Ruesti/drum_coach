/// Pure derivation of which program-day blocks count as done today, from the
/// number of finished practice sessions per exercise key. Blocks sharing a
/// key (warmup and tempo ladder are often the same rudiment) are ticked off
/// in order: the nth session of a key completes the nth block using it.
library;

import 'models/training_program.dart';

Set<int> completedBlockIndices(
    List<ExerciseBlock> blocks, Map<String, int> sessionCountByKey) {
  final used = <String, int>{};
  final done = <int>{};
  for (var i = 0; i < blocks.length; i++) {
    final key = blocks[i].exerciseKey;
    final seen = used[key] ?? 0;
    if (seen < (sessionCountByKey[key] ?? 0)) {
      done.add(i);
      used[key] = seen + 1;
    }
  }
  return done;
}
