import 'package:drum_coach/content/exercises.dart';
import 'package:drum_coach/measure/hit_matcher.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:drum_coach/measure/targets.dart';
import 'package:drum_coach/skill/metrics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/strokes.dart';

SessionMetrics metricsFor(
    Exercise e, List<TargetTime> targets, List<Stroke> strokes) {
  final match =
      matchHits(targets: targets, strokes: strokes, latencyOffsetMs: 0);
  return computeMetrics(match: match, strokes: strokes);
}

void main() {
  final targets = basicRockBeat.targetTimes(firstBeatMs: 2000);

  test('perfect play: rates 1, no wrong/extra, deviation 0, gap one 8th', () {
    final m = metricsFor(
        basicRockBeat, targets, [for (final t in targets) strokeFor(t)]);
    expect(m.targetCount, 192);
    expect(m.hitRate, {Voice.hiHat: 1.0, Voice.snare: 1.0, Voice.kick: 1.0});
    expect(m.wrongRate, 0);
    expect(m.extraRate, 0);
    expect(m.timingMedianMs, 0);
    expect(m.timingSpreadMs, 0);
    expect(m.snareVelocitySd, 0);
    expect(m.maxHitGapMs, 375);
    expect(m.countedStrokes, 192);
  });

  test('wrong instrument and extra strokes are per target count', () {
    final snare = targets.firstWhere((t) => t.voice == Voice.snare);
    final strokes = [
      for (final t in targets)
        if (t != snare) strokeFor(t),
      strokeFor(snare, as: Voice.kick), // snare target played on kick
      strokeFor(targets[1], shiftMs: 100), // extra hi-hat between targets
    ];
    final m = metricsFor(basicRockBeat, targets, strokes);
    expect(m.wrongRate, closeTo(1 / 192, 1e-12));
    expect(m.extraRate, closeTo(1 / 192, 1e-12));
    expect(m.hitRate[Voice.snare], closeTo(31 / 32, 1e-12));
  });

  test('no hits: timing null, velocity null, gap is the whole run', () {
    final m = metricsFor(basicRockBeat, targets, const []);
    expect(m.timingMedianMs, isNull);
    expect(m.timingSpreadMs, isNull);
    expect(m.snareVelocitySd, isNull);
    expect(m.maxHitGapMs, targets.last.timeMs - targets.first.timeMs);
    expect(m.countedStrokes, 0);
  });

  test('median and spread over hit deviations, even count averages middle', () {
    final strokes = [
      for (var i = 0; i < targets.length; i++)
        strokeFor(targets[i], shiftMs: i.isEven ? 10 : 20),
    ];
    final m = metricsFor(basicRockBeat, targets, strokes);
    expect(m.timingMedianMs, 15);
    expect(m.timingSpreadMs, 5);
  });
}
