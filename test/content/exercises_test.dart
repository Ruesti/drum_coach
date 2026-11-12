import 'package:drum_coach/content/exercises.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lookup by id', () {
    expect(exerciseById('entry'), same(entryExercise));
    expect(exerciseById('rock8'), same(basicRockBeat));
    expect(() => exerciseById('nope'), throwsArgumentError);
  });
  test('exercise parameters and bar length', () {
    expect(entryExercise.bpm, 70);
    expect(entryExercise.bars, 8);
    expect(basicRockBeat.bpm, 80);
    expect(basicRockBeat.bars, 16);
    expect(basicRockBeat.barMs, 3000);
  });
}
