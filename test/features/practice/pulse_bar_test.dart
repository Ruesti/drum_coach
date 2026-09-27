import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/features/practice/widgets/pulse_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pulseLevel', () {
    test('maps the pattern volumes to three visible sizes and silence', () {
      expect(pulseLevel(2.0), 1.0); // accent
      expect(pulseLevel(0.85), closeTo(0.6, 0.01)); // normal
      expect(pulseLevel(0.25), closeTo(0.3, 0.01)); // ghost / grace
      expect(pulseLevel(0.0), 0.0); // rest
    });
  });

  group('progressAt', () {
    test('runs from the anchor tick with the tick duration and wraps', () {
      final at = DateTime(2026, 9, 27, 12, 0, 0);
      // 96 ticks per loop, 10 ms per tick: at the anchor → tick 24 of 96.
      expect(
          progressAt(
              anchorTick: 24,
              anchorAt: at,
              now: at,
              tickDurMs: 10,
              totalTicks: 96),
          closeTo(0.25, 1e-9));
      // 240 ms later: 24 more ticks → 48/96.
      expect(
          progressAt(
              anchorTick: 24,
              anchorAt: at,
              now: at.add(const Duration(milliseconds: 240)),
              tickDurMs: 10,
              totalTicks: 96),
          closeTo(0.5, 1e-9));
      // A full loop later it wraps back.
      expect(
          progressAt(
              anchorTick: 24,
              anchorAt: at,
              now: at.add(const Duration(milliseconds: 960)),
              tickDurMs: 10,
              totalTicks: 96),
          closeTo(0.25, 1e-9));
    });

    test('a global (unwrapped) anchor tick is folded into the loop', () {
      final at = DateTime(2026, 9, 27);
      expect(
          progressAt(
              anchorTick: 96 * 5 + 48,
              anchorAt: at,
              now: at,
              tickDurMs: 10,
              totalTicks: 96),
          closeTo(0.5, 1e-9));
    });
  });

  testWidgets('idle bar paints quarter marks and no pulse', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: drumCoachPracticeTheme,
      home: const Scaffold(
        body: PulseBar(
          playing: false,
          anchorTick: -1,
          anchorAt: null,
          tickDurMs: 10,
          totalTicks: 96,
          ticksPerQuarter: 24,
          pulseVolume: 0,
        ),
      ),
    ));
    final painter = tester
        .widget<CustomPaint>(find.byType(CustomPaint).last)
        .painter as PulseBarPainter;
    expect(painter.quarterMarks, 4);
    expect(painter.progress, 0);
    expect(painter.pulse, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new onset flashes a pulse sized by its volume, then fades',
      (tester) async {
    Widget bar(int tick, double volume) => MaterialApp(
          theme: drumCoachPracticeTheme,
          home: Scaffold(
            body: PulseBar(
              playing: true,
              anchorTick: tick,
              anchorAt: DateTime.now(),
              tickDurMs: 10,
              totalTicks: 96,
              ticksPerQuarter: 24,
              pulseVolume: volume,
            ),
          ),
        );
    PulseBarPainter painter() => tester
        .widget<CustomPaint>(find.byType(CustomPaint).last)
        .painter as PulseBarPainter;

    await tester.pumpWidget(bar(0, 2.0));
    await tester.pump();
    expect(painter().pulse, closeTo(1.0, 0.05));

    await tester.pumpWidget(bar(24, 0.25));
    await tester.pump();
    expect(painter().pulse, closeTo(0.3, 0.05));
    // The flash fades out within 300 ms.
    await tester.pump(const Duration(milliseconds: 400));
    expect(painter().pulse, lessThan(0.05));
    expect(tester.takeException(), isNull);
  });
}
