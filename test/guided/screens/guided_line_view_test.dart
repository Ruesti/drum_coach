import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/guided_pages.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/run_clock.dart';
import 'package:drum_coach/features/guided/widgets/guided_line_view.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/practice/widgets/line_view.dart';
import 'package:drum_coach/shared/widgets/kit_layout.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../playhead_probe.dart';

GuidedExercise _first(GuidedPackage p) =>
    guidedCatalog.firstWhere((e) => e.package == p);

ExerciseLine _v1(GuidedExercise ex) =>
    ex.sections.firstWhere((s) => s.kind == SectionKind.variation).line;

RunPosition _pos({required int barInSection, required int tick}) => RunPosition(
      bar: 5,
      sectionIndex: 2,
      barInSection: barInSection,
      beat: tick ~/ 24 + 1,
      tick: tick,
      bpm: 90,
      plannedAt: DateTime(2026),
    );

Widget _host(Widget child, double width) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: drumCoachPracticeTheme,
      home: Scaffold(
        backgroundColor: PracticeColors.base,
        body: Center(
          child: RepaintBoundary(
            key: const Key('shot'),
            child: Container(
              width: width,
              color: PracticeColors.base,
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
    final loader = FontLoader('Bravura')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    AppTypography.label;
    await GoogleFonts.pendingFonts();
  });

  test('adapter keeps voices and grid', () {
    final ex = _first(GuidedPackage.kit);
    final line = _v1(ex);
    final r = rudimentForGuidedLine(ex, line);
    expect(r.isKit, isTrue);
    expect(r.sheet, hasLength(1));
    expect(r.gridUnit, ex.gridUnit);
    expect(r.beatsPerBar, guidedBeatsPerBar);
    expect(r.sheet.single.kitVoices.length, line.kitVoices.length);
    expect(ticksOf(r.sheet.single.beats, r.gridUnit),
        ticksOf(line.beats, ex.gridUnit));
  });

  test('adapter: pad line stays a pad line', () {
    final ex = _first(GuidedPackage.pad);
    final r = rudimentForGuidedLine(ex, _v1(ex));
    expect(r.isKit, isFalse);
    expect(r.sheet, hasLength(1));
    expect(r.sticking, _v1(ex).beats);
  });

  test('lineTickFor maps the bar in the section onto the line', () {
    final ex = _first(GuidedPackage.kit);
    final one = _v1(ex);
    final bars = ticksOf(one.beats, ex.gridUnit) ~/ 96;
    expect(lineTickFor(_pos(barInSection: 0, tick: 30), one, ex.gridUnit), 30);
    expect(
        lineTickFor(_pos(barInSection: bars, tick: 30), one, ex.gridUnit), 30);
    if (bars == 1) {
      expect(
          lineTickFor(_pos(barInSection: 3, tick: 10), one, ex.gridUnit), 10);
    }
    // A two-bar line: the second bar starts at tick 96.
    final two = ExerciseLine.kit([
      for (final v in one.kitVoices)
        Voice(v.instrument, [...v.beats, ...v.beats]),
    ]);
    final twoBars = ticksOf(two.beats, ex.gridUnit) ~/ 96;
    expect(twoBars, 2 * bars);
    expect(lineTickFor(_pos(barInSection: 1, tick: 10), two, ex.gridUnit), 106);
    expect(lineTickFor(_pos(barInSection: twoBars, tick: 10), two, ex.gridUnit),
        10);
  });

  testWidgets('dimmed renders at 45 %', (t) async {
    final ex = _first(GuidedPackage.kit);
    await t.pumpWidget(
        _host(GuidedLineView(exercise: ex, line: _v1(ex), dimmed: true), 760));
    final op = t.widget<Opacity>(find.descendant(
        of: find.byType(GuidedLineView), matching: find.byType(Opacity)));
    expect(op.opacity, 0.45);
    expect(find.byType(LineView), findsOneWidget);

    await t.pumpWidget(_host(GuidedLineView(exercise: ex, line: _v1(ex)), 760));
    expect(
        find.descendant(
            of: find.byType(GuidedLineView), matching: find.byType(Opacity)),
        findsNothing);
  });

  testWidgets('guided lines hide the line-number box (R3)', (t) async {
    final ex = _first(GuidedPackage.kit);
    await t.pumpWidget(_host(GuidedLineView(exercise: ex, line: _v1(ex)), 760));
    expect(t.widget<LineView>(find.byType(LineView)).showLineNumber, isFalse);
    expect(
        t
            .widget<SheetStaffWidget>(find.byType(SheetStaffWidget))
            .showLineNumber,
        isFalse);
  });

  testWidgets('pad cursor: tick maps to the note index', (t) async {
    final ex = _first(GuidedPackage.pad);
    await t.pumpWidget(_host(
        GuidedLineView(exercise: ex, line: _v1(ex), activeTick: 24), 380));
    final lv = t.widget<LineView>(find.byType(LineView));
    expect(lv.activeIndex, isNotNull);
    expect(lv.activeIndex, greaterThan(0));
  });

  testWidgets('wide layout scales up, capped by maxStaffHeight', (t) async {
    await t.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final ex = _first(GuidedPackage.kit);
    await t.pumpWidget(_host(GuidedLineView(exercise: ex, line: _v1(ex)), 380));
    final narrow = t.getSize(find.byType(GuidedLineView)).height;
    await t
        .pumpWidget(_host(GuidedLineView(exercise: ex, line: _v1(ex)), 1400));
    final wide = t.getSize(find.byType(GuidedLineView)).height;
    expect(wide, greaterThan(narrow));
    await t.pumpWidget(_host(
        GuidedLineView(exercise: ex, line: _v1(ex), maxStaffHeight: 200),
        1400));
    expect(
        t.getSize(find.byType(GuidedLineView)).height, lessThanOrEqualTo(200));
    expect(t.takeException(), isNull);
  });

  group('cursor style', () {
    Finder lv() => find.byType(GuidedLineView);

    testWidgets('default is the box cursor, unchanged', (t) async {
      final ex = _first(GuidedPackage.kit);
      await t.pumpWidget(_host(
          GuidedLineView(exercise: ex, line: _v1(ex), activeTick: 24), 760));
      expect(t.widget<GuidedLineView>(lv()).cursorStyle, CursorStyle.box);
      expect(t.widget<LineView>(find.byType(LineView)).cursorStyle,
          CursorStyle.box);
      final c = staffCalls(t, lv());
      expect(c.hasCursorField, isTrue);
      expect(c.playheads, isEmpty);
    });

    testWidgets('none draws neither cursor nor coloured note', (t) async {
      final ex = _first(GuidedPackage.kit);
      await t.pumpWidget(_host(
          GuidedLineView(
              exercise: ex,
              line: _v1(ex),
              activeTick: 24,
              cursorStyle: CursorStyle.none),
          760));
      final c = staffCalls(t, lv());
      expect(c.hasCursorField, isFalse);
      expect(c.hasNoteRing, isFalse);
      expect(c.playheads, isEmpty);
    });

    for (final package in GuidedPackage.values) {
      testWidgets('line: thin, full height, moves with the tick ($package)',
          (t) async {
        await t.binding.setSurfaceSize(const Size(2560, 1000));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final ex = _first(package);
        // One bar = one row, so the playhead row is the last row drawn.
        final line = pageLine(_v1(ex), ex.gridUnit, firstBar: 0, bars: 1);
        // Wide (scaled up) and narrow (natural size).
        for (final width in [2400.0, 380.0]) {
          final xs = <double>[];
          for (final tick in [0, 24, 48, 72]) {
            await t.pumpWidget(_host(
                GuidedLineView(
                    exercise: ex,
                    line: line,
                    activeTick: tick,
                    cursorStyle: CursorStyle.line),
                width));
            final c = staffCalls(t, lv());
            expect(c.playheads, hasLength(1), reason: '$width $tick');
            final ph = c.playheads.single;
            expect(ph.width, lessThanOrEqualTo(3.0), reason: '$width');
            expect(ph.width, greaterThanOrEqualTo(1.5), reason: '$width');
            // The whole staff (five lines = 24 units) and more.
            expect(ph.bottom - ph.top, greaterThan(24 * c.scale + 20));
            expect(c.hasCursorField, isFalse);
            expect(c.hasNoteRing, isFalse);
            // Drawn on top: the last call of its row.
            final last = c.calls.lastWhere((m) => m.$1 == #drawLine);
            expect((last.$2[2] as Paint).color.toARGB32(),
                AppColors.accent.toARGB32());
            xs.add(ph.x);
          }
          for (var i = 1; i < xs.length; i++) {
            expect(xs[i], greaterThan(xs[i - 1] + 5), reason: '$width $xs');
          }
        }
      });
    }

    testWidgets('line without a tick draws nothing', (t) async {
      final ex = _first(GuidedPackage.kit);
      await t.pumpWidget(_host(
          GuidedLineView(
              exercise: ex, line: _v1(ex), cursorStyle: CursorStyle.line),
          760));
      expect(staffCalls(t, lv()).playheads, isEmpty);
    });
  });

  testWidgets('golden: kit V1 wide with cursor', (t) async {
    await t.binding.setSurfaceSize(const Size(900, 500));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final ex = _first(GuidedPackage.kit);
    await t.pumpWidget(_host(
        GuidedLineView(exercise: ex, line: _v1(ex), activeTick: 24), 760));
    expect(t.takeException(), isNull);
    await expectLater(find.byKey(const Key('shot')),
        matchesGoldenFile('../../goldens/guided_line_kit_wide.png'));
  });

  testWidgets('golden: pad V1 narrow with cursor', (t) async {
    await t.binding.setSurfaceSize(const Size(420, 500));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final ex = _first(GuidedPackage.pad);
    await t.pumpWidget(_host(
        GuidedLineView(exercise: ex, line: _v1(ex), activeTick: 24), 380));
    expect(t.takeException(), isNull);
    await expectLater(find.byKey(const Key('shot')),
        matchesGoldenFile('../../goldens/guided_line_pad_narrow.png'));
  });
}
