import 'package:drum_coach/features/metronome/click_loop_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tickAtPosition', () {
    test('maps a loop position to tick index and in-tick offset', () {
      // 4 ticks à 500 ms; position 1250 ms → tick 2, 250 ms into it.
      final t = tickAtPosition(
          positionMs: 1250, tickDurMs: 500, ticksInLoop: 4);
      expect(t.tickInLoop, 2);
      expect(t.inTickMs, closeTo(250, 0.001));
    });

    test('clamps to the last tick when position sits at the loop end', () {
      final t = tickAtPosition(
          positionMs: 1999.9, tickDurMs: 500, ticksInLoop: 4);
      expect(t.tickInLoop, 3);
    });

    test('wraps positions beyond one loop cycle', () {
      final t = tickAtPosition(
          positionMs: 2250, tickDurMs: 500, ticksInLoop: 4);
      expect(t.tickInLoop, 0, reason: '2250 ms = second cycle, tick 0');
      expect(t.inTickMs, closeTo(250, 0.001));
    });
  });

  group('advanceGlobalTick', () {
    test('accumulates wraps when the loop position jumps backwards', () {
      // Last global tick was 3 (end of cycle 0); new in-loop tick is 0 →
      // the loop wrapped: global tick must be 4, not 0.
      expect(
        advanceGlobalTick(lastGlobalTick: 3, tickInLoop: 0, ticksInLoop: 4),
        4,
      );
    });

    test('moves forward within the same cycle', () {
      expect(
        advanceGlobalTick(lastGlobalTick: 4, tickInLoop: 2, ticksInLoop: 4),
        6,
      );
    });

    test('stays put when the tick has not changed', () {
      expect(
        advanceGlobalTick(lastGlobalTick: 6, tickInLoop: 2, ticksInLoop: 4),
        6,
      );
    });
  });
}
