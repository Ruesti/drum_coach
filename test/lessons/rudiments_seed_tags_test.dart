import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _byId(String id) => rudimentsSeedData.firstWhere((r) => r.id == id);

void main() {
  group('rudimentsSeedData tag axes', () {
    test('every seeded rudiment has at least one skill tag', () {
      for (final r in rudimentsSeedData) {
        expect(r.skill, isNotEmpty, reason: '${r.id} has no skill tag');
      }
    });

    test('classic PAS rudiment families are tagged', () {
      expect(_byId('single_stroke_roll').family, RudimentFamily.roll);
      expect(_byId('single_paradiddle').family, RudimentFamily.paradiddle);
      expect(_byId('flam').family, RudimentFamily.flam);
      expect(_byId('single_drag').family, RudimentFamily.ruff);
    });

    test('non-PAS exercises have no family tag', () {
      expect(_byId('ghost_note_groove').family, isNull);
      expect(_byId('linear_beat_1').family, isNull);
      expect(_byId('speed_singles_basis').family, isNull);
      expect(_byId('ausdauer_dauerlauf').family, isNull);
    });

    test('paradiddles are tagged koordination + kontrolle', () {
      expect(_byId('single_paradiddle').skill,
          containsAll([Skill.koordination, Skill.kontrolle]));
    });

    test('linear patterns are tagged koordination + independence', () {
      expect(_byId('linear_beat_1').skill,
          containsAll([Skill.koordination, Skill.independence]));
    });

    test('ausdauer exercises are tagged Skill.ausdauer', () {
      expect(_byId('ausdauer_dauerlauf').skill, [Skill.ausdauer]);
    });

    test('Marching Snare entries are tagged genre drumCorps, others general',
        () {
      final marching = _byId('eight_on_a_hand');
      expect(marching.genre, Genre.drumCorps);
      expect(marching.skill, containsAll([Skill.ausdauer, Skill.kontrolle]));

      expect(_byId('single_stroke_roll').genre, Genre.general);
      expect(_byId('speed_singles_basis').genre, Genre.general);
    });
  });
}
