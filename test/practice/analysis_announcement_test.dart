import 'package:drum_coach/features/coaching/models/session_analysis.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
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

  test('not measurable beats every other verdict', () {
    final a = analysisAnnouncement(
      const SessionAnalysis(
          detectedHits: 0, expectedHits: 8, notMeasurable: true),
      analysisMode: true,
    )!;
    expect(a.positive, isFalse);
    expect(a.text, contains('not measurable'));
  });

  test('a microphone that failed to start is not called a lost MIDI device',
      () {
    final a = analysisAnnouncement(
      const SessionAnalysis(
          detectedHits: 0,
          expectedHits: 8,
          notMeasurable: true,
          source: StrokeSourceKind.mic),
      analysisMode: true,
    )!;
    expect(a.text, 'Measurement failed — microphone could not start.');
    expect(a.text, isNot(contains('MIDI')));
  });

  test('priority: notMeasurable > noStrokesOnInstrument > latencyUncalibrated '
      '> signalTooWeak > verdicts', () {
    String text(SessionAnalysis a) =>
        analysisAnnouncement(a, analysisMode: true)!.text;
    expect(
        text(const SessionAnalysis(
            detectedHits: 0,
            expectedHits: 8,
            notMeasurable: true,
            noStrokesOnInstrument: true,
            latencyUncalibrated: true,
            signalTooWeak: true,
            source: StrokeSourceKind.midi)),
        contains('not measurable'));
    expect(
        text(const SessionAnalysis(
            detectedHits: 0,
            expectedHits: 8,
            noStrokesOnInstrument: true,
            expectedInstrumentLabel: 'Snare',
            latencyUncalibrated: true,
            signalTooWeak: true)),
        'No strokes on Snare — check kit mapping or pad role in Settings.');
    expect(
        text(const SessionAnalysis(
            detectedHits: 0,
            expectedHits: 8,
            latencyUncalibrated: true,
            signalTooWeak: true)),
        'MIDI latency not calibrated — timing may read late. Calibrate in '
        'Settings.');
    // The warning outranks even a clean verdict — numbers still show.
    final clean = analysisAnnouncement(
      SessionAnalysis(
          detectedHits: 100,
          expectedHits: 100,
          alignment: summary(handValues: true),
          timing: timing,
          latencyUncalibrated: true),
      analysisMode: true,
    )!;
    expect(clean.positive, isFalse);
    expect(clean.text, contains('not calibrated'));
    // Learn mode warns too.
    expect(
        analysisAnnouncement(
                const SessionAnalysis(
                    detectedHits: 8,
                    expectedHits: 8,
                    latencyUncalibrated: true),
                analysisMode: false)!
            .text,
        contains('not calibrated'));
  });

  test('withLatencyUncalibrated keeps every other field', () {
    final a = SessionAnalysis(
            detectedHits: 9,
            expectedHits: 10,
            timing: timing,
            source: StrokeSourceKind.midi,
            velocityExact: true)
        .withLatencyUncalibrated();
    expect(a.latencyUncalibrated, isTrue);
    expect(a.detectedHits, 9);
    expect(a.timing, same(timing));
    expect(a.velocityExact, isTrue);
  });
}
