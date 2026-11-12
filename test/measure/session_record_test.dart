import 'package:drum_coach/content/analysis.dart';
import 'package:drum_coach/content/exercises.dart';
import 'package:drum_coach/measure/hit_matcher.dart';
import 'package:drum_coach/measure/session_record.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synthetic.dart';

void main() {
  test('encode → decode → encode is byte-identical', () {
    final r = syntheticSession(basicRockBeat,
        latencyMs: 12.5, shiftMs: {3: 4.25}, drop: {7});
    final text = encodeSessionJsonl(r);
    expect(encodeSessionJsonl(decodeSessionJsonl(text)), text);
    expect(text.split('\n').first, startsWith('{"type":"header","version":1,'));
  });

  test('decode rejects version 2 and missing header', () {
    final text = encodeSessionJsonl(syntheticSession(entryExercise))
        .replaceFirst('"version":1', '"version":2');
    expect(() => decodeSessionJsonl(text), throwsFormatException);
    expect(() => decodeSessionJsonl('{"type":"stroke","t":1.0}\n'),
        throwsFormatException);
  });

  test('decode throws FormatException on missing or wrong-typed fields', () {
    final good = encodeSessionJsonl(syntheticSession(entryExercise));
    expect(() => decodeSessionJsonl(good.replaceFirst('"bpm":70,', '')),
        throwsFormatException);
    expect(
        () => decodeSessionJsonl(good.replaceFirst('"bpm":70', '"bpm":"fast"')),
        throwsFormatException);
    expect(() => decodeSessionJsonl(good.replaceFirst('"note":', '"nota":')),
        throwsFormatException);
    expect(
        () => decodeSessionJsonl(good.replaceFirst('"vel":100', '"vel":"x"')),
        throwsFormatException);
    expect(() => decodeSessionJsonl('{"type":"header","version":1\n'),
        throwsFormatException);
  });

  test('synthetic +7.0 ms on index 10 → deviation 7.0 ± 0.1 for that target',
      () {
    final a =
        analyzeSession(syntheticSession(basicRockBeat, shiftMs: {10: 7.0}));
    final o = a.match.targets[10];
    expect(o.kind, HitKind.hit);
    expect(o.deviationMs, closeTo(7.0, 0.1));
  });
}
