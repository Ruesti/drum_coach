import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/isar_service.dart';
import '../../data/local/models/practice_session.dart';
import '../../data/local/models/rudiment_progress.dart';
import '../learning/bpm_progression_service.dart';
import '../learning/spaced_repetition_service.dart';
import '../room/room_progress_service.dart';
import '../room/tempo_ladder.dart';

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
    await _putSession(rudimentId, durationSeconds, achievedBpm, rating);

    final progress = await _progressFor(rudimentId, achievedBpm);
    const srService = SpacedRepetitionService();
    const bpmService = BpmProgressionService();
    srService.updateAfterSession(progress, rating);
    bpmService.updateProgress(progress, achievedBpm, rating, targetBpm);
    await _putProgress(progress);

    ref.invalidate(recentSessionsProvider);
    ref.invalidate(exerciseStartBpmProvider);
  }

  /// Trainingsraum session: the same session row, but the progress follows
  /// the tempo ladder's rounds ([RoomProgressService]) instead of the
  /// rating's +5 / +2.
  Future<void> saveRoomSession({
    required String rudimentId,
    required int durationSeconds,
    required int achievedBpm,
    required int rating,
    required List<LadderRound> rounds,
    required int targetBpm,
    required int minBpm,
  }) async {
    await _putSession(rudimentId, durationSeconds, achievedBpm, rating);
    if (rounds.isNotEmpty) {
      // A fresh row has no clean tempo yet: only clean rounds lift it.
      final progress =
          await _progressFor(rudimentId, rounds.first.bpm, bestBpm: 0);
      const RoomProgressService()
          .applyRounds(progress, rounds, targetBpm: targetBpm, minBpm: minBpm);
      await _putProgress(progress);
    }
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(exerciseStartBpmProvider);
  }

  Future<void> _putSession(
      String rudimentId, int durationSeconds, int achievedBpm, int rating) {
    final session = PracticeSession()
      ..exerciseId = rudimentId
      ..durationSeconds = durationSeconds
      ..achievedBpm = achievedBpm
      ..rating = rating
      ..date = DateTime.now();
    return IsarService.instance.writeTxn(
      () => IsarService.instance.practiceSessions.put(session),
    );
  }

  /// The stored row of [rudimentId], or a fresh one starting at [bpm].
  Future<RudimentProgress> _progressFor(String rudimentId, int bpm,
      {int? bestBpm}) async {
    final allProgress = await IsarService.instance.rudimentProgress
        .buildQuery<RudimentProgress>()
        .findAll();
    final stored =
        allProgress.where((p) => p.exerciseId == rudimentId).firstOrNull;
    if (stored != null) return stored;
    final now = DateTime.now();
    return RudimentProgress()
      ..exerciseId = rudimentId
      ..currentBpm = bpm
      ..bestBpm = bestBpm ?? bpm
      ..mastery = MasteryLevel.beginner
      ..srInterval = 1
      ..srRepetitions = 0
      ..lastPracticed = now
      ..nextReviewDate = now.add(const Duration(days: 1));
  }

  Future<void> _putProgress(RudimentProgress progress) =>
      IsarService.instance.writeTxn(
        () => IsarService.instance.rudimentProgress.put(progress),
      );
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
