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

    test('exactly 7 rudiments carry the drumCorps genre tag', () {
      final count = rudimentsSeedData
          .where((r) => r.genres.contains(Genre.drumCorps))
          .length;
      expect(count, 7);
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
  });
}
