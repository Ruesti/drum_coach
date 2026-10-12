import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/mic_analysis_service.dart';
import 'package:drum_coach/features/coaching/services/onset_detector.dart';
import 'package:drum_coach/features/coaching/services/stroke_analysis.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const t0 = 1700000000000.0; // epoch ms
  const rlrl = [
    StrokeBeat(hand: Hand.right),
    StrokeBeat(hand: Hand.left),
    StrokeBeat(hand: Hand.right),
    StrokeBeat(hand: Hand.left),
  ];

  List<BeatRecord> beats(List<double> relMs) => [
        for (var i = 0; i < relMs.length; i++)
          (
            beatIndex: i,
            timestamp: DateTime.fromMicrosecondsSinceEpoch(
                ((t0 + relMs[i]) * 1000).round()),
          ),
      ];

  StrokeEvent midi(double relMs,
          {KitInstrument instrument = KitInstrument.snare,
          double velocity = 0.8,
          int rawNote = 38}) =>
      StrokeEvent(
        timeMs: t0 + relMs,
        instrument: instrument,
        velocity: velocity,
        rawNote: rawNote,
        source: StrokeSourceKind.midi,
      );

  group('splitGraceEvents', () {
    test('flam played: the earlier of two notes in the window is the grace',
        () {
      final r = splitGraceEvents(
        events: [midi(475), midi(500)],
        expectedMs: const [t0 + 500],
        hasGrace: const [true],
      );
      expect(r.grace.map((e) => e.timeMs), [t0 + 475]);
      expect(r.main.map((e) => e.timeMs), [t0 + 500]);
    });

    test('flam not played: the single note stays the main stroke', () {
      final r = splitGraceEvents(
        events: [midi(492)],
        expectedMs: const [t0 + 500],
        hasGrace: const [true],
      );
      expect(r.grace, isEmpty);
      expect(r.main.length, 1);
    });

    test('no grace expected: two close notes are both main (extra counts)',
        () {
      final r = splitGraceEvents(
        events: [midi(475), midi(500)],
        expectedMs: const [t0 + 500],
        hasGrace: const [false],
      );
      expect(r.grace, isEmpty);
      expect(r.main.length, 2);
    });

    test('neighbouring sixteenths at 200 BPM are not swallowed as graces',
        () {
      // 75 ms apart: outside the ±40 ms window of each other.
      final r = splitGraceEvents(
        events: [midi(425), midi(500)],
        expectedMs: const [t0 + 425, t0 + 500],
        hasGrace: const [true, true],
      );
      expect(r.grace, isEmpty);
      expect(r.main.length, 2);
    });
  });

  group('analyzeStrokes (midi)', () {
    test('clean snare run through MIDI: hand values, velocityExact, source',
        () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [for (final g in grid) midi(g + 5)],
        beatLog: beats(grid),
        sticking: rlrl,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
        analysisMode: true,
      );
      expect(a.source, StrokeSourceKind.midi);
      expect(a.velocityExact, isTrue);
      expect(a.alignment!.hitCount, 8);
      expect(a.timing!.overallDeviationMs, closeTo(5, 0.5));
      expect(a.events.every((e) => e.instrument == 'snare'), isTrue);
      expect(a.events.first.rawNote, 38);
      expect(a.accents, isNull);
    });

    test('accents computed for MIDI when the gate is open', () {
      const acc = [
        StrokeBeat(hand: Hand.right, isAccent: true),
        StrokeBeat(hand: Hand.left),
        StrokeBeat(hand: Hand.right),
        StrokeBeat(hand: Hand.left),
      ];
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [
          for (var i = 0; i < 8; i++)
            midi(grid[i], velocity: i % 4 == 0 ? 0.9 : 0.5),
        ],
        beatLog: beats(grid),
        sticking: acc,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
        analysisMode: true,
      );
      expect(a.accents, isNotNull);
      expect(a.accents!.accentCount, 2);
      expect(a.accents!.accentsLouder, 2);
    });

    test('off-instrument events are logged, not counted as extras', () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [
          for (final g in grid) midi(g),
          for (final g in grid)
            midi(g + 250, instrument: KitInstrument.kick, rawNote: 36),
        ],
        beatLog: beats(grid),
        sticking: rlrl,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
        analysisMode: true,
      );
      expect(a.alignment!.extraCount, 0);
      expect(a.alignment!.handValuesAllowed, isTrue);
      final kicks = a.events.where((e) => e.instrument == 'kick').toList();
      expect(kicks.length, 8);
      expect(kicks.every((e) => e.notePosition == null), isTrue);
      expect(a.detectedHits, 8);
    });

    test('flam notes become grace events, main strokes still hit', () {
      const flamSticking = [
        StrokeBeat(hand: Hand.right, graces: [Hand.left]),
        StrokeBeat(hand: Hand.left),
      ];
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final events = <StrokeEvent>[];
      for (var i = 0; i < 8; i++) {
        if (i.isEven) events.add(midi(grid[i] - 25, velocity: 0.3));
        events.add(midi(grid[i]));
      }
      final a = analyzeStrokes(
        events: events,
        beatLog: beats(grid),
        sticking: flamSticking,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
        analysisMode: true,
      );
      expect(a.alignment!.hitCount, 8);
      expect(a.alignment!.extraCount, 0);
      expect(a.events.where((e) => e.grace).length, 4);
      expect(a.detectedHits, 8);
    });

    test('no stroke-level filter for MIDI: quiet ghost notes still count', () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [for (final g in grid) midi(g, velocity: 0.05)],
        beatLog: beats(grid),
        sticking: rlrl,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
      );
      expect(a.signalTooWeak, isFalse);
      expect(a.alignment!.hitCount, 8);
    });

    test('mic source keeps the stroke-level filter', () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [
          for (final g in grid)
            StrokeEvent(
                timeMs: t0 + g,
                instrument: KitInstrument.pad,
                velocity: 0.05,
                rawNote: null,
                source: StrokeSourceKind.mic),
        ],
        beatLog: beats(grid),
        sticking: rlrl,
        source: StrokeSourceKind.mic,
      );
      expect(a.signalTooWeak, isTrue);
    });

    test('latency offset is subtracted for matching, raw times stay in log',
        () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [for (final g in grid) midi(g + 30)],
        beatLog: beats(grid),
        sticking: rlrl,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
        latencyOffsetMs: 30,
        analysisMode: true,
      );
      expect(a.timing!.overallDeviationMs, closeTo(0, 0.5));
      expect(a.events.first.timeMs, closeTo(t0 + 30, 0.001));
      expect(a.latencyOffsetAppliedMs, 30);
    });
  });

  test('strokes only off the pad-role instrument: flagged, logged, no '
      'verdict', () {
    final grid = [for (var i = 0; i < 8; i++) i * 500.0];
    final a = analyzeStrokes(
      events: [
        for (final g in grid)
          midi(g, instrument: KitInstrument.kick, rawNote: 36),
      ],
      beatLog: beats(grid),
      sticking: rlrl,
      source: StrokeSourceKind.midi,
      expectedInstrument: KitInstrument.snare,
      analysisMode: true,
    );
    expect(a.noStrokesOnInstrument, isTrue);
    expect(a.expectedInstrumentLabel, 'Snare');
    expect(a.timing, isNull);
    expect(a.alignment, isNull);
    expect(a.events.length, 8);
    expect(a.events.every((e) => e.instrument == 'kick'), isTrue);
    expect(a.events.every((e) => e.notePosition == null), isTrue);
  });

  test('strokes on the instrument: not flagged', () {
    final grid = [for (var i = 0; i < 8; i++) i * 500.0];
    final a = analyzeStrokes(
      events: [for (final g in grid) midi(g)],
      beatLog: beats(grid),
      sticking: rlrl,
      source: StrokeSourceKind.midi,
      expectedInstrument: KitInstrument.snare,
    );
    expect(a.noStrokesOnInstrument, isFalse);
  });

  test('analyzeHits still delegates with identical results (mic path)', () {
    final anchor = DateTime.fromMicrosecondsSinceEpoch((t0 * 1000).round());
    final grid = [for (var i = 0; i < 8; i++) i * 500.0];
    final a = MicAnalysisService.analyzeHits(
      hits: [for (final g in grid) OnsetHit(timeMs: g + 10, amplitude: 0.5)],
      anchor: anchor,
      beatLog: beats(grid),
      sticking: rlrl,
      analysisMode: true,
    );
    expect(a.source, StrokeSourceKind.mic);
    expect(a.velocityExact, isFalse);
    expect(a.timing!.overallDeviationMs, closeTo(10, 0.5));
    expect(a.events.first.instrument, 'pad');
  });
}
