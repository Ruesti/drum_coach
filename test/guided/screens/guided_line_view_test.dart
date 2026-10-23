import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/run_clock.dart';
import 'package:drum_coach/features/guided/widgets/guided_line_view.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/practice/widgets/line_view.dart';
import 'package:drum_coach/shared/widgets/kit_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

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
