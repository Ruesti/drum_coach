import 'dart:async';

import 'package:drum_coach/audio/click_track.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:drum_coach/midi/stroke_source.dart';
import 'package:drum_coach/run/device_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../run/fakes.dart';
import 'app_harness.dart';

/// Snare strokes [lagMs] after every click of the calibration track, which
/// FakeOut starts at the clock's current time.
FakeSource _lagging(FakeClock clock, double lagMs) {
  final t = renderClickTrack(bpm: 100, bars: 5, countInBars: 1);
  return FakeSource(strokes: [
    for (final o in t.clickOffsetsMs)
      Stroke(
          timeMs: clock.now + o + lagMs,
          note: 38,
          velocity: 90,
          instrument: KitInstrument.snare),
  ]);
}

Future<DeviceSettings> _openCalibration(WidgetTester tester,
    {required FakeClock clock,
    required Future<StrokeSource?> Function(String, KitMapping) open,
    double? storedMs}) async {
  late DeviceSettings settings;
  await pumpApp(tester, clock: clock, open: open, settings: (s) {
    settings = s;
    if (storedMs != null) s.saveLatency('Fake Module', storedMs, 1);
  });
  await tester.tap(find.text('Setup'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Calibrate latency'));
  await tester.pumpAndSettle();
  return settings;
}

OutlinedButton _startButton(WidgetTester tester) =>
    tester.widget<OutlinedButton>(find.byType(OutlinedButton));

void main() {
  testWidgets(
      'calibration: shows the difference to the stored value before Save; '
      'Save stores', (tester) async {
    final clock = FakeClock();
    final source = _lagging(clock, 23);
    final settings = await _openCalibration(tester,
        clock: clock, open: (_, __) async => source, storedMs: 21);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Offset: 23.0 ms'), findsOneWidget);
    expect(find.text('Differs from the stored calibration by 2.0 ms'),
        findsOneWidget);
    expect(find.text('More than 3 ms — repeat the calibration'), findsNothing);
    expect(settings.latencyFor('Fake Module')!.offsetMs, 21);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(settings.latencyFor('Fake Module')!.offsetMs, closeTo(23, 0.1));
    expect(source.disposed, 1);
  });

  testWidgets('calibration: more than 3 ms off → repeat hint', (tester) async {
    final clock = FakeClock();
    await _openCalibration(tester,
        clock: clock, open: (_, __) async => _lagging(clock, 23), storedMs: 15);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Differs from the stored calibration by 8.0 ms'),
        findsOneWidget);
    expect(
        find.text('More than 3 ms — repeat the calibration'), findsOneWidget);
  });

  testWidgets(
      'calibration: Start is disabled while starting (no second '
      'source)', (tester) async {
    final pending = Completer<StrokeSource?>();
    var opened = 0;
    await _openCalibration(tester, clock: FakeClock(), open: (_, __) {
      opened++;
      return pending.future;
    });
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(_startButton(tester).onPressed, isNull);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    expect(opened, 1);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Could not open the MIDI device.'), findsOneWidget);
    expect(_startButton(tester).onPressed, isNotNull);
  });
}
