import 'dart:math' as math;

/// Assignment-free measures (Brief Etappe 1, §1.4): always available, no
/// note/hand matching required. The systematic click-vs-onset offset shows up
/// in [timingMedianMs] and is reported, never silently subtracted (§1.3).
class UnassignedMetrics {
  /// Median of each onset's signed deviation to its nearest click.
  final double timingMedianMs;

  /// Spread (population std dev) of those deviations.
  final double timingSpreadMs;

  /// Spread of the intervals between consecutive onsets (evenness).
  final double intervalSpreadMs;

  /// Coefficient of variation of the peak levels; null with fewer than two
  /// onsets, meaningful only on the raw recording path.
  final double? dynamicsSpread;

  final int playedCount;
  final int expectedCount;

  const UnassignedMetrics({
    required this.timingMedianMs,
    required this.timingSpreadMs,
    required this.intervalSpreadMs,
    required this.dynamicsSpread,
    required this.playedCount,
    required this.expectedCount,
  });
}

UnassignedMetrics computeUnassignedMetrics({
  required List<double> clickMs,
  required List<double> onsetMs,
  required List<double> amplitudes,
}) {
  final deviations = <double>[];
  for (final onset in onsetMs) {
    double? best;
    for (final click in clickMs) {
      final d = onset - click;
      if (best == null || d.abs() < best.abs()) best = d;
    }
    if (best != null) deviations.add(best);
  }

  final intervals = <double>[
    for (var i = 1; i < onsetMs.length; i++) onsetMs[i] - onsetMs[i - 1],
  ];

  final ampMean = amplitudes.isEmpty ? 0.0 : _mean(amplitudes);

  return UnassignedMetrics(
    timingMedianMs: _median(deviations),
    timingSpreadMs: _stdDev(deviations),
    intervalSpreadMs: _stdDev(intervals),
    dynamicsSpread: amplitudes.length < 2 || ampMean == 0
        ? null
        : _stdDev(amplitudes) / ampMean,
    playedCount: onsetMs.length,
    expectedCount: clickMs.length,
  );
}

double _mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

double _median(List<double> v) {
  if (v.isEmpty) return 0;
  final sorted = List<double>.of(v)..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

double _stdDev(List<double> v) {
  if (v.length < 2) return 0;
  final m = _mean(v);
  final variance =
      v.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / v.length;
  return math.sqrt(variance);
}
