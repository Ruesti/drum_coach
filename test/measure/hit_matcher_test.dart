import 'dart:math' as math;

import 'package:drum_coach/content/exercises.dart';
import 'package:drum_coach/measure/hit_matcher.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:drum_coach/measure/targets.dart';
import 'package:flutter_test/flutter_test.dart';

const _gmNote = {Voice.hiHat: 42, Voice.snare: 38, Voice.kick: 36};
const _gmInstrument = {
  Voice.hiHat: KitInstrument.hiHatClosed,
  Voice.snare: KitInstrument.snare,
  Voice.kick: KitInstrument.kick,
};

Stroke _stroke(double timeMs, int note, KitInstrument instrument) =>
    Stroke(timeMs: timeMs, note: note, velocity: 100, instrument: instrument);

/// Perfect strokes for [targets] (GM notes: hi-hat closed 42, snare 38,
/// kick 36), one per target in target order, shifted by [shiftMs] plus the
/// per-voice [voiceShiftMs].
List<Stroke> strokesFor(
  List<TargetTime> targets, {
  double shiftMs = 0,
  Map<Voice, double> voiceShiftMs = const {},
}) =>
    [
      for (final t in targets)
        _stroke(t.timeMs + shiftMs + (voiceShiftMs[t.voice] ?? 0),
            _gmNote[t.voice]!, _gmInstrument[t.voice]!),
    ];

void main() {
  const firstBeatMs = 2000.0;
  final targets = basicRockBeat.targetTimes(firstBeatMs: firstBeatMs);
  // 80 BPM: bar = 3000 ms, hi-hat 8ths 375 ms apart → w = 187.5 ms.

  /// Index of the [voice] target in 0-based [bar] at [offsetMs] into the bar.
  int indexOf(Voice voice, int bar, double offsetMs) =>
      targets.indexWhere((t) =>
          t.voice == voice &&
          t.bar == bar &&
          t.timeMs == firstBeatMs + bar * 3000 + offsetMs);

  test('perfect play: all hit, deviation 0, no extras', () {
    final r = matchHits(
        targets: targets, strokes: strokesFor(targets), latencyOffsetMs: 0);
    expect(r.targets.length, targets.length);
    for (var i = 0; i < targets.length; i++) {
      expect(r.targets[i].target, same(targets[i]));
      expect(r.targets[i].kind, HitKind.hit);
      expect(r.targets[i].strokeIndex, i);
      expect(r.targets[i].deviationMs, 0);
    }
    expect(r.extraStrokeIndices, isEmpty);
    expect(r.ignoredStrokeIndices, isEmpty);
  });

  test('latency offset is subtracted: strokes +12 ms, offset 12 → deviation 0',
      () {
    final r = matchHits(
        targets: targets,
        strokes: strokesFor(targets, shiftMs: 12),
        latencyOffsetMs: 12);
    for (final o in r.targets) {
      expect(o.kind, HitKind.hit);
      expect(o.deviationMs, 0);
    }
    expect(r.extraStrokeIndices, isEmpty);
    expect(r.ignoredStrokeIndices, isEmpty);
  });

  test('+7 ms on every snare → snare deviations 7.0, others 0', () {
    final r = matchHits(
        targets: targets,
        strokes: strokesFor(targets, voiceShiftMs: {Voice.snare: 7}),
        latencyOffsetMs: 0);
    for (final o in r.targets) {
      expect(o.kind, HitKind.hit);
      expect(o.deviationMs, o.target.voice == Voice.snare ? 7.0 : 0.0);
    }
    expect(r.extraStrokeIndices, isEmpty);
  });

  test(
      'missing snare on bar 3 beat 2 → that target missed, nothing else changes',
      () {
    final missing = indexOf(Voice.snare, 2, 750); // bar 3 = 0-based 2
    expect(missing, isNonNegative);
    final strokes = strokesFor(targets)..removeAt(missing);
    final r = matchHits(targets: targets, strokes: strokes, latencyOffsetMs: 0);
    for (var i = 0; i < targets.length; i++) {
      final o = r.targets[i];
      if (i == missing) {
        expect(o.kind, HitKind.missed);
        expect(o.strokeIndex, isNull);
        expect(o.deviationMs, isNull);
      } else {
        expect(o.kind, HitKind.hit);
        expect(o.strokeIndex, i < missing ? i : i - 1);
        expect(o.deviationMs, 0);
      }
    }
    expect(r.extraStrokeIndices, isEmpty);
    expect(r.ignoredStrokeIndices, isEmpty);
  });

  test(
      'crash (note 49) instead of hi-hat on one 8th → wrongInstrument, not extra',
      () {
    final i = indexOf(Voice.hiHat, 5, 375); // "and" of beat 1, bar 6
    expect(i, isNonNegative);
    final strokes = strokesFor(targets);
    strokes[i] = _stroke(targets[i].timeMs + 4, 49, KitInstrument.crash1);
    final r = matchHits(targets: targets, strokes: strokes, latencyOffsetMs: 0);
    expect(r.targets[i].kind, HitKind.wrongInstrument);
    expect(r.targets[i].strokeIndex, i);
    expect(r.targets[i].deviationMs, 4);
    expect(r.targets.where((o) => o.kind != HitKind.hit).length, 1);
    expect(r.extraStrokeIndices, isEmpty);
  });

  test('double trigger: two snare notes 3 ms apart → 1 hit + 1 extra', () {
    final i = indexOf(Voice.snare, 4, 2250);
    expect(i, isNonNegative);
    final strokes = strokesFor(targets)
      ..add(_stroke(targets[i].timeMs + 3, 38, KitInstrument.snare));
    final r = matchHits(targets: targets, strokes: strokes, latencyOffsetMs: 0);
    for (final o in r.targets) {
      expect(o.kind, HitKind.hit);
    }
    expect(r.targets[i].strokeIndex, i);
    expect(r.targets[i].deviationMs, 0);
    expect(r.extraStrokeIndices, [strokes.length - 1]);
    expect(r.ignoredStrokeIndices, isEmpty);
  });

  test(
      'unmapped raw note 99 between targets → extra; on a target → wrongInstrument',
      () {
    // Between: halfway between two hi-hat 8ths of bar 2 (no snare/kick near).
    final between =
        _stroke(firstBeatMs + 3000 + 375 + 187.5, 99, KitInstrument.unknown);
    var strokes = strokesFor(targets)..add(between);
    var r = matchHits(targets: targets, strokes: strokes, latencyOffsetMs: 0);
    for (final o in r.targets) {
      expect(o.kind, HitKind.hit);
    }
    expect(r.extraStrokeIndices, [strokes.length - 1]);

    // On a target: replaces one hi-hat stroke.
    final i = indexOf(Voice.hiHat, 7, 1125);
    expect(i, isNonNegative);
    strokes = strokesFor(targets);
    strokes[i] = _stroke(targets[i].timeMs - 10, 99, KitInstrument.unknown);
    r = matchHits(targets: targets, strokes: strokes, latencyOffsetMs: 0);
    expect(r.targets[i].kind, HitKind.wrongInstrument);
    expect(r.targets[i].strokeIndex, i);
    expect(r.targets[i].deviationMs, -10);
    expect(r.targets.where((o) => o.kind != HitKind.hit).length, 1);
    expect(r.extraStrokeIndices, isEmpty);
  });

  test('strokes during count-in and 2 s after the end → ignored, not extra',
      () {
    final countIn = [
      for (var b = 0; b < 4; b++)
        _stroke(firstBeatMs - 3000 + b * 750, 42, KitInstrument.hiHatClosed),
    ];
    final after = _stroke(targets.last.timeMs + 2000, 38, KitInstrument.snare);
    final strokes = [...countIn, ...strokesFor(targets), after];
    final r = matchHits(targets: targets, strokes: strokes, latencyOffsetMs: 0);
    expect(r.ignoredStrokeIndices, [0, 1, 2, 3, strokes.length - 1]);
    expect(r.extraStrokeIndices, isEmpty);
    for (var i = 0; i < targets.length; i++) {
      expect(r.targets[i].kind, HitKind.hit);
      expect(r.targets[i].strokeIndex, i + 4);
      expect(r.targets[i].deviationMs, 0);
    }
  });

  test('shuffled stroke order gives the same result as in-order input', () {
    final missing = indexOf(Voice.snare, 2, 750);
    final inOrder = strokesFor(targets, voiceShiftMs: {Voice.kick: -5})
      ..[indexOf(Voice.hiHat, 5, 375)] = _stroke(
          targets[indexOf(Voice.hiHat, 5, 375)].timeMs + 4,
          49,
          KitInstrument.crash1)
      ..add(_stroke(targets[indexOf(Voice.snare, 4, 2250)].timeMs + 3, 38,
          KitInstrument.snare))
      ..removeAt(missing);
    final perm = List.generate(inOrder.length, (i) => i)
      ..shuffle(math.Random(42));
    final shuffled = [for (final p in perm) inOrder[p]];

    final a = matchHits(targets: targets, strokes: inOrder, latencyOffsetMs: 0);
    final b =
        matchHits(targets: targets, strokes: shuffled, latencyOffsetMs: 0);
    for (var i = 0; i < targets.length; i++) {
      expect(b.targets[i].kind, a.targets[i].kind);
      expect(b.targets[i].deviationMs, a.targets[i].deviationMs);
      final sa = a.targets[i].strokeIndex;
      final sb = b.targets[i].strokeIndex;
      expect(sb == null ? null : perm[sb], sa);
    }
    expect(([for (final s in b.extraStrokeIndices) perm[s]]..sort()),
        a.extraStrokeIndices);
    expect(a.targets[missing].kind, HitKind.missed);
  });

  test('two snare strokes given in reverse order both hit', () {
    final snares =
        targets.where((t) => t.voice == Voice.snare).take(2).toList();
    final strokes = [
      _stroke(snares[1].timeMs, 38, KitInstrument.snare),
      _stroke(snares[0].timeMs, 38, KitInstrument.snare),
    ];
    final r = matchHits(targets: snares, strokes: strokes, latencyOffsetMs: 0);
    expect(r.targets[0].kind, HitKind.hit);
    expect(r.targets[0].strokeIndex, 1);
    expect(r.targets[1].kind, HitKind.hit);
    expect(r.targets[1].strokeIndex, 0);
    expect(r.extraStrokeIndices, isEmpty);
  });

  test('hi-hat open counts as hi-hat hit', () {
    final i = indexOf(Voice.hiHat, 3, 1875);
    expect(i, isNonNegative);
    final strokes = strokesFor(targets);
    strokes[i] = _stroke(targets[i].timeMs, 46, KitInstrument.hiHatOpen);
    final r = matchHits(targets: targets, strokes: strokes, latencyOffsetMs: 0);
    expect(r.targets[i].kind, HitKind.hit);
    expect(r.targets[i].strokeIndex, i);
    expect(r.targets[i].deviationMs, 0);
    expect(r.extraStrokeIndices, isEmpty);
  });
}
