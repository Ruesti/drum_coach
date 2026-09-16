import '../learning/models/daily_routine.dart';
import '../program/models/training_program.dart';
import '../program/practice_route.dart';

enum PathStepKind { exercise, setup, restDay, dayDone, programComplete }

/// What Today offers behind "Continue the path".
class PathStep {
  final PathStepKind kind;
  final String title;
  final String detail;
  final int minutes;
  final String? route;

  const PathStep({
    required this.kind,
    required this.title,
    required this.detail,
    this.minutes = 0,
    this.route,
  });
}

/// Pure decision: the first open block of today's program day; without a
/// program the first routine item; otherwise the matching non-exercise state.
PathStep computeNextStep({
  required bool hasProgram,
  required ProgramDay? day,
  required Set<int> done,
  required List<DailyRoutineItem> routine,
  required String Function(String id) nameOf,
}) {
  if (!hasProgram) {
    if (routine.isNotEmpty) {
      final item = routine.first;
      final label = switch (item.type) {
        RoutineItemType.review => 'Review',
        RoutineItemType.progression => 'Progression',
        RoutineItemType.newRudiment => 'New',
      };
      return PathStep(
        kind: PathStepKind.exercise,
        title: nameOf(item.rudimentId),
        detail: '$label · ${item.suggestedBpm} BPM',
        minutes: item.suggestedDurationMinutes,
        route: '/routine/${item.rudimentId}?bpm=${item.suggestedBpm}',
      );
    }
    return const PathStep(
      kind: PathStepKind.setup,
      title: 'Set up your path',
      detail: 'Pick duration and level — the path does the rest.',
      route: '/program/setup',
    );
  }
  if (day == null) {
    return const PathStep(
      kind: PathStepKind.programComplete,
      title: 'Program complete',
      detail: 'Start a new one from the program page.',
      route: '/program',
    );
  }
  if (day.type == DayType.rest) {
    return PathStep(
      kind: PathStepKind.restDay,
      title: 'Rest day',
      detail: 'Day ${day.dayNumber} · nothing to play, the streak keeps.',
    );
  }
  int? index;
  for (var i = 0; i < day.blocks.length; i++) {
    if (!done.contains(i)) {
      index = i;
      break;
    }
  }
  if (index == null) {
    return PathStep(
      kind: PathStepKind.dayDone,
      title: 'Day ${day.dayNumber} done',
      detail: 'Come back tomorrow — or practice freely.',
      route: '/program',
    );
  }
  final block = day.blocks[index];
  final bpm = block.startBpm == null ? '' : ' · ${block.startBpm} BPM';
  return PathStep(
    kind: PathStepKind.exercise,
    title: nameOf(block.exerciseKey),
    detail: 'Day ${day.dayNumber} · Step ${index + 1} of ${day.blocks.length}$bpm',
    minutes: block.durationMinutes,
    route: practiceRouteFor(block),
  );
}
