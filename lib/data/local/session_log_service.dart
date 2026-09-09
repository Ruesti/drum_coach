import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/coaching/models/session_analysis.dart';
import '../../features/coaching/services/mic_analysis_service.dart';
import '../../features/coaching/services/recording_setup.dart';
import 'isar_service.dart';
import 'models/session_log.dart';
import 'session_log_codec.dart';

/// Pure assembly of the Phase-2 raw log from an analysis result and session
/// context. [analysis] is null for mic-less sessions — the header is logged
/// anyway (`audioSource: off`), events and clicks stay empty.
SessionLog buildSessionLog({
  required SessionAnalysis? analysis,
  required List<BeatRecord> beatLog,
  required String exerciseId,
  required int bpm,
  required int durationSeconds,
  required int rating,
  required DateTime startedAt,
  required String headphones,
  required DeviceInfo device,
  required double? latencyOffsetMs,
}) {
  final setup = analysis?.recordingSetup;
  return SessionLog()
    ..sessionUid = '${startedAt.millisecondsSinceEpoch}-$exerciseId'
    ..startedAt = startedAt
    ..exerciseId = exerciseId
    ..mode = 'learn'
    ..bpm = bpm
    ..durationSeconds = durationSeconds
    ..deviceModel = device.model
    ..androidVersion = device.androidVersion
    ..audioSource = (setup?['audioSource'] as String?) ?? 'off'
    ..sampleRate = (setup?['sampleRate'] as int?) ?? 0
    ..autoGain = (setup?['autoGain'] as bool?) ?? false
    ..echoCancel = (setup?['echoCancel'] as bool?) ?? false
    ..noiseSuppress = (setup?['noiseSuppress'] as bool?) ?? false
    ..unprocessedSupported = setup?['unprocessedSupported'] as bool?
    ..headphones = headphones
    ..latencyOffsetMs = latencyOffsetMs
    ..rating = rating
    ..clickTimesMs = [
      for (final b in beatLog) b.timestamp.microsecondsSinceEpoch / 1000.0,
    ]
    ..clickNoteIndices = [for (final b in beatLog) b.beatIndex]
    ..events = [
      for (final e in analysis?.events ?? const <OnsetEventData>[])
        OnsetEvent()
          ..timeMs = e.timeMs
          ..peakLevel = e.peakLevel
          ..notePosition = e.notePosition
          ..hand = e.hand
          ..deviationMs = e.deviationMs,
    ];
}

/// Persistence and export of raw session logs (Brief Etappe 1, Phase 2).
class SessionLogService {
  static Future<void> save(SessionLog log) =>
      IsarService.instance.writeTxn(
          () => IsarService.instance.sessionLogs.put(log));

  static Future<List<SessionLog>> forDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return IsarService.instance.sessionLogs
        .filter()
        .startedAtBetween(start, end, includeUpper: false)
        .sortByStartedAt()
        .findAll();
  }

  /// Writes [content] to a shareable temp file and returns it.
  static Future<File> writeExportFile(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  static Future<File> exportSession(SessionLog log) =>
      writeExportFile('session_${log.sessionUid}.jsonl',
          sessionLogToJsonl(log));

  /// All sessions of [day] concatenated into one JSONL file, or null when
  /// the day has no logs.
  static Future<File?> exportDay(DateTime day) async {
    final logs = await forDay(day);
    if (logs.isEmpty) return null;
    final content = [for (final l in logs) sessionLogToJsonl(l)].join();
    final stamp = '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return writeExportFile('sessions_$stamp.jsonl', content);
  }
}
