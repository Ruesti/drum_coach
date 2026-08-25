import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/program/models/program_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('totalDays = weeks × 7', () {
    const c = ProgramConfig(durationWeeks: 8, startDifficulty: Difficulty.beginner, pool: ProgramPool.mixed);
    expect(c.totalDays, 56);
  });
  test('pool labels', () {
    expect(ProgramPool.basicStrokes.label, 'Klassische Schlagübungen');
    expect(ProgramPool.rudimentEtudes.label, 'Rudiment-Étüden');
    expect(ProgramPool.techniqueStudies.label, 'Technik-Studien');
    expect(ProgramPool.padWorkouts.label, 'Pad-Workouts');
    expect(ProgramPool.mixed.label, 'Gemischt');
  });
}
