import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/guided_pages.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/widgets/guided_line_view.dart'
    show rudimentForGuidedLine;
import 'package:drum_coach/features/guided/widgets/guided_page_view.dart';
import 'package:drum_coach/features/practice/widgets/line_view.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../playhead_probe.dart';

GuidedExercise _named(String name) =>
    guidedCatalog.firstWhere((e) => e.name == name);

GuidedPage _preview(GuidedExercise ex, int i) =>
    guidedPreviewPages(ex, pageBars: 4)[i];

GuidedPage _outro(GuidedExercise ex) {
  final i = ex.sections.indexWhere((s) => s.kind == SectionKind.outro);
  final s = ex.sections[i];
  return GuidedPage(
      sectionIndex: i,
      firstBar: 0,
      bars: s.bars,
      line: pageLine(s.line, ex.gridUnit, firstBar: 0, bars: s.bars));
}

Widget _host(Widget child, double width, {double height = 400}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: drumCoachTheme,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: const Key('shot'),
            child: Container(
              width: width,
              height: height,
              color: Colors.white,
              child: child,
            ),
          ),
        ),
      ),
    );

bool _is(Paint p, Color c) => p.color.toARGB32() == c.toARGB32();

/// Playhead lines in [colour], x in screen pixels.
List<double> _heads(WidgetTester t, Color colour) {
  final sc = staffCalls(t, find.byType(GuidedPageView));
  return [
    for (final c in sc.calls)
      if (c.$1 == #drawLine && _is(c.$2[2] as Paint, colour))
        sc.origin.dx + (c.$2[0] as Offset).dx * sc.scale,
  ];
}

void main() {
  setUpAll(() async {
    final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
    final loader = FontLoader('Bravura')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    AppTypography.label;
    await GoogleFonts.pendingFonts();
  });

  for (final w in [2560.0, 1920.0]) {
    testWidgets('four-bar kit page is one row at ${w.toInt()}', (t) async {
      await t.binding.setSurfaceSize(Size(w, 500));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final ex = _named('Funk Sixteenths');
      final page = _preview(ex, 2);
      expect(page.bars, 4);
      await t.pumpWidget(_host(
          GuidedPageView(exercise: ex, page: page, maxStaffHeight: 300), w));
      expect(t.takeException(), isNull);
      final sheet = t.widget<SheetStaffWidget>(find.byType(SheetStaffWidget));
      final geo = sheet.geometry!;
      expect(geo.layouts[0].rowCount, 1);
      expect(geo.layouts[0].barsPerRow, 4);
    });
  }

  testWidgets('page staff is not drawn below natural size at 1920 wide',
      (t) async {
    await t.binding.setSurfaceSize(const Size(1920, 500));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final ex = _named('Funk Sixteenths');
    await t.pumpWidget(_host(
        GuidedPageView(exercise: ex, page: _preview(ex, 2), activeTick: 0),
        1920));
    final sc = staffCalls(t, find.byType(GuidedPageView));
    expect(sc.scale, greaterThanOrEqualTo(1.0));
    // Fills the width.
    expect(t.getSize(find.byType(FittedBox)).width, closeTo(1920, 1));
  });

  testWidgets('outro page bar has the width of a full page bar', (t) async {
    await t.binding.setSurfaceSize(const Size(1920, 500));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final ex = _named('Funk Sixteenths');
    final full = _preview(ex, 2);
    final outro = _outro(ex);
    expect(outro.bars, 1);
    Future<double> halfBar(GuidedPage p) async {
      await t.pumpWidget(
          _host(GuidedPageView(exercise: ex, page: p, activeTick: 0), 1920));
      final a = _heads(t, guidedPlayheadBlue).single;
      await t.pumpWidget(
          _host(GuidedPageView(exercise: ex, page: p, activeTick: 48), 1920));
      return _heads(t, guidedPlayheadBlue).single - a;
    }

    final f = await halfBar(full);
    final o = await halfBar(outro);
    expect(o, closeTo(f, 0.5));
    // Flush left: the outro staff is narrower than the full one.
    expect(t.getSize(find.byType(FittedBox)).width, lessThan(1920 / 2));
  });

  testWidgets('playhead is blue and moves with activeTick', (t) async {
    await t.binding.setSurfaceSize(const Size(1920, 500));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final ex = _named('Funk Sixteenths');
    final page = _preview(ex, 2);
    Future<List<double>> at(int? tick) async {
      await t.pumpWidget(_host(
          GuidedPageView(exercise: ex, page: page, activeTick: tick), 1920));
      return _heads(t, guidedPlayheadBlue);
    }

    expect(await at(null), isEmpty);
    final a = await at(0);
    final b = await at(96);
    expect(a, hasLength(1));
    expect(b, hasLength(1));
    expect(b.single, greaterThan(a.single + 100));
    // No accent-coloured playhead.
    final sc = staffCalls(t, find.byType(GuidedPageView));
    expect(sc.playheads, isEmpty);
  });

  testWidgets('no note is coloured', (t) async {
    await t.binding.setSurfaceSize(const Size(1920, 500));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final ex = _named('Funk Sixteenths');
    await t.pumpWidget(_host(
        GuidedPageView(exercise: ex, page: _preview(ex, 2), activeTick: 24),
        1920));
    final sc = staffCalls(t, find.byType(GuidedPageView));
    expect(sc.hasCursorField, isFalse);
    expect(sc.hasNoteRing, isFalse);
    // Accents are plain ink too: nothing is drawn in the accent colour.
    expect([
      for (final c in sc.calls)
        for (final a in c.$2)
          if (a is Paint && _is(a, AppColors.paperAccent)) a
    ], isEmpty);
    // And no paper card behind the notes.
    expect(
        find.descendant(
            of: find.byType(GuidedPageView),
            matching: find.byWidgetPredicate((w) =>
                w is Container &&
                w.decoration == SheetStaffWidget.cardDecoration)),
        findsNothing);
    expect(t.widget<LineView>(find.byType(LineView)).cursorStyle,
        CursorStyle.line);
  });

  testWidgets('dimmed page has opacity 0.38', (t) async {
    final ex = _named('Funk Sixteenths');
    await t.pumpWidget(_host(
        GuidedPageView(exercise: ex, page: _preview(ex, 2), dimmed: true),
        1200));
    final op = t.widget<Opacity>(find.descendant(
        of: find.byType(GuidedPageView), matching: find.byType(Opacity)));
    expect(op.opacity, 0.38);
  });

  testWidgets('practice LineView playhead stays accent', (t) async {
    final ex = _named('Funk Sixteenths');
    final r = rudimentForGuidedLine(ex, _preview(ex, 2).line);
    await t.pumpWidget(MaterialApp(
      theme: drumCoachTheme,
      home: Scaffold(
        body: SizedBox(
          width: 700,
          child: LineView(
              rudiment: r,
              line: 0,
              activeTick: 24,
              showCounts: false,
              cursorStyle: CursorStyle.line),
        ),
      ),
    ));
    final sc = staffCalls(t, find.byType(LineView));
    expect(sc.playheads, hasLength(1));
  });

  testWidgets('golden: kit page wide', (t) async {
    await t.binding.setSurfaceSize(const Size(1920, 400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final ex = _named('Funk Sixteenths');
    await t.pumpWidget(_host(
        GuidedPageView(
            exercise: ex,
            page: _preview(ex, 2),
            activeTick: 120,
            maxStaffHeight: 360),
        1920));
    expect(t.takeException(), isNull);
    await expectLater(find.byKey(const Key('shot')),
        matchesGoldenFile('../../goldens/guided_page_kit_wide.png'));
  });

  testWidgets('golden: pad page wide', (t) async {
    await t.binding.setSurfaceSize(const Size(1920, 400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final ex = _named('Triplet Flams and Drags');
    await t.pumpWidget(_host(
        GuidedPageView(
            exercise: ex,
            page: _preview(ex, 2),
            activeTick: 120,
            maxStaffHeight: 360),
        1920));
    expect(t.takeException(), isNull);
    await expectLater(find.byKey(const Key('shot')),
        matchesGoldenFile('../../goldens/guided_page_pad_wide.png'));
  });
}
