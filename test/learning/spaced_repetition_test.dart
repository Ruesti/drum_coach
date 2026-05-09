import 'package:drum_coach/data/local/models/rudiment_progress.dart';
import 'package:drum_coach/features/learning/spaced_repetition_service.dart';
import 'package:flutter_test/flutter_test.dart';

RudimentProgress _makeProgress({
  int srInterval = 1,
  int srRepetitions = 0,
}) {
  final p = RudimentProgress()
    ..rudimentId = 'test'
    ..currentBpm = 80
    ..bestBpm = 80
    ..mastery = MasteryLevel.beginner
    ..srInterval = srInterval
    ..srRepetitions = srRepetitions
    ..lastPracticed = DateTime(2025)
    ..nextReviewDate = DateTime(2025);
  return p;
}

void main() {
  const srs = SpacedRepetitionService();

  test('rating 1 resets interval to 1 and reps to 0', () {
    final p = _makeProgress(srInterval: 7, srRepetitions: 3);
    srs.updateAfterSession(p, 1);
    expect(p.srInterval, 1);
    expect(p.srRepetitions, 0);
  });

  test('rating 2 leaves interval unchanged', () {
    final p = _makeProgress(srInterval: 7, srRepetitions: 2);
    srs.updateAfterSession(p, 2);
    expect(p.srInterval, 7);
    expect(p.srRepetitions, 2);
  });

  test('rating 3 increments reps and advances interval', () {
    final p = _makeProgress(srInterval: 1, srRepetitions: 0);
    srs.updateAfterSession(p, 3);
    expect(p.srRepetitions, 1);
    expect(p.srInterval, 1); // idx = reps-1 = 0 → intervals[0] = 1
  });

  test('rating 3 advances to second interval after two solids', () {
    final p = _makeProgress(srInterval: 1, srRepetitions: 1);
    srs.updateAfterSession(p, 3);
    expect(p.srRepetitions, 2);
    expect(p.srInterval, 3); // idx = 1 → intervals[1] = 3
  });

  test('nextReviewDate is set to now + srInterval days', () {
    final p = _makeProgress(srInterval: 7);
    final before = DateTime.now();
    srs.updateAfterSession(p, 2);
    final after = DateTime.now();
    final diff = p.nextReviewDate.difference(before).inDays;
    expect(diff, greaterThanOrEqualTo(6));
    expect(p.nextReviewDate.isBefore(after.add(const Duration(days: 8))), true);
  });
}
