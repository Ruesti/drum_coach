import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/isar_service.dart';
import '../../data/local/models/practice_session.dart';
import '../../data/local/models/rudiment_progress.dart';

part 'stats_provider.g.dart';

class DailyMinutes {
  final DateTime date;
  final int minutes;
  const DailyMinutes(this.date, this.minutes);
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

@riverpod
Future<int> streakDays(StreakDaysRef ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  if (sessions.isEmpty) return 0;
  final practicedDays = sessions
      .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
      .toSet();
  var streak = 0;
  var day = DateTime.now();
  while (true) {
    final d = DateTime(day.year, day.month, day.day);
    if (!practicedDays.contains(d)) break;
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
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
