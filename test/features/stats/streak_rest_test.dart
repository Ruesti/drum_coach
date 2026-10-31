import 'package:flutter_test/flutter_test.dart';

import 'package:drum_coach/features/stats/stats_provider.dart';

void main() {
  // The training program (and its rest days) is gone with the Trainingsraum:
  // the streak only knows practiced days and the one-day grace.
  group('streak without rest days', () {
    test('consecutive days streak', () {
      final days = {
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
      };
      expect(computeCurrentStreak(days, DateTime(2026, 1, 3)), 3);
    });

    test('one missed day spends the freeze, a second gap ends the streak', () {
      final practiced = {
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 8),
        // Jan 9 missed
        DateTime(2026, 1, 10),
        // Jan 11 missed
        DateTime(2026, 1, 12),
        DateTime(2026, 1, 13),
      };
      // Jan 11 spends the freeze, Jan 9 ends it.
      expect(computeCurrentStreak(practiced, DateTime(2026, 1, 13)), 3);
    });

    test('today not yet practiced keeps the streak through the grace', () {
      final practiced = {
        DateTime(2026, 1, 8),
        DateTime(2026, 1, 9),
        DateTime(2026, 1, 10),
      };
      expect(computeCurrentStreak(practiced, DateTime(2026, 1, 11)), 3);
    });

    test('longest streak: any gap resets the run', () {
      expect(
          computeLongestStreak([DateTime(2026, 1, 10), DateTime(2026, 1, 12)]),
          1);
      expect(
          computeLongestStreak([
            DateTime(2026, 1, 1),
            DateTime(2026, 1, 2),
            DateTime(2026, 1, 3),
            DateTime(2026, 1, 7),
          ]),
          3);
    });
  });
}
