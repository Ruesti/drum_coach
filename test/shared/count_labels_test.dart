import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/count_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('eighths count 1 + 2 + 3 + 4 +', () {
    final c =
        countLabelsFor(eighths([R, L, R, L, R, L, R, L]), NoteGrid.eighth, 4);
    expect(c, ['1', '+', '2', '+', '3', '+', '4', '+']);
  });
  test('sixteenths count 1 e + a', () {
    final c = countLabelsFor(
        sixteenths([R, L, R, L, R, L, R, L]), NoteGrid.sixteenth, 4);
    expect(c, ['1', 'e', '+', 'a', '2', 'e', '+', 'a']);
  });
  test('eighth triplets count 1 + a', () {
    final c = countLabelsFor(triplet8([R, L, R, L, R, L]), NoteGrid.eighth, 4);
    expect(c, ['1', '+', 'a', '2', '+', 'a']);
  });
  test('legacy triplet grid counts ternary too', () {
    const beats = [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
    ];
    expect(countLabelsFor(beats, NoteGrid.triplet, 4), ['1', '+', 'a']);
  });
  test('mixed values: quarter, two eighths, a sixteenth group, rests get null',
      () {
    final beats = [
      note(R, NoteValue.quarter),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),
      ...sixteenths([L, R, L, R]),
      rest(NoteValue.quarter),
    ];
    expect(countLabelsFor(beats, NoteGrid.eighth, 4),
        ['1', '2', '+', '3', 'e', '+', 'a', null]);
  });
  test('second bar starts at 1 again; 32nds off the syllables get null', () {
    final beats = [
      ...eighths([R, L, R, L, R, L, R, L]),
      note(R, NoteValue.thirtySecond),
      note(L, NoteValue.thirtySecond),
      note(R, NoteValue.thirtySecond),
      note(L, NoteValue.thirtySecond),
      note(R, NoteValue.eighth),
      note(L, NoteValue.quarter),
      note(R, NoteValue.half),
    ];
    final c = countLabelsFor(beats, NoteGrid.eighth, 4);
    expect(c.sublist(8), ['1', null, 'e', null, '+', '2', '3']);
  });
}
