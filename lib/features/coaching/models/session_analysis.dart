import '../../lessons/models/rudiment.dart';
import '../services/lapse_detector.dart';
import '../services/stroke_source.dart';
import '../services/unassigned_metrics.dart';

export '../services/lapse_detector.dart' show Lapse;
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

  /// P3 extension (Auftraggeber-Entscheidung 11.09.): complete-but-wobbly
  /// runs (timing std dev above the jitter gate) also block hand values —
  /// with their own announcement wording in the UI.
  final bool jitterLimitExceeded;

  /// Locally bad stretches (Auftraggeber-Entscheidung 13.09.): a run whose
  /// averages look fine can still contain a stretch where the player fell
  /// off — detected per sliding window, times relative to the session's
  /// first click. Any lapse blocks hand values and gets announced with its
  /// position.
  final List<Lapse> lapses;

  const AlignmentSummary({
    required this.expectedCount,
    required this.hitCount,
    required this.missedCount,
    required this.extraCount,
    required this.handValuesAllowed,
    this.jitterLimitExceeded = false,
    this.lapses = const [],
  });

  double get hitRate => expectedCount == 0 ? 0 : hitCount / expectedCount;
  double get extraRate => expectedCount == 0 ? 0 : extraCount / expectedCount;
}

/// One detected onset as raw session-log material (Brief Phase 2): time is
/// the unclipped wall-clock instant (no latency subtracted — nothing is
/// computed away from logged data), assignment and hand are derived views.
class OnsetEventData {
  final double timeMs;      // raw epoch ms on the shared time axis
  final double peakLevel;   // mic: peak level; midi: velocity 0–1
  final int? notePosition;  // assigned note index, null = surplus onset
  final String? hand;       // 'R'/'L', only when assigned and gate open
  final double? deviationMs;

  /// `KitInstrument.name` the stroke came from (`pad` for the microphone).
  final String? instrument;

  /// MIDI note number, null for the microphone.
  final int? rawNote;

  /// True for a grace note absorbed by a flam/drag main stroke (Brief A.1):
  /// logged, never a hit and never an extra.
  final bool grace;

  const OnsetEventData({
    required this.timeMs,
    required this.peakLevel,
    this.notePosition,
    this.hand,
    this.deviationMs,
    this.instrument,
    this.rawNote,
    this.grace = false,
  });
}

/// Accent evaluation from exact velocities (Brief A.5): only computed for
/// MIDI. [accentRatio] = mean velocity of accented notes / mean of plain
/// notes; [accentsLouder] = how many accented notes beat the plain median.
class AccentAnalysis {
  final double accentRatio;
  final int accentsLouder;
  final int accentCount;

  const AccentAnalysis({
    required this.accentRatio,
    required this.accentsLouder,
    required this.accentCount,
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

  /// True when the recording carried (almost) no stroke-level onsets — only
  /// quiet click bleed or noise. No verdicts are computed then; the UI asks
  /// to move the phone closer instead of judging a signal that holds no
  /// strokes (13.09.: headphone click at level ≤0.14 was all the mic heard).
  final bool signalTooWeak;

  /// Which source measured this session; null = nothing measured.
  final StrokeSourceKind? source;

  /// Velocities are exact (MIDI) — accent and ghost values may show numbers.
  final bool velocityExact;

  /// Set when the exercise could not be measured with this setup (device
  /// lost, sensor level unmet). No numbers are shown then.
  final bool notMeasurable;

  final AccentAnalysis? accents;

  /// MIDI measured without a stored latency offset for the device (Brief
  /// A.4): numbers are shown, but timing may read late — the sheet warns.
  final bool latencyUncalibrated;

  /// Strokes arrived, but none on the instrument the exercise is measured
  /// on (pad role) — a kit-mapping or pad-role problem, not a bad run.
  final bool noStrokesOnInstrument;

  /// Label of the instrument the exercise was measured on, for the
  /// [noStrokesOnInstrument] hint.
  final String? expectedInstrumentLabel;

  const SessionAnalysis({
    this.timing,
    this.dynamics,
    this.unassigned,
    this.alignment,
    this.peakLevels = const [],
    this.deviationsMs = const [],
    this.events = const [],
    this.latencyOffsetAppliedMs = 0,
    this.signalTooWeak = false,
    this.source,
    this.velocityExact = false,
    this.notMeasurable = false,
    this.accents,
    this.latencyUncalibrated = false,
    this.noStrokesOnInstrument = false,
    this.expectedInstrumentLabel,
    required this.detectedHits,
    required this.expectedHits,
    this.recordingSetup,
  });

  bool get hasData => detectedHits > 3;

  /// The same analysis flagged as measured without a latency calibration.
  SessionAnalysis withLatencyUncalibrated() => SessionAnalysis(
        timing: timing,
        dynamics: dynamics,
        unassigned: unassigned,
        alignment: alignment,
        peakLevels: peakLevels,
        deviationsMs: deviationsMs,
        events: events,
        latencyOffsetAppliedMs: latencyOffsetAppliedMs,
        signalTooWeak: signalTooWeak,
        source: source,
        velocityExact: velocityExact,
        notMeasurable: notMeasurable,
        accents: accents,
        latencyUncalibrated: true,
        noStrokesOnInstrument: noStrokesOnInstrument,
        expectedInstrumentLabel: expectedInstrumentLabel,
        detectedHits: detectedHits,
        expectedHits: expectedHits,
        recordingSetup: recordingSetup,
      );
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
