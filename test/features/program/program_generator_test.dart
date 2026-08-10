import 'package:drum_coach/data/local/models/rudiment_progress.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/program/models/program_config.dart';
import 'package:drum_coach/features/program/program_generator.dart';
import 'package:drum_coach/features/program/models/training_program.dart';
import 'package:drum_coach/features/program/program_provider.dart' show dayTypeForDayNumber;
import 'package:flutter_test/flutter_test.dart';

Rudiment _r(String id, Difficulty d, {ExerciseCollection? c}) => Rudiment(
    id: id, name: id, description: '', minBpm: 60, targetBpm: 120,
    difficulty: d, sticking: const [StrokeBeat(hand: Hand.right)], collection: c);

void main() {
  final all = [
    _r('base_b', Difficulty.beginner),
    _r('base_i', Difficulty.intermediate),
    _r('etu_b', Difficulty.beginner, c: ExerciseCollection.rudimentEtudes),
    _r('etu_a', Difficulty.advanced, c: ExerciseCollection.rudimentEtudes),
  ];

  group('programPoolExercises', () {
    test('pool filtering', () {
      expect(programPoolExercises(all, ProgramPool.basicStrokes).map((r) => r.id), ['base_b', 'base_i']);
      expect(programPoolExercises(all, ProgramPool.newExercises).map((r) => r.id), ['etu_b', 'etu_a']);
      expect(programPoolExercises(all, ProgramPool.mixed).length, 4);
    });
  });

  group('exercisesForStage', () {
    test('filters by difficulty', () {
      final pool = programPoolExercises(all, ProgramPool.mixed);
      expect(exercisesForStage(pool, Difficulty.beginner).map((r) => r.id), ['base_b', 'etu_b']);
    });
  });

  group('effectiveStages', () {
    test('skips empty tiers', () {
      final pool = programPoolExercises(all, ProgramPool.newExercises); // beginner + advanced only
      expect(effectiveStages(pool, Difficulty.beginner),
          [Difficulty.beginner, Difficulty.advanced]); // intermediate + professional empty → skipped
    });
  });

  group('stageFocus', () {
    test('is the first exercise', () {
      final pool = programPoolExercises(all, ProgramPool.mixed);
      expect(stageFocus(exercisesForStage(pool, Difficulty.beginner)).id, 'base_b');
    });
  });

  group('isStageComplete', () {
    final f = _r('f', Difficulty.beginner); // targetBpm 120
    test('ready when clean tempo reached target', () {
      expect(isStageComplete(f, cleanBpm: 120, mastery: null), isTrue);
      expect(isStageComplete(f, cleanBpm: 119, mastery: null), isFalse);
    });
    test('ready when mastery proficient+', () {
      expect(isStageComplete(f, cleanBpm: null, mastery: MasteryLevel.proficient), isTrue);
      expect(isStageComplete(f, cleanBpm: null, mastery: MasteryLevel.developing), isFalse);
    });
    test('not ready with no signals', () {
      expect(isStageComplete(f, cleanBpm: null, mastery: null), isFalse);
    });
  });

  group('dayTypeForDayNumber — weekly rhythm (surviving pure helper)', () {
    test('dow 1-5 practice, 6 light, 7 rest', () {
      expect(dayTypeForDayNumber(1), DayType.practice);
      expect(dayTypeForDayNumber(5), DayType.practice);
      expect(dayTypeForDayNumber(6), DayType.light);
      expect(dayTypeForDayNumber(7), DayType.rest);
    });

    test('rhythm repeats every week (day 8 = dow 1 = practice)', () {
      expect(dayTypeForDayNumber(8), DayType.practice);
      expect(dayTypeForDayNumber(13), DayType.light);
      expect(dayTypeForDayNumber(14), DayType.rest);
    });
  });
}
