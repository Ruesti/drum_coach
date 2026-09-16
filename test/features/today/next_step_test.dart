import 'package:drum_coach/features/learning/models/daily_routine.dart';
import 'package:drum_coach/features/program/models/training_program.dart';
import 'package:drum_coach/features/today/next_step.dart';
import 'package:flutter_test/flutter_test.dart';

const _phase = ProgramPhase(
  index: 1,
  name: 'Foundation',
  focus: 'Both hands even.',
  weekStart: 1,
  weekEnd: 3,
  startBpm: 70,
  exerciseKey: 'single_stroke_roll',
);

ProgramDay _day({
  DayType type = DayType.practice,
  List<ExerciseBlock> blocks = const [],
}) =>
    ProgramDay(
      dayNumber: 9,
      week: 2,
      type: type,
      estimatedMinutes: 15,
      blocks: blocks,
      phase: _phase,
    );

const _blocks = [
  ExerciseBlock(
      type: BlockType.warmup,
      exerciseKey: 'single_stroke_roll',
      startBpm: 70,
      durationMinutes: 3),
  ExerciseBlock(
      type: BlockType.technique,
      exerciseKey: 'single_paradiddle',
      startBpm: 84,
      durationMinutes: 8),
  ExerciseBlock(
      type: BlockType.tempoLadder,
      exerciseKey: 'single_paradiddle',
      startBpm: 84,
      durationMinutes: 4),
];

String _name(String id) => id == 'single_paradiddle' ? 'Single Paradiddle' : id;

void main() {
  test('first open block of today is the next step', () {
    final step = computeNextStep(
        hasProgram: true,
        day: _day(blocks: _blocks),
        done: {0},
        routine: const [],
        nameOf: _name);
    expect(step.kind, PathStepKind.exercise);
    expect(step.title, 'Single Paradiddle');
    expect(step.detail, 'Day 9 · Step 2 of 3 · 84 BPM');
    expect(step.minutes, 8);
    expect(step.route, '/practice/single_paradiddle?bpm=84&min=8');
  });

  test('all blocks done → day done', () {
    final step = computeNextStep(
        hasProgram: true,
        day: _day(blocks: _blocks),
        done: {0, 1, 2},
        routine: const [],
        nameOf: _name);
    expect(step.kind, PathStepKind.dayDone);
    expect(step.route, '/program');
  });

  test('rest day has no route', () {
    final step = computeNextStep(
        hasProgram: true,
        day: _day(type: DayType.rest),
        done: const {},
        routine: const [],
        nameOf: _name);
    expect(step.kind, PathStepKind.restDay);
    expect(step.route, isNull);
  });

  test('program configured but no day → program complete', () {
    final step = computeNextStep(
        hasProgram: true,
        day: null,
        done: const {},
        routine: const [],
        nameOf: _name);
    expect(step.kind, PathStepKind.programComplete);
    expect(step.route, '/program');
  });

  test('no program: routine item first, else setup', () {
    const item = DailyRoutineItem(
        rudimentId: 'single_paradiddle',
        type: RoutineItemType.review,
        suggestedBpm: 90,
        suggestedDurationMinutes: 6);
    final withRoutine = computeNextStep(
        hasProgram: false,
        day: null,
        done: const {},
        routine: const [item],
        nameOf: _name);
    expect(withRoutine.kind, PathStepKind.exercise);
    expect(withRoutine.route, '/routine/single_paradiddle?bpm=90');
    expect(withRoutine.detail, 'Review · 90 BPM');
    expect(withRoutine.minutes, 6);
    final empty = computeNextStep(
        hasProgram: false,
        day: null,
        done: const {},
        routine: const [],
        nameOf: _name);
    expect(empty.kind, PathStepKind.setup);
    expect(empty.route, '/program/setup');
  });
}
