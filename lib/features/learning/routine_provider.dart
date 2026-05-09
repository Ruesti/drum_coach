import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/isar_service.dart';
import '../../data/local/models/rudiment_progress.dart';
import '../lessons/lessons_provider.dart';
import 'models/daily_routine.dart';

part 'routine_provider.g.dart';

const _maxItems = 5;

@riverpod
Future<List<DailyRoutineItem>> dailyRoutine(DailyRoutineRef ref) async {
  final allRudiments = ref.watch(rudimentsProvider);
  final allProgress =
      await IsarService.instance.rudimentProgress
          .buildQuery<RudimentProgress>()
          .findAll();
  final progressMap = {for (final p in allProgress) p.rudimentId: p};
  final today = DateTime.now();
  final items = <DailyRoutineItem>[];

  // 1. Overdue reviews
  for (final p in allProgress) {
    if (items.length >= _maxItems) break;
    if (!p.nextReviewDate.isAfter(today) &&
        p.mastery != MasteryLevel.mastered) {
      final r = allRudiments.where((r) => r.id == p.rudimentId).firstOrNull;
      if (r == null) continue;
      items.add(DailyRoutineItem(
        rudimentId: p.rudimentId,
        type: RoutineItemType.review,
        suggestedBpm: p.currentBpm,
        suggestedDurationMinutes: 6,
      ));
    }
  }

  // 2. Active progressions (started, not mastered, not yet due)
  for (final p in allProgress) {
    if (items.length >= _maxItems) break;
    if (p.mastery != MasteryLevel.mastered &&
        p.nextReviewDate.isAfter(today) &&
        items.every((i) => i.rudimentId != p.rudimentId)) {
      items.add(DailyRoutineItem(
        rudimentId: p.rudimentId,
        type: RoutineItemType.progression,
        suggestedBpm: p.currentBpm,
        suggestedDurationMinutes: 5,
      ));
    }
  }

  // 3. One new rudiment
  if (items.length < _maxItems) {
    final startedIds = progressMap.keys.toSet();
    final newRudiment = (allRudiments
          .where((r) => !startedIds.contains(r.id))
          .toList()
        ..sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index)))
        .firstOrNull;
    if (newRudiment != null) {
      items.add(DailyRoutineItem(
        rudimentId: newRudiment.id,
        type: RoutineItemType.newRudiment,
        suggestedBpm: newRudiment.minBpm,
        suggestedDurationMinutes: 7,
      ));
    }
  }

  return items;
}
