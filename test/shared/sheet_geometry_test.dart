import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/sheet_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<StrokeBeat> bar() => eighths([R, L, R, L, R, L, R, L]);
  final r = Rudiment(
      id: 'g',
      name: 'G',
      description: '',
      minBpm: 60,
      targetBpm: 100,
      difficulty: Difficulty.beginner,
      sticking: bar(),
      lines: [
        line([...bar(), ...bar()]), // 2 bars → 1 row
        line([...bar(), ...bar()], counts: true), // 1 row
        line([
          ...bar(), ...bar(), ...bar(), ...bar(),
          ...bar(), ...bar(), ...bar(), ...bar(),
        ], repeat: false), // 8 bars → 4 rows
      ]);

  test('rows per line, row starts and total rows', () {
    final g = computeSheetGeometry(r, 360, showCounts: true);
    expect(g.layouts.map((l) => l.rowCount), [1, 1, 4]);
    expect(g.rowStart, [0, 1, 2]);
    expect(g.totalRows, 6);
    expect(g.rowOf(0, 3), 0);
    expect(g.rowOf(2, 0), 2);
    expect(g.rowOf(2, 16), 3); // bar 3 of the challenge = its second row
    expect(g.rowOf(2, 63), 5);
    expect(g.lineOfRow(4), 2);
    expect(g.lineOfRow(0), 0);
  });

  test('row pitch is uniform: taller for the whole sheet when any line counts',
      () {
    expect(computeSheetGeometry(r, 360, showCounts: true).rowPitch,
        sheetRowPitchWithCounts);
    expect(computeSheetGeometry(r, 360, showCounts: false).rowPitch,
        sheetRowPitch);
    final plain = r.withSticking(bar());
    expect(computeSheetGeometry(plain, 360, showCounts: true).rowPitch,
        sheetRowPitch);
  });

  test('height is rows × pitch', () {
    final g = computeSheetGeometry(r, 360, showCounts: false);
    expect(g.height, 6 * sheetRowPitch);
  });

  test('a title costs no height (it sits inside the staff band)', () {
    final titled = Rudiment(
        id: 't',
        name: 'T',
        description: '',
        minBpm: 60,
        targetBpm: 100,
        difficulty: Difficulty.beginner,
        sticking: bar(),
        lines: [line(bar()), line(bar(), title: 'Challenge')]);
    expect(computeSheetGeometry(titled, 360, showCounts: true).rowPitch,
        sheetRowPitch);
  });

  test('a line opening with a flam gets extra room after the start repeat',
      () {
    expect(systemPadFor(repeat: true, graces: true),
        sheetSystemPad + sheetRepeatSystemPad + sheetGraceSystemPad);
    expect(systemPadFor(repeat: false, graces: true), sheetSystemPad);
    expect(leadsWithGraces([flam(R, NoteValue.eighth)]), isTrue);
    expect(leadsWithGraces(bar()), isFalse);
    expect(leadsWithGraces(const []), isFalse);
  });

  test('pads leave room for the number box and the repeat signs', () {
    expect(leftPadFor(numbered: true), sheetLeftPad + sheetNumberBoxW);
    expect(leftPadFor(numbered: false), sheetLeftPad);
    expect(rightPadFor(repeat: true), sheetRightPad + sheetRepeatW);
    expect(systemPadFor(repeat: true), sheetSystemPad + sheetRepeatSystemPad);
    expect(systemPadFor(repeat: false), sheetSystemPad);
  });
}
