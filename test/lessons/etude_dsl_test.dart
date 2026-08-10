import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('note applies flags', () {
    final n = note(R, NoteValue.eighth, accent: true);
    expect(n.hand, Hand.right);
    expect(n.value, NoteValue.eighth);
    expect(n.isAccent, isTrue);
  });
  test('flam / drag graces', () {
    expect(flam(R, NoteValue.quarter).graces, [Hand.left]);
    expect(drag(L, NoteValue.quarter).graces, [Hand.right, Hand.right]);
  });
  test('run applies accents by index', () {
    final r = run([R, L, R, L], NoteValue.sixteenth, accents: {0, 2});
    expect(r.length, 4);
    expect(r[0].isAccent, isTrue);
    expect(r[1].isAccent, isFalse);
    expect(r[2].isAccent, isTrue);
    expect(r.every((b) => b.value == NoteValue.sixteenth), isTrue);
  });
  test('triplet8 marks the tuplet', () {
    final t = triplet8([R, L, R]);
    expect(t.length, 3);
    expect(t.every((b) => b.tuplet == Tuplet.triplet && b.value == NoteValue.eighth), isTrue);
  });
  test('barCountOrThrow returns whole-bar count', () {
    final oneBar = [...eighths([R, L, R, L, R, L, R, L])]; // 8×0.5 = 4q
    expect(barCountOrThrow(oneBar, beatsPerBar: 4, grid: NoteGrid.eighth), 1);
  });
  test('barCountOrThrow throws on a partial bar', () {
    final partial = eighths([R, L, R]); // 1.5q
    expect(() => barCountOrThrow(partial, beatsPerBar: 4, grid: NoteGrid.eighth),
        throwsArgumentError);
  });
}
