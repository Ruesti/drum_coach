import 'package:drum_coach/data/local/models/rudiment_progress.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/room/session_planner.dart';
import 'package:drum_coach/features/room/training_area.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment ex(String id, TrainingArea? area,
        [Difficulty d = Difficulty.beginner]) =>
    Rudiment(
      id: id,
      name: id,
      description: '',
      minBpm: 60,
      targetBpm: 100,
      difficulty: d,
      sticking: const [],
      area: area,
    );

final now = DateTime(2026, 10, 31);

RudimentProgress prog(
  String id, {
  MasteryLevel m = MasteryLevel.developing,
  DateTime? last,
  DateTime? next,
}) =>
    RudimentProgress()
      ..exerciseId = id
      ..currentBpm = 80
      ..bestBpm = 80
      ..mastery = m
      ..srInterval = 1
      ..srRepetitions = 0
      ..lastPracticed = last ?? DateTime(2026, 10, 20)
      ..nextReviewDate = next ?? DateTime(2026, 11, 20);

void main() {
  const h = TrainingArea.handTechnique;
  const ru = TrainingArea.rudiments;
  const f = TrainingArea.feet;
  const g = TrainingArea.groove;
  const mt = TrainingArea.metal;

  test('warmup takes one from hands, rudiments, feet', () {
    final cat = [
      ex('h1', h),
      ex('h2', h),
      ex('r1', ru),
      ex('f1', f),
      ex('g1', g),
    ];
    final s = planSession(catalog: cat, progress: {}, now: now, chosen: g);
    expect(s.warmup, ['h1', 'r1', 'f1']);
  });

  test('warmup prefers played, not-due exercises', () {
    final cat = [ex('h1', h), ex('h2', h), ex('r1', ru), ex('g1', g)];
    final p = {
      'h1': prog('h1', next: DateTime(2026, 10, 1)), // due
      'h2': prog('h2'),
    };
    final s = planSession(catalog: cat, progress: p, now: now, chosen: g);
    expect(s.warmup, ['h2', 'r1']);
  });

  test('warmup omits an empty area', () {
    final cat = [ex('h1', h), ex('f1', f), ex('g1', g)];
    final s = planSession(catalog: cat, progress: {}, now: now);
    expect(s.warmup, ['h1', 'f1']);
  });

  test('area with due reviews wins', () {
    final cat = [ex('g1', g), ex('m1', mt)];
    final p = {
      'g1': prog('g1', last: DateTime(2026, 10, 30)),
      'm1': prog('m1',
          last: DateTime(2026, 10, 30), next: DateTime(2026, 10, 30)),
    };
    expect(planSession(catalog: cat, progress: p, now: now).area, mt);
  });

  test('never-played area counts as longest', () {
    final cat = [ex('g1', g), ex('m1', mt)];
    expect(
        planSession(catalog: cat, progress: {'g1': prog('g1')}, now: now).area,
        mt);
    expect(
        planSession(catalog: cat, progress: {'m1': prog('m1')}, now: now).area,
        g);
  });

  test('longest not played among played areas', () {
    final cat = [ex('g1', g), ex('m1', mt)];
    final p = {
      'g1': prog('g1', last: DateTime(2026, 10, 25)),
      'm1': prog('m1', last: DateTime(2026, 10, 10)),
    };
    expect(planSession(catalog: cat, progress: p, now: now).area, mt);
  });

  test('chosen area overrides', () {
    final cat = [ex('g1', g), ex('m1', mt)];
    final p = {'m1': prog('m1', next: DateTime(2026, 10, 1))};
    expect(planSession(catalog: cat, progress: p, now: now, chosen: g).area, g);
  });

  test('empty area is never suggested', () {
    final cat = [ex('g1', g), ex('x', null)];
    expect(planSession(catalog: cat, progress: {}, now: now).area, g);
    expect(
        planSession(catalog: cat, progress: {}, now: now, chosen: mt).area, g);
  });

  test('deepen lists due reviews first, max 5', () {
    final cat = [for (var i = 0; i < 8; i++) ex('g$i', g)];
    final p = {
      'g6': prog('g6', next: DateTime(2026, 10, 5)),
      'g7': prog('g7', next: DateTime(2026, 10, 3)),
    };
    final s = planSession(catalog: cat, progress: p, now: now, chosen: g);
    expect(s.deepen, ['g7', 'g6', 'g0', 'g1', 'g2']);
  });

  test('deepen skips mastered exercises', () {
    final cat = [ex('g1', g), ex('g2', g)];
    final p = {'g1': prog('g1', m: MasteryLevel.mastered)};
    final s = planSession(catalog: cat, progress: p, now: now, chosen: g);
    expect(s.deepen, ['g2']);
  });

  test('advanced player falls back to highest available level', () {
    final cat = [ex('g1', g), ex('g2', g, Difficulty.intermediate)];
    final p = {
      'g1': prog('g1', m: MasteryLevel.mastered),
      'g2': prog('g2', m: MasteryLevel.mastered),
    };
    final s = planSession(catalog: cat, progress: p, now: now, chosen: g);
    expect(s.area, g);
    expect(s.deepen, isEmpty);
  });
}
