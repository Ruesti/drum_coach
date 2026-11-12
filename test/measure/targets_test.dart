import 'package:drum_coach/content/exercises.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rock beat: 16 bars x (8 hh + 2 sn + 2 kick) = 192 targets', () {
    final t = basicRockBeat.targetTimes(firstBeatMs: 1000);
    expect(t.length, 192);
    expect(t.where((x) => x.voice == Voice.snare).first.timeMs, 1000 + 750);
    expect(t.last.bar, 15);
    expect(t.last.voice, Voice.hiHat);
    expect(t.last.timeMs, closeTo(1000 + 15 * 3000 + 3.5 * 750, 1e-9));
    expect([for (final x in t) x.index], List.generate(192, (i) => i));
  });
  test('entry: 8 bars x (4 hh + 2 kick) = 48 targets, bar 1 at 70 BPM', () {
    final t = entryExercise.targetTimes(firstBeatMs: 0);
    expect(t.length, 48);
    expect(
        t.where((x) => x.bar == 1).first.timeMs, closeTo(4 * 60000 / 70, 1e-9));
  });
  test('simultaneous targets sorted hiHat, snare, kick', () {
    final t = basicRockBeat.targetTimes(firstBeatMs: 0);
    expect(t.take(2).map((x) => x.voice), [Voice.hiHat, Voice.kick]);
    final atBeat2 = t.where((x) => x.timeMs == 750 && x.bar == 0).toList();
    expect(atBeat2.map((x) => x.voice), [Voice.hiHat, Voice.snare]);
  });
}
