import 'package:drum_coach/features/program/day_completion.dart';
import 'package:drum_coach/features/program/models/training_program.dart';
import 'package:flutter_test/flutter_test.dart';

const _blocks = [
  ExerciseBlock(type: BlockType.warmup, exerciseKey: 'single_stroke_roll'),
  ExerciseBlock(type: BlockType.technique, exerciseKey: 'double_stroke_roll'),
  ExerciseBlock(type: BlockType.tempoLadder, exerciseKey: 'single_stroke_roll'),
];

void main() {
  group('completedBlockIndices', () {
    test('eine Session hakt den ersten Block mit diesem Key ab', () {
      expect(
        completedBlockIndices(_blocks, {'single_stroke_roll': 1}),
        {0},
      );
    });

    test('zwei Sessions desselben Keys haken Warmup und Leiter ab', () {
      expect(
        completedBlockIndices(_blocks, {'single_stroke_roll': 2}),
        {0, 2},
      );
    });

    test('verschiedene Keys haken ihre jeweiligen Blöcke ab', () {
      expect(
        completedBlockIndices(
            _blocks, {'single_stroke_roll': 1, 'double_stroke_roll': 1}),
        {0, 1},
      );
    });

    test('überzählige Sessions ändern nichts', () {
      expect(
        completedBlockIndices(_blocks, {'single_stroke_roll': 5}),
        {0, 2},
      );
    });

    test('keine Sessions → nichts abgehakt', () {
      expect(completedBlockIndices(_blocks, {}), isEmpty);
    });

    test('fremde Keys werden ignoriert', () {
      expect(completedBlockIndices(_blocks, {'paradiddle': 3}), isEmpty);
    });
  });
}
