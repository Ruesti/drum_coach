import '../../lessons/models/rudiment.dart';

/// Which exercises the program draws from. One entry per source (the base
/// catalog plus each [ExerciseCollection]), plus [mixed] for everything.
enum ProgramPool { basicStrokes, rudimentEtudes, techniqueStudies, padWorkouts, mixed }

extension ProgramPoolLabel on ProgramPool {
  String get label => switch (this) {
        ProgramPool.basicStrokes => 'Classic stroke exercises',
        ProgramPool.rudimentEtudes => 'Rudiment Etudes',
        ProgramPool.techniqueStudies => 'Technique Studies',
        ProgramPool.padWorkouts => 'Pad Workouts',
        ProgramPool.mixed => 'Mixed',
      };
}

/// User-chosen program configuration (persisted).
class ProgramConfig {
  final int durationWeeks; // pacing target
  final Difficulty startDifficulty;
  final ProgramPool pool;
  const ProgramConfig({
    required this.durationWeeks,
    required this.startDifficulty,
    required this.pool,
  });

  int get totalDays => durationWeeks * 7;
}
