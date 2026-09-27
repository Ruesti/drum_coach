import 'package:drum_coach/features/program/models/training_program.dart';
import 'package:drum_coach/features/program/practice_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds the practice route with bpm, min and ladder', () {
    const block = ExerciseBlock(
      type: BlockType.tempoLadder,
      exerciseKey: 'single_paradiddle',
      startBpm: 84,
      durationMinutes: 8,
    );
    expect(practiceRouteFor(block),
        '/practice/single_paradiddle?bpm=84&min=8&ladder=1');
  });

  test('omits empty parameters', () {
    const block =
        ExerciseBlock(type: BlockType.warmup, exerciseKey: 'single_stroke_roll');
    expect(practiceRouteFor(block), '/practice/single_stroke_roll');
  });

  test('carries the program phase for the practice backdrop', () {
    const block = ExerciseBlock(
      type: BlockType.technique,
      exerciseKey: 'single_paradiddle',
      startBpm: 84,
      durationMinutes: 8,
    );
    final route = practiceRouteFor(block, ctx: 'Day 9', phase: 2);
    expect(Uri.parse(route).queryParameters['phase'], '2');
    expect(Uri.parse(route).queryParameters['ctx'], 'Day 9');
  });

  test('appends the context line url-encoded', () {
    const block = ExerciseBlock(
      type: BlockType.technique,
      exerciseKey: 'single_paradiddle',
      startBpm: 84,
      durationMinutes: 8,
    );
    final route =
        practiceRouteFor(block, ctx: 'Day 9 · Step 2 of 3 · 84 BPM');
    expect(route, startsWith('/practice/single_paradiddle?bpm=84&min=8&ctx='));
    expect(Uri.parse(route).queryParameters['ctx'],
        'Day 9 · Step 2 of 3 · 84 BPM');
  });
}
