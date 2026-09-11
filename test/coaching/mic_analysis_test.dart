import 'package:drum_coach/features/coaching/services/mic_analysis_service.dart';
import 'package:drum_coach/features/coaching/services/onset_detector.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final anchor = DateTime.fromMicrosecondsSinceEpoch(1000000000);
  const rlrl = [
    StrokeBeat(hand: Hand.right),
    StrokeBeat(hand: Hand.left),
    StrokeBeat(hand: Hand.right),
    StrokeBeat(hand: Hand.left),
  ];

  List<BeatRecord> beatLogAt(List<double> ms) => [
        for (var i = 0; i < ms.length; i++)
          (
            beatIndex: i,
            timestamp:
                anchor.add(Duration(microseconds: (ms[i] * 1000).round())),
          ),
      ];

  List<OnsetHit> hitsAt(List<double> ms, {List<double>? amps}) => [
        for (var i = 0; i < ms.length; i++)
          OnsetHit(timeMs: ms[i], amplitude: amps?[i] ?? 0.5),
      ];

  group('MicAnalysisService.analyzeHits', () {
    test('clean run: hand values present and per-hand deviations correct', () {
      // 8 notes R L R L R L R L, 500 ms grid; right always 10 ms late,
      // left always 20 ms early.
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final onsets = [
        for (var i = 0; i < 8; i++) grid[i] + (i.isEven ? 10 : -20),
      ];
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt(onsets),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
        analysisMode: true,
      );
      expect(a.alignment, isNotNull);
      expect(a.alignment!.handValuesAllowed, isTrue);
      expect(a.timing, isNotNull);
      expect(a.timing!.rightHandDeviationMs, closeTo(10, 0.5));
      expect(a.timing!.leftHandDeviationMs, closeTo(-20, 0.5));
      expect(a.unassigned, isNotNull);
      expect(a.detectedHits, 8);
      expect(a.expectedHits, 8);
    });

    test('below the confidence gate: no hand values, unassigned still there',
        () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      // 5 of 8 strokes played with the misses *inside* the run (notes 1, 3
      // and 5 skipped) — 62.5% hit rate in the assessed window.
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt([grid[0], grid[2], grid[4], grid[6], grid[7]]),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
      );
      expect(a.alignment!.handValuesAllowed, isFalse);
      expect(a.timing, isNull);
      expect(a.dynamics, isNull);
      expect(a.unassigned, isNotNull);
      expect(a.unassigned!.playedCount, 5);
      expect(a.unassigned!.expectedCount, 8);
    });

    test('one omission in a long run: counted, hands stay correct after it',
        () {
      final grid = [for (var i = 0; i < 20; i++) i * 500.0];
      final onsets = [...grid]..removeAt(7); // one missed stroke = 95%
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt(onsets),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
        analysisMode: true,
      );
      expect(a.alignment!.missedCount, 1);
      expect(a.alignment!.extraCount, 0);
      expect(a.alignment!.handValuesAllowed, isTrue);
      // Right hand = even note indices, all played dead on time.
      expect(a.timing!.rightHandDeviationMs, closeTo(0, 0.5));
      expect(a.timing!.leftHandDeviationMs, closeTo(0, 0.5));
    });

    test('stored latency offset is applied to onsets before matching (§1.3)',
        () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final shifted = [for (final g in grid) g + 130]; // loopback latency
      final withOffset = MicAnalysisService.analyzeHits(
        hits: hitsAt(shifted),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
        latencyOffsetMs: 130,
        analysisMode: true,
      );
      expect(withOffset.timing!.overallDeviationMs, closeTo(0, 0.5));
      expect(withOffset.latencyOffsetAppliedMs, 130);

      // Without calibration the same run shows the offset openly in the
      // median instead of silently hiding it.
      final withoutOffset = MicAnalysisService.analyzeHits(
        hits: hitsAt(shifted),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
      );
      expect(withoutOffset.unassigned!.timingMedianMs, closeTo(130, 0.5));
    });

    test('peak levels are exposed chronologically for the §1.1 check', () {
      final grid = <double>[0, 500, 1000, 1500];
      final amps = <double>[0.9, 0.2, 0.85, 0.25];
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt(grid, amps: amps),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
      );
      expect(a.peakLevels, amps);
    });

    test('unplayed lead-in and tail notes are not counted as omissions', () {
      // 20 expected notes; the player joins at note 3 and stops after
      // note 16 (session kept clicking) — plus one real omission at note 9.
      final grid = [for (var i = 0; i < 20; i++) i * 500.0];
      final played = [
        for (var i = 3; i <= 16; i++)
          if (i != 9) grid[i],
      ];
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt(played),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
      );
      expect(a.alignment!.expectedCount, 14,
          reason: 'only notes 3..16 are assessed');
      expect(a.alignment!.missedCount, 1,
          reason: 'the mid-run omission stays an omission');
      expect(a.alignment!.extraCount, 0);
      expect(a.alignment!.handValuesAllowed, isTrue,
          reason: '13/14 = 93% within the assessed window');
      expect(a.unassigned!.expectedCount, 14);
    });

    test('deviations of assigned notes are exposed in note order', () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final onsets = [...grid]..[3] = grid[3] - 150; // one early stroke
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt(onsets),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
      );
      expect(a.deviationsMs.length, 8);
      expect(a.deviationsMs[3], closeTo(-150, 0.5));
      expect(a.deviationsMs[0], closeTo(0, 0.5));
    });

    test('emits one raw event per onset for the session log (Phase 2)', () {
      // 24 notes, all hit on time, plus one extra stroke between notes 4
      // and 5 — extra rate 1/24 < 5%, so the gate stays open and assigned
      // events carry hands. Stored latency offset 100 ms: event times must
      // stay RAW (nothing is subtracted from logged data).
      final grid = [for (var i = 0; i < 24; i++) i * 500.0];
      final shifted = [for (final g in grid) g + 100];
      final onsets = [...shifted, 2250.0 + 100]..sort();
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt(onsets),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
        latencyOffsetMs: 100,
        analysisMode: true,
      );
      expect(a.events.length, 25);

      final extra = a.events.where((e) => e.notePosition == null).toList();
      expect(extra.length, 1);
      expect(extra.single.hand, isNull);
      expect(extra.single.deviationMs, isNull);

      final assigned = a.events.where((e) => e.notePosition != null).toList();
      expect(assigned.length, 24);
      expect(assigned.first.notePosition, 0);
      expect(assigned.first.hand, 'R');
      expect(assigned[1].hand, 'L');
      expect(assigned.first.deviationMs, closeTo(0, 0.5));

      // Raw time: anchor epoch + 100 ms shift, latency NOT subtracted.
      final anchorMs = anchor.microsecondsSinceEpoch / 1000.0;
      expect(assigned.first.timeMs, closeTo(anchorMs + 100, 0.5));
      expect(assigned.first.peakLevel, closeTo(0.5, 0.001));
    });

    test('events carry no hands when the run is below the gate', () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt([grid[0], grid[2], grid[4], grid[6], grid[7]]),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
      );
      expect(a.events.length, 5);
      expect(a.events.every((e) => e.hand == null), isTrue,
          reason: 'below the gate no event gets a hand');
      expect(a.events.first.notePosition, 0,
          reason: 'assignment itself is still recorded');
    });

    test('learn mode never reports hand values, even on a clean run (P3)',
        () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt(grid),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
        analysisMode: false,
      );
      expect(a.alignment!.handValuesAllowed, isTrue,
          reason: 'the gate itself stays computed for the report');
      expect(a.timing, isNull, reason: 'learn mode: no hand values');
      expect(a.dynamics, isNull);
      expect(a.events.every((e) => e.hand == null), isTrue,
          reason: 'logged events carry no hands in learn mode');
      expect(a.unassigned, isNotNull);
    });

    test('analysis mode reports hand values above the gate (P3)', () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt(grid),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
        analysisMode: true,
      );
      expect(a.timing, isNotNull);
      expect(a.events.first.hand, 'R');
    });

    test('high timing jitter blocks hand values in analysis mode (P3)', () {
      // All 20 notes played, none missing — but wildly uneven: alternating
      // ±80 ms around the grid (std dev ≈ 80 ms, far above the 50 ms gate).
      final grid = [for (var i = 0; i < 20; i++) i * 500.0];
      final onsets = [
        for (var i = 0; i < 20; i++) grid[i] + (i.isEven ? 80 : -80),
      ];
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt(onsets),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
        analysisMode: true,
      );
      expect(a.alignment!.hitCount, 20, reason: 'nothing was missed');
      expect(a.alignment!.jitterLimitExceeded, isTrue);
      expect(a.timing, isNull,
          reason: 'sloppy-but-complete must not get hand values');
      expect(a.unassigned, isNotNull);
    });

    test('moderate jitter keeps the analysis gate open', () {
      final grid = [for (var i = 0; i < 20; i++) i * 500.0];
      final onsets = [
        for (var i = 0; i < 20; i++) grid[i] + (i.isEven ? 15 : -15),
      ];
      final a = MicAnalysisService.analyzeHits(
        hits: hitsAt(onsets),
        anchor: anchor,
        beatLog: beatLogAt(grid),
        sticking: rlrl,
        analysisMode: true,
      );
      expect(a.alignment!.jitterLimitExceeded, isFalse);
      expect(a.timing, isNotNull);
    });

    test('no anchor or no hits yields counts only', () {
      final a = MicAnalysisService.analyzeHits(
        hits: [],
        anchor: null,
        beatLog: beatLogAt([0, 500]),
        sticking: rlrl,
      );
      expect(a.timing, isNull);
      expect(a.unassigned, isNull);
      expect(a.detectedHits, 0);
      expect(a.expectedHits, 2);
    });
  });
}
