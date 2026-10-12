import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../lessons/models/rudiment.dart';
import '../midi/kit_instrument.dart';
import '../models/session_analysis.dart';
import 'onset_detector.dart';
import 'recording_setup.dart';
import 'sample_clock_map.dart';
import 'stroke_analysis.dart';
import 'stroke_source.dart';

typedef BeatRecord = ({int beatIndex, DateTime timestamp});

class MicAnalysisService {
  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription<Uint8List>? _audioSub;
  OnsetDetector _detector = OnsetDetector(sampleRate: _sampleRate);
  final List<int> _byteBuffer = [];

  /// The raw recording path used for the current run (§1.1); null until
  /// [startRecording] ran once.
  RecordingSetup? setup;

  /// Piecewise sample-clock → wall-clock mapping — see [SampleClockMap];
  /// a single global anchor let pipeline drift accumulate over the
  /// recording (§1.3 device test).
  SampleClockMap _clock = SampleClockMap(sampleRate: _sampleRate);

  static const int _sampleRate = RecordingSetup.sampleRate;

  /// P3 jitter gate: above this timing std dev the analysis mode withholds
  /// hand values and announces it (Auftraggeber-Entscheidung 11.09.).
  static const double jitterGateMs = 50;

  /// Minimum peak level an onset needs to count as a stroke: headphone
  /// click bleed measured ≤~0.14, real pad strokes ~0.8 (13.09. sessions).
  static const double minStrokeLevel = 0.18;

  /// Detected onsets on the wall clock (epoch ms), each mapped through its
  /// own chunk neighborhood — exposed for the latency calibration (§1.3).
  List<double> get absoluteOnsetMs => [
        for (final h in _detector.hits)
          _clock.timeAt(h.timeMs)!.microsecondsSinceEpoch / 1000.0,
      ];

  /// How far the sample clock fell behind the wall clock over this
  /// recording — §1.3 diagnostic.
  double? get clockDriftMs => _clock.driftMs;

  /// Detected strokes as [StrokeEvent]s on the shared time axis (epoch ms),
  /// instrument `pad`, rough peak level as velocity — the microphone's half
  /// of the StrokeSource contract (Brief Etappe 2, A.1).
  List<StrokeEvent> get strokeEvents {
    if (_clock.timeAt(0) == null) return const [];
    return [
      for (final h in _detector.hits)
        StrokeEvent(
          timeMs: _clock.timeAt(h.timeMs)!.microsecondsSinceEpoch / 1000.0,
          instrument: KitInstrument.pad,
          velocity: h.amplitude,
          rawNote: null,
          source: StrokeSourceKind.mic,
        ),
    ];
  }

  Future<bool> get hasPermission => _recorder.hasPermission();

  Future<void> startRecording() async {
    _detector = OnsetDetector(sampleRate: _sampleRate);
    _byteBuffer.clear();
    _clock = SampleClockMap(sampleRate: _sampleRate);

    // Re-chosen on every start: the headphone state can change between
    // sessions, and with a headset plugged the CAMCORDER source keeps the
    // recording on the built-in mics (A/B 13.09.; an explicit device pin is
    // NOT used — it collapsed the levels on the S23).
    setup = RecordingSetup.choose(
      unprocessedSupported: await AudioCapabilities.isUnprocessedSupported(),
      headphonesPlugged: (await AudioCapabilities.headphonesType()) != 'none',
    );
    final stream = await _recorder.startStream(setup!.config);

    _audioSub = stream.listen((chunk) {
      _clock.addChunk(arrivedAt: DateTime.now(), samples: chunk.length ~/ 2);
      _byteBuffer.addAll(chunk);
      final usable = _byteBuffer.length & ~1;
      if (usable == 0) return;
      final bytes = Uint8List.fromList(_byteBuffer.sublist(0, usable));
      _byteBuffer.removeRange(0, usable);
      final data = ByteData.sublistView(bytes);
      final samples = Int16List(usable ~/ 2);
      for (var i = 0; i < samples.length; i++) {
        samples[i] = data.getInt16(i * 2, Endian.little);
      }
      _detector.addSamples(samples);
    });
  }

  Future<void> stopRecording() async {
    await _audioSub?.cancel();
    _audioSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  /// Correlates detected hits with [beatLog] timestamps and [sticking] pattern.
  SessionAnalysis analyze({
    required List<BeatRecord> beatLog,
    required List<StrokeBeat> sticking,
    double latencyOffsetMs = 0,
    bool analysisMode = false,
  }) {
    // Rebase each hit through its chunk-local wall-clock mapping so pipeline
    // drift within the recording cannot skew late onsets (§1.3).
    final ref = _clock.timeAt(0);
    final corrected = ref == null
        ? const <OnsetHit>[]
        : [
            for (final h in _detector.hits)
              OnsetHit(
                timeMs: (_clock.timeAt(h.timeMs)!.microsecondsSinceEpoch -
                        ref.microsecondsSinceEpoch) /
                    1000.0,
                amplitude: h.amplitude,
              ),
          ];
    return analyzeHits(
      hits: corrected,
      anchor: ref,
      beatLog: beatLog,
      sticking: sticking,
      latencyOffsetMs: latencyOffsetMs,
      analysisMode: analysisMode,
      recordingSetup: setup?.describe(),
    );
  }

  /// Pure analysis core (§1.2/§1.4): aligns expected notes and onsets as two
  /// sequences (omissions, insertions and time deviation all carry cost),
  /// derives hands only from *assigned* notes, and reports per-hand values
  /// only above the confidence gate. Assignment-free measures are always
  /// computed. [latencyOffsetMs] (§1.3 calibration) is subtracted from onset
  /// times before matching; the remaining systematic offset stays visible in
  /// the unassigned median.
  /// [analysisMode] (Brief Phase 3): hand values are exclusive to the
  /// analysis mode — learn mode (default) reports only assignment-free
  /// measures, however clean the run. The gate itself stays computed so
  /// reports can show how close a run was.
  static SessionAnalysis analyzeHits({
    required List<OnsetHit> hits,
    required DateTime? anchor,
    required List<BeatRecord> beatLog,
    required List<StrokeBeat> sticking,
    double latencyOffsetMs = 0,
    bool analysisMode = false,
    Map<String, Object>? recordingSetup,
  }) {
    if (anchor == null) {
      return SessionAnalysis(
        detectedHits: hits.length,
        expectedHits: beatLog.length,
        recordingSetup: recordingSetup,
        source: StrokeSourceKind.mic,
      );
    }
    final anchorMs = anchor.microsecondsSinceEpoch / 1000.0;
    return analyzeStrokes(
      events: [
        for (final h in hits)
          StrokeEvent(
            timeMs: anchorMs + h.timeMs,
            instrument: KitInstrument.pad,
            velocity: h.amplitude,
            rawNote: null,
            source: StrokeSourceKind.mic,
          ),
      ],
      beatLog: beatLog,
      sticking: sticking,
      source: StrokeSourceKind.mic,
      expectedInstrument: KitInstrument.pad,
      latencyOffsetMs: latencyOffsetMs,
      analysisMode: analysisMode,
      recordingSetup: recordingSetup,
    );
  }

  void dispose() {
    _audioSub?.cancel();
    _recorder.dispose();
  }
}
