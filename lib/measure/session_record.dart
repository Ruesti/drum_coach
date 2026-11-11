/// A recorded session as stored on disk: one JSONL file, header line first,
/// then one line per stroke. Analysis is a pure function of this record.
library;

import 'dart:convert';

import 'kit.dart';
import 'stroke.dart';

class SessionRecord {
  const SessionRecord({
    this.version = 1,
    required this.exerciseId,
    required this.bpm,
    required this.firstBeatMs,
    required this.latencyOffsetMs,
    required this.deviceName,
    required this.mapping,
    required this.platform,
    required this.recordedAt,
    required this.strokes,
  });

  final int version;
  final String exerciseId;
  final int bpm;
  final double firstBeatMs;

  /// Null when the device was not calibrated.
  final double? latencyOffsetMs;
  final String deviceName;
  final KitMapping mapping;

  /// Free string: "linux", "android", "windows", "test".
  final String platform;
  final DateTime recordedAt;
  final List<Stroke> strokes;
}

String encodeSessionJsonl(SessionRecord r) {
  final b = StringBuffer();
  b.writeln(jsonEncode({
    'type': 'header',
    'version': r.version,
    'exerciseId': r.exerciseId,
    'bpm': r.bpm,
    'firstBeatMs': r.firstBeatMs,
    'latencyOffsetMs': r.latencyOffsetMs,
    'deviceName': r.deviceName,
    'mapping': r.mapping.toJson(),
    'platform': r.platform,
    'recordedAt': r.recordedAt.toUtc().toIso8601String(),
  }));
  for (final s in r.strokes) {
    b.writeln(jsonEncode({
      'type': 'stroke',
      't': s.timeMs,
      'note': s.note,
      'vel': s.velocity,
      'instrument': s.instrument.name,
    }));
  }
  return b.toString();
}

SessionRecord decodeSessionJsonl(String text) {
  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) throw const FormatException('Empty session file');
  final header = jsonDecode(lines.first);
  if (header is! Map<String, Object?> || header['type'] != 'header') {
    throw const FormatException('Missing session header');
  }
  if (header['version'] != 1) {
    throw FormatException('Unknown session version: ${header['version']}');
  }
  final strokes = <Stroke>[];
  for (final line in lines.skip(1)) {
    final m = jsonDecode(line);
    if (m is! Map<String, Object?> || m['type'] != 'stroke') {
      throw FormatException('Bad stroke line: $line');
    }
    strokes.add(Stroke(
      timeMs: (m['t'] as num).toDouble(),
      note: m['note'] as int,
      velocity: m['vel'] as int,
      instrument: KitInstrument.fromName(m['instrument'] as String) ??
          KitInstrument.unknown,
    ));
  }
  return SessionRecord(
    version: 1,
    exerciseId: header['exerciseId'] as String,
    bpm: header['bpm'] as int,
    firstBeatMs: (header['firstBeatMs'] as num).toDouble(),
    latencyOffsetMs: (header['latencyOffsetMs'] as num?)?.toDouble(),
    deviceName: header['deviceName'] as String,
    mapping:
        KitMapping.fromJson((header['mapping'] as Map).cast<String, Object?>()),
    platform: header['platform'] as String,
    recordedAt: DateTime.parse(header['recordedAt'] as String),
    strokes: strokes,
  );
}
