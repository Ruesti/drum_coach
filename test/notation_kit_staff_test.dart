import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:drum_coach/shared/widgets/sheet_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/kit_fixtures.dart';

void main() {
  setUpAll(() async {
    final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
    final loader = FontLoader('Bravura')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    AppTypography.label;
    await GoogleFonts.pendingFonts();
  });

  group('kitStaffStep / kitHeadShape (Brief B.2 table)', () {
    test('every instrument has its line or space', () {
      expect(kitStaffStep(KitInstrument.hiHatPedal), -5);
      expect(kitStaffStep(KitInstrument.kick), -3);
      expect(kitStaffStep(KitInstrument.floorTom2), -2);
      expect(kitStaffStep(KitInstrument.floorTom1), -1);
      expect(kitStaffStep(KitInstrument.snare), 1);
      expect(kitStaffStep(KitInstrument.snareRim), 1);
      expect(kitStaffStep(KitInstrument.tom2), 2);
      expect(kitStaffStep(KitInstrument.tom1), 3);
      expect(kitStaffStep(KitInstrument.ride), 4);
      expect(kitStaffStep(KitInstrument.rideBell), 4);
      expect(kitStaffStep(KitInstrument.hiHatClosed), 5);
      expect(kitStaffStep(KitInstrument.hiHatOpen), 5);
      for (final c in [
        KitInstrument.crash1,
        KitInstrument.crash2,
        KitInstrument.china,
        KitInstrument.splash
      ]) {
        expect(kitStaffStep(c), 6, reason: c.name);
      }
      expect(kitStaffStep(KitInstrument.pad), 0);
    });
    test('head shapes', () {
      expect(kitHeadShape(KitInstrument.snare), KitHeadShape.normal);
      expect(kitHeadShape(KitInstrument.kick), KitHeadShape.normal);
      expect(kitHeadShape(KitInstrument.tom1), KitHeadShape.normal);
      for (final x in [
        KitInstrument.snareRim,
        KitInstrument.hiHatClosed,
        KitInstrument.hiHatOpen,
        KitInstrument.hiHatPedal,
        KitInstrument.ride,
        KitInstrument.crash1,
        KitInstrument.crash2
      ]) {
        expect(kitHeadShape(x), KitHeadShape.x, reason: x.name);
      }
      expect(kitHeadShape(KitInstrument.rideBell), KitHeadShape.diamond);
      expect(kitHeadShape(KitInstrument.china), KitHeadShape.circleX);
      expect(kitHeadShape(KitInstrument.splash), KitHeadShape.xSmall);
    });
  });

  group('kit sheet', () {
    final r = kitShowcase();
    Finder paints() => find.descendant(
        of: find.byType(SheetStaffWidget), matching: find.byType(CustomPaint));

    testWidgets('one CustomPaint per line at the kit pitch (+ count band)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body:
                  SizedBox(width: 360, child: SheetStaffWidget(rudiment: r)))));
      expect(tester.takeException(), isNull);
      expect(paints(), findsNWidgets(2));
      final h = [
        for (final e in paints().evaluate())
          (e.widget as CustomPaint).size.height
      ];
      const pitch = kitRowPitch + sheetCountBand;
      expect(h[0], pitch); // two bars, one row
      expect(h[1], pitch);
    });

    testWidgets('geometry of a kit sheet: kit pitch, kit layouts, row by tick',
        (tester) async {
      final g = computeSheetGeometry(r, 352, showCounts: true);
      expect(g.isKit, isTrue);
      expect(g.rowPitch, kitRowPitch + sheetCountBand);
      expect(g.kitLayouts.length, 2);
      expect(g.kitLayouts.every((k) => k != null), isTrue);
      expect(g.rowStart, [0, 1]);
      expect(g.rowOfTick(0, 0), 0);
      expect(g.rowOfTick(1, 100), 1);
      expect(computeSheetGeometry(r, 352, showCounts: false).rowPitch,
          kitRowPitch);
    });

    testWidgets('cursor by tick renders without throwing', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360,
                  child: SheetStaffWidget(
                      rudiment: r, activeLine: 1, activeTick: 24 * 6)))));
      expect(tester.takeException(), isNull);
    });

    testWidgets('golden: groove line with counts, showcase line',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body:
                  SizedBox(width: 360, child: SheetStaffWidget(rudiment: r)))));
      await expectLater(find.byType(SheetStaffWidget),
          matchesGoldenFile('goldens/kit_staff_sheet.png'));
    });

    testWidgets('golden: the PATTERN box draws the pattern voices',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360, child: NotationStaffWidget(rudiment: r)))));
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(NotationStaffWidget),
          matchesGoldenFile('goldens/kit_staff_pattern.png'));
    });
  });
}
