import 'package:drum_coach/content/exercises.dart';
import 'package:drum_coach/measure/hit_matcher.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:drum_coach/measure/targets.dart';
import 'package:drum_coach/skill/gate.dart';
import 'package:drum_coach/skill/metrics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/strokes.dart';

GateResult gateFor(
  Exercise e,
  List<TargetTime> targets,
  List<Stroke> strokes, {
  bool calibrated = true,
}) {
  final match =
      matchHits(targets: targets, strokes: strokes, latencyOffsetMs: 0);
  final metrics = computeMetrics(match: match, strokes: strokes);
  return evaluateGate(
      spec: e.gate,
      metrics: metrics,
      voices: {for (final h in e.barHits) h.voice},
      barMs: e.barMs,
      calibrated: calibrated);
}

Set<String> failedIds(GateResult r) => {
      for (final c in r.criteria)
        if (!c.passed) c.id,
    };

void main() {
  final rock = basicRockBeat.targetTimes(firstBeatMs: 2000);
  final entry = entryExercise.targetTimes(firstBeatMs: 2000);
  final perfectRock = [for (final t in rock) strokeFor(t)];

  test('rock, perfect play → passed, every criterion listed', () {
    final r = gateFor(basicRockBeat, rock, perfectRock);
    expect(r.status, GateStatus.passed);
    expect(r.reason, isNull);
    expect([
      for (final c in r.criteria) c.id
    ], [
      'hitRate.hiHat',
      'hitRate.snare',
      'hitRate.kick',
      'wrongRate',
      'extraRate',
      'timingMedian',
      'timingSpread',
      'snareVelocitySd',
    ]);
    final hh = r.criteria.first;
    expect(hh.label, 'Hi-hat hit rate');
    expect(hh.actual, 1.0);
    expect(hh.threshold, 0.95);
    expect(hh.atMost, isFalse);
    final median = r.criteria.firstWhere((c) => c.id == 'timingMedian');
    expect(median.label, 'Timing median (ms)');
    expect(median.atMost, isTrue);
    expect(median.threshold, 15);
  });

  test('rock, hi-hat hit rate below 0.95 → failed on hitRate.hiHat only', () {
    var skipped = 0;
    final strokes = [
      for (final t in rock)
        if (t.voice != Voice.hiHat || skipped++ >= 8) strokeFor(t),
    ];
    final r = gateFor(basicRockBeat, rock, strokes);
    expect(r.status, GateStatus.failed);
    expect(failedIds(r), {'hitRate.hiHat'});
    expect(r.criteria.first.actual, closeTo(120 / 128, 1e-12));
  });

  test('rock, spread exactly 20 ms → passes (thresholds inclusive)', () {
    final strokes = [
      for (var i = 0; i < rock.length; i++)
        strokeFor(rock[i], shiftMs: i.isEven ? 20 : -20),
    ];
    final r = gateFor(basicRockBeat, rock, strokes);
    final spread = r.criteria.firstWhere((c) => c.id == 'timingSpread');
    expect(spread.actual, 20);
    expect(spread.passed, isTrue);
    expect(r.status, GateStatus.passed);
  });

  test('rock, snare velocities alternating 80/110 → SD 15 → failed', () {
    var n = 0;
    final strokes = [
      for (final t in rock)
        strokeFor(t, velocity: t.voice == Voice.snare ? _alt(n++) : 100),
    ];
    final r = gateFor(basicRockBeat, rock, strokes);
    final sd = r.criteria.firstWhere((c) => c.id == 'snareVelocitySd');
    expect(sd.actual, closeTo(15, 1e-9));
    expect(failedIds(r), {'snareVelocitySd'});
    expect(r.status, GateStatus.failed);
  });

  test('entry, player stops after bar 4 of 8 → gap > 1 bar → failed', () {
    final strokes = [
      for (final t in entry)
        if (t.bar < 4) strokeFor(t),
    ];
    final r = gateFor(entryExercise, entry, strokes);
    expect(r.status, GateStatus.failed);
    final gap = r.criteria.firstWhere((c) => c.id == 'hitGap');
    expect(gap.label, 'Longest gap (bars)');
    expect(gap.actual, greaterThan(1));
    expect(failedIds(r), contains('hitGap'));
  });

  test('entry, 87.5 % hits, gaps ≤ 1 bar, 60 ms late → passed, no timing row',
      () {
    // Drop the 2nd hi-hat of even bars (4 of 32) and the 2nd kick of bars
    // 1 and 5 (2 of 16): 28/32 and 14/16 = 0.875 each.
    final strokes = [
      for (var i = 0; i < entry.length; i++)
        if (!_dropped(entry[i])) strokeFor(entry[i], shiftMs: 60),
    ];
    final r = gateFor(entryExercise, entry, strokes);
    expect(r.status, GateStatus.passed);
    expect([for (final c in r.criteria) c.id],
        ['hitRate.hiHat', 'hitRate.kick', 'hitGap']);
    expect(r.criteria.first.actual, 0.875);
  });

  test('not calibrated → notMeasurable (uncalibrated), criteria still filled',
      () {
    final r = gateFor(basicRockBeat, rock, perfectRock, calibrated: false);
    expect(r.status, GateStatus.notMeasurable);
    expect(r.reason, 'uncalibrated');
    expect(r.criteria, hasLength(8));
    expect(r.criteria.every((c) => c.passed), isTrue);
  });

  test('zero strokes → notMeasurable (no-strokes), also when uncalibrated', () {
    final r = gateFor(basicRockBeat, rock, const [], calibrated: false);
    expect(r.status, GateStatus.notMeasurable);
    expect(r.reason, 'no-strokes');
    expect(r.criteria, hasLength(8));
    expect(r.criteria.any((c) => !c.passed), isTrue);
  });

  test('only strokes outside the window → no-strokes', () {
    final r =
        gateFor(basicRockBeat, rock, [strokeFor(rock.first, shiftMs: -1500)]);
    expect(r.reason, 'no-strokes');
  });
}

bool _dropped(TargetTime t) {
  final inBar = t.timeMs - 2000 - t.bar * entryExercise.barMs;
  final quarterMs = 60000 / entryExercise.bpm;
  if (t.voice == Voice.hiHat) {
    return t.bar.isEven && (inBar - quarterMs).abs() < 1e-6;
  }
  if (t.voice == Voice.kick) {
    return (t.bar == 1 || t.bar == 5) && (inBar - 2 * quarterMs).abs() < 1e-6;
  }
  return false;
}

int _alt(int n) => n.isEven ? 80 : 110;
