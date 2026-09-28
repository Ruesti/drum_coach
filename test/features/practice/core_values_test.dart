import 'package:drum_coach/features/coaching/models/session_analysis.dart';
import 'package:drum_coach/features/coaching/services/unassigned_metrics.dart';
import 'package:drum_coach/features/practice/core_values.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UnassignedMetrics u({
    double median = 0,
    double spread = 8,
    double interval = 6,
    int played = 32,
    int expected = 32,
  }) =>
      UnassignedMetrics(
        timingMedianMs: median,
        timingSpreadMs: spread,
        intervalSpreadMs: interval,
        dynamicsSpread: null,
        playedCount: played,
        expectedCount: expected,
      );

  AlignmentSummary al({int hit = 32, int missed = 0, int extra = 0}) =>
      AlignmentSummary(
        expectedCount: hit + missed,
        hitCount: hit,
        missedCount: missed,
        extraCount: extra,
        handValuesAllowed: true,
        jitterLimitExceeded: false,
        lapses: const [],
      );

  SessionAnalysis a({
    AlignmentSummary? alignment,
    UnassignedMetrics? unassigned,
    TimingAnalysis? timing,
    bool tooWeak = false,
  }) =>
      SessionAnalysis(
        alignment: alignment,
        unassigned: unassigned,
        timing: timing,
        signalTooWeak: tooWeak,
        detectedHits: 30,
        expectedHits: 32,
      );

  List<String> heads(SessionAnalysis s, {bool analysisMode = true}) =>
      coreValues(s, analysisMode: analysisMode).map((c) => c.head).toList();

  group('hits', () {
    test('every note hit', () {
      final v =
          coreValues(a(alignment: al(), unassigned: u()), analysisMode: true);
      expect(v[0].head, 'You hit every note');
      expect(v[0].sub, '32 of 32 hit · 100 %');
    });
    test('missed notes, singular and plural', () {
      expect(heads(a(alignment: al(hit: 31, missed: 1), unassigned: u()))[0],
          'You miss 1 note');
      final v = coreValues(
          a(alignment: al(hit: 30, missed: 2), unassigned: u()),
          analysisMode: true);
      expect(v[0].head, 'You miss 2 notes');
      expect(v[0].sub, '30 of 32 hit · 94 %');
    });
    test('extra strokes without misses', () {
      final v = coreValues(a(alignment: al(extra: 3), unassigned: u()),
          analysisMode: true);
      expect(v[0].head, 'You add 3 extra strokes');
      expect(v[0].sub, '32 of 32 hit · 100 % · 3 extra');
      expect(heads(a(alignment: al(extra: 1), unassigned: u()))[0],
          'You add 1 extra stroke');
    });
    test('without alignment the played/expected counts decide', () {
      expect(heads(a(unassigned: u(played: 29, expected: 32)))[0],
          'You miss 3 notes');
      expect(heads(a(unassigned: u(played: 34, expected: 32)))[0],
          'You add 2 extra strokes');
      final v = coreValues(a(unassigned: u()), analysisMode: true);
      expect(v[0].head, 'You hit every note');
      expect(v[0].sub, '32 of 32 played');
    });
  });

  group('timing', () {
    test('thresholds at 5 and 15 ms, sign = rush/drag', () {
      expect(heads(a(unassigned: u(median: -5)))[1],
          "You're right on the click");
      expect(heads(a(unassigned: u(median: -5.4)))[1],
          "You're right on the click");
      expect(heads(a(unassigned: u(median: -6)))[1], 'You rush a little');
      expect(heads(a(unassigned: u(median: 15)))[1], 'You drag a little');
      expect(heads(a(unassigned: u(median: 16)))[1], 'You drag');
      expect(heads(a(unassigned: u(median: -30)))[1], 'You rush');
    });
    test('measurement line names direction and spread', () {
      final rush = coreValues(a(unassigned: u(median: -3.2, spread: 11.4)),
          analysisMode: true);
      expect(rush[1].sub, '3 ms ahead of the click · ±11 ms spread');
      final drag = coreValues(a(unassigned: u(median: 8, spread: 4)),
          analysisMode: true);
      expect(drag[1].sub, '8 ms behind the click · ±4 ms spread');
      final on = coreValues(a(unassigned: u(median: 0.3, spread: 5)),
          analysisMode: true);
      expect(on[1].sub, 'on the click · ±5 ms spread');
    });
  });

  group('hands and evenness', () {
    const even = TimingAnalysis(
        overallDeviationMs: 3,
        rightHandDeviationMs: 2,
        leftHandDeviationMs: 5,
        jitterMs: 9);
    const rightLate = TimingAnalysis(
        overallDeviationMs: 6,
        rightHandDeviationMs: 9,
        leftHandDeviationMs: 1,
        jitterMs: 12);
    const leftLate = TimingAnalysis(
        overallDeviationMs: 6,
        rightHandDeviationMs: 0,
        leftHandDeviationMs: 12,
        jitterMs: 12);

    test('analysis mode with hand values', () {
      final v =
          coreValues(a(unassigned: u(), timing: even), analysisMode: true);
      expect(v[2].head, 'Your hands are even');
      expect(v[2].sub, 'right +2 ms · left +5 ms · ±9 ms jitter');
      expect(heads(a(unassigned: u(), timing: rightLate))[2],
          'Your right hand is late');
      expect(heads(a(unassigned: u(), timing: leftLate))[2],
          'Your left hand is late');
    });
    test('learn mode never shows hands, even with values', () {
      final v = coreValues(a(unassigned: u(interval: 6), timing: even),
          analysisMode: false);
      expect(v[2].head, 'Your strokes are even');
      expect(v[2].sub, '±6 ms between strokes');
    });
    test('evenness thresholds at 10 and 20 ms', () {
      expect(heads(a(unassigned: u(interval: 10)))[2],
          'Your strokes are even');
      expect(heads(a(unassigned: u(interval: 14)))[2],
          'Your strokes are slightly uneven');
      expect(heads(a(unassigned: u(interval: 21)))[2],
          'Your strokes are uneven');
    });
  });

  group('edge cases', () {
    test('too weak signal yields nothing', () {
      expect(coreValues(a(unassigned: u(), tooWeak: true), analysisMode: true),
          isEmpty);
    });
    test('no unassigned metrics: only the hits line from alignment', () {
      final v = coreValues(a(alignment: al(hit: 30, missed: 2)),
          analysisMode: true);
      expect(v.length, 1);
      expect(v[0].head, 'You miss 2 notes');
    });
    test('nothing at all yields an empty list', () {
      expect(coreValues(a(), analysisMode: true), isEmpty);
    });
  });
}
