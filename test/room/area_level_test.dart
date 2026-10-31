import 'package:drum_coach/data/local/models/rudiment_progress.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/room/area_level.dart';
import 'package:drum_coach/features/room/training_area.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment ex(String id, TrainingArea? area, Difficulty d) => Rudiment(
      id: id,
      name: id,
      description: '',
      minBpm: 60,
      targetBpm: 100,
      difficulty: d,
      sticking: const [],
      area: area,
    );

RudimentProgress prog(String id, MasteryLevel m) => RudimentProgress()
  ..exerciseId = id
  ..currentBpm = 80
  ..bestBpm = 80
  ..mastery = m
  ..srInterval = 1
  ..srRepetitions = 0
  ..lastPracticed = DateTime(2026, 10, 1)
  ..nextReviewDate = DateTime(2026, 10, 2);

void main() {
  const a = TrainingArea.handTechnique;

  test('level is beginner while less than 80 % mastered', () {
    final cat = [
      for (var i = 0; i < 5; i++) ex('b$i', a, Difficulty.beginner),
      ex('i0', a, Difficulty.intermediate),
    ];
    final p = {
      for (var i = 0; i < 3; i++) 'b$i': prog('b$i', MasteryLevel.mastered),
    };
    expect(areaLevel(a, cat, p), Difficulty.beginner);
    p['b3'] = prog('b3', MasteryLevel.mastered); // 4 of 5 = 80 %
    expect(areaLevel(a, cat, p), Difficulty.intermediate);
  });

  test('level skips empty levels', () {
    final cat = [
      ex('b0', a, Difficulty.beginner),
      ex('a0', a, Difficulty.advanced),
    ];
    final p = {'b0': prog('b0', MasteryLevel.mastered)};
    expect(areaLevel(a, cat, p), Difficulty.advanced);
  });

  test('advanced player falls back to highest available level', () {
    final cat = [
      ex('b0', a, Difficulty.beginner),
      ex('i0', a, Difficulty.intermediate),
      ex('x', TrainingArea.feet, Difficulty.professional),
    ];
    final p = {
      'b0': prog('b0', MasteryLevel.mastered),
      'i0': prog('i0', MasteryLevel.mastered),
    };
    expect(areaLevel(a, cat, p), Difficulty.intermediate);
  });
}
