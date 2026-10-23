import 'package:shared_preferences/shared_preferences.dart';

import '../../features/coaching/midi/kit_instrument.dart';
import '../../features/lessons/models/rudiment.dart';
import '../../features/program/models/program_config.dart';

/// Which stroke source may measure (Brief Etappe 2, A.6). `auto` = MIDI when
/// a device is connected, otherwise the microphone where allowed.
enum MeasurementSource {
  auto,
  mic,
  midi,
  off;

  bool get mayUseMic => this == auto || this == mic;
  bool get mayUseMidi => this == auto || this == midi;

  static MeasurementSource fromName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return auto;
  }
}

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

  /// Measurement source. Migration: the Etappe-1 switch `mic_analysis_enabled`
  /// = false must not come back as "auto" — a user who turned the mic off
  /// stays off until they choose a source.
  static MeasurementSource get measurementSource {
    final stored = _prefs.getString('measurement_source');
    if (stored != null) return MeasurementSource.fromName(stored);
    final legacy = _prefs.getBool('mic_analysis_enabled');
    return legacy == false ? MeasurementSource.off : MeasurementSource.auto;
  }

  static Future<void> setMeasurementSource(MeasurementSource s) =>
      _prefs.setString('measurement_source', s.name);

  static String? get midiLastDeviceId => _prefs.getString('midi_last_device');
  static Future<void> setMidiLastDeviceId(String? id) => id == null
      ? _prefs.remove('midi_last_device')
      : _prefs.setString('midi_last_device', id);

  static String _deviceKey(String prefix, String deviceName) =>
      '$prefix${deviceName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}';

  static KitMapping kitMappingFor(String deviceName) {
    final raw = _prefs.getString(_deviceKey('kit_mapping_', deviceName));
    return raw == null ? KitMapping.gm() : KitMapping.decode(raw);
  }

  static Future<void> setKitMappingFor(String deviceName, KitMapping m) =>
      _prefs.setString(_deviceKey('kit_mapping_', deviceName), m.encode());

  static double? midiLatencyOffsetMsFor(String deviceName) =>
      _prefs.getDouble(_deviceKey('midi_latency_', deviceName));

  static Future<void> setMidiLatencyOffsetMsFor(String deviceName, double v) =>
      _prefs.setDouble(_deviceKey('midi_latency_', deviceName), v);

  /// Instrument that plays the pad's role in pad exercises at the set
  /// (Brief A.5), default snare.
  static KitInstrument get padRoleInstrument =>
      KitInstrument.fromName(_prefs.getString('pad_role_instrument') ?? '') ??
      KitInstrument.snare;

  static Future<void> setPadRoleInstrument(KitInstrument i) =>
      _prefs.setString('pad_role_instrument', i.name);

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

  /// Last line (0-based) played per exercise; null = never practised.
  /// The practice screen opens there when the route names no lines.
  static int? lastLineFor(String exerciseId) =>
      _prefs.getInt('sheet_line_$exerciseId');
  static Future<void> setLastLine(String exerciseId, int line) =>
      _prefs.setInt('sheet_line_$exerciseId', line);

  /// Passes per line in a sequence of selected lines (1–4, default 2).
  static int get sequenceRepeats =>
      (_prefs.getInt('sequence_repeats') ?? 2).clamp(1, 4);
  static Future<void> setSequenceRepeats(int n) =>
      _prefs.setInt('sequence_repeats', n.clamp(1, 4));

  /// Library mode: 'exercises' (default) or 'guided'.
  static String get libraryMode {
    final v = _prefs.getString('library_mode');
    return v == 'guided' ? 'guided' : 'exercises';
  }

  static Future<void> setLibraryMode(String mode) =>
      _prefs.setString('library_mode', mode == 'guided' ? 'guided' : 'exercises');

  /// Guided exercises: spoken teacher voice (default on).
  static bool get guidedTeacher => _prefs.getBool('guided_teacher') ?? true;
  static Future<void> setGuidedTeacher(bool v) =>
      _prefs.setBool('guided_teacher', v);

  /// Guided exercises: play-along backing (default on).
  static bool get guidedPlayAlong =>
      _prefs.getBool('guided_play_along') ?? true;
  static Future<void> setGuidedPlayAlong(bool v) =>
      _prefs.setBool('guided_play_along', v);

  // ── Practice-session snapshot ────────────────────────────────────────────
  // Written when the app goes to background mid-session so the timer survives
  // Android killing the process (e.g. during a phone call).

  static Future<void> savePracticeSnapshot({
    required String rudimentId,
    required int elapsedSeconds,
    int? goalSeconds,
    int sessionSeconds = 0,
    List<int> lines = const [0],
    int start = 0,
  }) async {
    await _prefs.setString('practice_snap_id', rudimentId);
    await _prefs.setInt('practice_snap_elapsed', elapsedSeconds);
    await _prefs.setInt('practice_snap_session', sessionSeconds);
    await _prefs.setString('practice_snap_lines', lines.join(','));
    await _prefs.setInt('practice_snap_start', start);
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
    List<int> lines,
    int start,
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
    // Before 16.10. a snapshot held one line (`practice_snap_line`).
    final stored = _prefs.getString('practice_snap_lines');
    final lines = stored == null
        ? [_prefs.getInt('practice_snap_line') ?? 0]
        : [
            for (final p in stored.split(','))
              if (int.tryParse(p) != null) int.parse(p),
          ];
    return (
      elapsedSeconds: elapsed,
      goalSeconds: _prefs.getInt('practice_snap_goal'),
      sessionSeconds: _prefs.getInt('practice_snap_session') ?? 0,
      lines: lines.isEmpty ? const [0] : lines,
      start: _prefs.getInt('practice_snap_start') ?? 0,
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
    await _prefs.remove('practice_snap_lines');
    await _prefs.remove('practice_snap_start');
  }
}
