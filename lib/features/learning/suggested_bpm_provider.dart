import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/isar_service.dart';
import '../../data/local/models/rudiment_progress.dart';
import '../lessons/lessons_provider.dart';

part 'suggested_bpm_provider.g.dart';

/// The BPM to start an exercise at: the tempo left off at last session
/// (already rating-adjusted by [BpmProgressionService] — struggled keeps it,
/// OK adds 2, solid adds 5), or the exercise's minimum tempo if it's never
/// been practiced. Used so starting any exercise picks up where that
/// exercise left off instead of carrying over whatever tempo another
/// exercise happened to be left at.
@riverpod
Future<int> suggestedBpm(SuggestedBpmRef ref, String rudimentId) async {
  final allProgress = await IsarService.instance.rudimentProgress
      .buildQuery<RudimentProgress>()
      .findAll();
  final progress =
      allProgress.where((p) => p.exerciseId == rudimentId).firstOrNull;
  if (progress != null) return progress.currentBpm;
  return ref.watch(rudimentByIdProvider(rudimentId)).minBpm;
}
