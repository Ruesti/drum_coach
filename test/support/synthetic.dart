import 'package:drum_coach/content/exercises.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/session_record.dart';
import 'package:drum_coach/measure/stroke.dart';

import 'strokes.dart';

double _r3(double v) => (v * 1000).round() / 1000;

/// A perfect play-through of [e], with optional defects. Indices are
/// `TargetTime.index`. [latencyMs] is added to every stroke time and stored
/// as the calibrated latency (null when [calibrated] is false).
SessionRecord syntheticSession(
  Exercise e, {
  double latencyMs = 0,
  Map<int, double> shiftMs = const {},
  Set<int> drop = const {},
  Map<int, int> replaceNote = const {},
  List<Stroke> extra = const [],
  int velocity = 100,
  double firstBeatMs = 3000,
  bool calibrated = true,
}) {
  final targets = e.targetTimes(firstBeatMs: firstBeatMs);
  final strokes = <Stroke>[];
  for (final t in targets) {
    if (drop.contains(t.index)) continue;
    final s = strokeFor(t,
        shiftMs: (shiftMs[t.index] ?? 0) + latencyMs, velocity: velocity);
    final note = replaceNote[t.index];
    strokes.add(Stroke(
      timeMs: _r3(s.timeMs),
      note: note ?? s.note,
      velocity: s.velocity,
      instrument: note == null
          ? s.instrument
          : KitMapping.gm().instrumentFor(note) ?? KitInstrument.unknown,
    ));
  }
  strokes
    ..addAll(extra)
    ..sort((a, b) => a.timeMs.compareTo(b.timeMs));
  return SessionRecord(
    exerciseId: e.id,
    bpm: e.bpm,
    firstBeatMs: firstBeatMs,
    latencyOffsetMs: calibrated ? latencyMs : null,
    deviceName: 'Test Kit',
    mapping: KitMapping.gm(),
    platform: 'test',
    recordedAt: DateTime.utc(2026, 11, 12, 10),
    strokes: strokes,
  );
}
