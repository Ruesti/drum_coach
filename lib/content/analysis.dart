/// Analysis pipeline: a pure function of a recorded session. Lives in
/// `content/` because it resolves the exercise by id.
library;

import 'dart:convert';

import '../measure/hit_matcher.dart';
import '../measure/session_record.dart';
import '../measure/targets.dart';
import '../skill/gate.dart';
import '../skill/metrics.dart';
import 'exercises.dart';

class SessionAnalysis {
  const SessionAnalysis({
    required this.exercise,
    required this.targets,
    required this.match,
    required this.metrics,
    required this.gate,
  });

  final Exercise exercise;
  final List<TargetTime> targets;
  final MatchResult match;
  final SessionMetrics metrics;
  final GateResult gate;
}

SessionAnalysis analyzeSession(SessionRecord r) {
  final exercise = exerciseById(r.exerciseId);
  final targets = exercise.targetTimes(firstBeatMs: r.firstBeatMs);
  final match = matchHits(
    targets: targets,
    strokes: r.strokes,
    latencyOffsetMs: r.latencyOffsetMs ?? 0,
  );
  final metrics = computeMetrics(match: match, strokes: r.strokes);
  final gate = evaluateGate(
    spec: exercise.gate,
    metrics: metrics,
    voices: {for (final h in exercise.barHits) h.voice},
    barMs: exercise.barMs,
    calibrated: r.latencyOffsetMs != null,
  );
  return SessionAnalysis(
    exercise: exercise,
    targets: targets,
    match: match,
    metrics: metrics,
    gate: gate,
  );
}

double? _r(double? v) => v == null ? null : (v * 1000).round() / 1000;

/// Deterministic pretty JSON used for the golden reference files.
String analysisToJson(SessionAnalysis a) {
  final m = a.metrics;
  final map = <String, Object?>{
    'exercise': a.exercise.id,
    'gate': {
      'status': a.gate.status.name,
      'reason': a.gate.reason,
      'criteria': [
        for (final c in a.gate.criteria)
          {
            'id': c.id,
            'actual': _r(c.actual),
            'threshold': _r(c.threshold),
            'atMost': c.atMost,
            'passed': c.passed,
          },
      ],
    },
    'metrics': {
      'hitRate': {
        for (final e in m.hitRate.entries) e.key.name: _r(e.value),
      },
      'wrongRate': _r(m.wrongRate),
      'extraRate': _r(m.extraRate),
      'timingMedianMs': _r(m.timingMedianMs),
      'timingSpreadMs': _r(m.timingSpreadMs),
      'snareVelocitySd': _r(m.snareVelocitySd),
      'maxHitGapMs': _r(m.maxHitGapMs),
      'targetCount': m.targetCount,
      'countedStrokes': m.countedStrokes,
    },
    'targets': [
      for (final o in a.match.targets)
        {
          'index': o.target.index,
          'voice': o.target.voice.name,
          'bar': o.target.bar,
          'timeMs': _r(o.target.timeMs),
          'kind': o.kind.name,
          'strokeIndex': o.strokeIndex,
          'deviationMs': _r(o.deviationMs),
        },
    ],
    'extraStrokeIndices': a.match.extraStrokeIndices,
    'ignoredStrokeIndices': a.match.ignoredStrokeIndices,
  };
  return '${const JsonEncoder.withIndent('  ').convert(map)}\n';
}
