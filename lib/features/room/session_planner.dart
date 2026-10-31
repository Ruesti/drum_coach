import '../../data/local/models/rudiment_progress.dart';
import '../lessons/models/rudiment.dart';
import 'area_level.dart';
import 'training_area.dart';

/// One planned room session: warm-up, the focus area, and what to deepen.
class RoomSession {
  final List<String> warmup;
  final TrainingArea area;
  final List<String> deepen;

  const RoomSession({
    required this.warmup,
    required this.area,
    required this.deepen,
  });
}

const _warmupAreas = [
  TrainingArea.handTechnique,
  TrainingArea.rudiments,
  TrainingArea.feet,
];
const _maxDeepen = 5;

bool _due(RudimentProgress? p, DateTime now) =>
    p != null && !p.nextReviewDate.isAfter(now);

/// Returns null when no exercise has an area (nothing to plan).
RoomSession? planSession({
  required List<Rudiment> catalog,
  required Map<String, RudimentProgress> progress,
  required DateTime now,
  TrainingArea? chosen,
}) {
  final inArea = <TrainingArea, List<Rudiment>>{};
  for (final r in catalog) {
    final a = r.area;
    if (a != null) (inArea[a] ??= []).add(r);
  }

  // Warm-up: one exercise per basic area, from its current level.
  final warmup = <String>[];
  for (final a in _warmupAreas) {
    if (inArea[a] == null) continue;
    final level = areaLevel(a, catalog, progress);
    final cands = inArea[a]!.where((r) => r.difficulty == level).toList();
    if (cands.isEmpty) continue;
    final pick = cands.firstWhere(
      (r) => progress[r.id] != null && !_due(progress[r.id], now),
      orElse: () => cands.first,
    );
    warmup.add(pick.id);
  }

  final area = _pickArea(inArea, progress, now, chosen);
  if (area == null) return null;

  // Deepen: due reviews first (earliest due first), then next unmastered.
  final due = inArea[area]!.where((r) => _due(progress[r.id], now)).toList()
    ..sort((a, b) => progress[a.id]!
        .nextReviewDate
        .compareTo(progress[b.id]!.nextReviewDate));
  final deepen = due.map((r) => r.id).toList();
  final level = areaLevel(area, catalog, progress);
  final next = inArea[area]!.where((r) =>
      r.difficulty == level &&
      progress[r.id]?.mastery != MasteryLevel.mastered &&
      !deepen.contains(r.id));
  deepen.addAll(next.map((r) => r.id));

  return RoomSession(
    warmup: warmup.take(3).toList(),
    area: area,
    deepen: deepen.take(_maxDeepen).toList(),
  );
}

TrainingArea? _pickArea(
  Map<TrainingArea, List<Rudiment>> inArea,
  Map<String, RudimentProgress> progress,
  DateTime now,
  TrainingArea? chosen,
) {
  if (chosen != null && inArea[chosen] != null) return chosen;
  final areas = TrainingArea.values.where((a) => inArea[a] != null).toList();
  if (areas.isEmpty) return null;

  int dueCount(TrainingArea a) =>
      inArea[a]!.where((r) => _due(progress[r.id], now)).length;
  final withDue = areas.where((a) => dueCount(a) > 0).toList();
  if (withDue.isNotEmpty) {
    var best = withDue.first;
    for (final a in withDue) {
      if (dueCount(a) > dueCount(best)) best = a;
    }
    return best;
  }

  // Longest not played; never played counts as longest.
  DateTime? lastPlayed(TrainingArea a) {
    DateTime? latest;
    for (final r in inArea[a]!) {
      final p = progress[r.id];
      if (p != null && (latest == null || p.lastPracticed.isAfter(latest))) {
        latest = p.lastPracticed;
      }
    }
    return latest;
  }

  var best = areas.first;
  var bestTime = lastPlayed(best);
  for (final a in areas.skip(1)) {
    if (bestTime == null) break;
    final t = lastPlayed(a);
    if (t == null || t.isBefore(bestTime)) {
      best = a;
      bestTime = t;
    }
  }
  return best;
}
