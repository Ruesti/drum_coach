/// Gate thresholds per exercise and their evaluation against session metrics.
library;

import '../measure/kit.dart';
import 'metrics.dart';

class GateSpec {
  const GateSpec({
    required this.minHitRatePerVoice,
    this.maxWrongRate,
    this.maxExtraRate,
    this.maxAbsMedianMs,
    this.maxSpreadMs,
    this.maxSnareVelocitySd,
    this.maxHitGapBars,
  });

  final double minHitRatePerVoice;
  final double? maxWrongRate;
  final double? maxExtraRate;
  final double? maxAbsMedianMs;
  final double? maxSpreadMs;
  final double? maxSnareVelocitySd;
  final double? maxHitGapBars;
}

class GateCriterion {
  const GateCriterion({
    required this.id,
    required this.label,
    required this.actual,
    required this.threshold,
    required this.atMost,
    required this.passed,
  });

  final String id;
  final String label;

  /// Null when it could not be computed (e.g. no hits → no median); fails.
  final double? actual;
  final double threshold;

  /// True: actual must be <= threshold; false: actual must be >= threshold.
  final bool atMost;
  final bool passed;
}

enum GateStatus { passed, failed, notMeasurable }

class GateResult {
  const GateResult({required this.status, required this.criteria, this.reason});

  final GateStatus status;
  final List<GateCriterion> criteria;

  /// `'uncalibrated'` or `'no-strokes'` when [status] is notMeasurable.
  final String? reason;
}

const _voiceCriteria = {
  Voice.hiHat: ('hitRate.hiHat', 'Hi-hat hit rate'),
  Voice.snare: ('hitRate.snare', 'Snare hit rate'),
  Voice.kick: ('hitRate.kick', 'Kick hit rate'),
};

/// [voices] are the voices present in the exercise, [barMs] its bar length.
/// Evaluates [metrics] against [spec]. All thresholds are inclusive. Without
/// any counted stroke the run is not measurable (`no-strokes`), else without
/// calibration it is not measurable (`uncalibrated`); the criteria are listed
/// either way.
GateResult evaluateGate({
  required GateSpec spec,
  required SessionMetrics metrics,
  required Set<Voice> voices,
  required double barMs,
  required bool calibrated,
}) {
  final criteria = <GateCriterion>[];

  void add(String id, String label, double? actual, double threshold,
      {required bool atMost}) {
    final ok =
        actual != null && (atMost ? actual <= threshold : actual >= threshold);
    criteria.add(GateCriterion(
      id: id,
      label: label,
      actual: actual,
      threshold: threshold,
      atMost: atMost,
      passed: ok,
    ));
  }

  for (final v in Voice.values) {
    if (!voices.contains(v)) continue;
    final (id, label) = _voiceCriteria[v]!;
    add(id, label, metrics.hitRate[v] ?? 0, spec.minHitRatePerVoice,
        atMost: false);
  }
  if (spec.maxWrongRate != null) {
    add('wrongRate', 'Wrong instrument', metrics.wrongRate, spec.maxWrongRate!,
        atMost: true);
  }
  if (spec.maxExtraRate != null) {
    add('extraRate', 'Extra hits', metrics.extraRate, spec.maxExtraRate!,
        atMost: true);
  }
  if (spec.maxAbsMedianMs != null) {
    add('timingMedian', 'Timing median (ms)', metrics.timingMedianMs?.abs(),
        spec.maxAbsMedianMs!,
        atMost: true);
  }
  if (spec.maxSpreadMs != null) {
    add('timingSpread', 'Timing spread (ms)', metrics.timingSpreadMs,
        spec.maxSpreadMs!,
        atMost: true);
  }
  if (spec.maxSnareVelocitySd != null) {
    add('snareVelocitySd', 'Snare velocity SD', metrics.snareVelocitySd,
        spec.maxSnareVelocitySd!,
        atMost: true);
  }
  if (spec.maxHitGapBars != null) {
    add('hitGap', 'Longest gap (bars)', metrics.maxHitGapMs / barMs,
        spec.maxHitGapBars!,
        atMost: true);
  }

  if (metrics.countedStrokes == 0) {
    return GateResult(
        status: GateStatus.notMeasurable,
        criteria: criteria,
        reason: 'no-strokes');
  }
  if (!calibrated) {
    return GateResult(
        status: GateStatus.notMeasurable,
        criteria: criteria,
        reason: 'uncalibrated');
  }
  return GateResult(
    status:
        criteria.every((c) => c.passed) ? GateStatus.passed : GateStatus.failed,
    criteria: criteria,
  );
}
