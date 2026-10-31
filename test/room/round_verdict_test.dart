import 'package:drum_coach/features/coaching/models/session_analysis.dart';
import 'package:drum_coach/features/room/round_verdict.dart';
import 'package:flutter_test/flutter_test.dart';

SessionAnalysis fx({
  int expected = 100,
  int hits = 100,
  int extra = 0,
  double median = 0,
  double spread = 5,
  bool weak = false,
  bool notMeasurable = false,
  int detected = 100,
  bool withAlignment = true,
  bool withUnassigned = true,
}) =>
    SessionAnalysis(
      detectedHits: detected,
      expectedHits: expected,
      signalTooWeak: weak,
      notMeasurable: notMeasurable,
      alignment: withAlignment
          ? AlignmentSummary(
              expectedCount: expected,
              hitCount: hits,
              missedCount: expected - hits,
              extraCount: extra,
              handValuesAllowed: true,
            )
          : null,
      unassigned: withUnassigned
          ? UnassignedMetrics(
              timingMedianMs: median,
              timingSpreadMs: spread,
              intervalSpreadMs: 0,
              dynamicsSpread: null,
              playedCount: detected,
              expectedCount: expected,
            )
          : null,
    );

void main() {
  test('clean at 0.95 hit rate and 15 ms', () {
    expect(verdictOf(fx(hits: 95, extra: 5, median: -15, spread: 20)),
        RoundVerdict.clean);
  });
  test('close just outside the clean edges', () {
    expect(verdictOf(fx(hits: 94)), RoundVerdict.close);
    expect(verdictOf(fx(extra: 6)), RoundVerdict.close);
    expect(verdictOf(fx(median: 15.1)), RoundVerdict.close);
    expect(verdictOf(fx(spread: 20.1)), RoundVerdict.close);
  });
  test('close when signal too weak', () {
    expect(verdictOf(fx(weak: true)), RoundVerdict.close);
  });
  test('close when too few hits detected', () {
    expect(verdictOf(fx(detected: 3)), RoundVerdict.close);
  });
  test('null when not measurable or no analysis', () {
    expect(verdictOf(fx(notMeasurable: true)), isNull);
    expect(verdictOf(null), isNull);
  });
  test('off below 0.80 hit rate', () {
    expect(verdictOf(fx(hits: 79)), RoundVerdict.off);
    expect(verdictOf(fx(hits: 80)), RoundVerdict.close);
  });
  test('off when spread above 40 ms', () {
    expect(verdictOf(fx(spread: 40.1)), RoundVerdict.off);
    expect(verdictOf(fx(spread: 40)), RoundVerdict.close);
  });
  test('missing alignment or unassigned counts as not enough data: close', () {
    expect(verdictOf(fx(withAlignment: false)), RoundVerdict.close);
    expect(verdictOf(fx(withUnassigned: false)), RoundVerdict.close);
  });
  test('rating maps 3/2/1', () {
    expect(verdictOfRating(3), RoundVerdict.clean);
    expect(verdictOfRating(2), RoundVerdict.close);
    expect(verdictOfRating(1), RoundVerdict.off);
  });
}
