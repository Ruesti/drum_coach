/// Pure generator for the adaptive training program (SP4): pool selection,
/// difficulty stages, and (later tasks) readiness gating + day building.
/// No I/O — fully unit-testable.
library;

import '../lessons/models/rudiment.dart';
import 'models/program_config.dart';

/// The exercises drawn from [all] for the given [pool]. `basicStrokes` = base
/// catalog (no [Rudiment.collection]); `newExercises` = collection content
/// (étude/technique-study collections); `mixed` = everything.
List<Rudiment> programPoolExercises(List<Rudiment> all, ProgramPool pool) =>
    switch (pool) {
      ProgramPool.basicStrokes => all.where((r) => r.collection == null).toList(),
      ProgramPool.newExercises => all.where((r) => r.collection != null).toList(),
      ProgramPool.mixed => List<Rudiment>.of(all),
    };

/// The exercises of [poolExercises] at exactly [stage] difficulty.
List<Rudiment> exercisesForStage(List<Rudiment> poolExercises, Difficulty stage) =>
    poolExercises.where((r) => r.difficulty == stage).toList();

/// Difficulty tiers from [start] up to professional that actually have
/// exercises in [poolExercises] (empty tiers are skipped).
List<Difficulty> effectiveStages(List<Rudiment> poolExercises, Difficulty start) {
  final out = <Difficulty>[];
  for (final d in Difficulty.values) {
    if (d.index < start.index) continue;
    if (exercisesForStage(poolExercises, d).isNotEmpty) out.add(d);
  }
  return out;
}

/// The stable focus exercise of a stage (first in list).
Rudiment stageFocus(List<Rudiment> stageExercises) => stageExercises.first;
