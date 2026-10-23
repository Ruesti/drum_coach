import 'package:drum_coach/features/guided/run_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('run_clock maps ms to bar/beat across tempo change', () {
    final c = RunClock();
    c.addBar(0, 0, 120, 96);
    c.addBar(1, 2000, 120, 96);
    c.addBar(2, 4000, 120, 96);
    c.addBar(3, 6000, 60, 96, sectionIndex: 1, barInSection: 2);
    final p = c.at(7000)!;
    expect(p.bar, 3);
    expect(p.beat, 2);
    expect(p.tick, 24);
    expect(p.bpm, 60);
    expect(p.sectionIndex, 1);
    expect(p.barInSection, 2);
    expect(c.at(1999)!.bar, 0);
    expect(c.at(2000)!.bar, 1);
    expect(c.at(2500)!.beat, 2); // 500 ms = one beat at 120
  });

  test('empty clock and position before the first bar give null', () {
    final c = RunClock();
    expect(c.at(0), isNull);
    c.addBar(0, 100, 120, 96);
    expect(c.at(50), isNull);
  });

  test('past the last bar clamps to its last tick', () {
    final c = RunClock()..addBar(0, 0, 120, 96);
    final p = c.at(5000)!;
    expect(p.bar, 0);
    expect(p.tick, 95);
    expect(p.beat, 4);
  });

  test('plannedAt is now minus the in-tick offset', () {
    final c = RunClock()..addBar(0, 0, 60, 96); // tick = 1000/24 ms
    final now = DateTime(2026, 10, 18, 12);
    final p = c.at(50, now: now)!; // tick 1 starts at 41.67 ms
    expect(p.tick, 1);
    final agoUs = now.difference(p.plannedAt).inMicroseconds;
    expect(agoUs, closeTo((50 - 1000 / 24) * 1000, 2));
  });

  test('addBar must be in order', () {
    final c = RunClock()..addBar(0, 0, 120, 96);
    expect(() => c.addBar(1, -1, 120, 96), throwsArgumentError);
  });

  test('countdown: last step reached in the bar; GO only on beat 1', () {
    final c = RunClock()
      ..addBar(0, 0, 120, 96)
      ..addBar(1, 2000, 120, 96, countdownSteps: const [
        (tick: 24, remaining: 3),
        (tick: 48, remaining: 2),
        (tick: 72, remaining: 1),
      ])
      ..addBar(2, 4000, 120, 96,
          countdownSteps: const [(tick: 0, remaining: 0)]);
    expect(c.at(100)!.countdown, isNull);
    expect(c.at(2100)!.countdown, isNull); // beat 1 of the countdown bar
    expect(c.at(2600)!.countdown, 3);
    expect(c.at(3100)!.countdown, 2);
    expect(c.at(3900)!.countdown, 1);
    expect(c.at(4100)!.countdown, 0); // GO on beat 1 of the variation
    expect(c.at(4600)!.countdown, isNull); // beat 2: gone
  });
}
