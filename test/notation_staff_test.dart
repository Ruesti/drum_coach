import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/data/etudes.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:drum_coach/shared/widgets/sheet_geometry.dart';

void main() {
  setUpAll(() async {
    // The engraving font is a bundled font, not an asset: load it by hand so
    // the golden shows real noteheads, clef and digits instead of tofu.
    final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
    final loader = FontLoader('Bravura')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  group('SheetStaffWidget (Blattform)', () {
    List<StrokeBeat> bar() => eighths([R, L, R, L, R, L, R, L]);
    final sheet = Rudiment(
        id: 'sheet',
        name: 'Sheet',
        description: '',
        minBpm: 60,
        targetBpm: 100,
        difficulty: Difficulty.beginner,
        sticking: bar(),
        lines: [
          line([...bar(), ...bar()], counts: true),
          line([...bar(), ...bar()], title: 'Accents'),
          line([...bar(), ...bar(), ...bar(), ...bar()],
              repeat: false, title: 'Challenge'),
        ]);

    Finder paints() => find.descendant(
        of: find.byType(SheetStaffWidget), matching: find.byType(CustomPaint));

    testWidgets(
        'draws a three-line sheet, one CustomPaint per line, uniform pitch',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360, child: SheetStaffWidget(rudiment: sheet)))));
      expect(tester.takeException(), isNull);
      expect(paints(), findsNWidgets(3));
      final h = [
        for (final e in paints().evaluate())
          (e.widget as CustomPaint).size.height
      ];
      // Counts and titles each add a band to EVERY row of the sheet.
      const pitch = sheetRowPitch + sheetCountBand + sheetTitleBand;
      expect(h[0], pitch);
      expect(h[1], pitch);
      expect(h[2], 2 * pitch);
    });

    testWidgets('every seeded exercise renders as a sheet without throwing',
        (tester) async {
      for (final r in [...rudimentsSeedData, ...allEtudes]) {
        // Scrollable like the info page: a 12-bar étude is taller than the
        // test screen, and a bare Column would report an overflow.
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: SizedBox(
                        width: 360, child: SheetStaffWidget(rudiment: r))))));
        expect(tester.takeException(), isNull, reason: r.id);
      }
    });

    testWidgets('tapping a line reports its index', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360,
                  child: SheetStaffWidget(
                      rudiment: sheet, activeLine: 0, onLineTap: taps.add)))));
      await tester.tap(paints().at(1));
      expect(taps, [1]);
    });

    testWidgets('active line and index render a cursor without throwing',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360,
                  child: SheetStaffWidget(
                      rudiment: sheet, activeLine: 2, activeIndex: 17)))));
      expect(tester.takeException(), isNull);
    });

    testWidgets('hiding sticking and counts keeps the layout', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360,
                  child: SheetStaffWidget(
                      rudiment: sheet,
                      showSticking: false,
                      showCounts: false)))));
      expect(tester.takeException(), isNull);
      final h = [
        for (final e in paints().evaluate())
          (e.widget as CustomPaint).size.height
      ];
      // No count band without counts; the title band stays (titles exist).
      expect(h[0], sheetRowPitch + sheetTitleBand);
    });

    testWidgets(
        'golden: number boxes, repeat signs, title, counts, final barline',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360, child: SheetStaffWidget(rudiment: sheet)))));
      await expectLater(find.byType(SheetStaffWidget),
          matchesGoldenFile('goldens/sheet_staff_three_lines.png'));
    });
  });

  group('NotationStaffWidget (5-line staff)', () {
    testWidgets('renders every seeded pattern without throwing', (tester) async {
      for (final rudiment in [...rudimentsSeedData, ...allEtudes]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: NotationStaffWidget(rudiment: rudiment),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull,
            reason: 'failed rendering ${rudiment.id}');
        expect(find.byType(NotationStaffWidget), findsOneWidget);

        final size = tester.getSize(find.byType(CustomPaint).first);
        expect(size.height, greaterThan(0));
      }
    });

    testWidgets('renders a mixed-value multi-bar étude without throwing',
        (tester) async {
      const etude = Rudiment(
        id: 'etude_mixed', name: 'Mixed', description: 'x',
        minBpm: 60, targetBpm: 120, difficulty: Difficulty.intermediate,
        gridUnit: NoteGrid.eighth, beatsPerBar: 4,
        sticking: [
          StrokeBeat(hand: Hand.right, value: NoteValue.quarter, isAccent: true),
          StrokeBeat(hand: Hand.left, value: NoteValue.eighth),
          StrokeBeat(hand: Hand.right, value: NoteValue.eighth),
          StrokeBeat(hand: Hand.left, value: NoteValue.sixteenth),
          StrokeBeat(hand: Hand.right, value: NoteValue.sixteenth),
          StrokeBeat(hand: Hand.left, value: NoteValue.eighth),
          StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
          StrokeBeat(hand: Hand.left, value: NoteValue.eighth, tuplet: Tuplet.triplet),
          StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
          StrokeBeat(hand: Hand.left, value: NoteValue.quarter),
        ],
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 360, child: NotationStaffWidget(rudiment: etude)),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with an active cursor during playback', (tester) async {
      final rudiment = rudimentsSeedData.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: NotationStaffWidget(rudiment: rudiment, activeIndex: 2),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders whole/half/dotted note values without throwing',
        (tester) async {
      const etude = Rudiment(
        id: 'etude_values',
        name: 'Values',
        description: 'x',
        minBpm: 60,
        targetBpm: 120,
        difficulty: Difficulty.intermediate,
        gridUnit: NoteGrid.quarter,
        beatsPerBar: 4,
        sticking: [
          StrokeBeat(hand: Hand.right, value: NoteValue.whole), // bar 1: 4 quarters
          StrokeBeat(hand: Hand.left, value: NoteValue.half), // bar 2: 2
          StrokeBeat(hand: Hand.right, value: NoteValue.quarter, dotted: true), // 1.5
          StrokeBeat(hand: Hand.left, value: NoteValue.eighth), // 0.5 -> bar 2 = 4
        ],
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 360, child: NotationStaffWidget(rudiment: etude)),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
