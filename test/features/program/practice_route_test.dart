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
}
