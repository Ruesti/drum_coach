import '../../data/local/models/rudiment_progress.dart';

class BpmProgressionService {
  const BpmProgressionService();

  int nextSuggestedBpm(RudimentProgress progress, int rating, int targetBpm) {
    return switch (rating) {
      3 => (progress.currentBpm + 5).clamp(1, targetBpm),
      2 => (progress.currentBpm + 2).clamp(1, targetBpm),
      _ => progress.currentBpm,
    };
  }

  /// Mutates [progress] in-place and returns it for convenience.
  RudimentProgress updateProgress(
    RudimentProgress progress,
    int achievedBpm,
    int rating,
    int targetBpm,
  ) {
    progress.currentBpm = nextSuggestedBpm(progress, rating, targetBpm);
    if (achievedBpm > progress.bestBpm) progress.bestBpm = achievedBpm;
    progress.mastery = _mastery(progress.bestBpm, targetBpm);
    return progress;
  }

  MasteryLevel _mastery(int bestBpm, int targetBpm) {
    final ratio = bestBpm / targetBpm;
    if (ratio >= 1.0) return MasteryLevel.mastered;
    if (ratio >= 0.85) return MasteryLevel.proficient;
    if (ratio >= 0.65) return MasteryLevel.competent;
    if (ratio >= 0.40) return MasteryLevel.developing;
    return MasteryLevel.beginner;
  }
}
