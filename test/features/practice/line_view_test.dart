import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/practice/widgets/line_view.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:drum_coach/shared/widgets/sheet_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() async {
    final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
    final loader = FontLoader('Bravura')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    AppTypography.label;
    await GoogleFonts.pendingFonts();
  });

  final fill =
      rudimentsSeedData.firstWhere((r) => r.id == 'set_fill_sixteenth_singles');

  Future<void> pump(WidgetTester tester, Widget w) => tester.pumpWidget(
      MaterialApp(
          home: Scaffold(
              body:
                  SizedBox(width: 360, height: 800, child: Center(child: w)))));

  testWidgets('shows only the given line, height fits its rows',
      (tester) async {
    await pump(tester, LineView(rudiment: fill, line: 0));
    expect(tester.takeException(), isNull);
    expect(
        find.descendant(
            of: find.byType(LineView), matching: find.byType(CustomPaint)),
        findsOneWidget);
    final geo = computeSheetGeometry(fill, 360 - 2 * SheetStaffWidget.hPad,
        showCounts: true);
    // A kit line of sixteenths: one bar per row at phone width.
    expect(geo.layouts[0].rowCount, 4);
    expect(tester.getSize(find.byType(LineView)).height,
        geo.layouts[0].rowCount * geo.rowPitch + 2 * SheetStaffWidget.vPad);
  });

  testWidgets('a later line draws without throwing, cursor on a tick',
      (tester) async {
    for (var l = 0; l < fill.sheet.length; l++) {
      await pump(tester, LineView(rudiment: fill, line: l, activeTick: 0));
      expect(tester.takeException(), isNull, reason: 'line $l');
    }
  });

  testWidgets(
      'a line taller than its space: the played row on top, the next row '
      'below, the last rows stay together', (tester) async {
    final geo = computeSheetGeometry(fill, 360 - 2 * SheetStaffWidget.hPad,
        showCounts: true);
    // Room for two of the four rows.
    final room = 2.5 * geo.rowPitch + 2 * SheetStaffWidget.vPad;
    Future<void> at(int? tick) => tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 360,
                    height: room,
                    child: Center(
                        child: LineView(
                            rudiment: fill, line: 0, activeTick: tick)))))));
    double offset() =>
        tester.getTopLeft(find.byType(SheetStaffWidget)).dy -
        tester.getTopLeft(find.byType(LineView)).dy;
    await at(0);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(LineView)).height,
        2 * geo.rowPitch + 2 * SheetStaffWidget.vPad);
    expect(offset(), 0); // rows 1 + 2
    // Bar 2 plays in the last visible row: the window moves on, so bar 3
    // shows below it.
    await at(96);
    expect(offset(), -geo.rowPitch); // rows 2 + 3
    await at(3 * 96); // bar 4: the window stops at the end
    expect(offset(), -2 * geo.rowPitch); // rows 3 + 4
    // No cursor (the gap after a unit change): the window stays.
    await at(null);
    expect(offset(), -2 * geo.rowPitch);
  });

  testWidgets('a line with foot letters uses the taller kit rows',
      (tester) async {
    final feet =
        rudimentsSeedData.firstWhere((r) => r.id == 'feet_double_bass_eighths');
    expect(feet.hasFootSides, isTrue);
    await pump(tester, LineView(rudiment: feet, line: 0, showCounts: false));
    expect(tester.takeException(), isNull);
    final geo = computeSheetGeometry(feet, 360 - 2 * SheetStaffWidget.hPad,
        showCounts: false);
    expect(geo.rowPitch, kitRowPitchWithFeet);
    expect(
        tester.getSize(find.byType(LineView)).height,
        geo.layouts[0].rowCount * kitRowPitchWithFeet +
            2 * SheetStaffWidget.vPad);
  });

  testWidgets('golden: a four-bar fill line, one bar per row', (tester) async {
    await pump(tester, LineView(rudiment: fill, line: 0));
    await expectLater(
        find.byType(LineView),
        matchesGoldenFile(
            '../../goldens/line_view_fill_sixteenth_singles.png'));
  });
}
