import 'package:drum_coach/features/lessons/lessons_provider.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _r(String id, {RudimentFamily? family, List<Skill> skill = const []}) {
  return Rudiment(
    id: id,
    name: id,
    description: '',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: const [StrokeBeat(hand: Hand.right)],
    family: family,
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
  });
}
