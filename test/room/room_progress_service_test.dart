import 'package:drum_coach/data/local/models/rudiment_progress.dart';
import 'package:drum_coach/features/room/room_progress_service.dart';
import 'package:drum_coach/features/room/round_verdict.dart';
import 'package:drum_coach/features/room/tempo_ladder.dart';
import 'package:flutter_test/flutter_test.dart';

LadderRound r(int bpm, RoundVerdict v) => LadderRound(bpm: bpm, verdict: v);

RudimentProgress fresh(int bpm) {
  final then = DateTime(2026, 10, 1);
  return RudimentProgress()
    ..exerciseId = 'x'
    ..currentBpm = bpm
    ..bestBpm = bpm
    ..mastery = MasteryLevel.beginner
    ..srInterval = 1
    ..srRepetitions = 0
    ..lastPracticed = then
    ..nextReviewDate = then.add(const Duration(days: 1));
}

void main() {
  const s = RoomProgressService();

  test('applyRounds sets mastered after two clean rounds at target', () {
    final p = s.applyRounds(
        fresh(92),
        [
          r(92, RoundVerdict.clean),
          r(96, RoundVerdict.clean),
          r(100, RoundVerdict.clean),
          r(104, RoundVerdict.clean),
        ],
        targetBpm: 100,
        minBpm: 60);
    expect(p.mastery, MasteryLevel.mastered);
    expect(p.currentBpm, 108);
    expect(p.bestBpm, 104);
    // "Sits" = Solid for the spaced repetition: the review advances.
    expect(p.srRepetitions, 1);
    expect(p.lastPracticed.isAfter(DateTime(2026, 10, 2)), isTrue);
  });

  test('applyRounds keeps old rows valid', () {
    // A row written by the old +5 progression: clean tempo 85, best 90,
    // two solid reviews behind it.
    final old = fresh(85)
      ..bestBpm = 90
      ..mastery = MasteryLevel.proficient
      ..srRepetitions = 2
      ..srInterval = 3;
    final p = s.applyRounds(old, [r(85, RoundVerdict.close)],
        targetBpm: 100, minBpm: 60);
    expect(p.currentBpm, 85, reason: 'close holds the tempo');
    expect(p.bestBpm, 90, reason: 'never lowered');
    expect(p.mastery, MasteryLevel.proficient);
    expect(p.srRepetitions, 2);
    expect(p.srInterval, 3, reason: 'rating 2 keeps the interval');
    expect(p.exerciseId, 'x');
  });

  test('a last round off resets the review and steps down', () {
    final old = fresh(80)
      ..srRepetitions = 3
      ..srInterval = 14;
    final p = s.applyRounds(
        old, [r(80, RoundVerdict.clean), r(84, RoundVerdict.off)],
        targetBpm: 100, minBpm: 60);
    expect(p.currentBpm, 80);
    expect(p.bestBpm, 80);
    expect(p.srRepetitions, 0);
    expect(p.srInterval, 1);
  });

  test('sitting earlier in the session still counts', () {
    final p = s.applyRounds(
        fresh(100),
        [
          r(100, RoundVerdict.clean),
          r(104, RoundVerdict.clean),
          r(108, RoundVerdict.off),
        ],
        targetBpm: 100,
        minBpm: 60);
    expect(p.mastery, MasteryLevel.mastered);
    expect(p.srRepetitions, 1);
    expect(p.currentBpm, 104);
  });

  test('never below the exercise minimum', () {
    final p = s.applyRounds(fresh(60), [r(60, RoundVerdict.off)],
        targetBpm: 100, minBpm: 60);
    expect(p.currentBpm, 60);
  });

  test('no rounds: the row stays as it was', () {
    final p = s.applyRounds(fresh(70), const [], targetBpm: 100, minBpm: 60);
    expect(p.currentBpm, 70);
    expect(p.srRepetitions, 0);
    expect(p.lastPracticed, DateTime(2026, 10, 1));
  });
}
