import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../lessons/models/rudiment.dart';
import '../models/session_analysis.dart';
import 'onset_detector.dart';
import 'recording_setup.dart';
import 'sample_clock_map.dart';
import 'sequence_aligner.dart';
import 'unassigned_metrics.dart';

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

  /// Detected onsets on the wall clock (epoch ms), each mapped through its
  /// own chunk neighborhood — exposed for the latency calibration (§1.3).
  List<double> get absoluteOnsetMs => [
        for (final h in _detector.hits)
          _clock.timeAt(h.timeMs)!.microsecondsSinceEpoch / 1000.0,
      ];

  /// How far the sample clock fell behind the wall clock over this
  /// recording — §1.3 diagnostic.
  double? get clockDriftMs => _clock.driftMs;

  Future<bool> get hasPermission => _recorder.hasPermission();

  Future<void> startRecording() async {
    _detector = OnsetDetector(sampleRate: _sampleRate);
    _byteBuffer.clear();
    _clock = SampleClockMap(sampleRate: _sampleRate);

    setup ??= RecordingSetup.choose(
        unprocessedSupported: await AudioCapabilities.isUnprocessedSupported());
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
  static SessionAnalysis analyzeHits({
    required List<OnsetHit> hits,
    required DateTime? anchor,
    required List<BeatRecord> beatLog,
    required List<StrokeBeat> sticking,
    double latencyOffsetMs = 0,
    Map<String, Object>? recordingSetup,
  }) {
    if (hits.isEmpty || anchor == null || beatLog.isEmpty || sticking.isEmpty) {
      return SessionAnalysis(
        detectedHits: hits.length,
        expectedHits: beatLog.length,
        recordingSetup: recordingSetup,
      );
    }

    final anchorMs = anchor.microsecondsSinceEpoch / 1000.0;
    final expectedMs = [
      for (final b in beatLog) b.timestamp.microsecondsSinceEpoch / 1000.0,
    ];
    final onsetMs = [
      for (final h in hits) anchorMs + h.timeMs - latencyOffsetMs,
    ];
    final amplitudes = [for (final h in hits) h.amplitude];

    final aligned = alignSequences(expectedMs: expectedMs, onsetMs: onsetMs);
    final summary = AlignmentSummary(
      expectedCount: aligned.notes.length,
      hitCount: aligned.hitCount,
      missedCount: aligned.missedCount,
      extraCount: aligned.extraCount,
      handValuesAllowed: aligned.handValuesAllowed,
    );

    final unassigned = computeUnassignedMetrics(
      clickMs: expectedMs,
      onsetMs: onsetMs,
      amplitudes: amplitudes,
    );

    // Hands come exclusively from the sticking of *assigned* notes; unmatched
    // onsets get no hand (§1.2).
    final matched = <MatchedHit>[];
    for (var i = 0; i < aligned.notes.length; i++) {
      final note = aligned.notes[i];
      if (!note.hit) continue;
      final patternPos = beatLog[i].beatIndex % sticking.length;
      matched.add(MatchedHit(
        hitTimestamp: DateTime.fromMicrosecondsSinceEpoch(
            (onsetMs[note.onsetIndex!] * 1000).round()),
        amplitude: amplitudes[note.onsetIndex!],
        deviationMs: note.deviationMs!,
        hand: sticking[patternPos].hand,
      ));
    }

    final gateOpen = summary.handValuesAllowed && matched.length >= 4;
    return SessionAnalysis(
      timing: gateOpen ? _calcTiming(matched) : null,
      dynamics: gateOpen ? _calcDynamics(matched) : null,
      unassigned: unassigned,
      alignment: summary,
      peakLevels: amplitudes,
      latencyOffsetAppliedMs: latencyOffsetMs,
      detectedHits: hits.length,
      expectedHits: beatLog.length,
      recordingSetup: recordingSetup,
    );
  }

  static TimingAnalysis _calcTiming(List<MatchedHit> hits) {
    List<double> devs(Hand h) =>
        hits.where((m) => m.hand == h).map((m) => m.deviationMs).toList();

    final all = hits.map((m) => m.deviationMs).toList();
    final right = devs(Hand.right);
    final left = devs(Hand.left);

    final avgAll = _mean(all);
    return TimingAnalysis(
      overallDeviationMs: avgAll,
      rightHandDeviationMs: right.isEmpty ? 0 : _mean(right),
      leftHandDeviationMs: left.isEmpty ? 0 : _mean(left),
      jitterMs: _stdDev(all, avgAll),
    );
  }

  static DynamicsAnalysis _calcDynamics(List<MatchedHit> hits) {
    List<double> amps(Hand h) =>
        hits.where((m) => m.hand == h).map((m) => m.amplitude).toList();

    final right = amps(Hand.right);
    final left = amps(Hand.left);
    return DynamicsAnalysis(
      rightHandLevel: right.isEmpty ? 0 : _mean(right),
      leftHandLevel: left.isEmpty ? 0 : _mean(left),
    );
  }

  static double _mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

  static double _stdDev(List<double> v, double mean) {
    final variance =
        v.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
            v.length;
    return math.sqrt(variance);
  }

  void dispose() {
    _audioSub?.cancel();
    _recorder.dispose();
  }
}
