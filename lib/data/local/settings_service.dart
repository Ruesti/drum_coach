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

  /// Click track on the practice screen (K2 step 2, 27.09.): a quarter-note
  /// pulse next to the exercise. Default on; analysis mode mutes it anyway.
  static bool get clickTrackEnabled =>
      _prefs.getBool('click_track_enabled') ?? true;
  static Future<void> setClickTrackEnabled(bool v) =>
      _prefs.setBool('click_track_enabled', v);

  /// Backing loop (Engine part 1): on by default; the style itself is
  /// automatic (`autoBackingStyle`), the user only switches the band on/off.
  static bool get backingEnabled => _prefs.getBool('backing_enabled') ?? true;
  static Future<void> setBackingEnabled(bool v) =>
      _prefs.setBool('backing_enabled', v);

  /// The backing track's own level, global. Default 0.7.
  static double get backingLevel => _prefs.getDouble('backing_level') ?? 0.7;
  static Future<void> setBackingLevel(double v) =>
      _prefs.setDouble('backing_level', v.clamp(0.0, 1.0).toDouble());

  /// Loopback-calibrated output+input latency (§1.3). `null` = never
  /// calibrated; onsets are then compared uncorrected.
  static double? get latencyOffsetMs => _prefs.getDouble('latency_offset_ms');
  static Future<void> setLatencyOffsetMs(double v) async {
    await _prefs.setDouble('latency_offset_ms', v);
    await _prefs.setString(
        'latency_calibrated_at', DateTime.now().toIso8601String());
  }

  static DateTime? get latencyCalibratedAt =>
      DateTime.tryParse(_prefs.getString('latency_calibrated_at') ?? '');

  /// Analysis mode is remembered per exercise (Brief Phase 3); learn mode is
  /// the default.
  static bool analysisModeFor(String exerciseId) =>
      _prefs.getBool('analysis_mode_$exerciseId') ?? false;
  static Future<void> setAnalysisModeFor(String exerciseId, bool v) =>
      _prefs.setBool('analysis_mode_$exerciseId', v);

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

  // ── Sheet (Blattform, 30.09.) ────────────────────────────────────────────
  static bool get showSticking => _prefs.getBool('show_sticking') ?? true;
  static Future<void> setShowSticking(bool v) =>
      _prefs.setBool('show_sticking', v);
  static bool get showCounts => _prefs.getBool('show_counts') ?? true;
  static Future<void> setShowCounts(bool v) => _prefs.setBool('show_counts', v);

  /// Last line (0-based) and mode played per exercise; the practice screen
  /// resumes there.
  static ({int line, bool sheet}) sheetPositionFor(String exerciseId) => (
        line: _prefs.getInt('sheet_line_$exerciseId') ?? 0,
        sheet: _prefs.getBool('sheet_mode_$exerciseId') ?? false,
      );
  static Future<void> setSheetPosition(String exerciseId,
      {required int line, required bool sheet}) async {
    await _prefs.setInt('sheet_line_$exerciseId', line);
    await _prefs.setBool('sheet_mode_$exerciseId', sheet);
  }

  // ── Practice-session snapshot ────────────────────────────────────────────
  // Written when the app goes to background mid-session so the timer survives
  // Android killing the process (e.g. during a phone call).

  static Future<void> savePracticeSnapshot({
    required String rudimentId,
    required int elapsedSeconds,
    int? goalSeconds,
    int sessionSeconds = 0,
    int line = 0,
    bool sheet = false,
  }) async {
    await _prefs.setString('practice_snap_id', rudimentId);
    await _prefs.setInt('practice_snap_elapsed', elapsedSeconds);
    await _prefs.setInt('practice_snap_session', sessionSeconds);
    await _prefs.setInt('practice_snap_line', line);
    await _prefs.setBool('practice_snap_sheet', sheet);
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
  static ({
    int elapsedSeconds,
    int? goalSeconds,
    int sessionSeconds,
    int line,
    bool sheet,
  })? practiceSnapshotFor(
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
      line: _prefs.getInt('practice_snap_line') ?? 0,
      sheet: _prefs.getBool('practice_snap_sheet') ?? false,
    );
  }

  static Future<void> clearPracticeSnapshot() async {
    await _prefs.remove('practice_snap_id');
    await _prefs.remove('practice_snap_elapsed');
    await _prefs.remove('practice_snap_session');
    await _prefs.remove('practice_snap_goal');
    await _prefs.remove('practice_snap_time');
    await _prefs.remove('practice_snap_line');
    await _prefs.remove('practice_snap_sheet');
  }
}
