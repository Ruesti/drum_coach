/// Session metrics computed from a per-voice match result.
library;

import 'dart:math' as math;

import '../measure/hit_matcher.dart';
import '../measure/kit.dart';
import '../measure/stroke.dart';

class SessionMetrics {
  const SessionMetrics({
    required this.hitRate,
    required this.wrongRate,
    required this.extraRate,
    required this.timingMedianMs,
    required this.timingSpreadMs,
    required this.snareVelocitySd,
    required this.maxHitGapMs,
    required this.targetCount,
    required this.countedStrokes,
  });

  /// Hit rate per voice present in the exercise (hits / targets of voice).
  final Map<Voice, double> hitRate;

  /// Wrong-instrument outcomes per target count.
  final double wrongRate;

  /// Extra strokes per target count.
  final double extraRate;

  /// Median / population SD of deviations of hit outcomes; null without hits.
  final double? timingMedianMs;
  final double? timingSpreadMs;

  /// Population SD of velocities of strokes matched as snare hit; null if < 2.
  final double? snareVelocitySd;

  /// Largest time between consecutive hit targets, including first target to
  /// first hit and last hit to last target; whole run length without hits.
  final double maxHitGapMs;
  final int targetCount;

  /// Strokes inside the exercise window (not ignored). Zero means the player
  /// did not play at all, which makes the run not measurable.
  final int countedStrokes;
}

double _mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

double _popSd(List<double> v) {
  final m = _mean(v);
  return math.sqrt(_mean([for (final x in v) (x - m) * (x - m)]));
}

double _median(List<double> v) {
  final s = [...v]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

SessionMetrics computeMetrics({
  required MatchResult match,
  required List<Stroke> strokes,
}) {
  final outcomes = match.targets;
  final n = outcomes.length;

  final totals = <Voice, int>{};
  final hits = <Voice, int>{};
  var wrong = 0;
  final deviations = <double>[];
  final snareVelocities = <double>[];
  for (final o in outcomes) {
    final v = o.target.voice;
    totals[v] = (totals[v] ?? 0) + 1;
    if (o.kind == HitKind.wrongInstrument) wrong++;
    if (o.kind == HitKind.hit) {
      hits[v] = (hits[v] ?? 0) + 1;
      if (o.deviationMs != null) deviations.add(o.deviationMs!);
      if (v == Voice.snare && o.strokeIndex != null) {
        snareVelocities.add(strokes[o.strokeIndex!].velocity.toDouble());
      }
    }
  }

  var maxGap = 0.0;
  if (n > 0) {
    final times = [for (final o in outcomes) o.target.timeMs]..sort();
    final first = times.first;
    final last = times.last;
    final hitTimes = [
      for (final o in outcomes)
        if (o.kind == HitKind.hit) o.target.timeMs,
    ]..sort();
    if (hitTimes.isEmpty) {
      maxGap = last - first;
    } else {
      final points = [first, ...hitTimes, last];
      for (var i = 1; i < points.length; i++) {
        maxGap = math.max(maxGap, points[i] - points[i - 1]);
      }
    }
  }

  return SessionMetrics(
    hitRate: {
      for (final e in totals.entries) e.key: (hits[e.key] ?? 0) / e.value,
    },
    wrongRate: n == 0 ? 0 : wrong / n,
    extraRate: n == 0 ? 0 : match.extraStrokeIndices.length / n,
    timingMedianMs: deviations.isEmpty ? null : _median(deviations),
    timingSpreadMs: deviations.isEmpty ? null : _popSd(deviations),
    snareVelocitySd:
        snareVelocities.length < 2 ? null : _popSd(snareVelocities),
    maxHitGapMs: maxGap,
    targetCount: n,
    countedStrokes: strokes.length - match.ignoredStrokeIndices.length,
  );
}
