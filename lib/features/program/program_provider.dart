import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/isar_service.dart';
import '../../data/local/models/clean_tempo.dart';
import '../../data/local/settings_service.dart';
import 'data/stick_control_program.dart';
import 'models/training_program.dart';

part 'program_provider.g.dart';

/// Total days in the program: 12 weeks × 7 days.
const programTotalDays = 84;

// ---------------------------------------------------------------------------
// Pure generator (STICK_CONTROL_PROGRAM.md §5) — no I/O, fully unit-testable.
// ---------------------------------------------------------------------------

/// Technique variants per phase (§5).
List<Variant> _techniqueVariants(int phaseIndex) => switch (phaseIndex) {
      1 => const [Variant.even, Variant.pp, Variant.ff, Variant.crescendo],
      2 => const [Variant.fingers, Variant.rebound],
      3 => const [Variant.accentTap, Variant.even],
      4 => const [Variant.even, Variant.endurance],
      _ => const [Variant.even],
    };

/// The exercise line for a day. Phase 4 rotates the line per week (§9.3);
/// every other phase uses its fixed [ProgramPhase.exerciseKey].
String exerciseKeyFor(ProgramPhase phase, int week) {
  if (phase.index == 4) {
    return const {10: scSingles, 11: scDoubles, 12: scParadiddle}[week] ??
        phase.exerciseKey;
  }
  return phase.exerciseKey;
}

/// The scheduled [DayType] for a global day number (1..84) by the weekly
/// rhythm: dow 1–5 practice, 6 light, 7 rest (§1).
DayType dayTypeForDayNumber(int dayNumber) {
  final dow = ((dayNumber - 1) % 7) + 1;
  if (dow <= 5) return DayType.practice;
  if (dow == 6) return DayType.light;
  return DayType.rest;
}

/// Expands a single [ProgramDay] from the program definition + weekly rhythm
/// (§5). Pure: [cleanBpmFor] returns the stored clean tempo for an exercise
/// key (or null → the phase start tempo is used).
ProgramDay buildProgramDay(
  TrainingProgram program,
  int dayNumber, {
  int? Function(String exerciseKey)? cleanBpmFor,
}) {
  assert(dayNumber >= 1 && dayNumber <= programTotalDays);
  final week = ((dayNumber - 1) ~/ 7) + 1;
  final phase = program.phaseForWeek(week);
  final exerciseKey = exerciseKeyFor(phase, week);
  final type = dayTypeForDayNumber(dayNumber);

  List<ExerciseBlock> blocks;
  int estimatedMinutes;
  switch (type) {
    case DayType.practice:
      final ladderStart =
          cleanBpmFor?.call(exerciseKey) ?? phase.startBpm;
      blocks = [
        const ExerciseBlock(
          type: BlockType.warmup,
          exerciseKey: scSingles, // loose single strokes, low tempo (§3)
          variants: [Variant.even],
          durationMinutes: 3,
        ),
        ExerciseBlock(
          type: BlockType.technique,
          exerciseKey: exerciseKey,
          variants: _techniqueVariants(phase.index),
          durationMinutes: 8,
        ),
        ExerciseBlock(
          type: BlockType.tempoLadder,
          exerciseKey: exerciseKey,
          startBpm: ladderStart,
          durationMinutes: 4,
          cleanPassRequired: true,
        ),
      ];
      estimatedMinutes = 15;
    case DayType.light:
      blocks = [
        const ExerciseBlock(
          type: BlockType.warmup,
          exerciseKey: scSingles,
          variants: [Variant.even],
          durationMinutes: 3,
        ),
        ExerciseBlock(
          type: BlockType.technique,
          exerciseKey: exerciseKey,
          variants: _techniqueVariants(phase.index),
          startBpm: phase.startBpm, // deep tempo, no ladder (§3)
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

@riverpod
TrainingProgram trainingProgram(TrainingProgramRef ref) => stickControlProgram;

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
  /// [ladderStartBpm] + 4 (§6). Idempotent per unique-indexed exercise key.
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
      row.bpm = next;
      await isar.cleanTempos.put(row);
    });
    ref.invalidateSelf();
  }
}

/// A single expanded program day, with the stored clean tempo folded in.
@riverpod
Future<ProgramDay> programDay(ProgramDayRef ref, int dayNumber) async {
  final program = ref.watch(trainingProgramProvider);
  final clean = await ref.watch(cleanTempoNotifierProvider.future);
  return buildProgramDay(program, dayNumber, cleanBpmFor: (k) => clean[k]);
}

/// The current program day derived from the stored start date, or null if the
/// program has not been started (or has run past its final day).
@riverpod
Future<ProgramDay?> currentProgramDay(CurrentProgramDayRef ref) async {
  final start = SettingsService.programStartDate;
  if (start == null) return null;
  final totalDays = SettingsService.programConfig?.totalDays ?? programTotalDays;
  final dayNumber = dayNumberOn(start, DateTime.now(), totalDays);
  if (dayNumber == null) return null; // program finished / before start
  return ref.watch(programDayProvider(dayNumber).future);
}

/// Controls program lifecycle (start / reset).
@riverpod
class ProgramController extends _$ProgramController {
  @override
  void build() {}

  Future<void> start() async {
    await SettingsService.setProgramStartDate(DateTime.now());
    ref.invalidate(currentProgramDayProvider);
  }

  Future<void> reset() async {
    await SettingsService.clearProgramStartDate();
    ref.invalidate(currentProgramDayProvider);
  }
}
