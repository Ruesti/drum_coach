import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/practice/auto_backing.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _r({
  NoteGrid grid = NoteGrid.eighth,
  List<StrokeBeat>? sticking,
  Set<Genre> genres = const {},
  String? backing,
}) =>
    Rudiment(
      id: 'x',
      name: 'x',
      description: '',
      minBpm: 60,
      targetBpm: 120,
      difficulty: Difficulty.beginner,
      sticking: sticking ??
          const [
            StrokeBeat(hand: Hand.right),
            StrokeBeat(hand: Hand.left),
            StrokeBeat(hand: Hand.right),
            StrokeBeat(hand: Hand.left),
          ],
      gridUnit: grid,
      genres: genres,
      backing: backing,
    );

void main() {
  test('an explicit exercise default wins over every rule', () {
    expect(autoBackingStyle(_r(backing: 'halftime', genres: {Genre.jazz}),
        bpm: 90), 'halftime');
  });
  test('unknown explicit id falls through to the rules', () {
    expect(autoBackingStyle(_r(backing: 'bossa'), bpm: 90), 'rock8');
  });
  test('jazz swings, funk gets sixteenths', () {
    expect(autoBackingStyle(_r(genres: {Genre.jazz}), bpm: 90), 'swing');
    expect(autoBackingStyle(_r(genres: {Genre.funk}), bpm: 90), 'funk16');
  });
  test('triplet grid or tuplets in the pattern → shuffle', () {
    expect(autoBackingStyle(_r(grid: NoteGrid.triplet), bpm: 90), 'shuffle');
    expect(
        autoBackingStyle(
            _r(sticking: const [
              StrokeBeat(hand: Hand.right, tuplet: Tuplet.sextuplet),
              StrokeBeat(hand: Hand.left, tuplet: Tuplet.sextuplet),
            ]),
            bpm: 90),
        'shuffle');
  });
  test('sixteenths → rock16, but rock8 from 140 BPM', () {
    expect(autoBackingStyle(_r(grid: NoteGrid.sixteenth), bpm: 100), 'rock16');
    expect(autoBackingStyle(_r(grid: NoteGrid.sixteenth), bpm: 139), 'rock16');
    expect(autoBackingStyle(_r(grid: NoteGrid.sixteenth), bpm: 140), 'rock8');
    // Sixteenth note values inside an eighth grid count too.
    expect(
        autoBackingStyle(
            _r(sticking: const [
              StrokeBeat(hand: Hand.right, value: NoteValue.sixteenth),
              StrokeBeat(hand: Hand.left, value: NoteValue.sixteenth),
            ]),
            bpm: 100),
        'rock16');
  });
  test('eighths and quarters → rock8', () {
    expect(autoBackingStyle(_r(), bpm: 90), 'rock8');
    expect(autoBackingStyle(_r(grid: NoteGrid.quarter), bpm: 90), 'rock8');
  });
}
