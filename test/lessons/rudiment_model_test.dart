import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _makeRudiment({
  ExerciseSource? source,
  ExerciseVoicing? voicing,
  Set<Skill>? skills,
  Set<Genre>? genres,
  Set<Limb>? limbs,
}) {
  return Rudiment(
    id: 'test_rudiment',
    name: 'Test',
    description: 'desc',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: const [StrokeBeat(hand: Hand.right)],
    source: source ?? ExerciseSource.authored,
    voicing: voicing ?? ExerciseVoicing.pad,
    skills: skills ?? const {},
    genres: genres ?? const {},
    limbs: limbs ?? const {Limb.hands},
  );
}

void main() {
  group('Rudiment.source / Rudiment.voicing', () {
    test('defaults to authored + pad when not specified', () {
      final r = Rudiment(
        id: 'defaults',
        name: 'Defaults',
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

  group('Rudiment.skills / genres / limbs', () {
    test('defaults to empty skills/genres and hands-only limbs', () {
      final r = Rudiment(
        id: 'defaults',
        name: 'Defaults',
        description: 'desc',
        minBpm: 60,
        targetBpm: 120,
        difficulty: Difficulty.beginner,
        sticking: const [StrokeBeat(hand: Hand.right)],
      );
      expect(r.skills, isEmpty);
      expect(r.genres, isEmpty);
      expect(r.limbs, {Limb.hands});
    });

    test('accepts explicit skills, genres, and limbs', () {
      final r = _makeRudiment(
        skills: {Skill.control, Skill.coordination},
        genres: {Genre.drumCorps},
        limbs: {Limb.feet},
      );
      expect(r.skills, {Skill.control, Skill.coordination});
      expect(r.genres, {Genre.drumCorps});
      expect(r.limbs, {Limb.feet});
    });
  });

  group('NoteGrid.label', () {
    test('labels every subdivision value', () {
      expect(NoteGrid.eighth.label, '8tel');
      expect(NoteGrid.triplet.label, 'Triolen');
      expect(NoteGrid.sixteenth.label, '16tel');
      expect(NoteGrid.sixteenthTriplet.label, '16tel-Triolen');
      expect(NoteGrid.thirtySecond.label, '32tel');
    });

    test('extends cellsPerQuarter for the two new brief-required values', () {
      expect(NoteGrid.sixteenthTriplet.cellsPerQuarter, 6);
      expect(NoteGrid.thirtySecond.cellsPerQuarter, 8);
    });
  });
}
