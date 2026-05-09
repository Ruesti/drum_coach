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
      ..rudimentId = rudimentId
      ..durationSeconds = durationSeconds
      ..achievedBpm = achievedBpm
      ..rating = rating
      ..date = DateTime.now();

    await IsarService.instance.writeTxn(
      () => IsarService.instance.practiceSessions.put(session),
    );

    await _updateProgress(rudimentId, achievedBpm, rating, targetBpm);

    ref.invalidate(recentSessionsProvider);
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
        allProgress.where((p) => p.rudimentId == rudimentId).firstOrNull;

    final now = DateTime.now();
    progress ??= RudimentProgress()
      ..rudimentId = rudimentId
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

@riverpod
Future<List<PracticeSession>> recentSessions(RecentSessionsRef ref) async {
  final sessions = await IsarService.instance.practiceSessions
      .buildQuery<PracticeSession>()
      .findAll();
  sessions.sort((a, b) => b.date.compareTo(a.date));
  return sessions.take(200).toList();
}
