import 'dart:math' as math;

/// A locally bad stretch of a run: the player fell off (missed notes and/or
/// wild timing) for a bounded period. Whole-session averages dilute such
/// stretches away — 1 bad minute in 10 minutes is still 90% overall — so
/// they are detected in sliding windows (Auftraggeber-Entscheidung 13.09.).
class Lapse {
  /// Bounds on the assessed-note time axis (same axis as the note times
  /// passed to [detectLapses]), trimmed to the first/last bad note.
  final double startMs;
  final double endMs;

  /// Hit rate and timing spread over the merged bad windows.
  final double hitRate;
  final double jitterMs;

  const Lapse({
    required this.startMs,
    required this.endMs,
    required this.hitRate,
    required this.jitterMs,
  });

  double get durationMs => endMs - startMs;
}

/// Scans the assessed notes with a sliding window; a window is bad when its
/// local hit rate falls below [minHitRate] or its local timing std dev
/// exceeds [maxJitterMs]. Overlapping bad windows merge into one [Lapse],
/// trimmed to the first/last actually-bad note so a lapse stays local.
///
/// [deviationsMs] is indexed like [noteTimesMs]; null = the note was missed.
/// Runs shorter than one window report nothing — the global gate covers
/// those already.
List<Lapse> detectLapses({
  required List<double> noteTimesMs,
  required List<double?> deviationsMs,
  double windowMs = 8000,
  double stepMs = 2000,
  double minHitRate = 0.7,
  double maxJitterMs = 50,
}) {
  assert(noteTimesMs.length == deviationsMs.length);
  if (noteTimesMs.length < 2) return const [];
  final spanStart = noteTimesMs.first;
  final spanEnd = noteTimesMs.last;
  if (spanEnd - spanStart < windowMs) return const [];

  // Collect bad windows as [start, end) intervals.
  final badWindows = <(double, double)>[];
  for (var w = spanStart; w <= spanEnd - windowMs; w += stepMs) {
    final wEnd = w + windowMs;
    final devs = <double?>[];
    for (var i = 0; i < noteTimesMs.length; i++) {
      if (noteTimesMs[i] >= w && noteTimesMs[i] < wEnd) {
        devs.add(deviationsMs[i]);
      }
    }
    if (devs.length < 4) continue;
    final hit = devs.whereType<double>().toList();
    final hitRate = hit.length / devs.length;
    final jitter = hit.length >= 4 ? _stdDev(hit) : 0.0;
    if (hitRate < minHitRate || jitter > maxJitterMs) {
      badWindows.add((w, wEnd));
    }
  }
  if (badWindows.isEmpty) return const [];

  // Merge overlapping/adjacent bad windows.
  final merged = <(double, double)>[];
  var (curStart, curEnd) = badWindows.first;
  for (final (s, e) in badWindows.skip(1)) {
    if (s <= curEnd) {
      curEnd = math.max(curEnd, e);
    } else {
      merged.add((curStart, curEnd));
      (curStart, curEnd) = (s, e);
    }
  }
  merged.add((curStart, curEnd));

  // Trim each merged region to its first/last actually-bad note so the good
  // shoulders of the sliding windows don't inflate the lapse.
  final lapses = <Lapse>[];
  for (final (s, e) in merged) {
    double? firstBad;
    double? lastBad;
    final regionDevs = <double?>[];
    for (var i = 0; i < noteTimesMs.length; i++) {
      final t = noteTimesMs[i];
      if (t < s || t >= e) continue;
      final d = deviationsMs[i];
      regionDevs.add(d);
      final bad = d == null || d.abs() > maxJitterMs;
      if (bad) {
        firstBad ??= t;
        lastBad = t;
      }
    }
    if (firstBad == null || lastBad == null) continue;
    final hit = regionDevs.whereType<double>().toList();
    lapses.add(Lapse(
      startMs: firstBad,
      endMs: lastBad,
      hitRate: regionDevs.isEmpty ? 0 : hit.length / regionDevs.length,
      jitterMs: hit.length >= 2 ? _stdDev(hit) : 0,
    ));
  }
  return lapses;
}

double _stdDev(List<double> xs) {
  final mean = xs.reduce((a, b) => a + b) / xs.length;
  final variance =
      xs.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
          xs.length;
  return math.sqrt(variance);
}
