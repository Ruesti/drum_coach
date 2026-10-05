import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/practice/widgets/sheet_window.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:drum_coach/shared/widgets/sheet_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<StrokeBeat> bar() => eighths([R, L, R, L, R, L, R, L]);
  final six = Rudiment(
      id: 'w',
      name: 'W',
      description: '',
      minBpm: 60,
      targetBpm: 100,
      difficulty: Difficulty.beginner,
      sticking: bar(),
      lines: [
        line([...bar(), ...bar()]),
        line([...bar(), ...bar()]),
        line([
          ...bar(), ...bar(), ...bar(), ...bar(),
          ...bar(), ...bar(), ...bar(), ...bar(),
        ], repeat: false),
      ]); // rows: 1 + 1 + 4 = 6
  final one = six.withSticking(bar());

  Future<void> pump(WidgetTester tester, Widget w, {double height = 800}) =>
      tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360, height: height, child: Center(child: w)))));

  double offsetOf(WidgetTester tester) =>
      tester.getTopLeft(find.byType(SheetStaffWidget).first).dy -
      tester.getTopLeft(find.byType(ClipRect).first).dy;

  test('slidesUp only for the next row', () {
    expect(slidesUp(0, 1), isTrue);
    expect(slidesUp(3, 4), isTrue);
    expect(slidesUp(4, 0), isFalse);
    expect(slidesUp(1, 3), isFalse);
    expect(slidesUp(2, 2), isFalse);
  });

  test('visibleRowsFor: up to 4, never more than the sheet, at least 2', () {
    expect(visibleRowsFor(maxHeight: 800, rowPitch: 104, totalRows: 6), 4);
    expect(visibleRowsFor(maxHeight: 800, rowPitch: 104, totalRows: 1), 1);
    expect(visibleRowsFor(maxHeight: 800, rowPitch: 104, totalRows: 3), 3);
    expect(visibleRowsFor(maxHeight: 300, rowPitch: 104, totalRows: 6), 2);
    expect(visibleRowsFor(maxHeight: 100, rowPitch: 104, totalRows: 6), 2);
    expect(visibleRowsFor(maxHeight: 350, rowPitch: 104, totalRows: 6), 3);
  });

  testWidgets('a one-row sheet is one row high, a long sheet four rows',
      (tester) async {
    await pump(tester, SheetWindow(rudiment: one, activeLine: 0));
    expect(tester.getSize(find.byType(ClipRect).first).height,
        sheetRowPitch + 2 * sheetWindowPad);
    await pump(tester, SheetWindow(rudiment: six, activeLine: 0));
    expect(tester.getSize(find.byType(ClipRect).first).height,
        4 * sheetRowPitch + 2 * sheetWindowPad);
  });

  testWidgets('the active row is on top; the next row slides up, animated',
      (tester) async {
    await pump(tester,
        SheetWindow(rudiment: six, activeLine: 0, activeIndex: 0));
    expect(offsetOf(tester), 0);
    // line 1 = row 1
    await pump(tester,
        SheetWindow(rudiment: six, activeLine: 1, activeIndex: 0));
    await tester.pump(const Duration(milliseconds: 90));
    final mid = offsetOf(tester);
    expect(mid, lessThan(0));
    expect(mid, greaterThan(-sheetRowPitch));
    await tester.pump(const Duration(milliseconds: 200));
    expect(offsetOf(tester), -sheetRowPitch);
    // challenge, bar 3 = row 3 (line 2 starts at row 2): not the next row,
    // so it jumps
    await pump(tester,
        SheetWindow(rudiment: six, activeLine: 2, activeIndex: 16));
    await tester.pump();
    expect(offsetOf(tester), -3 * sheetRowPitch);
  });

  testWidgets('jumping back to the start is immediate', (tester) async {
    await pump(tester,
        SheetWindow(rudiment: six, activeLine: 2, activeIndex: 63));
    await tester.pump();
    expect(offsetOf(tester), -5 * sheetRowPitch);
    await pump(tester,
        SheetWindow(rudiment: six, activeLine: 2, activeIndex: 0));
    await tester.pump();
    expect(offsetOf(tester), -2 * sheetRowPitch);
  });

  testWidgets('before the start the selected line sits on top',
      (tester) async {
    await pump(tester, SheetWindow(rudiment: six, activeLine: 2));
    await tester.pump();
    expect(offsetOf(tester), -2 * sheetRowPitch);
  });

  testWidgets(
      'sheet mode wraps: a second copy follows the last row; line mode does not',
      (tester) async {
    await pump(
        tester,
        SheetWindow(
            rudiment: six, activeLine: 2, activeIndex: 63, sheetMode: true));
    await tester.pump();
    expect(find.byType(SheetStaffWidget), findsNWidgets(2));
    final second = tester.getTopLeft(find.byType(SheetStaffWidget).at(1)).dy -
        tester.getTopLeft(find.byType(ClipRect).first).dy;
    // Row 0 of the copy sits right under the last row (row 5 at the top).
    expect(second, closeTo(sheetRowPitch, 0.5));
    await pump(tester,
        SheetWindow(rudiment: six, activeLine: 2, activeIndex: 63));
    await tester.pump();
    expect(find.byType(SheetStaffWidget), findsOneWidget);
  });

  testWidgets('tapping a visible line reports it', (tester) async {
    final taps = <int>[];
    await pump(tester,
        SheetWindow(rudiment: six, activeLine: 0, onLineTap: taps.add));
    final clip = tester.getRect(find.byType(ClipRect).first);
    // row 1 = line 1
    await tester.tapAt(Offset(
        clip.center.dx, clip.top + sheetWindowPad + 1.5 * sheetRowPitch));
    expect(taps, [1]);
  });
}
