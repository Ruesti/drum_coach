import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/isar_service.dart';
import '../../data/local/models/practice_session.dart';
import '../../data/local/models/rudiment_progress.dart';
import '../learning/bpm_progression_service.dart';
import '../learning/spaced_repetition_service.dart';

part 'practice_provider.g.dart';

@riverpod
class PracticeNotifier extends _$PracticeNotifier {
  @override
  void build() {}

  Future<void> saveSession({
    required String rudimentId,
    required int durationSeconds,
    required int achievedBpm,
    required int rating,
    required int targetBpm,
  }) async {
    final session = PracticeSession()
      ..exerciseId = rudimentId
      ..durationSeconds = durationSeconds
      ..achievedBpm = achievedBpm
      ..rating = rating
      ..date = DateTime.now();

    await IsarService.instance.writeTxn(
      () => IsarService.instance.practiceSessions.put(session),
    );

    await _updateProgress(rudimentId, achievedBpm, rating, targetBpm);

    ref.invalidate(recentSessionsProvider);
    ref.invalidate(exerciseStartBpmProvider);
  }

  Future<void> _updateProgress(
    String rudimentId,
    int achievedBpm,
    int rating,
    int targetBpm,
  ) async {
    final allProgress = await IsarService.instance.rudimentProgress
        .buildQuery<RudimentProgress>()
        .findAll();
    var progress =
        allProgress.where((p) => p.exerciseId == rudimentId).firstOrNull;

    final now = DateTime.now();
    progress ??= RudimentProgress()
      ..exerciseId = rudimentId
      ..currentBpm = achievedBpm
      ..bestBpm = achievedBpm
      ..mastery = MasteryLevel.beginner
      ..srInterval = 1
      ..srRepetitions = 0
      ..lastPracticed = now
      ..nextReviewDate = now.add(const Duration(days: 1));

    const srService = SpacedRepetitionService();
    const bpmService = BpmProgressionService();
    srService.updateAfterSession(progress, rating);
    bpmService.updateProgress(progress, achievedBpm, rating, targetBpm);

    await IsarService.instance.writeTxn(
      () => IsarService.instance.rudimentProgress.put(progress!),
    );
  }
}

/// The suggested start tempo for an exercise: the BPM progression's current
/// value (lifted +2/+5 by session ratings), or null if never practiced or
/// the store is unavailable. Practice sessions preset the metronome with
/// this so tempo never leaks over from a previously played exercise.
@riverpod
Future<int?> exerciseStartBpm(ExerciseStartBpmRef ref, String rudimentId) async {
  try {
    final all = await IsarService.instance.rudimentProgress
        .buildQuery<RudimentProgress>()
        .findAll();
    return all.where((p) => p.exerciseId == rudimentId).firstOrNull?.currentBpm;
  } catch (_) {
    return null;
  }
}

@riverpod
Future<List<PracticeSession>> recentSessions(RecentSessionsRef ref) async {
  final sessions = await IsarService.instance.practiceSessions
      .buildQuery<PracticeSession>()
      .findAll();
  sessions.sort((a, b) => b.date.compareTo(a.date));
  return sessions.take(200).toList();
}
