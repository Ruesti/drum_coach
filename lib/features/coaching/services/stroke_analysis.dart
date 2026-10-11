import 'dart:math' as math;

import '../../lessons/models/rudiment.dart';
import '../midi/kit_instrument.dart';
import '../models/session_analysis.dart';
import 'lapse_detector.dart';
import 'mic_analysis_service.dart' show BeatRecord, MicAnalysisService;
import 'sequence_aligner.dart';
import 'stroke_source.dart';
import 'unassigned_metrics.dart';

/// Grace handling (Brief A.1): MIDI delivers a flam as two notes. Inside a
/// ±[windowMs] window around an expected note that carries graces, all but
/// the latest event are graces. Without graces expected, nothing is split
/// (an early double stroke stays an extra). Times are latency-corrected.
({List<StrokeEvent> main, List<StrokeEvent> grace}) splitGraceEvents({
  required List<StrokeEvent> events,
  required List<double> expectedMs,
  required List<bool> hasGrace,
  double windowMs = 40,
}) {
  final sorted = List<StrokeEvent>.of(events)
    ..sort((a, b) => a.timeMs.compareTo(b.timeMs));
  final isGrace = List<bool>.filled(sorted.length, false);
  for (var n = 0; n < expectedMs.length; n++) {
    if (!hasGrace[n]) continue;
    final lo = expectedMs[n] - windowMs;
    final hi = expectedMs[n] + windowMs;
    final inWindow = <int>[];
    for (var j = 0; j < sorted.length; j++) {
      if (isGrace[j]) continue;
      final t = sorted[j].timeMs;
      if (t >= lo && t <= hi) inWindow.add(j);
    }
    if (inWindow.length < 2) continue;
    for (var k = 0; k < inWindow.length - 1; k++) {
      isGrace[inWindow[k]] = true;
    }
  }
  return (
    main: [for (var j = 0; j < sorted.length; j++) if (!isGrace[j]) sorted[j]],
    grace: [for (var j = 0; j < sorted.length; j++) if (isGrace[j]) sorted[j]],
  );
}

/// Pure analysis core (Etappe 1 §1.2/§1.4, now source-agnostic): aligns
/// expected notes and strokes of [expectedInstrument] as two sequences,
/// derives hands only from assigned notes, reports per-hand values only
/// above the confidence gate. Strokes of other instruments are logged
/// unassigned (Brief A.1/A.9). [latencyOffsetMs] is subtracted before
/// matching; logged times stay raw.
SessionAnalysis analyzeStrokes({
  required List<StrokeEvent> events,
  required List<BeatRecord> beatLog,
  required List<StrokeBeat> sticking,
  required StrokeSourceKind source,
  KitInstrument expectedInstrument = KitInstrument.pad,
  double latencyOffsetMs = 0,
  bool analysisMode = false,
  Map<String, Object>? recordingSetup,
  double graceWindowMs = 40,
}) {
  final velocityExact = source == StrokeSourceKind.midi;
  if (events.isEmpty || beatLog.isEmpty || sticking.isEmpty) {
    return SessionAnalysis(
      detectedHits: events.length,
      expectedHits: beatLog.length,
      recordingSetup: recordingSetup,
      source: source,
      velocityExact: velocityExact,
    );
  }

  OnsetEventData unassigned(StrokeEvent e, {bool grace = false}) =>
      OnsetEventData(
        timeMs: e.timeMs,
        peakLevel: e.velocity,
        instrument: e.instrument.name,
        rawNote: e.rawNote,
        grace: grace,
      );

  final onInstrument = [
    for (final e in events)
      if (e.instrument == expectedInstrument) e,
  ];
  final offInstrument = [
    for (final e in events)
      if (e.instrument != expectedInstrument) e,
  ];

  // Stroke-level filter (13.09.) — microphone only: headphone click bleed
  // registers as quiet on-grid onsets. MIDI velocities are exact; a quiet
  // ghost note is a stroke.
  final strokes = <StrokeEvent>[];
  final dropped = <StrokeEvent>[];
  for (final e in onInstrument) {
    if (source == StrokeSourceKind.mic &&
        e.velocity < MicAnalysisService.minStrokeLevel) {
      dropped.add(e);
    } else {
      strokes.add(e);
    }
  }
  if (source == StrokeSourceKind.mic &&
      onInstrument.length >= 8 &&
      strokes.length < onInstrument.length * 0.2) {
    return SessionAnalysis(
      detectedHits: strokes.length,
      expectedHits: beatLog.length,
      recordingSetup: recordingSetup,
      signalTooWeak: true,
      peakLevels: [for (final e in onInstrument) e.velocity],
      events: [for (final e in events) unassigned(e)]
        ..sort((a, b) => a.timeMs.compareTo(b.timeMs)),
      source: source,
      velocityExact: velocityExact,
    );
  }

  final expectedMs = [
    for (final b in beatLog) b.timestamp.microsecondsSinceEpoch / 1000.0,
  ];
  final hasGrace = [
    for (final b in beatLog)
      sticking[b.beatIndex % sticking.length].graces.isNotEmpty,
  ];
  final corrected = [
    for (final e in strokes)
      StrokeEvent(
        timeMs: e.timeMs - latencyOffsetMs,
        instrument: e.instrument,
        velocity: e.velocity,
        rawNote: e.rawNote,
        source: e.source,
      ),
  ];
  final split = splitGraceEvents(
    events: corrected,
    expectedMs: expectedMs,
    hasGrace: hasGrace,
    windowMs: graceWindowMs,
  );
  final mainStrokes = split.main;
  final onsetMs = [for (final e in mainStrokes) e.timeMs];
  final amplitudes = [for (final e in mainStrokes) e.velocity];

  final aligned = alignSequences(expectedMs: expectedMs, onsetMs: onsetMs);

  // Assess only the window from the first to the last note actually hit
  // (phantom misses before joining / after stopping, device test Etappe 1).
  var firstHit = -1, lastHit = -1;
  for (var i = 0; i < aligned.notes.length; i++) {
    if (!aligned.notes[i].hit) continue;
    if (firstHit < 0) firstHit = i;
    lastHit = i;
  }
  final assessed = firstHit < 0
      ? aligned.notes
      : aligned.notes.sublist(firstHit, lastHit + 1);

  final hitCount = assessed.where((n) => n.hit).length;
  final assessedDevs = [
    for (final n in assessed)
      if (n.hit) n.deviationMs!,
  ];
  final jitterMs = _stdDev(assessedDevs);
  final jitterExceeded =
      assessedDevs.length >= 4 && jitterMs > MicAnalysisService.jitterGateMs;
  final sessionStartMs = expectedMs.isNotEmpty ? expectedMs.first : 0.0;
  final lapses = detectLapses(
    noteTimesMs: [for (final n in assessed) n.expectedMs - sessionStartMs],
    deviationsMs: [for (final n in assessed) n.hit ? n.deviationMs : null],
  );
  final summary = AlignmentSummary(
    expectedCount: assessed.length,
    hitCount: hitCount,
    missedCount: assessed.length - hitCount,
    extraCount: aligned.extraCount,
    handValuesAllowed: assessed.isNotEmpty &&
        hitCount / assessed.length >= 0.9 &&
        aligned.extraCount / assessed.length < 0.05 &&
        !jitterExceeded &&
        lapses.isEmpty,
    jitterLimitExceeded: jitterExceeded,
    lapses: lapses,
  );

  final unassignedMetrics = computeUnassignedMetrics(
    clickMs: [for (final n in assessed) n.expectedMs],
    onsetMs: onsetMs,
    amplitudes: amplitudes,
  );

  final matched = <MatchedHit>[];
  final deviations = <double>[];
  for (final note in assessed) {
    if (!note.hit) continue;
    deviations.add(note.deviationMs!);
    final patternPos = beatLog[note.noteIndex].beatIndex % sticking.length;
    matched.add(MatchedHit(
      hitTimestamp: DateTime.fromMicrosecondsSinceEpoch(
          (onsetMs[note.onsetIndex!] * 1000).round()),
      amplitude: amplitudes[note.onsetIndex!],
      deviationMs: note.deviationMs!,
      hand: sticking[patternPos].hand,
    ));
  }

  final gateOpen =
      analysisMode && summary.handValuesAllowed && matched.length >= 4;

  final noteByOnset = <int, AlignedNote>{
    for (final n in assessed)
      if (n.hit) n.onsetIndex!: n,
  };
  final logged = <OnsetEventData>[
    for (var j = 0; j < mainStrokes.length; j++)
      OnsetEventData(
        timeMs: mainStrokes[j].timeMs + latencyOffsetMs,
        peakLevel: amplitudes[j],
        notePosition: noteByOnset[j] == null
            ? null
            : beatLog[noteByOnset[j]!.noteIndex].beatIndex,
        hand: noteByOnset[j] == null || !gateOpen
            ? null
            : (sticking[beatLog[noteByOnset[j]!.noteIndex].beatIndex %
                            sticking.length]
                        .hand ==
                    Hand.right
                ? 'R'
                : 'L'),
        deviationMs: noteByOnset[j]?.deviationMs,
        instrument: mainStrokes[j].instrument.name,
        rawNote: mainStrokes[j].rawNote,
      ),
    for (final e in split.grace)
      OnsetEventData(
        timeMs: e.timeMs + latencyOffsetMs,
        peakLevel: e.velocity,
        instrument: e.instrument.name,
        rawNote: e.rawNote,
        grace: true,
      ),
    for (final e in dropped) unassigned(e),
    for (final e in offInstrument) unassigned(e),
  ]..sort((a, b) => a.timeMs.compareTo(b.timeMs));

  return SessionAnalysis(
    timing: gateOpen ? _calcTiming(matched) : null,
    dynamics: gateOpen ? _calcDynamics(matched) : null,
    unassigned: unassignedMetrics,
    alignment: summary,
    peakLevels: amplitudes,
    deviationsMs: deviations,
    events: logged,
    latencyOffsetAppliedMs: latencyOffsetMs,
    detectedHits: mainStrokes.length,
    expectedHits: beatLog.length,
    recordingSetup: recordingSetup,
    source: source,
    velocityExact: velocityExact,
  );
}

TimingAnalysis _calcTiming(List<MatchedHit> hits) {
  List<double> devs(Hand h) =>
      hits.where((m) => m.hand == h).map((m) => m.deviationMs).toList();

  final all = hits.map((m) => m.deviationMs).toList();
  final right = devs(Hand.right);
  final left = devs(Hand.left);

  final avgAll = _mean(all);
  return TimingAnalysis(
    overallDeviationMs: avgAll,
    rightHandDeviationMs: right.isEmpty ? 0 : _mean(right),
    leftHandDeviationMs: left.isEmpty ? 0 : _mean(left),
    jitterMs: _stdDevWithMean(all, avgAll),
  );
}

DynamicsAnalysis _calcDynamics(List<MatchedHit> hits) {
  List<double> amps(Hand h) =>
      hits.where((m) => m.hand == h).map((m) => m.amplitude).toList();

  final right = amps(Hand.right);
  final left = amps(Hand.left);
  return DynamicsAnalysis(
    rightHandLevel: right.isEmpty ? 0 : _mean(right),
    leftHandLevel: left.isEmpty ? 0 : _mean(left),
  );
}

double _mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

double _stdDev(List<double> v) {
  if (v.length < 2) return 0;
  final mean = v.reduce((a, b) => a + b) / v.length;
  return _stdDevWithMean(v, mean);
}

double _stdDevWithMean(List<double> v, double mean) {
  final variance =
      v.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
          v.length;
  return math.sqrt(variance);
}
