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

  group('sheet (Blattform)', () {
    const a = StrokeBeat(hand: Hand.right);
    const b = StrokeBeat(hand: Hand.left);
    const plain = Rudiment(
        id: 'p',
        name: 'P',
        description: '',
        minBpm: 60,
        targetBpm: 100,
        difficulty: Difficulty.beginner,
        sticking: [a, b]);
    test('without lines the sheet is one repeating line made of the sticking',
        () {
      expect(plain.lines, isEmpty);
      expect(plain.sheet.length, 1);
      expect(plain.sheet.first.beats, same(plain.sticking));
      expect(plain.sheet.first.repeat, isTrue);
      expect(plain.sheet.first.title, isNull);
      expect(plain.sheet.first.counts, isFalse);
    });
    test('with lines the sheet is exactly those lines', () {
      const r = Rudiment(
          id: 's',
          name: 'S',
          description: '',
          minBpm: 60,
          targetBpm: 100,
          difficulty: Difficulty.beginner,
          sticking: [a, b],
          lines: [
            ExerciseLine([a, b]),
            ExerciseLine([b, a],
                repeat: false, title: 'Challenge', counts: true),
          ]);
      expect(r.sheet.length, 2);
      expect(r.sheet[1].repeat, isFalse);
      expect(r.sheet[1].title, 'Challenge');
      expect(r.sheet[1].counts, isTrue);
    });
    test('withSticking swaps only the notes and drops the lines', () {
      const r = Rudiment(
          id: 's',
          name: 'S',
          description: 'd',
          minBpm: 60,
          targetBpm: 100,
          difficulty: Difficulty.advanced,
          sticking: [a, b],
          gridUnit: NoteGrid.sixteenth,
          beatsPerBar: 2,
          backing: 'swing',
          skills: {Skill.fill},
          lines: [
            ExerciseLine([a]),
            ExerciseLine([b]),
          ]);
      final u = r.withSticking(const [b, b, b]);
      expect(u.sticking.length, 3);
      expect(u.id, 's');
      expect(u.gridUnit, NoteGrid.sixteenth);
      expect(u.beatsPerBar, 2);
      expect(u.backing, 'swing');
      expect(u.skills, {Skill.fill});
      expect(u.difficulty, Difficulty.advanced);
      expect(u.lines, isEmpty);
      expect(u.sheet.first.beats.length, 3);
    });
  });

  group('NoteGrid.label', () {
    test('labels every subdivision value', () {
      expect(NoteGrid.eighth.label, '8ths');
      expect(NoteGrid.triplet.label, 'Triplets');
      expect(NoteGrid.sixteenth.label, '16ths');
      expect(NoteGrid.sixteenthTriplet.label, '16th triplets');
      expect(NoteGrid.thirtySecond.label, '32nds');
    });

    test('extends cellsPerQuarter for the two new brief-required values', () {
      expect(NoteGrid.sixteenthTriplet.cellsPerQuarter, 6);
      expect(NoteGrid.thirtySecond.cellsPerQuarter, 8);
    });
  });
}
