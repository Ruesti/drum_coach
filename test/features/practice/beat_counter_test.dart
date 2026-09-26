import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/features/practice/widgets/beat_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('beatOfTick', () {
    test('maps ticks to beats within the bar', () {
      expect(beatOfTick(0, ticksPerQuarter: 24, beatsPerBar: 4), 0);
      expect(beatOfTick(23, ticksPerQuarter: 24, beatsPerBar: 4), 0);
      expect(beatOfTick(24, ticksPerQuarter: 24, beatsPerBar: 4), 1);
      expect(beatOfTick(96, ticksPerQuarter: 24, beatsPerBar: 4), 0);
    });

    test('wraps by the exercise\'s own bar length', () {
      expect(beatOfTick(48, ticksPerQuarter: 24, beatsPerBar: 2), 0);
      expect(beatOfTick(72, ticksPerQuarter: 24, beatsPerBar: 3), 0);
      expect(beatOfTick(48, ticksPerQuarter: 24, beatsPerBar: 3), 2);
    });
  });

  Future<void> pump(WidgetTester tester,
      {required int beatsPerBar, int? activeBeat}) {
    return tester.pumpWidget(MaterialApp(
      theme: drumCoachPracticeTheme,
      home: Scaffold(
        body: BeatCounter(beatsPerBar: beatsPerBar, activeBeat: activeBeat),
      ),
    ));
  }

  Color? colorOf(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style?.color;

  testWidgets('shows one number per beat of the bar', (tester) async {
    await pump(tester, beatsPerBar: 3);
    for (final n in ['1', '2', '3']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('4'), findsNothing);
  });

  testWidgets('paints only the active beat in accent', (tester) async {
    await pump(tester, beatsPerBar: 4, activeBeat: 1);
    expect(colorOf(tester, '2'), PracticeColors.accent);
    expect(colorOf(tester, '1'), PracticeColors.textFaint);
    expect(colorOf(tester, '3'), PracticeColors.textFaint);
    expect(colorOf(tester, '4'), PracticeColors.textFaint);
  });

  testWidgets('idle: no beat is active', (tester) async {
    await pump(tester, beatsPerBar: 4, activeBeat: null);
    for (final n in ['1', '2', '3', '4']) {
      expect(colorOf(tester, n), PracticeColors.textFaint);
    }
  });
}
