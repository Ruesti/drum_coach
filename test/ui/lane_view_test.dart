import 'package:drum_coach/content/analysis.dart';
import 'package:drum_coach/measure/hit_matcher.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/session_record.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:drum_coach/ui/lane_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_loader.dart';

int _count(LaneLayout l, LaneMarkerKind k) =>
    l.markers.where((m) => m.kind == k).length;

SessionRecord _withStrokes(SessionRecord r, List<Stroke> strokes) =>
    SessionRecord(
      exerciseId: r.exerciseId,
      bpm: r.bpm,
      firstBeatMs: r.firstBeatMs,
      latencyOffsetMs: r.latencyOffsetMs,
      deviceName: r.deviceName,
      mapping: r.mapping,
      platform: r.platform,
      recordedAt: r.recordedAt,
      strokes: strokes,
    );

LaneLayout _layout(SessionRecord r) =>
    LaneLayout.fromAnalysis(analyzeSession(r), r, const Size(3092, 150));

/// Each outcome marker directly follows its target tick.
List<(LaneMarker, LaneMarker)> _pairs(LaneLayout l) => [
      for (var i = 0; i < l.markers.length - 1; i++)
        if (l.markers[i].kind == LaneMarkerKind.target)
          (l.markers[i], l.markers[i + 1]),
    ];

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

  test('deviation offset: 0.5 px per ms, clamped to ±30 px', () {
    expect(deviationOffsetPx(7), 3.5);
    expect(deviationOffsetPx(-7), -3.5);
    expect(deviationOffsetPx(100), 30);
    expect(deviationOffsetPx(-100), -30);
  });

  test('layout: +7 ms → every dot 3.5 px right of its target tick', () {
    final l = _layout(loadFixture('rock_plus7ms').record);
    final pairs = _pairs(l);
    expect(pairs, hasLength(192));
    for (final (tick, dot) in pairs) {
      expect(dot.kind, LaneMarkerKind.hit);
      expect(dot.center.dx - tick.center.dx, closeTo(3.5, 1e-9));
      expect(dot.center.dy, tick.center.dy);
    }
  });

  test('layout: +100 ms → dot clamped to 30 px right of its target', () {
    final r = loadFixture('rock_perfect').record;
    final late = _withStrokes(r, [
      for (final s in r.strokes)
        Stroke(
            timeMs: s.timeMs + 100,
            note: s.note,
            velocity: s.velocity,
            instrument: s.instrument),
    ]);
    final pairs = _pairs(_layout(late));
    expect(pairs.where((p) => p.$2.kind == LaneMarkerKind.hit), isNotEmpty);
    for (final (tick, dot) in pairs) {
      if (dot.kind != LaneMarkerKind.hit) continue;
      expect(dot.deviationMs, closeTo(100, 0.01));
      expect(dot.center.dx - tick.center.dx, closeTo(30, 1e-9));
    }
  });

  test('layout: minimum width gives every 8th note 24 px', () {
    final a = loadFixture('rock_plus7ms').analysis;
    // 16 bars × 8 eighths × 24 px + 2 × 10 px padding.
    expect(LaneLayout.minWidth(a.exercise), 3092);
  });

  test('layout: unmapped notes are labelled with their raw note number', () {
    final r = loadFixture('rock_plus7ms').record;
    final strokes = [...r.strokes];
    final i = strokes.indexWhere(
        (s) => s.instrument == KitInstrument.hiHatClosed && s.timeMs > 9000);
    final hh = strokes[i];
    strokes[i] = Stroke(
        timeMs: hh.timeMs,
        note: 99,
        velocity: 70,
        instrument: KitInstrument.unknown);
    // Halfway between two 8th notes: no target near, so an extra.
    strokes.add(Stroke(
        timeMs: hh.timeMs + 187.5,
        note: 98,
        velocity: 80,
        instrument: KitInstrument.unknown));
    strokes.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    final l = _layout(_withStrokes(r, strokes));
    final wrong =
        l.markers.singleWhere((m) => m.kind == LaneMarkerKind.wrongInstrument);
    expect(wrong.label, 'Note 99');
    expect(describeMarker(wrong), contains('Note 99 instead'));
    final extra = l.markers.singleWhere((m) => m.kind == LaneMarkerKind.extra);
    expect(describeMarker(extra), 'extra · Note 98 · vel 80');
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

  testWidgets('narrow: lane view scrolls, taps still hit while scrolled',
      (tester) async {
    final a = loadFixture('rock_plus7ms');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 400,
                child: LaneView(analysis: a.analysis, record: a.record)))));
    final painterFinder = find
        .byWidgetPredicate((w) => w is CustomPaint && w.painter is LanePainter);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.getSize(painterFinder).width, 3092);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(-1500, 0));
    await tester.pumpAndSettle();
    final origin = tester.getTopLeft(painterFinder);
    expect(origin.dx, lessThan(-1000));
    final painter =
        tester.widget<CustomPaint>(painterFinder).painter! as LanePainter;
    final dot = painter.layout.markers.firstWhere((m) =>
        m.kind == LaneMarkerKind.hit && m.bar == 8 && m.lane == Voice.snare);
    final target = origin + dot.center;
    expect(target.dx, inInclusiveRange(56, 400));
    await tester.tapAt(target);
    await tester.pump();
    expect(
        find.textContaining(RegExp(r'^bar 9 · snare · \+7\.0 ms · vel \d+$')),
        findsOneWidget);
  });
}
