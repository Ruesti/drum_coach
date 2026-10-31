import '../room/session_planner.dart';

/// What Today offers behind "Continue": always today's room session.
class PathStep {
  final String title;
  final String detail;
  final int minutes;
  final String route;

  const PathStep({
    required this.title,
    required this.detail,
    required this.minutes,
    required this.route,
  });
}

/// Rough length of a session: 5 min warm-up + 25 min deepen (spec 4.2).
const roomSessionMinutes = 30;

/// Pure decision: Continue always opens the room (warm-up + one area). The
/// detail names the suggested area; without a plan the room shows its own
/// empty state.
PathStep computeNextStep({required RoomSession? session}) => PathStep(
      title: "Today's session",
      detail: session == null ? 'Warm-up' : 'Warm-up + ${session.area.label}',
      minutes: roomSessionMinutes,
      route: '/room',
    );
