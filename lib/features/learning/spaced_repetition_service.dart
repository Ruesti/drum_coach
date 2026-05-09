import '../../data/local/models/rudiment_progress.dart';

class SpacedRepetitionService {
  static const _intervals = [1, 3, 7, 14, 30, 60];

  const SpacedRepetitionService();

  /// Mutates [progress] in-place and returns it for convenience.
  RudimentProgress updateAfterSession(RudimentProgress progress, int rating) {
    final now = DateTime.now();
    progress.lastPracticed = now;

    switch (rating) {
      case 1: // Struggled – reset
        progress.srInterval = 1;
        progress.srRepetitions = 0;
      case 2: // OK – interval unchanged
        break;
      case 3: // Solid – advance
        progress.srRepetitions++;
        final idx = (progress.srRepetitions - 1).clamp(0, _intervals.length - 1);
        progress.srInterval = _intervals[idx];
    }

    progress.nextReviewDate = now.add(Duration(days: progress.srInterval));
    return progress;
  }
}
