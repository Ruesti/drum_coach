import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/isar_service.dart';
import '../../data/local/models/practice_session.dart';
import '../../data/local/models/rudiment_progress.dart';
import '../../data/local/settings_service.dart';

part 'stats_provider.g.dart';

class DailyMinutes {
  final DateTime date;
  final int minutes;
  const DailyMinutes(this.date, this.minutes);
}

/// Today's practice progress against the daily goal.
class TodayStatus {
  final int minutes;
  final int goalMinutes;
  const TodayStatus({required this.minutes, required this.goalMinutes});

  bool get practiced => minutes > 0;
  bool get goalMet => minutes >= goalMinutes;
}

@riverpod
Future<List<PracticeSession>> allSessions(AllSessionsRef ref) async {
  final sessions = await IsarService.instance.practiceSessions
      .buildQuery<PracticeSession>()
      .findAll();
  sessions.sort((a, b) => b.date.compareTo(a.date));
  return sessions;
}

@riverpod
Future<List<RudimentProgress>> allProgress(AllProgressRef ref) async {
  return IsarService.instance.rudimentProgress
      .buildQuery<RudimentProgress>()
      .findAll();
}

@riverpod
Future<List<DailyMinutes>> last14DaysMinutes(Last14DaysMinutesRef ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final now = DateTime.now();
  return List.generate(14, (i) {
    final day = DateTime(now.year, now.month, now.day - (13 - i));
    final minutes = sessions
        .where((s) =>
            s.date.year == day.year &&
            s.date.month == day.month &&
            s.date.day == day.day)
        .fold(0, (sum, s) => sum + s.durationSeconds ~/ 60);
    return DailyMinutes(day, minutes);
  });
}

/// Current streak with a one-day grace: a single missed day does not reset the
/// streak (it consumes the "freeze"), but two missed days in a row do. This also
/// means the streak still shows the day after practicing, even before you've
/// practiced again today.
@riverpod
Future<int> streakDays(StreakDaysRef ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  if (sessions.isEmpty) return 0;
  final practicedDays = sessions
      .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
      .toSet();
  final earliest = practicedDays.reduce((a, b) => a.isBefore(b) ? a : b);

  var streak = 0;
  var freezes = 1; // one allowed gap
  var day = DateTime.now();
  while (!day.isBefore(earliest)) {
    final d = DateTime(day.year, day.month, day.day);
    if (practicedDays.contains(d)) {
      streak++;
    } else if (freezes > 0) {
      freezes--;
    } else {
      break;
    }
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

/// The longest consecutive-day run ever recorded (no grace — true record).
@riverpod
Future<int> longestStreak(LongestStreakRef ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  if (sessions.isEmpty) return 0;
  final days = sessions
      .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
      .toSet()
      .toList()
    ..sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    final gap = days[i].difference(days[i - 1]).inDays;
    if (gap == 1) {
      run++;
      if (run > best) best = run;
    } else if (gap > 1) {
      run = 1;
    }
  }
  return best;
}

/// Today's minutes vs. the user's daily goal.
@riverpod
Future<TodayStatus> todayStatus(TodayStatusRef ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final now = DateTime.now();
  final minutes = sessions
      .where((s) =>
          s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day)
      .fold(0, (sum, s) => sum + s.durationSeconds ~/ 60);
  return TodayStatus(
    minutes: minutes,
    goalMinutes: SettingsService.practiceTargetMinutes,
  );
}

/// Per-day practice minutes for the last [days] days (oldest first), for the
/// calendar heatmap.
@riverpod
Future<List<DailyMinutes>> practiceCalendar(PracticeCalendarRef ref,
    {int days = 119}) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final now = DateTime.now();
  return List.generate(days, (i) {
    final day = DateTime(now.year, now.month, now.day - (days - 1 - i));
    final minutes = sessions
        .where((s) =>
            s.date.year == day.year &&
            s.date.month == day.month &&
            s.date.day == day.day)
        .fold(0, (sum, s) => sum + s.durationSeconds ~/ 60);
    return DailyMinutes(day, minutes);
  });
}

@riverpod
Future<List<PracticeSession>> bpmHistoryForRudiment(
  BpmHistoryForRudimentRef ref,
  String rudimentId,
) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  return sessions
      .where((s) => s.rudimentId == rudimentId)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}
