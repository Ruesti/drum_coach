import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../lessons/models/rudiment.dart';
import '../models/session_analysis.dart';
import 'onset_detector.dart';

typedef BeatRecord = ({int beatIndex, DateTime timestamp});

class MicAnalysisService {
  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription<Uint8List>? _audioSub;
  OnsetDetector _detector = OnsetDetector(sampleRate: _sampleRate);
  final List<int> _byteBuffer = [];

  /// Wall-clock instant of sample 0, estimated from the first chunk's
  /// arrival minus its own duration. Hit timestamps are anchor + sample
  /// time — wall-clock stamping per processing window is wrong, because
  /// audio arrives in batched chunks.
  DateTime? _sampleClockAnchor;

  static const int _sampleRate = 16000;

  Future<bool> get hasPermission => _recorder.hasPermission();

  Future<void> startRecording() async {
    _detector = OnsetDetector(sampleRate: _sampleRate);
    _byteBuffer.clear();
    _sampleClockAnchor = null;

    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: _sampleRate,
      numChannels: 1,
    ));

    _audioSub = stream.listen((chunk) {
      _sampleClockAnchor ??= DateTime.now().subtract(Duration(
          microseconds: (chunk.length ~/ 2) * 1000000 ~/ _sampleRate));
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
    required int bpm,
  }) {
    final anchor = _sampleClockAnchor;
    final hits = _detector.hits;
    if (hits.isEmpty || anchor == null || beatLog.isEmpty || sticking.isEmpty) {
      return SessionAnalysis(
        detectedHits: hits.length,
        expectedHits: beatLog.length,
      );
    }

    // Both lists are chronological — walk them with two pointers and match
    // each hit to its temporally nearest expected beat (within ±250 ms).
    final matched = <MatchedHit>[];
    var j = 0;
    for (final hit in hits) {
      final ts = anchor.add(Duration(microseconds: (hit.timeMs * 1000).round()));
      while (j + 1 < beatLog.length &&
          (beatLog[j + 1].timestamp.difference(ts)).abs() <=
              (beatLog[j].timestamp.difference(ts)).abs()) {
        j++;
      }
      final nearest = beatLog[j];
      final devMs = ts.difference(nearest.timestamp).inMilliseconds.toDouble();
      if (devMs.abs() >= 250) continue;
      final patternPos = nearest.beatIndex % sticking.length;
      matched.add(MatchedHit(
        hitTimestamp: ts,
        amplitude: hit.amplitude,
        deviationMs: devMs,
        hand: sticking[patternPos].hand,
      ));
    }

    if (matched.length < 4) {
      return SessionAnalysis(
        detectedHits: hits.length,
        expectedHits: beatLog.length,
      );
    }

    return SessionAnalysis(
      timing: _calcTiming(matched),
      dynamics: _calcDynamics(matched),
      detectedHits: hits.length,
      expectedHits: beatLog.length,
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
