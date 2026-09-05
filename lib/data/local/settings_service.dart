import 'package:shared_preferences/shared_preferences.dart';

import '../../features/lessons/models/rudiment.dart';
import '../../features/program/models/program_config.dart';

class SettingsService {
  SettingsService._();

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isOnboardingDone => _prefs.getBool('onboarding_done') ?? false;
  static Future<void> setOnboardingDone() => _prefs.setBool('onboarding_done', true);
  static Future<void> resetOnboarding() => _prefs.setBool('onboarding_done', false);

  /// Day 1 anchor of the training program. `null` = program not started.
  /// Stored as an ISO-8601 string (matching the string-value style here).
  static DateTime? get programStartDate {
    final s = _prefs.getString('program_start_date');
    return s == null ? null : DateTime.tryParse(s);
  }

  static Future<void> setProgramStartDate(DateTime d) =>
      _prefs.setString('program_start_date', d.toIso8601String());

  static Future<void> clearProgramStartDate() =>
      _prefs.remove('program_start_date');

  static int get practiceTargetMinutes => _prefs.getInt('practice_target_min') ?? 20;
  static Future<void> setPracticeTargetMinutes(int v) =>
      _prefs.setInt('practice_target_min', v);

  static bool get hapticsEnabled => _prefs.getBool('haptics_enabled') ?? true;
  static Future<void> setHapticsEnabled(bool v) =>
      _prefs.setBool('haptics_enabled', v);

  static int get reminderHour => _prefs.getInt('reminder_hour') ?? 18;
  static int get reminderMinute => _prefs.getInt('reminder_minute') ?? 0;
  static Future<void> setReminderTime(int hour, int minute) async {
    await _prefs.setInt('reminder_hour', hour);
    await _prefs.setInt('reminder_minute', minute);
  }

  static bool get reminderEnabled => _prefs.getBool('reminder_enabled') ?? true;
  static Future<void> setReminderEnabled(bool v) =>
      _prefs.setBool('reminder_enabled', v);

  static String get claudeApiKey => _prefs.getString('claude_api_key') ?? '';
  static Future<void> setClaudeApiKey(String v) =>
      _prefs.setString('claude_api_key', v);

  static bool get micAnalysisEnabled =>
      _prefs.getBool('mic_analysis_enabled') ?? false;
  static Future<void> setMicAnalysisEnabled(bool v) =>
      _prefs.setBool('mic_analysis_enabled', v);

  /// Adaptive training program configuration. `null` = not configured.
  static ProgramConfig? get programConfig {
    final weeks = _prefs.getInt('program_duration_weeks');
    final diff = _prefs.getString('program_start_difficulty');
    final pool = _prefs.getString('program_pool');
    if (weeks == null || diff == null || pool == null) return null;
    return ProgramConfig(
      durationWeeks: weeks,
      startDifficulty: Difficulty.values.firstWhere((d) => d.name == diff,
          orElse: () => Difficulty.beginner),
      pool: ProgramPool.values.firstWhere((p) => p.name == pool,
          orElse: () => ProgramPool.mixed),
    );
  }

  static Future<void> setProgramConfig(ProgramConfig c) async {
    await _prefs.setInt('program_duration_weeks', c.durationWeeks);
    await _prefs.setString('program_start_difficulty', c.startDifficulty.name);
    await _prefs.setString('program_pool', c.pool.name);
  }

  static Future<void> clearProgramConfig() async {
    await _prefs.remove('program_duration_weeks');
    await _prefs.remove('program_start_difficulty');
    await _prefs.remove('program_pool');
    await _prefs.remove('program_stage_index');
  }

  /// Index into the effective difficulty stages of the current program run.
  static int get programStageIndex => _prefs.getInt('program_stage_index') ?? 0;
  static Future<void> setProgramStageIndex(int i) =>
      _prefs.setInt('program_stage_index', i);

  // ── Practice-session snapshot ────────────────────────────────────────────
  // Written when the app goes to background mid-session so the timer survives
  // Android killing the process (e.g. during a phone call).

  static Future<void> savePracticeSnapshot({
    required String rudimentId,
    required int elapsedSeconds,
    int? goalSeconds,
    int sessionSeconds = 0,
  }) async {
    await _prefs.setString('practice_snap_id', rudimentId);
    await _prefs.setInt('practice_snap_elapsed', elapsedSeconds);
    await _prefs.setInt('practice_snap_session', sessionSeconds);
    if (goalSeconds != null) {
      await _prefs.setInt('practice_snap_goal', goalSeconds);
    } else {
      await _prefs.remove('practice_snap_goal');
    }
    await _prefs.setString(
        'practice_snap_time', DateTime.now().toIso8601String());
  }

  /// The stored snapshot for [rudimentId], or null if none exists, it belongs
  /// to another exercise, or it is older than [maxAge].
  static ({int elapsedSeconds, int? goalSeconds, int sessionSeconds})?
      practiceSnapshotFor(
    String rudimentId, {
    Duration maxAge = const Duration(hours: 1),
  }) {
    if (_prefs.getString('practice_snap_id') != rudimentId) return null;
    final time =
        DateTime.tryParse(_prefs.getString('practice_snap_time') ?? '');
    if (time == null || DateTime.now().difference(time) > maxAge) return null;
    final elapsed = _prefs.getInt('practice_snap_elapsed');
    if (elapsed == null || elapsed <= 0) return null;
    return (
      elapsedSeconds: elapsed,
      goalSeconds: _prefs.getInt('practice_snap_goal'),
      sessionSeconds: _prefs.getInt('practice_snap_session') ?? 0,
    );
  }

  static Future<void> clearPracticeSnapshot() async {
    await _prefs.remove('practice_snap_id');
    await _prefs.remove('practice_snap_elapsed');
    await _prefs.remove('practice_snap_session');
    await _prefs.remove('practice_snap_goal');
    await _prefs.remove('practice_snap_time');
  }
}
