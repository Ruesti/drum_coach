import 'dart:convert';

import 'models/session_log.dart';

/// JSONL serialization of a [SessionLog] (Brief Etappe 1, Phase 2): line 1
/// is the session header, every following line one onset event. Day exports
/// simply concatenate the per-session strings.
String sessionLogToJsonl(SessionLog log) {
  final buffer = StringBuffer()
    ..writeln(jsonEncode({
      'type': 'session',
      'sessionUid': log.sessionUid,
      'startedAt': log.startedAt.toIso8601String(),
      'exerciseId': log.exerciseId,
      'mode': log.mode,
      'bpm': log.bpm,
      'durationSeconds': log.durationSeconds,
      'deviceModel': log.deviceModel,
      'androidVersion': log.androidVersion,
      'audioSource': log.audioSource,
      'sampleRate': log.sampleRate,
      'autoGain': log.autoGain,
      'echoCancel': log.echoCancel,
      'noiseSuppress': log.noiseSuppress,
      'unprocessedSupported': log.unprocessedSupported,
      'headphones': log.headphones,
      'latencyOffsetMs': log.latencyOffsetMs,
      'rating': log.rating,
      'clickTimesMs': log.clickTimesMs,
      'clickNoteIndices': log.clickNoteIndices,
    }));
  for (final e in log.events) {
    buffer.writeln(jsonEncode({
      'type': 'onset',
      'timeMs': e.timeMs,
      'peakLevel': e.peakLevel,
      'notePosition': e.notePosition,
      'hand': e.hand,
      'deviationMs': e.deviationMs,
    }));
  }
  return buffer.toString();
}
