import '../../lessons/models/rudiment.dart';

/// Which exercises the program draws from.
enum ProgramPool { basicStrokes, newExercises, mixed }

extension ProgramPoolLabel on ProgramPool {
  String get label => switch (this) {
        ProgramPool.basicStrokes => 'Klassische Schlagübungen',
        ProgramPool.newExercises => 'Neue Übungen',
        ProgramPool.mixed => 'Gemischt',
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
