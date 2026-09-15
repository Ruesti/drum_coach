import 'package:drum_coach/features/coaching/models/session_analysis.dart';
import 'package:drum_coach/features/practice/analysis_announcement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AlignmentSummary summary({
    bool handValues = false,
    bool jitter = false,
    List<Lapse> lapses = const [],
  }) =>
      AlignmentSummary(
        expectedCount: 100,
        hitCount: 90,
        missedCount: 10,
        extraCount: 0,
        handValuesAllowed: handValues,
        jitterLimitExceeded: jitter,
        lapses: lapses,
      );

  const timing = TimingAnalysis(
    overallDeviationMs: 1,
    rightHandDeviationMs: 1,
    leftHandDeviationMs: 1,
    jitterMs: 10,
  );

  test('too-weak recording beats everything, in both modes', () {
    for (final mode in [true, false]) {
      final a = analysisAnnouncement(
        const SessionAnalysis(
            signalTooWeak: true, detectedHits: 0, expectedHits: 100),
        analysisMode: mode,
      );
      expect(a, isNotNull);
      expect(a!.positive, isFalse);
      expect(a.text, contains('too quiet'));
    }
  });

  test('lapses win over the global reasons and name the spot', () {
    final a = analysisAnnouncement(
      SessionAnalysis(
        alignment: summary(
            jitter: true,
            lapses: const [
              Lapse(startMs: 14000, endMs: 24000, hitRate: 0.4, jitterMs: 80),
              Lapse(startMs: 40000, endMs: 52000, hitRate: 0.2, jitterMs: 90),
            ]),
        detectedHits: 90,
        expectedHits: 100,
      ),
      analysisMode: true,
    );
    expect(a!.text, '2 breakdowns (first at 0:14) — not solid yet.');
    expect(a.positive, isFalse);
  });

  test('clean analysis run announces success positively', () {
    final a = analysisAnnouncement(
      SessionAnalysis(
        alignment: summary(handValues: true),
        timing: timing,
        detectedHits: 100,
        expectedHits: 100,
      ),
      analysisMode: true,
    );
    expect(a!.positive, isTrue);
    expect(a.text, contains('Clean run'));
  });

  test('learn mode without problems shows no banner', () {
    final a = analysisAnnouncement(
      SessionAnalysis(
        alignment: summary(handValues: true),
        detectedHits: 100,
        expectedHits: 100,
      ),
      analysisMode: false,
    );
    expect(a, isNull);
  });

  test('jitter and omission wordings stay distinct', () {
    final jitter = analysisAnnouncement(
      SessionAnalysis(
          alignment: summary(jitter: true),
          detectedHits: 90,
          expectedHits: 100),
      analysisMode: true,
    );
    final omissions = analysisAnnouncement(
      SessionAnalysis(
          alignment: summary(), detectedHits: 90, expectedHits: 100),
      analysisMode: true,
    );
    expect(jitter!.text, contains('unsteady'));
    expect(omissions!.text, contains('dropped notes'));
  });
}
