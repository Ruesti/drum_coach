import 'package:drum_coach/features/room/session_planner.dart';
import 'package:drum_coach/features/room/training_area.dart';
import 'package:drum_coach/features/today/next_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Continue is always today's session in the room", () {
    final step = computeNextStep(
      session: const RoomSession(
        warmup: ['a'],
        area: TrainingArea.rudiments,
        deepen: ['b'],
      ),
    );
    expect(step.title, "Today's session");
    expect(step.detail, 'Warm-up + Rudiments');
    expect(step.minutes, 30);
    expect(step.route, '/room');
  });

  test('without a plan Continue still opens the room', () {
    final step = computeNextStep(session: null);
    expect(step.title, "Today's session");
    expect(step.detail, 'Warm-up');
    expect(step.route, '/room');
  });
}
