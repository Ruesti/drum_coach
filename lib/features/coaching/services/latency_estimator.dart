/// Loopback latency estimation (Brief Etappe 1, §1.3): clicks are played on
/// the speaker and recorded through the mic; the measured shift is exactly
/// the sum of output latency (schedule → speaker) and input latency
/// (membrane → sample clock) — the quantity to subtract when relating onsets
/// to planned click times.
library;

import 'dart:math' as math;

import 'sequence_aligner.dart';

class LatencyEstimate {
  final double offsetMs;
  final int matchedClicks;
  final int totalClicks;

  /// Offset of each matched click in click order — the raw material for
  /// judging stability *within* one recording, where it matters: a practice
  /// session is a single recording too.
  final List<double> perClickOffsetsMs;

  const LatencyEstimate({
    required this.offsetMs,
    required this.matchedClicks,
    required this.totalClicks,
    this.perClickOffsetsMs = const [],
  });

  /// Median offset of [n] consecutive click blocks within this recording.
  List<double> blockOffsets(int n) {
    if (perClickOffsetsMs.isEmpty || n < 1) return const [];
    final size = (perClickOffsetsMs.length / n).ceil();
    return [
      for (var i = 0; i < perClickOffsetsMs.length; i += size)
        _median(perClickOffsetsMs.sublist(
            i, math.min(i + size, perClickOffsetsMs.length))),
    ];
  }

  /// Max minus min of [blockOffsets] — the within-recording spread.
  double? blockSpreadMs(int n) {
    final blocks = blockOffsets(n);
    if (blocks.length < 2) return null;
    final sorted = List<double>.of(blocks)..sort();
    return sorted.last - sorted.first;
  }
}

/// Two stages: a rough offset as the median of each onset's distance to its
/// nearest click (valid while the true latency stays below half the click
/// interval), then a monotone 1:1 alignment on the re-centered onsets whose
/// matched residuals refine the estimate and count the found clicks.
LatencyEstimate? estimateLatencyOffset({
  required List<double> plannedClickMs,
  required List<double> onsetMs,
}) {
  if (plannedClickMs.isEmpty || onsetMs.isEmpty) return null;

  final rough = _median([
    for (final onset in onsetMs)
      onset -
          plannedClickMs.reduce((a, b) =>
              (onset - a).abs() <= (onset - b).abs() ? a : b),
  ]);

  final aligned = alignSequences(
    expectedMs: plannedClickMs,
    onsetMs: [for (final o in onsetMs) o - rough],
    maxMatchDevMs: 150,
  );
  final residuals = [
    for (final n in aligned.notes)
      if (n.hit) n.deviationMs!,
  ];
  if (residuals.isEmpty) return null;

  return LatencyEstimate(
    offsetMs: rough + _median(residuals),
    matchedClicks: residuals.length,
    totalClicks: plannedClickMs.length,
    perClickOffsetsMs: [for (final r in residuals) rough + r],
  );
}

double _median(List<double> v) {
  final sorted = List<double>.of(v)..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}
