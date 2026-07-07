/// Value objects for the fixed multi-week "Stick Control" training program.
///
/// These are plain immutable data classes (like [DailyRoutineItem]) — NOT Isar
/// collections. The program definition lives as a `const` in
/// `data/stick_control_program.dart`, and the 84 [ProgramDay]s are expanded at
/// runtime by the generator (see `program_provider.dart`), never hard-stored.
library;

/// The kind of a day in the weekly rhythm (day 1–5 practice, 6 light, 7 rest).
enum DayType { practice, light, rest }

/// The kind of an exercise block inside a practice/light day.
enum BlockType { warmup, technique, tempoLadder, endurance }

/// A practice variation applied to the day's single line. `endurance` is used
/// by phase 4's technique block (§5); the others come from §4.
enum Variant { even, pp, ff, crescendo, fingers, rebound, accentTap, endurance }

/// One block within a [ProgramDay] (e.g. warmup, technique, tempo ladder).
class ExerciseBlock {
  final BlockType type;

  /// Which line to practice — references an existing [Rudiment.id]
  /// (`single_stroke_roll` / `double_stroke_roll` / `single_paradiddle`).
  final String exerciseKey;
  final List<Variant> variants;
  final int? startBpm;
  final int durationMinutes;

  /// When true, the tempo only rises after a self-rated clean pass (§6).
  /// Kept as a field so a later mic-based gate replaces the self-rating
  /// without changing the model.
  final bool cleanPassRequired;

  const ExerciseBlock({
    required this.type,
    required this.exerciseKey,
    this.variants = const [],
    this.startBpm,
    this.durationMinutes = 0,
    this.cleanPassRequired = false,
  });
}

/// One of the four phases of the program (the *why* + which line + start tempo).
class ProgramPhase {
  final int index; // 1..4
  final String name;

  /// The one-thought focus text shown 1:1 on the program screen (§9.2).
  final String focus;

  /// Optional second line / tooltip (the "cue" in §9.2).
  final String? focusCue;

  final int weekStart; // inclusive
  final int weekEnd; // inclusive
  final int startBpm;

  /// Default line for the phase. Phase 4 overrides this per week (§9.3).
  final String exerciseKey;

  const ProgramPhase({
    required this.index,
    required this.name,
    required this.focus,
    this.focusCue,
    required this.weekStart,
    required this.weekEnd,
    required this.startBpm,
    required this.exerciseKey,
  });
}

/// A single expanded day of the program (1..84). Produced by the generator.
class ProgramDay {
  final int dayNumber; // 1..84 (global)
  final int week; // 1..12
  final DayType type;
  final int estimatedMinutes; // 15 / 8 / 0
  final List<ExerciseBlock> blocks; // empty on rest days

  /// The phase this day belongs to (for the focus text on screen).
  final ProgramPhase phase;

  const ProgramDay({
    required this.dayNumber,
    required this.week,
    required this.type,
    required this.estimatedMinutes,
    required this.blocks,
    required this.phase,
  });
}

/// The whole curriculum: a named program with an ordered list of phases.
class TrainingProgram {
  final String name;
  final String description;
  final int totalWeeks;
  final List<ProgramPhase> phases;

  const TrainingProgram({
    required this.name,
    required this.description,
    required this.totalWeeks,
    required this.phases,
  });

  /// The phase whose [ProgramPhase.weekStart]..[ProgramPhase.weekEnd] range
  /// contains [week]. Falls back to the last phase for out-of-range weeks.
  ProgramPhase phaseForWeek(int week) {
    for (final p in phases) {
      if (week >= p.weekStart && week <= p.weekEnd) return p;
    }
    return phases.last;
  }
}
