import 'package:drum_coach/measure/hit_matcher.dart';
import 'package:drum_coach/ui/lane_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_loader.dart';

int _count(LaneLayout l, LaneMarkerKind k) =>
    l.markers.where((m) => m.kind == k).length;

void main() {
  test('layout: one tick per target, one outcome per target, one × per extra',
      () {
    final a = loadFixture('rock_double_trigger');
    final l =
        LaneLayout.fromAnalysis(a.analysis, a.record, const Size(800, 150));
    final targets = a.analysis.match.targets;
    expect(_count(l, LaneMarkerKind.target), targets.length);
    expect(_count(l, LaneMarkerKind.hit),
        targets.where((o) => o.kind == HitKind.hit).length);
    expect(_count(l, LaneMarkerKind.missed),
        targets.where((o) => o.kind == HitKind.missed).length);
    expect(_count(l, LaneMarkerKind.extra),
        a.analysis.match.extraStrokeIndices.length);
    expect(_count(l, LaneMarkerKind.extra), 5);
  });

  test('layout: wrong instrument gets a square with the instrument label', () {
    final a = loadFixture('rock_crash_for_hihat');
    final l =
        LaneLayout.fromAnalysis(a.analysis, a.record, const Size(800, 150));
    final wrong =
        l.markers.where((m) => m.kind == LaneMarkerKind.wrongInstrument);
    expect(wrong.length, 40);
    expect(wrong.first.label, 'Crash 1');
  });

  test('layout: dot radius grows with velocity, 3–8 px', () {
    expect(dotRadius(1), 3);
    expect(dotRadius(127), 8);
    expect(dotRadius(64), closeTo(5.5, 0.01));
  });

  test('layout: deviation colour — early blue, on time green, late orange', () {
    expect(deviationColor(-15.1), laneEarly);
    expect(deviationColor(-15), laneOnTime);
    expect(deviationColor(15), laneOnTime);
    expect(deviationColor(15.1), laneLate);
  });

  test('describe: bar is 1-based, signed deviation, velocity', () {
    final a = loadFixture('rock_plus7ms');
    final l =
        LaneLayout.fromAnalysis(a.analysis, a.record, const Size(800, 150));
    final hit = l.markers.firstWhere((m) => m.kind == LaneMarkerKind.hit);
    expect(describeMarker(hit),
        matches(r'^bar 1 · hi-hat · \+7\.0 ms · vel \d+$'));
  });

  testWidgets('lane view paints one marker per target and per extra',
      (tester) async {
    final a = loadFixture('rock_double_trigger');
    await tester.pumpWidget(MaterialApp(
        home:
            Scaffold(body: LaneView(analysis: a.analysis, record: a.record))));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<LanePainter>()
        .single;
    expect(_count(painter.layout, LaneMarkerKind.target),
        a.analysis.targets.length);
    expect(_count(painter.layout, LaneMarkerKind.extra), 5);
    expect(tester.takeException(), isNull);
  });
}
