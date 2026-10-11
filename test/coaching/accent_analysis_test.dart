import 'package:drum_coach/features/coaching/services/stroke_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accents louder than plain notes: ratio and count', () {
    final a = accentAnalysis(
      velocities: const [0.9, 0.5, 0.8, 0.4, 0.95, 0.5],
      accented: const [true, false, true, false, true, false],
      ghost: const [false, false, false, false, false, false],
    )!;
    expect(a.accentCount, 3);
    expect(a.accentsLouder, 3);
    expect(a.accentRatio, closeTo((0.9 + 0.8 + 0.95) / 3 / (1.4 / 3), 0.01));
  });

  test('one accent swallowed: counts 2 of 3 louder', () {
    final a = accentAnalysis(
      velocities: const [0.9, 0.5, 0.45, 0.5, 0.95, 0.5],
      accented: const [true, false, true, false, true, false],
      ghost: const [false, false, false, false, false, false],
    )!;
    expect(a.accentsLouder, 2);
  });

  test('ghost notes are excluded from the plain reference', () {
    final a = accentAnalysis(
      velocities: const [0.9, 0.5, 0.1, 0.5, 0.9, 0.1],
      accented: const [true, false, false, false, true, false],
      ghost: const [false, false, true, false, false, true],
    )!;
    expect(a.accentRatio, closeTo(0.9 / 0.5, 0.01));
  });

  test('too few notes: null', () {
    expect(
      accentAnalysis(
          velocities: const [0.9, 0.5],
          accented: const [true, false],
          ghost: const [false, false]),
      isNull,
    );
  });
}
