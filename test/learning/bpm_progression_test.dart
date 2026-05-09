import 'package:drum_coach/data/local/models/rudiment_progress.dart';
import 'package:drum_coach/features/learning/bpm_progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

RudimentProgress _makeProgress({int currentBpm = 80, int bestBpm = 80}) {
  final p = RudimentProgress()
    ..rudimentId = 'test'
    ..currentBpm = currentBpm
    ..bestBpm = bestBpm
    ..mastery = MasteryLevel.beginner
    ..srInterval = 1
    ..srRepetitions = 0
    ..lastPracticed = DateTime(2025)
    ..nextReviewDate = DateTime(2025);
  return p;
}

void main() {
  const svc = BpmProgressionService();

  group('nextSuggestedBpm', () {
    test('rating 3 increases bpm by 5', () {
      final p = _makeProgress(currentBpm: 80);
      expect(svc.nextSuggestedBpm(p, 3, 120), 85);
    });

    test('rating 2 increases bpm by 2', () {
      final p = _makeProgress(currentBpm: 80);
      expect(svc.nextSuggestedBpm(p, 2, 120), 82);
    });

    test('rating 1 keeps bpm unchanged', () {
      final p = _makeProgress(currentBpm: 80);
      expect(svc.nextSuggestedBpm(p, 1, 120), 80);
    });

    test('bpm is clamped to targetBpm', () {
      final p = _makeProgress(currentBpm: 118);
      expect(svc.nextSuggestedBpm(p, 3, 120), 120);
    });
  });

  group('updateProgress mastery', () {
    test('bestBpm below 40% → beginner', () {
      final p = _makeProgress(currentBpm: 30, bestBpm: 30);
      svc.updateProgress(p, 35, 3, 120);
      expect(p.mastery, MasteryLevel.beginner);
    });

    test('bestBpm at 100% → mastered', () {
      final p = _makeProgress(currentBpm: 120, bestBpm: 120);
      svc.updateProgress(p, 120, 3, 120);
      expect(p.mastery, MasteryLevel.mastered);
    });

    test('bestBpm at 85% → proficient', () {
      final p = _makeProgress(currentBpm: 102, bestBpm: 102);
      svc.updateProgress(p, 102, 3, 120);
      expect(p.mastery, MasteryLevel.proficient);
    });

    test('updates bestBpm when achievedBpm is higher', () {
      final p = _makeProgress(currentBpm: 80, bestBpm: 80);
      svc.updateProgress(p, 95, 3, 120);
      expect(p.bestBpm, 95);
    });

    test('does not lower bestBpm', () {
      final p = _makeProgress(currentBpm: 100, bestBpm: 100);
      svc.updateProgress(p, 80, 1, 120);
      expect(p.bestBpm, 100);
    });
  });
}
