import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dart:math' as math;

import '../../data/local/isar_service.dart';
import '../../data/local/models/clean_tempo.dart';
import '../../data/local/models/rudiment_progress.dart';
import '../../data/local/settings_service.dart';
import '../lessons/lessons_provider.dart';
import '../practice/practice_provider.dart';
import 'day_completion.dart';
import 'models/program_config.dart';
import 'models/training_program.dart';
import 'program_generator.dart';

part 'program_provider.g.dart';

/// Total days in the program: 12 weeks × 7 days. Fallback default for the
/// (now rare) case where no [ProgramConfig] has been chosen yet.
const programTotalDays = 84;

/// The scheduled [DayType] for a global day number (1..totalDays) by the
/// weekly rhythm: dow 1–5 practice, 6 light, 7 rest (§1). Shared by both the
/// legacy fixed-program rhythm and the adaptive builder in
/// `program_generator.dart`.
DayType dayTypeForDayNumber(int dayNumber) {
  final dow = ((dayNumber - 1) % 7) + 1;
  if (dow <= 5) return DayType.practice;
  if (dow == 6) return DayType.light;
  return DayType.rest;
}

/// The global day number for a calendar [date] given the program [start] date
/// and the program's [totalDays] window, or null if [date] falls outside it.
int? dayNumberOn(DateTime start, DateTime date, int totalDays) {
  final startDay = DateTime(start.year, start.month, start.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = d.difference(startDay).inDays;
  if (diff < 0 || diff >= totalDays) return null;
  return diff + 1;
}

/// Whether [date] is a scheduled rest day of the program started on [start],
/// within a [totalDays] window. Used by the streak logic so intentional rest
/// days don't break the streak.
bool isScheduledRestDay(DateTime start, DateTime date, int totalDays) {
  final dn = dayNumberOn(start, date, totalDays);
  return dn != null && dayTypeForDayNumber(dn) == DayType.rest;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// A lightweight description of the current adaptive program run, built from
/// the persisted [ProgramConfig]. `phases` is intentionally empty — the
/// adaptive program has no fixed phase list; per-day content comes from
/// [currentProgramDay] instead.
@riverpod
TrainingProgram trainingProgram(TrainingProgramRef ref) {
  final config = SettingsService.programConfig;
  return TrainingProgram(
    name: 'Adaptives Programm',
    description: config == null
        ? 'Wähle Dauer, Startniveau und Übungspool, um dein persönliches '
            'Programm zu starten.'
        : 'Passt sich automatisch an dein Tempo an — Pool: '
            '${config.pool.label}, Start: ${config.startDifficulty.label}.',
    totalWeeks: config?.durationWeeks ?? 12,
    phases: const [],
  );
}

/// Stored clean tempos keyed by exercise key (the last clean tempo per line).
@riverpod
class CleanTempoNotifier extends _$CleanTempoNotifier {
  @override
  Future<Map<String, int>> build() async {
    final rows = await IsarService.instance.cleanTempos
        .buildQuery<CleanTempo>()
        .findAll();
    return {for (final r in rows) r.exerciseKey: r.bpm};
  }

  /// Records a clean pass: lifts the stored clean tempo for [exerciseKey] to
  /// [ladderStartBpm] + 4 (§6), never lowering an already higher value.
  /// Idempotent per unique-indexed exercise key.
  Future<void> recordCleanPass(String exerciseKey, int ladderStartBpm) async {
    final isar = IsarService.instance;
    final next = ladderStartBpm + 4;
    await isar.writeTxn(() async {
      final all =
          await isar.cleanTempos.buildQuery<CleanTempo>().findAll();
      final existing =
          all.where((r) => r.exerciseKey == exerciseKey).firstOrNull;
      final row = existing ?? CleanTempo();
      row.exerciseKey = exerciseKey;
      row.bpm = math.max(existing?.bpm ?? 0, next);
      await isar.cleanTempos.put(row);
    });
    ref.invalidateSelf();
  }
}

/// A single expanded program day for the current adaptive stage, with the
/// stored clean tempo folded in. Kept only for its generated provider
/// signature (family, non-nullable `Future<ProgramDay>`) — [currentProgramDay]
/// builds the day directly now and no longer routes through this provider,
/// so it throws if invoked with no config/stages rather than returning a
/// meaningless day for an arbitrary [dayNumber].
@riverpod
Future<ProgramDay> programDay(ProgramDayRef ref, int dayNumber) async {
  final config = SettingsService.programConfig;
  if (config == null) {
    throw StateError('programDay: no ProgramConfig configured');
  }
  final pool = programPoolExercises(ref.watch(rudimentsProvider), config.pool);
  final stages = effectiveStages(pool, config.startDifficulty);
  if (stages.isEmpty) {
    throw StateError('programDay: no exercises available for this config');
  }
  final stageIndex = SettingsService.programStageIndex.clamp(0, stages.length - 1);
  final stageExercises = exercisesForStage(pool, stages[stageIndex]);
  final clean = await ref.watch(cleanTempoNotifierProvider.future);
  return buildAdaptiveProgramDay(
    stageExercises: stageExercises,
    stage: stages[stageIndex],
    dayNumber: dayNumber,
    totalDays: config.totalDays,
    cleanBpmFor: (k) => clean[k],
  );
}

/// The current program day derived from the stored config + start date, or
/// null if the program has not been started, has no config, has no exercises
/// for the configured pool/difficulty, or has run past its final day.
@riverpod
Future<ProgramDay?> currentProgramDay(CurrentProgramDayRef ref) async {
  final config = SettingsService.programConfig;
  final start = SettingsService.programStartDate;
  if (config == null || start == null) return null;

  final dayNumber = dayNumberOn(start, DateTime.now(), config.totalDays);
  if (dayNumber == null) return null; // program finished / before start

  final pool = programPoolExercises(ref.watch(rudimentsProvider), config.pool);
  final stages = effectiveStages(pool, config.startDifficulty);
  if (stages.isEmpty) return null; // no exercises for this pool/difficulty

  final stageIndex = SettingsService.programStageIndex.clamp(0, stages.length - 1);
  final stageExercises = exercisesForStage(pool, stages[stageIndex]);

  // Daily technique rotation over everything from the start difficulty up to
  // the current stage — not just the current tier — for variety.
  final techniquePool = pool
      .where((r) =>
          r.difficulty.index >= config.startDifficulty.index &&
          r.difficulty.index <= stages[stageIndex].index)
      .toList();

  // Refresh after every finished session: the ladder gate below reads the
  // per-exercise BPM progression, which each session's rating updates.
  ref.watch(recentSessionsProvider);
  final clean = await ref.watch(cleanTempoNotifierProvider.future);
  final progressBpm = <String, int>{};
  try {
    final rows = await IsarService.instance.rudimentProgress
        .buildQuery<RudimentProgress>()
        .findAll();
    for (final p in rows) {
      progressBpm[p.exerciseId] = p.currentBpm;
    }
  } catch (_) {} // store unavailable (tests) — fall back to clean/minBpm

  return buildAdaptiveProgramDay(
    stageExercises: stageExercises,
    stage: stages[stageIndex],
    dayNumber: dayNumber,
    totalDays: config.totalDays,
    // Ladder gate: stored clean tempo, else the tempo the learner actually
    // practices at (BPM progression), else the exercise minimum.
    cleanBpmFor: (k) => clean[k] ?? progressBpm[k],
    techniquePool: techniquePool,
  );
}

/// Which of today's program-day blocks already count as done, derived from
/// today's finished practice sessions (ordinal per exercise key — see
/// [completedBlockIndices]). Empty when no program day is active.
@riverpod
Future<Set<int>> programDayCompletion(ProgramDayCompletionRef ref) async {
  final day = await ref.watch(currentProgramDayProvider.future);
  if (day == null || day.blocks.isEmpty) return const {};
  final sessions = await ref.watch(recentSessionsProvider.future);
  final now = DateTime.now();
  final counts = <String, int>{};
  for (final s in sessions) {
    if (s.date.year == now.year &&
        s.date.month == now.month &&
        s.date.day == now.day) {
      counts[s.exerciseId] = (counts[s.exerciseId] ?? 0) + 1;
    }
  }
  return completedBlockIndices(day.blocks, counts);
}

/// Controls program lifecycle (start / reset / stage advance).
@riverpod
class ProgramController extends _$ProgramController {
  @override
  void build() {}

  /// Starts a fresh adaptive program run with config [c]: persists it, resets
  /// the stage index to the first stage, anchors day 1 on today, and
  /// refreshes the current-day provider.
  Future<void> startWithConfig(ProgramConfig c) async {
    await SettingsService.setProgramConfig(c);
    await SettingsService.setProgramStageIndex(0);
    await SettingsService.setProgramStartDate(DateTime.now());
    ref.invalidate(currentProgramDayProvider);
    ref.invalidate(trainingProgramProvider);
  }

  Future<void> reset() async {
    await SettingsService.clearProgramStartDate();
    await SettingsService.clearProgramConfig();
    ref.invalidate(currentProgramDayProvider);
    ref.invalidate(trainingProgramProvider);
  }

  /// Advances to the next difficulty stage if the current stage's focus
  /// exercise is ready (stored clean tempo at target, or tracked mastery
  /// proficient+). Returns whether it advanced, so the caller can show a
  /// level-up UI. No-op (returns false) with no config or at the last stage.
  Future<bool> advanceStageIfReady() async {
    final config = SettingsService.programConfig;
    if (config == null) return false;

    final pool =
        programPoolExercises(ref.read(rudimentsProvider), config.pool);
    final stages = effectiveStages(pool, config.startDifficulty);
    if (stages.isEmpty) return false;

    final stageIndex =
        SettingsService.programStageIndex.clamp(0, stages.length - 1);
    if (stageIndex >= stages.length - 1) return false; // already at the top

    final stageExercises = exercisesForStage(pool, stages[stageIndex]);
    final focus = stageFocus(stageExercises);

    final clean = await ref.read(cleanTempoNotifierProvider.future);
    final progress = await IsarService.instance.rudimentProgress
        .buildQuery<RudimentProgress>()
        .findAll();
    final mastery =
        progress.where((p) => p.exerciseId == focus.id).firstOrNull?.mastery;

    if (!isStageComplete(focus, cleanBpm: clean[focus.id], mastery: mastery)) {
      return false;
    }

    await SettingsService.setProgramStageIndex(stageIndex + 1);
    ref.invalidate(currentProgramDayProvider);
    return true;
  }
}
