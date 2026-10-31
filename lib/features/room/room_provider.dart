import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/models/rudiment_progress.dart';
import '../lessons/lessons_provider.dart';
import '../stats/stats_provider.dart';
import 'session_planner.dart';
import 'training_area.dart';

/// All stored progress rows by exercise id — the old rows stay valid.
final roomProgressProvider =
    FutureProvider.autoDispose<Map<String, RudimentProgress>>((ref) async {
  final rows = await ref.watch(allProgressProvider.future);
  return {for (final p in rows) p.exerciseId: p};
});

/// The area the player picked in the room; null = take the suggestion.
final roomChosenAreaProvider =
    StateProvider.autoDispose<TrainingArea?>((ref) => null);

/// One room session plus what the area picker needs.
class RoomPlan {
  final RoomSession session;

  /// The planner's own pick, marked on its chip.
  final TrainingArea suggested;

  /// Every area with at least one exercise, in enum order.
  final List<TrainingArea> areas;

  const RoomPlan({
    required this.session,
    required this.suggested,
    required this.areas,
  });
}

/// Today's plan; null when nothing can be planned (empty catalog).
final roomPlanProvider = FutureProvider.autoDispose<RoomPlan?>((ref) async {
  // Watch everything before the first await: a dependency first watched
  // after it would sit unwatched meanwhile and an autoDispose one (the
  // chosen area) would reset.
  final catalog = ref.watch(rudimentsProvider);
  final chosen = ref.watch(roomChosenAreaProvider);
  final progress = await ref.watch(roomProgressProvider.future);
  final now = DateTime.now();
  final suggestion =
      planSession(catalog: catalog, progress: progress, now: now);
  if (suggestion == null) return null;
  final session = chosen == null
      ? suggestion
      : planSession(
              catalog: catalog, progress: progress, now: now, chosen: chosen) ??
          suggestion;
  final present = {for (final r in catalog) r.area};
  return RoomPlan(
    session: session,
    suggested: suggestion.area,
    areas: TrainingArea.values.where(present.contains).toList(),
  );
});
