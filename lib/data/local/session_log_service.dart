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
  String mode = 'learn',
  int? sheetLine,
  String? sheetMode,
  String? sheetLines,
  String source = 'off',
  String? midiDevice,
  String? kitMapping,
}) {
  final setup = analysis?.recordingSetup;
  return SessionLog()
    ..sessionUid = '${startedAt.millisecondsSinceEpoch}-$exerciseId'
    ..startedAt = startedAt
    ..exerciseId = exerciseId
    ..mode = mode
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
    ..sheetLine = sheetLine
    ..sheetMode = sheetMode
    ..sheetLines = sheetLines
    ..source = source
    ..midiDevice = midiDevice
    ..kitMapping = kitMapping
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
          ..deviationMs = e.deviationMs
          ..instrument = e.instrument
          ..rawNote = e.rawNote
          ..grace = e.grace,
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

  /// Writes [content] as [name] into [dir] (default: the temp directory,
  /// shareable) and returns the file.
  static Future<File> writeExportFile(String name, String content,
      {Directory? dir}) async {
    final target = dir ?? await getTemporaryDirectory();
    await target.create(recursive: true);
    final file = File('${target.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  static Future<File> exportSession(SessionLog log, {Directory? dir}) =>
      writeExportFile('session_${log.sessionUid}.jsonl',
          sessionLogToJsonl(log),
          dir: dir);

  /// All sessions of [day] concatenated into one JSONL file, or null when
  /// the day has no logs.
  static Future<File?> exportDay(DateTime day, {Directory? dir}) async {
    final logs = await forDay(day);
    if (logs.isEmpty) return null;
    final content = [for (final l in logs) sessionLogToJsonl(l)].join();
    final stamp = '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return writeExportFile('sessions_$stamp.jsonl', content, dir: dir);
  }

  /// Export or save (Etappe 2 fix C2): where file sharing works the file is
  /// written to the temp directory and handed to [share]; on the desktop
  /// (share_plus 13 throws `UnimplementedError` on Linux) it is written into
  /// `<documents>/drum_coach/` and returned unshared, for a SnackBar.
  static Future<ExportOutcome> deliverExport({
    required Future<File?> Function(Directory dir) write,
    required bool shareAvailable,
    required Future<void> Function(File file) share,
    Future<Directory> Function()? tempDir,
    Future<Directory> Function()? documentsDir,
  }) async {
    final Directory dir;
    if (shareAvailable) {
      dir = await (tempDir ?? getTemporaryDirectory)();
    } else {
      final docs = await (documentsDir ?? getApplicationDocumentsDirectory)();
      dir = Directory('${docs.path}/drum_coach');
    }
    final file = await write(dir);
    if (file == null) return (file: null, shared: false);
    if (!shareAvailable) return (file: file, shared: false);
    await share(file);
    return (file: file, shared: true);
  }

  /// [day]'s logs, shared or saved — see [deliverExport].
  static Future<ExportOutcome> exportDayTo(
    DateTime day, {
    required bool shareAvailable,
    required Future<void> Function(File file) share,
  }) =>
      deliverExport(
        write: (dir) => exportDay(day, dir: dir),
        shareAvailable: shareAvailable,
        share: share,
      );

  /// SnackBar text for an export outcome, null when the share sheet took it.
  static String? exportMessage(ExportOutcome outcome,
      {String empty = 'No session logs today yet.'}) {
    final file = outcome.file;
    if (file == null) return empty;
    if (outcome.shared) return null;
    return 'Saved to ${file.path}';
  }
}

/// What an export did: the written file (null = nothing to export) and
/// whether it went through the share sheet.
typedef ExportOutcome = ({File? file, bool shared});
