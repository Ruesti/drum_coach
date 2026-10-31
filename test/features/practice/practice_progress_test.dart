import 'package:drum_coach/data/local/models/rudiment_progress.dart';
import 'package:drum_coach/features/practice/practice_provider.dart';
import 'package:flutter_test/flutter_test.dart';

RudimentProgress _row({int bpm = 100, int best = 100}) => RudimentProgress()
  ..exerciseId = 'x'
  ..currentBpm = bpm
  ..bestBpm = best
  ..mastery = MasteryLevel.developing
  ..srInterval = 7
  ..srRepetitions = 3
  ..lastPracticed = DateTime(2026, 10, 1)
  ..nextReviewDate = DateTime(2026, 10, 8);

void main() {
  test('warm-up rated Struggled at the target: no mastery, tempo unchanged',
      () {
    final p = _row(bpm: 92, best: 96);
    applyPracticeSession(p,
        achievedBpm: 120, rating: 1, targetBpm: 120, warmup: true);
    expect(p.mastery, MasteryLevel.developing);
    expect(p.currentBpm, 92);
    expect(p.bestBpm, 96);
    // Spaced repetition still follows the rating.
    expect(p.srInterval, 1);
    expect(p.srRepetitions, 0);
    expect(p.lastPracticed.isAfter(DateTime(2026, 10, 1)), isTrue);
  });

  test('warm-up rated Solid at the target leaves tempo and mastery too', () {
    final p = _row(bpm: 92, best: 96);
    applyPracticeSession(p,
        achievedBpm: 130, rating: 3, targetBpm: 120, warmup: true);
    expect(p.mastery, MasteryLevel.developing);
    expect(p.currentBpm, 92);
    expect(p.bestBpm, 96);
    expect(p.srRepetitions, 4);
  });

  test('library practice at the target never masters', () {
    for (final rating in [1, 2, 3]) {
      final p = _row(bpm: 120, best: 120);
      applyPracticeSession(p, achievedBpm: 120, rating: rating, targetBpm: 120);
      expect(p.mastery, MasteryLevel.proficient, reason: 'rating $rating');
    }
  });

  test('library practice still moves the tempo and best tempo', () {
    final p = _row(bpm: 100, best: 100);
    applyPracticeSession(p, achievedBpm: 104, rating: 3, targetBpm: 120);
    expect(p.currentBpm, 105);
    expect(p.bestBpm, 104);
  });
}
