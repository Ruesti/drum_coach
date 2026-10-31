import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/isar_service.dart';
import '../../data/local/models/practice_session.dart';
import '../../data/local/models/rudiment_progress.dart';
import '../../data/local/settings_service.dart';

part 'stats_provider.g.dart';

/// Current streak with a one-day grace: a missed day consumes the single
/// freeze; a second gap ends the streak. Pure for testability.
int computeCurrentStreak(Set<DateTime> practicedDays, DateTime now) {
  if (practicedDays.isEmpty) return 0;
  final earliest = practicedDays.reduce((a, b) => a.isBefore(b) ? a : b);

  var streak = 0;
  var freezes = 1; // one allowed gap
  var day = now;
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

/// Longest consecutive-day run (no grace). Pure for testability. Expects
/// [sortedDays] ascending, date-only, deduplicated.
int computeLongestStreak(List<DateTime> sortedDays) {
  if (sortedDays.isEmpty) return 0;

  var best = 1;
  var run = 1;
  for (var i = 1; i < sortedDays.length; i++) {
    final gap = sortedDays[i].difference(sortedDays[i - 1]).inDays;
    if (gap == 1) {
      run++;
      if (run > best) best = run;
    } else if (gap > 1) {
      run = 1;
    }
  }
  return best;
}

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

/// Current streak with a one-day grace. See [computeCurrentStreak].
@riverpod
Future<int> streakDays(StreakDaysRef ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final practicedDays = sessions
      .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
      .toSet();
  return computeCurrentStreak(practicedDays, DateTime.now());
}

/// The longest consecutive-day run ever recorded (no grace). See
/// [computeLongestStreak].
@riverpod
Future<int> longestStreak(LongestStreakRef ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final days = sessions
      .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
      .toSet()
      .toList()
    ..sort();
  return computeLongestStreak(days);
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
      .where((s) => s.exerciseId == rudimentId)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}
