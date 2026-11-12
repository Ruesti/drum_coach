import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/ui/feedback_screen.dart';
import 'package:drum_coach/ui/lane_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_loader.dart';

Future<void> _pump(WidgetTester tester, FeedbackArgs args) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: FeedbackScreen(args: args)));
}

void main() {
  testWidgets(
      'feedback: rock_plus7ms fixture → PASSED, 8 rows (3 hit rates, wrong, '
      'extra, median, spread, velocity), median 7.0', (tester) async {
    final args = loadFixture('rock_plus7ms');
    await _pump(tester, args);
    expect(find.text('PASSED'), findsOneWidget);
    expect(find.byType(GateRow), findsNWidgets(8));
    for (final label in [
      'Hi-hat hit rate',
      'Snare hit rate',
      'Kick hit rate',
      'Wrong instrument',
      'Extra hits',
      'Timing median (ms)',
      'Timing spread (ms)',
      'Snare velocity SD',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('7.0'), findsOneWidget);
    expect(find.text('≤ 15.0'), findsOneWidget);
    expect(find.text('≥ 95.0 %'), findsNWidgets(3));
    expect(find.text('✗'), findsNothing);
    expect(find.text(args.path), findsOneWidget);
    expect(find.text('uncalibrated'), findsNothing);
  });

  testWidgets(
      'feedback: tapping a hit dot shows bar, voice, deviation and velocity',
      (tester) async {
    final args = loadFixture('rock_plus7ms');
    await _pump(tester, args);
    final painterFinder = find
        .byWidgetPredicate((w) => w is CustomPaint && w.painter is LanePainter);
    final painter =
        tester.widget<CustomPaint>(painterFinder).painter! as LanePainter;
    // A snare dot of bar 3: away from the edges, alone in its lane.
    final dot = painter.layout.markers.firstWhere((m) =>
        m.kind == LaneMarkerKind.hit && m.bar == 2 && m.lane == Voice.snare);
    await tester.tapAt(tester.getTopLeft(painterFinder) + dot.center);
    await tester.pump();
    expect(
        find.textContaining(RegExp(r'^bar 3 · snare · \+7\.0 ms · vel \d+$')),
        findsOneWidget);
  });

  testWidgets('feedback: rock_uncalibrated → NOT MEASURABLE banner',
      (tester) async {
    await _pump(tester, loadFixture('rock_uncalibrated'));
    expect(find.text('NOT MEASURABLE (calibrate first)'), findsOneWidget);
    expect(find.text('uncalibrated'), findsOneWidget);
    expect(find.text('PASSED'), findsNothing);
  });

  testWidgets('feedback: entry_stops_bar4 → NOT PASSED + basics hint',
      (tester) async {
    await _pump(tester, loadFixture('entry_stops_bar4'));
    expect(find.text('NOT PASSED'), findsOneWidget);
    expect(find.text('Start with the basics first'), findsOneWidget);
    expect(find.text('✗'), findsWidgets);
  });
}
