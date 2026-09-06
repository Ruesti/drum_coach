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
      expect(programPoolExercises(all, ProgramPool.rudimentEtudes).map((r) => r.id), ['etu_b', 'etu_a']);
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
      final pool = programPoolExercises(all, ProgramPool.rudimentEtudes); // beginner + advanced only
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

  group('buildAdaptiveProgramDay', () {
    const stage = Difficulty.beginner;
    final stageExercises = [
      _r('ex_a', Difficulty.beginner), // minBpm 60, targetBpm 120 (stageFocus)
      _r('ex_b', Difficulty.beginner),
      _r('ex_c', Difficulty.beginner),
    ];

    test(
        'practice day: warmup + technique + tempoLadder; technique rotates; '
        'ladder is on the focus, starting at focus.minBpm with no stored clean tempo',
        () {
      final day = buildAdaptiveProgramDay(
        stageExercises: stageExercises,
        stage: stage,
        dayNumber: 1, // dow 1 -> practice
        totalDays: 56,
      );
      expect(day.dayNumber, 1);
      expect(day.type, DayType.practice);
      expect(day.blocks.map((b) => b.type),
          [BlockType.warmup, BlockType.technique, BlockType.tempoLadder]);
      expect(day.blocks[0].exerciseKey, 'single_stroke_roll');
      // technique line rotates: stageExercises[dayNumber % stageExercises.length]
      // = stageExercises[1 % 3] = ex_b
      expect(day.blocks[1].exerciseKey, 'ex_b');
      final ladder = day.blocks[2];
      expect(ladder.exerciseKey, 'ex_a'); // stageFocus = first exercise
      expect(ladder.startBpm, 60); // focus.minBpm, no cleanBpmFor
      expect(ladder.cleanPassRequired, isTrue);
      expect(day.phase.name, Difficulty.beginner.label);
      expect(day.phase.startBpm, 60);
    });

    test('tempo ladder uses the stored clean tempo for the focus when provided', () {
      final day = buildAdaptiveProgramDay(
        stageExercises: stageExercises,
        stage: stage,
        dayNumber: 1,
        totalDays: 56,
        cleanBpmFor: (id) => id == 'ex_a' ? 96 : null,
      );
      expect(day.blocks.last.startBpm, 96);
    });

    test('light day: warmup + technique only, no tempo ladder', () {
      final day = buildAdaptiveProgramDay(
        stageExercises: stageExercises,
        stage: stage,
        dayNumber: 6, // dow 6 -> light
        totalDays: 56,
      );
      expect(day.type, DayType.light);
      expect(day.blocks.map((b) => b.type), [BlockType.warmup, BlockType.technique]);
    });

    test('rest day: no blocks', () {
      final day = buildAdaptiveProgramDay(
        stageExercises: stageExercises,
        stage: stage,
        dayNumber: 7, // dow 7 -> rest
        totalDays: 56,
      );
      expect(day.type, DayType.rest);
      expect(day.blocks, isEmpty);
    });
  });

  group('programPacing', () {
    test('ahead: stageIndex is beyond the expected stage for the nominal week', () {
      final p = programPacing(durationWeeks: 8, totalStages: 4, stageIndex: 1, dayNumber: 1);
      expect(p.nominalWeek, 1);
      expect(p.totalStages, 4);
      expect(p.expectedStageIndex, 0);
      expect(p.status, PacingStatus.ahead);
    });

    test('onTrack: stageIndex matches the expected stage', () {
      final p = programPacing(durationWeeks: 8, totalStages: 4, stageIndex: 1, dayNumber: 15);
      expect(p.nominalWeek, 3);
      expect(p.expectedStageIndex, 1);
      expect(p.status, PacingStatus.onTrack);
    });

    test('behind: stageIndex lags the expected stage', () {
      final p = programPacing(durationWeeks: 8, totalStages: 4, stageIndex: 0, dayNumber: 29);
      expect(p.nominalWeek, 5);
      expect(p.expectedStageIndex, 2);
      expect(p.status, PacingStatus.behind);
    });

    test('expectedStageIndex clamps to totalStages - 1 past the nominal end', () {
      final p = programPacing(durationWeeks: 8, totalStages: 4, stageIndex: 3, dayNumber: 57);
      expect(p.nominalWeek, 9);
      expect(p.expectedStageIndex, 3); // unclamped would be 4
      expect(p.status, PacingStatus.onTrack);
    });
  });

  group('variety (Gerätetest-Feedback: gleiche Übungen jeden Tag)', () {
    final stageExercises = [
      _r('ex_a', Difficulty.beginner),
      _r('ex_b', Difficulty.beginner),
    ];
    final techniquePool = [
      _r('ex_a', Difficulty.beginner),
      _r('ex_b', Difficulty.beginner),
      _r('ex_c', Difficulty.beginner),
      _r('ex_d', Difficulty.beginner),
      _r('ex_e', Difficulty.beginner),
    ];

    test('technique rotates over the wider techniquePool when given', () {
      final keys = [
        for (final dayNumber in [1, 2, 3, 4, 5])
          buildAdaptiveProgramDay(
            stageExercises: stageExercises,
            stage: Difficulty.beginner,
            dayNumber: dayNumber,
            totalDays: 56,
            techniquePool: techniquePool,
          ).blocks[1].exerciseKey,
      ];
      expect(keys.toSet(), {'ex_a', 'ex_b', 'ex_c', 'ex_d', 'ex_e'});
    });

    test('warmup variant changes from one practice day to the next', () {
      ExerciseBlock warmupOn(int dayNumber) => buildAdaptiveProgramDay(
            stageExercises: stageExercises,
            stage: Difficulty.beginner,
            dayNumber: dayNumber,
            totalDays: 56,
          ).blocks[0];
      expect(warmupOn(1).variants, isNot(warmupOn(2).variants));
    });

    test('empty techniquePool falls back to the stage exercises', () {
      final day = buildAdaptiveProgramDay(
        stageExercises: stageExercises,
        stage: Difficulty.beginner,
        dayNumber: 1,
        totalDays: 56,
        techniquePool: const [],
      );
      expect(day.blocks[1].exerciseKey, 'ex_b');
    });
  });
}
