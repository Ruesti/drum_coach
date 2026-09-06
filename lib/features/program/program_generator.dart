/// Pure generator for the adaptive training program (SP4): pool selection,
/// difficulty stages, and (later tasks) readiness gating + day building.
/// No I/O — fully unit-testable.
library;

import '../../data/local/models/rudiment_progress.dart';
import '../lessons/models/rudiment.dart';
import 'models/program_config.dart';
import 'models/training_program.dart';
import 'program_provider.dart' show dayTypeForDayNumber;

/// The exercises drawn from [all] for the given [pool]. `basicStrokes` = base
/// catalog (no [Rudiment.collection]); each other named pool = exactly that
/// [ExerciseCollection]; `mixed` = everything.
List<Rudiment> programPoolExercises(List<Rudiment> all, ProgramPool pool) =>
    switch (pool) {
      ProgramPool.basicStrokes => all.where((r) => r.collection == null).toList(),
      ProgramPool.rudimentEtudes =>
        all.where((r) => r.collection == ExerciseCollection.rudimentEtudes).toList(),
      ProgramPool.techniqueStudies =>
        all.where((r) => r.collection == ExerciseCollection.techniqueStudies).toList(),
      ProgramPool.padWorkouts =>
        all.where((r) => r.collection == ExerciseCollection.padWorkouts).toList(),
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

/// Whether the stage's [focus] exercise is ready to advance: either the
/// stored clean tempo reached its target, or tracked mastery is proficient+.
bool isStageComplete(Rudiment focus,
        {required int? cleanBpm, required MasteryLevel? mastery}) =>
    (cleanBpm != null && cleanBpm >= focus.targetBpm) ||
    (mastery != null && mastery.index >= MasteryLevel.proficient.index);

// ---------------------------------------------------------------------------
// Adaptive day builder + pacing
// ---------------------------------------------------------------------------

/// A short German focus hint shown alongside the stage name (§9.2-style
/// one-thought cue, adapted for the adaptive program's per-difficulty stages).
String _stageHint(Difficulty stage) => switch (stage) {
      Difficulty.beginner => 'Saubere Grundschläge',
      Difficulty.intermediate => 'Kontrolle bei Tempo',
      Difficulty.advanced => 'Präzision unter Druck',
      Difficulty.professional => 'Musikalische Anwendung',
    };

/// Daily rotation of warmup variants so the fixed single-stroke warmup still
/// feels different every practice day (§4 variants).
const _warmupVariants = [
  Variant.even,
  Variant.accentTap,
  Variant.pp,
  Variant.crescendo,
  Variant.ff,
];

/// Expands a single [ProgramDay] from the current stage's exercises, using
/// the existing weekly practice/light/rest rhythm ([dayTypeForDayNumber]).
/// Pure: [cleanBpmFor] returns the stored clean tempo for an exercise id (or
/// null → the focus exercise's [Rudiment.minBpm] is used). [techniquePool]
/// (default: the stage's own exercises) widens the daily technique rotation —
/// e.g. to every pool exercise up to the current stage — so consecutive days
/// don't cycle through the same two or three lines.
ProgramDay buildAdaptiveProgramDay({
  required List<Rudiment> stageExercises,
  required Difficulty stage,
  required int dayNumber,
  required int totalDays,
  int? Function(String id)? cleanBpmFor,
  List<Rudiment>? techniquePool,
}) {
  assert(dayNumber >= 1 && dayNumber <= totalDays);
  assert(stageExercises.isNotEmpty);

  final focus = stageFocus(stageExercises);
  final rotation =
      (techniquePool == null || techniquePool.isEmpty) ? stageExercises : techniquePool;
  final technique = rotation[dayNumber % rotation.length];
  final warmupVariant = _warmupVariants[dayNumber % _warmupVariants.length];
  final type = dayTypeForDayNumber(dayNumber);
  final week = ((dayNumber - 1) ~/ 7) + 1;
  final totalWeeks = ((totalDays - 1) ~/ 7) + 1;

  final phase = ProgramPhase(
    index: stage.index + 1,
    name: stage.label,
    focus: _stageHint(stage),
    weekStart: week,
    weekEnd: totalWeeks,
    startBpm: focus.minBpm,
    exerciseKey: focus.id,
  );

  List<ExerciseBlock> blocks;
  int estimatedMinutes;
  switch (type) {
    case DayType.practice:
      blocks = [
        ExerciseBlock(
          type: BlockType.warmup,
          exerciseKey: 'single_stroke_roll',
          variants: [warmupVariant],
          durationMinutes: 3,
        ),
        ExerciseBlock(
          type: BlockType.technique,
          exerciseKey: technique.id,
          variants: const [Variant.even],
          durationMinutes: 8,
        ),
        ExerciseBlock(
          type: BlockType.tempoLadder,
          exerciseKey: focus.id,
          startBpm: cleanBpmFor?.call(focus.id) ?? focus.minBpm,
          durationMinutes: 4,
          cleanPassRequired: true,
        ),
      ];
      estimatedMinutes = 15;
    case DayType.light:
      blocks = [
        const ExerciseBlock(
          type: BlockType.warmup,
          exerciseKey: 'single_stroke_roll',
          variants: [Variant.even],
          durationMinutes: 3,
        ),
        ExerciseBlock(
          type: BlockType.technique,
          exerciseKey: technique.id,
          variants: const [Variant.even],
          startBpm: focus.minBpm,
          durationMinutes: 5,
        ),
      ];
      estimatedMinutes = 8;
    case DayType.rest:
      blocks = const [];
      estimatedMinutes = 0;
  }

  return ProgramDay(
    dayNumber: dayNumber,
    week: week,
    type: type,
    estimatedMinutes: estimatedMinutes,
    blocks: blocks,
    phase: phase,
  );
}

/// Where the learner stands relative to the nominal pacing of the program.
enum PacingStatus { behind, onTrack, ahead }

/// A snapshot of adaptive-program pacing: how far the learner should
/// nominally be (by calendar time) vs. where they actually are (by stage).
class ProgramPacing {
  final int nominalWeek;
  final int totalStages;
  final int expectedStageIndex;
  final PacingStatus status;

  const ProgramPacing({
    required this.nominalWeek,
    required this.totalStages,
    required this.expectedStageIndex,
    required this.status,
  });
}

/// Compares the learner's actual [stageIndex] to the stage nominally expected
/// at [dayNumber], given a [durationWeeks] target and [totalStages] in the
/// current run. Pure — no I/O.
ProgramPacing programPacing({
  required int durationWeeks,
  required int totalStages,
  required int stageIndex,
  required int dayNumber,
}) {
  final nominalWeek = ((dayNumber - 1) ~/ 7) + 1;
  final expectedStageIndex =
      ((nominalWeek - 1) * totalStages ~/ durationWeeks).clamp(0, totalStages - 1);
  final status = stageIndex > expectedStageIndex
      ? PacingStatus.ahead
      : stageIndex < expectedStageIndex
          ? PacingStatus.behind
          : PacingStatus.onTrack;
  return ProgramPacing(
    nominalWeek: nominalWeek,
    totalStages: totalStages,
    expectedStageIndex: expectedStageIndex,
    status: status,
  );
}
