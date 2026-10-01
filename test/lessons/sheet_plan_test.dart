import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l1 = line(eighths([R, L, R, L, R, L, R, L])); // 1 bar, 8 notes
  final l2 = line(
      sixteenths([R, L, R, R, L, R, L, L, R, L, R, R, L, R, L, L])); // 1 bar, 16
  final l3 = line([
    ...eighths([R, L, R, L, R, L, R, L]),
    ...eighths([L, R, L, R, L, R, L, R]),
  ], repeat: false); // 2 bars, 16
  final r = Rudiment(
      id: 't',
      name: 'T',
      description: '',
      minBpm: 60,
      targetBpm: 100,
      difficulty: Difficulty.beginner,
      sticking: eighths([R, L]),
      lines: [l1, l2, l3]);

  test('line plan is exactly that line', () {
    final p = SheetPlan.line(r, 1);
    expect(p.beats, same(l2.beats));
    expect(p.lines, [1]);
    expect(p.lineStarts, [0]);
    expect(p.wholeSheet, isFalse);
    expect(p.lineIndex, 1);
    expect(p.locate(5), (line: 1, index: 5));
  });

  test('whole-sheet plan concatenates all lines once', () {
    final p = SheetPlan.wholeSheet(r);
    expect(p.beats.length, 8 + 16 + 16);
    expect(p.lines, [0, 1, 2]);
    expect(p.lineStarts, [0, 8, 24]);
    expect(p.wholeSheet, isTrue);
    expect(p.lineIndex, 0);
    expect(p.locate(0), (line: 0, index: 0));
    expect(p.locate(7), (line: 0, index: 7));
    expect(p.locate(8), (line: 1, index: 0));
    expect(p.locate(39), (line: 2, index: 15));
  });

  test('legacy exercise without lines is a one-line sheet plan', () {
    final legacy = Rudiment(
        id: 'l',
        name: 'L',
        description: '',
        minBpm: 60,
        targetBpm: 100,
        difficulty: Difficulty.beginner,
        sticking: eighths([R, L, R, L]));
    expect(SheetPlan.line(legacy, 0).beats, same(legacy.sticking));
    expect(SheetPlan.wholeSheet(legacy).beats.length, 4);
  });

  test('line index is clamped into the sheet', () {
    expect(SheetPlan.line(r, 7).lineIndex, 2);
    expect(SheetPlan.line(r, -1).lineIndex, 0);
  });

  test('barsOf and sheetBars count whole bars, never throw', () {
    expect(barsOf(l3.beats, grid: NoteGrid.eighth, beatsPerBar: 4), 2);
    expect(barsOf(eighths([R, L, R]), grid: NoteGrid.eighth, beatsPerBar: 4), 1);
    expect(barsOf(const [], grid: NoteGrid.eighth, beatsPerBar: 4), 0);
    expect(sheetBars(r), 4);
  });
}
