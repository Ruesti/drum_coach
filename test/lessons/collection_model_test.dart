import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collection defaults to null (base catalog)', () {
    const r = Rudiment(
        id: 'x', name: 'x', description: 'x', minBpm: 60, targetBpm: 120,
        difficulty: Difficulty.beginner, sticking: [StrokeBeat(hand: Hand.right)]);
    expect(r.collection, isNull);
    expect(r.collectionGroup, isNull);
  });
  test('accepts an explicit collection + group', () {
    const r = Rudiment(
        id: 'x', name: 'x', description: 'x', minBpm: 60, targetBpm: 120,
        difficulty: Difficulty.beginner, sticking: [StrokeBeat(hand: Hand.right)],
        collection: ExerciseCollection.rudimentEtudes,
        collectionGroup: 'Single Paradiddle');
    expect(r.collection, ExerciseCollection.rudimentEtudes);
    expect(r.collection!.label, 'Rudiment-Étüden');
    expect(r.collectionGroup, 'Single Paradiddle');
  });
}
