import 'package:drum_coach/content/exercises.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/run/run_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

RunController make(FakeClock clock, FakeSource src, FakeOut out) =>
    RunController(
        exercise: basicRockBeat,
        source: src,
        out: out,
        mapping: KitMapping.gm(),
        latencyOffsetMs: 20,
        platform: 'test',
        nowMs: () => clock.now,
        wait: clock.wait);

void main() {
  test(
      'run: perfect fake strokes → record with firstBeatMs = start + 3000 (80 BPM)',
      () async {
    final clock = FakeClock();
    final start = clock.now;
    final src = FakeSource();
    final out = FakeOut(clock);
    final c = make(clock, src, out);
    final phases = <RunPhase>[];
    c.addListener(() => phases.add(c.phase));
    await c.start();
    expect(c.phase, RunPhase.finished);
    expect(phases,
        containsAllInOrder([RunPhase.countIn, RunPhase.playing, RunPhase.finished]));
    expect(c.record!.firstBeatMs, closeTo(start + 3000, 0.01));
    expect(c.record!.bpm, 80);
    expect(c.record!.latencyOffsetMs, 20);
    expect(c.currentBar, 15);
    expect(src.started && src.stopped && out.stopped, isTrue);
  });

  test('run: device disconnect while playing → deviceLost, record null',
      () async {
    final clock = FakeClock();
    final src = FakeSource();
    final out = FakeOut(clock);
    final c = make(clock, src, out);
    clock.onTick = () {
      if (clock.now > 1000000 + 6000) {
        clock.onTick = null;
        src.conn.add(false);
      }
    };
    await c.start();
    expect(c.phase, RunPhase.deviceLost);
    expect(c.record, isNull);
    expect(out.stopped && src.stopped, isTrue);
  });
}
