import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/rudiment_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _r(
  String id, {
  Set<Skill> skills = const {},
  Set<Genre> genres = const {},
  Set<Limb> limbs = const {Limb.hands},
  NoteGrid gridUnit = NoteGrid.eighth,
}) {
  return Rudiment(
    id: id,
    name: id,
    description: '',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: const [StrokeBeat(hand: Hand.right)],
    skills: skills,
    genres: genres,
    limbs: limbs,
    gridUnit: gridUnit,
  );
}

void main() {
  final control = _r('control', skills: {Skill.control});
  final coordination =
      _r('coordination', skills: {Skill.coordination}, gridUnit: NoteGrid.sixteenth);
  final drumCorps = _r('drumCorps',
      skills: {Skill.control}, genres: {Genre.drumCorps});
  final feetEndurance =
      _r('feetEndurance', skills: {Skill.endurance}, limbs: {Limb.feet});
  final all = [control, coordination, drumCorps, feetEndurance];

  group('filterRudiments', () {
    test('empty filters returns everything', () {
      expect(filterRudiments(all, const RudimentFilters()), all);
    });

    test('single skill filter matches any rudiment with that skill', () {
      final result =
          filterRudiments(all, const RudimentFilters(skills: {Skill.control}));
      expect(result, [control, drumCorps]);
    });

    test('two skills selected match rudiments with either (OR within axis)', () {
      final result = filterRudiments(
        all,
        const RudimentFilters(skills: {Skill.control, Skill.endurance}),
      );
      expect(result, [control, drumCorps, feetEndurance]);
    });

    test('skill + genre filter requires both (AND across axes)', () {
      final result = filterRudiments(
        all,
        const RudimentFilters(
          skills: {Skill.control},
          genres: {Genre.drumCorps},
        ),
      );
      expect(result, [drumCorps]);
    });

    test('subdivision filter matches gridUnit', () {
      final result = filterRudiments(
        all,
        const RudimentFilters(subdivisions: {NoteGrid.sixteenth}),
      );
      expect(result, [coordination]);
    });

    test('limb filter narrows to matching limb set', () {
      final result =
          filterRudiments(all, const RudimentFilters(limbs: {Limb.feet}));
      expect(result, [feetEndurance]);
    });
  });
}
