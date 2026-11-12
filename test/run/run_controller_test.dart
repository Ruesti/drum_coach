import 'package:drum_coach/content/exercises.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:drum_coach/run/run_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

final kitMap = KitMapping.gm().assign(KitInstrument.kick, 35);

RunController make(FakeClock clock, FakeSource src, FakeOut out,
        {double? latency = 20}) =>
    RunController(
        exercise: basicRockBeat,
        source: src,
        out: out,
        mapping: kitMap,
        latencyOffsetMs: latency,
        platform: 'test',
        nowMs: () => clock.now,
        wait: clock.wait);

void main() {
  test(
      'run: perfect fake strokes → record with firstBeatMs = start + 3000 (80 BPM)',
      () async {
    final clock = FakeClock();
    final start = clock.now;
    final strokes = [
      Stroke(
          timeMs: start + 3000,
          note: 35,
          velocity: 100,
          instrument: KitInstrument.kick),
      Stroke(
          timeMs: start + 3400,
          note: 38,
          velocity: 90,
          instrument: KitInstrument.snare),
    ];
    final src = FakeSource(strokes: strokes);
    final out = FakeOut(clock);
    final c = make(clock, src, out);
    final phases = <RunPhase>[];
    c.addListener(() => phases.add(c.phase));
    await c.start();
    expect(c.phase, RunPhase.finished);
    expect(
        phases,
        containsAllInOrder(
            [RunPhase.countIn, RunPhase.playing, RunPhase.finished]));
    expect(c.record!.firstBeatMs, closeTo(start + 3000, 0.01));
    expect(c.record!.bpm, 80);
    expect(c.record!.latencyOffsetMs, 20);
    expect(c.record!.strokes, strokes);
    expect(c.record!.platform, 'test');
    expect(c.record!.deviceName, 'Fake Module');
    expect(c.record!.mapping.toJson(), kitMap.toJson());
    expect(c.record!.exerciseId, 'rock8');
    expect(c.record!.recordedAt.microsecondsSinceEpoch,
        closeTo((clock.now * 1000).round(), 1000));
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

  test('run: uncalibrated device → latencyOffsetMs null in the record',
      () async {
    final clock = FakeClock();
    final c = make(clock, FakeSource(), FakeOut(clock), latency: null);
    await c.start();
    expect(c.record!.latencyOffsetMs, isNull);
  });

  test('run: device lost while out.play is pending → click stopped', () async {
    final clock = FakeClock();
    final src = FakeSource();
    final out = FakeOut(clock);
    out.onPlay = () async => src.conn.add(false);
    final c = make(clock, src, out);
    out.onPlay = () async {
      src.conn.add(false);
      await Future<void>.delayed(Duration.zero);
    };
    await c.start();
    expect(c.phase, RunPhase.deviceLost);
    expect(c.record, isNull);
    expect(out.played, isNotNull);
    expect(out.stopped, isTrue);
  });

  test('run: device lost during source.start → click never starts', () async {
    final clock = FakeClock();
    final src = FakeSource();
    final out = FakeOut(clock);
    src.onStart = () async {
      src.conn.add(false);
      await Future<void>.delayed(Duration.zero);
    };
    final c = make(clock, src, out);
    await c.start();
    expect(c.phase, RunPhase.deviceLost);
    expect(out.played, isNull);
    expect(c.record, isNull);
  });

  test('run: failing source.start resets to idle and can be retried', () async {
    final clock = FakeClock();
    final src = FakeSource()..startError = StateError('boom');
    final c = make(clock, src, FakeOut(clock));
    await expectLater(c.start(), throwsStateError);
    expect(c.phase, RunPhase.idle);
    src.startError = null;
    await c.start();
    expect(c.phase, RunPhase.finished);
  });

  test(
      'run: cancel while playing → no record, source stopped, click left alone',
      () async {
    final clock = FakeClock();
    final src = FakeSource();
    final out = FakeOut(clock);
    final c = make(clock, src, out);
    var polls = 0;
    clock.onTick = () {
      polls++;
      if (clock.now > 1000000 + 6000) {
        clock.onTick = null;
        c.cancel();
      }
    };
    await c.start();
    expect(c.cancelled, isTrue);
    expect(c.record, isNull);
    expect(c.phase, isNot(RunPhase.finished));
    expect(src.stopped, isTrue);
    expect(out.stopped, isFalse);
    // Ended at the next poll, not at the run's end (51 s = ~1000 polls).
    expect(polls, lessThan(200));
  });

  test('run: cancel during source.start → click never played', () async {
    final clock = FakeClock();
    final src = FakeSource();
    final out = FakeOut(clock);
    final c = make(clock, src, out);
    src.onStart = () async => c.cancel();
    await c.start();
    expect(out.played, isNull);
    expect(src.stopped, isTrue);
    expect(c.record, isNull);
  });

  test('run: cancel while play() is in flight → its own click is stopped',
      () async {
    final clock = FakeClock();
    final src = FakeSource();
    final out = FakeOut(clock);
    final c = make(clock, src, out);
    out.onPlay = () async => c.cancel();
    await c.start();
    expect(out.stopped, isTrue);
    expect(src.stopped, isTrue);
    expect(c.record, isNull);
  });
}
