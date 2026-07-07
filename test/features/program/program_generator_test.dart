import 'package:flutter_test/flutter_test.dart';

import 'package:drum_coach/features/program/data/stick_control_program.dart';
import 'package:drum_coach/features/program/models/training_program.dart';
import 'package:drum_coach/features/program/program_provider.dart';

void main() {
  ExerciseBlock? blockOf(ProgramDay day, BlockType type) =>
      day.blocks.where((b) => b.type == type).firstOrNull;

  group('buildProgramDay — weekly rhythm', () {
    final days = [
      for (var n = 1; n <= programTotalDays; n++)
        buildProgramDay(stickControlProgram, n),
    ];

    test('expands exactly 84 days', () {
      expect(days.length, 84);
      expect(days.first.dayNumber, 1);
      expect(days.last.dayNumber, 84);
    });

    test('60 practice / 12 light / 12 rest', () {
      int count(DayType t) => days.where((d) => d.type == t).length;
      expect(count(DayType.practice), 60);
      expect(count(DayType.light), 12);
      expect(count(DayType.rest), 12);
    });

    test('dow 6 = light, dow 7 = rest for every week', () {
      for (final d in days) {
        final dow = ((d.dayNumber - 1) % 7) + 1;
        if (dow == 6) {
          expect(d.type, DayType.light, reason: 'day ${d.dayNumber}');
        } else if (dow == 7) {
          expect(d.type, DayType.rest, reason: 'day ${d.dayNumber}');
        } else {
          expect(d.type, DayType.practice, reason: 'day ${d.dayNumber}');
        }
      }
    });

    test('week numbers span 1..12', () {
      expect(days.first.week, 1);
      expect(days[7].week, 2); // day 8
      expect(days.last.week, 12);
    });

    test('rest days have empty block list and 0 minutes', () {
      for (final d in days.where((d) => d.type == DayType.rest)) {
        expect(d.blocks, isEmpty);
        expect(d.estimatedMinutes, 0);
      }
    });

    test('practice days have warmup + technique + tempoLadder (15 min)', () {
      final practice = days.firstWhere((d) => d.type == DayType.practice);
      expect(
        practice.blocks.map((b) => b.type),
        [BlockType.warmup, BlockType.technique, BlockType.tempoLadder],
      );
      expect(practice.estimatedMinutes, 15);
    });

    test('light days are warmup + technique only, no tempo ladder (8 min)', () {
      final light = days.firstWhere((d) => d.type == DayType.light);
      expect(
        light.blocks.map((b) => b.type),
        [BlockType.warmup, BlockType.technique],
      );
      expect(blockOf(light, BlockType.tempoLadder), isNull);
      expect(light.estimatedMinutes, 8);
    });
  });

  group('buildProgramDay — tempo ladder gating', () {
    test('ladder starts at phase.startBpm when no clean tempo stored', () {
      // Day 1 = phase 1, startBpm 70.
      final day = buildProgramDay(stickControlProgram, 1);
      expect(blockOf(day, BlockType.tempoLadder)!.startBpm, 70);
    });

    test('ladder starts at stored clean tempo, not 0/default', () {
      final day = buildProgramDay(
        stickControlProgram,
        1,
        cleanBpmFor: (k) => k == scSingles ? 96 : null,
      );
      expect(blockOf(day, BlockType.tempoLadder)!.startBpm, 96);
    });

    test('every practice tempo ladder requires a clean pass (mic-ready gate)',
        () {
      for (var n = 1; n <= programTotalDays; n++) {
        final day = buildProgramDay(stickControlProgram, n);
        final ladder = blockOf(day, BlockType.tempoLadder);
        if (day.type == DayType.practice) {
          expect(ladder!.cleanPassRequired, isTrue, reason: 'day $n');
        } else {
          expect(ladder, isNull, reason: 'day $n');
        }
      }
    });
  });

  group('buildProgramDay — exercise line per phase', () {
    test('phases 1–3 use their fixed line', () {
      // W1 practice → singles; W4 (day 22) → doubles; W7 (day 43) → paradiddle.
      expect(buildProgramDay(stickControlProgram, 1).blocks[1].exerciseKey,
          scSingles);
      expect(buildProgramDay(stickControlProgram, 22).blocks[1].exerciseKey,
          scDoubles);
      expect(buildProgramDay(stickControlProgram, 43).blocks[1].exerciseKey,
          scParadiddle);
    });

    test('phase 4 rotates line per week: W10 singles, W11 doubles, W12 paradiddle',
        () {
      // week = ((day-1) ~/ 7) + 1  ->  W10 day 64, W11 day 71, W12 day 78.
      expect(buildProgramDay(stickControlProgram, 64).blocks[1].exerciseKey,
          scSingles);
      expect(buildProgramDay(stickControlProgram, 71).blocks[1].exerciseKey,
          scDoubles);
      expect(buildProgramDay(stickControlProgram, 78).blocks[1].exerciseKey,
          scParadiddle);
    });
  });

  group('scheduled rest-day helper', () {
    final start = DateTime(2026, 1, 5); // day 1
    test('day 7 (dow 7) is a rest day', () {
      expect(isScheduledRestDay(start, start.add(const Duration(days: 6))),
          isTrue);
    });
    test('day 1 (dow 1) is not a rest day', () {
      expect(isScheduledRestDay(start, start), isFalse);
    });
    test('a date outside the 84-day window is not a program rest day', () {
      expect(isScheduledRestDay(start, start.add(const Duration(days: 200))),
          isFalse);
    });
  });
}
