import 'package:drum_coach/audio/click_track.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:drum_coach/run/calibration_controller.dart';
import 'package:drum_coach/run/device_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<CalibrationController> runWith(double lagMs) async {
  final clock = FakeClock();
  final t = renderClickTrack(bpm: 100, bars: 5, countInBars: 1);
  expect(t.clickOffsetsMs.length, 24);
  final strokes = [
    for (final o in t.clickOffsetsMs)
      Stroke(
          timeMs: clock.now + o + lagMs,
          note: 38,
          velocity: 90,
          instrument: KitInstrument.snare),
  ];
  final c = CalibrationController(
      source: FakeSource(strokes: strokes),
      out: FakeOut(clock),
      nowMs: () => clock.now,
      wait: clock.wait);
  await c.run();
  return c;
}

void main() {
  test(
      'calibration: strokes 23 ms after every click → offset 23 ± 0.1, not unsure',
      () async {
    final c = await runWith(23);
    expect(c.result!.offsetMs, closeTo(23, 0.1));
    expect(c.result!.clicks, 20);
    expect(c.result!.unsure, isFalse);
  });

  test('calibration difference to previous: 23 vs 21 → 2.0', () async {
    SharedPreferences.setMockInitialValues({});
    final s = DeviceSettings(await SharedPreferences.getInstance());
    final c = await runWith(23);
    expect(c.differenceToPreviousMs(s, 'Fake Module'), isNull);
    await s.saveLatency('Fake Module', 21, 1);
    await s.saveLatency('Fake Module', 21, 1);
    expect(c.differenceToPreviousMs(s, 'Fake Module'), closeTo(2.0, 0.1));
    await c.save(s, 'Fake Module');
    expect(s.latencyFor('Fake Module')!.offsetMs, closeTo(23, 0.1));
  });
}
