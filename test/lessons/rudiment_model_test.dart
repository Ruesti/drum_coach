import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _makeRudiment({ExerciseSource? source, ExerciseVoicing? voicing}) {
  return Rudiment(
    id: 'test_rudiment',
    name: 'Test',
    category: 'Rolls',
    description: 'desc',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: const [StrokeBeat(hand: Hand.right)],
    source: source ?? ExerciseSource.authored,
    voicing: voicing ?? ExerciseVoicing.pad,
  );
}

void main() {
  group('Rudiment.source / Rudiment.voicing', () {
    test('defaults to authored + pad when not specified', () {
      final r = Rudiment(
        id: 'defaults',
        name: 'Defaults',
        category: 'Rolls',
        description: 'desc',
        minBpm: 60,
        targetBpm: 120,
        difficulty: Difficulty.beginner,
        sticking: const [StrokeBeat(hand: Hand.right)],
      );
      expect(r.source, ExerciseSource.authored);
      expect(r.voicing, ExerciseVoicing.pad);
    });

    test('accepts an explicit generated source', () {
      final r = _makeRudiment(source: ExerciseSource.generated);
      expect(r.source, ExerciseSource.generated);
    });

    test('accepts an explicit excerpt source', () {
      final r = _makeRudiment(source: ExerciseSource.excerpt);
      expect(r.source, ExerciseSource.excerpt);
    });

    test('accepts an explicit kit voicing', () {
      final r = _makeRudiment(voicing: ExerciseVoicing.kit);
      expect(r.voicing, ExerciseVoicing.kit);
    });
  });
}
