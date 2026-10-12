import 'package:drum_coach/data/local/session_log_codec.dart';
import 'package:drum_coach/data/local/session_log_service.dart';
import 'package:drum_coach/features/coaching/models/session_analysis.dart';
import 'package:drum_coach/features/coaching/services/mic_analysis_service.dart';
import 'package:drum_coach/features/coaching/services/recording_setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final started = DateTime.utc(2026, 9, 8, 19);

  List<BeatRecord> beatLog(List<double> ms) => [
        for (var i = 0; i < ms.length; i++)
          (
            beatIndex: i,
            timestamp: DateTime.fromMicrosecondsSinceEpoch(
                (ms[i] * 1000).round()),
          ),
      ];

  test('builds a complete session log from analysis and context', () {
    final analysis = SessionAnalysis(
      detectedHits: 2,
      expectedHits: 2,
      events: const [
        OnsetEventData(
            timeMs: 1069.5,
            peakLevel: 0.4,
            notePosition: 0,
            hand: 'R',
            deviationMs: 0.5),
        OnsetEventData(timeMs: 1420, peakLevel: 0.1),
      ],
      recordingSetup: const {
        'audioSource': 'voice_recognition',
        'sampleRate': 16000,
        'unprocessedSupported': false,
        'autoGain': false,
        'echoCancel': false,
        'noiseSuppress': false,
      },
      latencyOffsetAppliedMs: 69,
    );

    final log = buildSessionLog(
      analysis: analysis,
      beatLog: beatLog([1000, 1500]),
      exerciseId: 'single_stroke_roll',
      bpm: 74,
      durationSeconds: 17,
      rating: 2,
      startedAt: started,
      headphones: 'wired',
      device: const DeviceInfo(model: 'SM-S918B', androidVersion: '14'),
      latencyOffsetMs: 69,
    );

    expect(log.sessionUid,
        '${started.millisecondsSinceEpoch}-single_stroke_roll');
    expect(log.mode, 'learn');
    expect(log.audioSource, 'voice_recognition');
    expect(log.unprocessedSupported, false);
    expect(log.headphones, 'wired');
    expect(log.deviceModel, 'SM-S918B');
    expect(log.latencyOffsetMs, 69);
    expect(log.clickTimesMs, [1000, 1500]);
    expect(log.clickNoteIndices, [0, 1]);
    expect(log.events.length, 2);
    expect(log.events.first.hand, 'R');
    expect(log.events.first.timeMs, 1069.5);
    expect(log.events[1].notePosition, isNull);
  });

  test('logs a mic-less session with empty events and audioSource off', () {
    final log = buildSessionLog(
      analysis: null,
      beatLog: const [],
      exerciseId: 'single_stroke_roll',
      bpm: 90,
      durationSeconds: 60,
      rating: 3,
      startedAt: started,
      headphones: 'none',
      device: const DeviceInfo(model: 'SM-S918B', androidVersion: '14'),
      latencyOffsetMs: null,
    );
    expect(log.audioSource, 'off');
    expect(log.events, isEmpty);
    expect(log.clickTimesMs, isEmpty);
    expect(log.unprocessedSupported, isNull);
    expect(log.latencyOffsetMs, isNull);
    // Legacy / whole-sheet sessions carry no sheet position.
    expect(log.sheetLine, isNull);
    expect(log.sheetMode, isNull);
  });

  test('records the sheet line and mode (Blattform)', () {
    final log = buildSessionLog(
      analysis: null,
      beatLog: const [],
      exerciseId: 'single_paradiddle',
      bpm: 90,
      durationSeconds: 60,
      rating: 3,
      startedAt: started,
      headphones: 'none',
      device: const DeviceInfo(model: 'SM-S918B', androidVersion: '14'),
      latencyOffsetMs: null,
      sheetLine: 3,
      sheetMode: 'line',
    );
    expect(log.sheetLine, 3);
    expect(log.sheetMode, 'line');
    final jsonl = sessionLogToJsonl(log);
    expect(jsonl, contains('"sheetLine":3'));
    expect(jsonl, contains('"sheetMode":"line"'));
  });

  test('midi session: source, device, mapping and per-event instrument', () {
    final analysis = SessionAnalysis(
      detectedHits: 1,
      expectedHits: 1,
      events: const [
        OnsetEventData(
            timeMs: 1000,
            peakLevel: 0.8,
            notePosition: 0,
            instrument: 'snare',
            rawNote: 38),
        OnsetEventData(
            timeMs: 975,
            peakLevel: 0.3,
            instrument: 'snare',
            rawNote: 38,
            grace: true),
        OnsetEventData(
            timeMs: 1250, peakLevel: 0.9, instrument: 'kick', rawNote: 36),
      ],
      recordingSetup: const {'audioSource': 'midi', 'sampleRate': 0},
    );
    final log = buildSessionLog(
      analysis: analysis,
      beatLog: beatLog([1000]),
      exerciseId: 'single_stroke_roll',
      bpm: 100,
      durationSeconds: 30,
      rating: 2,
      startedAt: started,
      headphones: 'none',
      device: const DeviceInfo(model: 'laptop', androidVersion: 'linux'),
      latencyOffsetMs: 12,
      source: 'midi',
      midiDevice: 'Millenium MPS-850',
      kitMapping: '{"snare":[38]}',
    );
    expect(log.source, 'midi');
    expect(log.midiDevice, 'Millenium MPS-850');
    expect(log.kitMapping, '{"snare":[38]}');
    expect(log.audioSource, 'midi');
    expect(log.events[0].instrument, 'snare');
    expect(log.events[0].rawNote, 38);
    expect(log.events[0].grace, isFalse);
    expect(log.events[1].grace, isTrue);
    expect(log.events[2].instrument, 'kick');
  });

  test('default source is off and mic sessions say mic', () {
    final log = buildSessionLog(
      analysis: null,
      beatLog: const [],
      exerciseId: 'x',
      bpm: 100,
      durationSeconds: 1,
      rating: 1,
      startedAt: started,
      headphones: 'none',
      device: const DeviceInfo(model: 'm', androidVersion: 'v'),
      latencyOffsetMs: null,
    );
    expect(log.source, 'off');
    expect(log.midiDevice, isNull);
  });
}
