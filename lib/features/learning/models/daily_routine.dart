enum RoutineItemType { review, progression, newRudiment }

class DailyRoutineItem {
  final String rudimentId;
  final RoutineItemType type;
  final int suggestedBpm;
  final int suggestedDurationMinutes;

  const DailyRoutineItem({
    required this.rudimentId,
    required this.type,
    required this.suggestedBpm,
    required this.suggestedDurationMinutes,
  });
}
