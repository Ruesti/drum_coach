import 'package:drum_coach/features/coaching/exercise_generator_screen.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildGeneratedRudiment', () {
    test('tags the result as ExerciseSource.generated', () {
      const pattern = [
        StrokeBeat(hand: Hand.right, isAccent: true),
        StrokeBeat(hand: Hand.left),
      ];
      final rudiment = buildGeneratedRudiment(pattern);
      expect(rudiment.source, ExerciseSource.generated);
    });

    test('carries the given pattern through as sticking', () {
      const pattern = [
        StrokeBeat(hand: Hand.right),
        StrokeBeat(hand: Hand.left),
        StrokeBeat(hand: Hand.right),
      ];
      final rudiment = buildGeneratedRudiment(pattern);
      expect(rudiment.sticking, pattern);
    });
  });
}
