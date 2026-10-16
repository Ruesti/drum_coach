import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:drum_coach/features/practice/line_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final r = rudimentsSeedData.firstWhere((r) => r.id == 'single_paradiddle');

  test(
      'lines=all selects every line',
      () => expect(initialLineSelection(lineCount: 8, linesParam: 'all'),
          [0, 1, 2, 3, 4, 5, 6, 7]));
  test(
      'lines=1,3,5 is 1-based, order kept',
      () => expect(
          initialLineSelection(lineCount: 8, linesParam: '1,3,5'), [0, 2, 4]));
  test('garbage is dropped, never an error', () {
    expect(initialLineSelection(lineCount: 8, linesParam: '0,abc,99,3,3'), [2]);
    expect(
        initialLineSelection(lineCount: 8, linesParam: '', rememberedLine: 4),
        [4]);
    expect(
        initialLineSelection(lineCount: 8, linesParam: 'x', lineParam: 2), [1]);
  });
  test('line=N is an alias; out of range opens line 1', () {
    expect(initialLineSelection(lineCount: 8, lineParam: 3), [2]);
    expect(initialLineSelection(lineCount: 8, lineParam: 40), [0]);
  });
  test('no params: the remembered line, clamped; never practised = line 1', () {
    expect(initialLineSelection(lineCount: 8, rememberedLine: 4), [4]);
    expect(initialLineSelection(lineCount: 3, rememberedLine: 7), [0]);
    expect(initialLineSelection(lineCount: 8), [0]);
  });
  test('lines=all on a one-line exercise is that line',
      () => expect(initialLineSelection(lineCount: 1, linesParam: 'all'), [0]));
  test('linesQuery is 1-based and comma separated',
      () => expect(linesQuery([0, 2, 4]), '1,3,5'));
  test('lineNavLabel: single line and sequence', () {
    expect(
        lineNavLabel(
            line: 2, lineCount: 8, step: 0, steps: 1, pass: 0, repeats: 1),
        'Line 3 of 8');
    expect(
        lineNavLabel(
            line: 4, lineCount: 8, step: 1, steps: 4, pass: 0, repeats: 2),
        'Sequence 2 of 4 · Line 5 · 1/2');
  });
  test('sessionLogSheetFields: line number for one line, null for a sequence',
      () {
    expect(
        sessionLogSheetFields(SheetPlan.line(r, 2)), (line: 3, mode: 'line'));
    expect(sessionLogSheetFields(SheetPlan.sequence(r, [0, 2])),
        (line: null, mode: 'sequence'));
  });
}
