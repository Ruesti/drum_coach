import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/rudiment_filter.dart';
import 'package:drum_coach/features/room/training_area.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _r(
  String id, {
  Set<Skill> skills = const {},
  Set<Genre> genres = const {},
  Set<Limb> limbs = const {Limb.hands},
  NoteGrid gridUnit = NoteGrid.eighth,
  TrainingArea? area,
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
    area: area,
  );
}

void main() {
  final control = _r('control', skills: {Skill.control});
  final coordination = _r('coordination',
      skills: {Skill.coordination}, gridUnit: NoteGrid.sixteenth);
  final drumCorps =
      _r('drumCorps', skills: {Skill.control}, genres: {Genre.drumCorps});
  final feetEndurance =
      _r('feetEndurance', skills: {Skill.endurance}, limbs: {Limb.feet});
  final all = [control, coordination, drumCorps, feetEndurance];

  group('filter by area', () {
    final hand =
        _r('hand', skills: {Skill.control}, area: TrainingArea.handTechnique);
    final grv = _r('grv', skills: {Skill.control}, area: TrainingArea.groove);
    final none = _r('none', skills: {Skill.control});
    final list = [hand, grv, none];
    test('OR within axis, untagged excluded', () {
      expect(
          filterRudiments(
              list,
              const RudimentFilters(
                  areas: {TrainingArea.handTechnique, TrainingArea.groove})),
          [hand, grv]);
    });
    test('AND with other axes', () {
      expect(
          filterRudiments(
              list,
              const RudimentFilters(
                  areas: {TrainingArea.groove}, skills: {Skill.endurance})),
          isEmpty);
    });
  });

  group('filterRudiments', () {
    test('empty filters returns everything', () {
      expect(filterRudiments(all, const RudimentFilters()), all);
    });

    test('single skill filter matches any rudiment with that skill', () {
      final result =
          filterRudiments(all, const RudimentFilters(skills: {Skill.control}));
      expect(result, [control, drumCorps]);
    });

    test('two skills selected match rudiments with either (OR within axis)',
        () {
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
