import 'package:flutter_test/flutter_test.dart';

import 'package:drum_coach/features/stats/stats_provider.dart';

void main() {
  // Program day 1 = Mon 2026-01-05, so day 7 (rest) = Sun 2026-01-11.
  final programStart = DateTime(2026, 1, 5);

  group('computeCurrentStreak — rest-day awareness', () {
    test('plain consecutive days without a program still streak', () {
      final days = {
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
      };
      expect(computeCurrentStreak(days, DateTime(2026, 1, 3)), 3);
    });

    test('a scheduled rest day does not consume the freeze, so a real gap '
        'earlier is still bridged by it', () {
      // Practiced every day except Jan 9 (a real missed practice day) and
      // Jan 11 (a scheduled rest day). now = Jan 13.
      final practiced = {
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 8),
        // Jan 9 missed (practice day — real gap, spends the freeze)
        DateTime(2026, 1, 10),
        // Jan 11 rest (skipped, does not spend the freeze)
        DateTime(2026, 1, 12),
        DateTime(2026, 1, 13),
      };
      final now = DateTime(2026, 1, 13);

      // With the program: rest day is skipped, freeze absorbs Jan 9 → full run.
      expect(
        computeCurrentStreak(practiced, now,
            programStart: programStart, totalDays: 84),
        7,
      );
      // Without a program: the rest day spends the freeze, then Jan 9 breaks it.
      expect(computeCurrentStreak(practiced, now), 3);
    });

    test('a lone rest day today does not break the streak', () {
      // Practiced up to Jan 10; today Jan 11 is a rest day, not practiced.
      final practiced = {
        DateTime(2026, 1, 8),
        DateTime(2026, 1, 9),
        DateTime(2026, 1, 10),
      };
      expect(
        computeCurrentStreak(
          practiced,
          DateTime(2026, 1, 11),
          programStart: programStart,
          totalDays: 84,
        ),
        3,
      );
    });
  });

  group('computeLongestStreak — bridges rest days', () {
    test('a run separated only by a rest day counts as continuous', () {
      final days = [DateTime(2026, 1, 10), DateTime(2026, 1, 12)];
      // Jan 11 between them is a scheduled rest day → bridged.
      expect(
          computeLongestStreak(days, programStart: programStart, totalDays: 84),
          2);
      // Without the program the 2-day gap resets the run.
      expect(computeLongestStreak(days), 1);
    });

    test('a non-rest gap still resets the run', () {
      // Jan 8 → Jan 10 gap is Jan 9 (a practice day), not a rest day.
      final days = [DateTime(2026, 1, 8), DateTime(2026, 1, 10)];
      expect(
          computeLongestStreak(days, programStart: programStart, totalDays: 84),
          1);
    });
  });
}
