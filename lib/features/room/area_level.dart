import '../../data/local/models/rudiment_progress.dart';
import '../lessons/models/rudiment.dart';
import 'training_area.dart';

/// Share of an area's exercises in one level that must "sit" (mastered)
/// before the level counts as done.
const double kLevelDoneShare = 0.8;

/// The player's current level in [area]: the lowest level where fewer than
/// 80 % of the exercises are mastered. Levels without exercises are skipped;
/// if every level is done, the highest existing one is returned.
Difficulty areaLevel(
  TrainingArea area,
  List<Rudiment> catalog,
  Map<String, RudimentProgress> progress,
) {
  Difficulty? highest;
  for (final level in Difficulty.values) {
    final cell =
        catalog.where((r) => r.area == area && r.difficulty == level).toList();
    if (cell.isEmpty) continue;
    highest = level;
    final sitting = cell
        .where((r) => progress[r.id]?.mastery == MasteryLevel.mastered)
        .length;
    if (sitting / cell.length < kLevelDoneShare) return level;
  }
  return highest ?? Difficulty.values.first;
}
