import 'package:drum_coach/features/lessons/lessons_provider.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _r(
  String id, {
  RudimentFamily? family,
  Genre genre = Genre.general,
  List<Skill> skill = const [],
}) {
  return Rudiment(
    id: id,
    name: id,
    description: '',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: const [StrokeBeat(hand: Hand.right)],
    family: family,
    genre: genre,
    skill: skill,
  );
}

void main() {
  group('filterRudiments', () {
    final all = [
      _r('a', family: RudimentFamily.roll, skill: const [Skill.kontrolle]),
      _r('b', family: RudimentFamily.paradiddle, skill: const [Skill.koordination, Skill.kontrolle]),
      _r('c', skill: const [Skill.ausdauer]),
    ];

    test('with no filter, returns all rudiments sorted by name', () {
      final result = filterRudiments(all);
      expect(result.map((r) => r.id), ['a', 'b', 'c']);
    });

    test('family filter narrows to that family only', () {
      final result = filterRudiments(all, family: RudimentFamily.roll);
      expect(result.map((r) => r.id), ['a']);
    });

    test('skill filter uses OR semantics across selected skills', () {
      final result = filterRudiments(
        all,
        skills: {Skill.kontrolle, Skill.ausdauer},
      );
      expect(result.map((r) => r.id), ['a', 'b', 'c']);
    });

    test('family and skill filters combine with AND semantics', () {
      final result = filterRudiments(
        all,
        family: RudimentFamily.paradiddle,
        skills: {Skill.ausdauer},
      );
      expect(result, isEmpty);
    });

    test('empty skills set means no skill filter applied', () {
      final result = filterRudiments(all, skills: const {});
      expect(result.map((r) => r.id), ['a', 'b', 'c']);
    });

    test('genre filter narrows to that genre only', () {
      final result = filterRudiments(all, genre: Genre.drumCorps);
      expect(result, isEmpty); // none of the fixture rudiments are drumCorps
    });
  });

  group('LessonsFilter', () {
    test('toggleSkill adds then removes a skill', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(lessonsFilterProvider.notifier);

      expect(container.read(lessonsFilterProvider).skills, isEmpty);

      notifier.toggleSkill(Skill.kontrolle);
      expect(container.read(lessonsFilterProvider).skills, {Skill.kontrolle});

      notifier.toggleSkill(Skill.kontrolle);
      expect(container.read(lessonsFilterProvider).skills, isEmpty);
    });

    test('setFamily and setGenre update independently of skills', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(lessonsFilterProvider.notifier);

      notifier.toggleSkill(Skill.ausdauer);
      notifier.setFamily(RudimentFamily.roll);
      notifier.setGenre(Genre.drumCorps);

      final state = container.read(lessonsFilterProvider);
      expect(state.family, RudimentFamily.roll);
      expect(state.genre, Genre.drumCorps);
      expect(state.skills, {Skill.ausdauer});
    });
  });
}
