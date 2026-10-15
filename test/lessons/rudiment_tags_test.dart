import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('seed rudiment tags', () {
    test('every seed rudiment has at least one skill tag', () {
      for (final r in rudimentsSeedData) {
        expect(r.skills, isNotEmpty, reason: '${r.id} has no skill tag');
      }
    });

    test('exactly 10 rudiments carry the drumCorps genre tag', () {
      // 7 from the tag migration + the three roll/triplet sheets of
      // Katalog 3a (five/seven stroke roll, Swiss army triplet).
      final count = rudimentsSeedData
          .where((r) => r.genres.contains(Genre.drumCorps))
          .length;
      expect(count, 10);
    });

    test('at least 3 rudiments are tagged both control and coordination', () {
      final count = rudimentsSeedData
          .where((r) =>
              r.skills.contains(Skill.control) &&
              r.skills.contains(Skill.coordination))
          .length;
      expect(count, greaterThanOrEqualTo(3));
    });

    test('at least 2 rudiments are tagged endurance', () {
      final count = rudimentsSeedData
          .where((r) => r.skills.contains(Skill.endurance))
          .length;
      expect(count, greaterThanOrEqualTo(2));
    });

    test('linear-pattern-family rudiments are tagged fill', () {
      final linear =
          rudimentsSeedData.where((r) => r.id.startsWith('linear_beat_'));
      expect(linear, isNotEmpty);
      for (final r in linear) {
        expect(r.skills, contains(Skill.fill), reason: r.id);
      }
    });

    test('the eight fill sheets (Katalog 3b) are tagged fill, never drum corps',
        () {
      final fills =
          rudimentsSeedData.where((r) => r.id.startsWith('fill_')).toList();
      expect(fills.length, 8);
      for (final r in fills) {
        expect(r.skills, contains(Skill.fill), reason: r.id);
        expect(r.genres, isNot(contains(Genre.drumCorps)), reason: r.id);
      }
    });
  });
}
