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
