import '../../lessons/models/rudiment.dart';
import '../services/unassigned_metrics.dart';

export '../services/unassigned_metrics.dart' show UnassignedMetrics;

/// Alignment outcome of one run (§1.2): how many expected notes were hit or
/// missed, how many onsets were extra, and whether the run clears the
/// confidence gate for per-hand values.
class AlignmentSummary {
  final int expectedCount;
  final int hitCount;
  final int missedCount;
  final int extraCount;
  final bool handValuesAllowed;

  const AlignmentSummary({
    required this.expectedCount,
    required this.hitCount,
    required this.missedCount,
    required this.extraCount,
    required this.handValuesAllowed,
  });

  double get hitRate => expectedCount == 0 ? 0 : hitCount / expectedCount;
  double get extraRate => expectedCount == 0 ? 0 : extraCount / expectedCount;
}

/// One detected onset as raw session-log material (Brief Phase 2): time is
/// the unclipped wall-clock instant (no latency subtracted — nothing is
/// computed away from logged data), assignment and hand are derived views.
class OnsetEventData {
  final double timeMs;      // raw epoch ms on the shared time axis
  final double peakLevel;
  final int? notePosition;  // assigned note index, null = surplus onset
  final String? hand;       // 'R'/'L', only when assigned and gate open
  final double? deviationMs;

  const OnsetEventData({
    required this.timeMs,
    required this.peakLevel,
    this.notePosition,
    this.hand,
    this.deviationMs,
  });
}

class SessionAnalysis {
  /// Per-hand timing — only present when the run cleared the §1.2 gate.
  final TimingAnalysis? timing;

  /// Per-hand dynamics — same gate as [timing].
  final DynamicsAnalysis? dynamics;

  /// Assignment-free measures (§1.4) — present whenever anything was matched
  /// against the click, independent of the gate.
  final UnassignedMetrics? unassigned;

  final AlignmentSummary? alignment;

  /// Peak level of every detected onset, chronological (§1.1 check).
  final List<double> peakLevels;

  /// Deviation of each assigned note in note order (§1.2 check: an early
  /// stroke shows up as its own outlier here).
  final List<double> deviationsMs;

  /// One raw event per detected onset, chronological — the per-event half
  /// of the Phase-2 session log.
  final List<OnsetEventData> events;

  /// The stored calibration offset that was subtracted from onset times
  /// before matching; 0 = uncalibrated (§1.3).
  final double latencyOffsetAppliedMs;

  final int detectedHits;
  final int expectedHits;

  /// The recording path used (§1.1: audioSource, effects, UNPROCESSED
  /// support) — shown in the measurement details and, from Phase 2 on,
  /// written into the session header.
  final Map<String, Object>? recordingSetup;

  const SessionAnalysis({
    this.timing,
    this.dynamics,
    this.unassigned,
    this.alignment,
    this.peakLevels = const [],
    this.deviationsMs = const [],
    this.events = const [],
    this.latencyOffsetAppliedMs = 0,
    required this.detectedHits,
    required this.expectedHits,
    this.recordingSetup,
  });

  bool get hasData => detectedHits > 3;
}

class TimingAnalysis {
  final double overallDeviationMs;    // positive = consistently late
  final double rightHandDeviationMs;
  final double leftHandDeviationMs;
  final double jitterMs;              // std deviation → consistency

  const TimingAnalysis({
    required this.overallDeviationMs,
    required this.rightHandDeviationMs,
    required this.leftHandDeviationMs,
    required this.jitterMs,
  });
}

class DynamicsAnalysis {
  final double rightHandLevel;  // avg amplitude 0–1
  final double leftHandLevel;

  const DynamicsAnalysis({
    required this.rightHandLevel,
    required this.leftHandLevel,
  });

  double get balance => leftHandLevel / (rightHandLevel + 0.001);
}

class MatchedHit {
  final DateTime hitTimestamp;
  final double amplitude;
  final double deviationMs;
  final Hand hand;

  const MatchedHit({
    required this.hitTimestamp,
    required this.amplitude,
    required this.deviationMs,
    required this.hand,
  });
}
