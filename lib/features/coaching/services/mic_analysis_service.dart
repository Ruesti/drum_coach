import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../lessons/models/rudiment.dart';
import '../models/session_analysis.dart';

typedef BeatRecord = ({int beatIndex, DateTime timestamp});

class MicAnalysisService {
  final AudioRecorder _recorder = AudioRecorder();

  final List<_HitCandidate> _hits = [];
  StreamSubscription<Uint8List>? _audioSub;

  double _baseline = 0.02;
  DateTime? _lastHitTime;

  static const int _sampleRate = 16000;
  static const int _windowSamples = 160;        // 10 ms at 16 kHz
  static const double _onsetThreshold = 3.0;    // energy / baseline ratio
  static const int _minGapMs = 100;             // prevent double-trigger

  Future<bool> get hasPermission => _recorder.hasPermission();

  Future<void> startRecording() async {
    _hits.clear();
    _baseline = 0.02;
    _lastHitTime = null;

    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: _sampleRate,
      numChannels: 1,
    ));

    var buffer = <int>[];

    _audioSub = stream.listen((chunk) {
      buffer.addAll(chunk);
      while (buffer.length >= _windowSamples * 2) {
        final window = Uint8List.fromList(buffer.sublist(0, _windowSamples * 2));
        buffer = buffer.sublist(_windowSamples * 2);
        _processWindow(window);
      }
    });
  }

  void _processWindow(Uint8List bytes) {
    double sumSq = 0;
    final samples = bytes.buffer.asInt16List(bytes.offsetInBytes, bytes.lengthInBytes ~/ 2);
    for (final s in samples) {
      final norm = s / 32768.0;
      sumSq += norm * norm;
    }
    final energy = math.sqrt(sumSq / samples.length);

    // Slow baseline tracking; excludes onset windows
    _baseline = _baseline * 0.996 + energy * 0.004;

    final now = DateTime.now();
    final gapOk = _lastHitTime == null ||
        now.difference(_lastHitTime!).inMilliseconds >= _minGapMs;

    if (gapOk &&
        energy > _baseline * _onsetThreshold &&
        energy > 0.008) {
      _hits.add(_HitCandidate(timestamp: now, amplitude: energy));
      _lastHitTime = now;
      // Raise baseline temporarily so the tail of the hit doesn't re-trigger
      _baseline = math.max(_baseline, energy * 0.4);
    }
  }

  Future<void> stopRecording() async {
    await _audioSub?.cancel();
    _audioSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  /// Correlates recorded hits with [beatLog] timestamps and [sticking] pattern.
  SessionAnalysis analyze({
    required List<BeatRecord> beatLog,
    required List<StrokeBeat> sticking,
    required int bpm,
  }) {
    if (_hits.isEmpty || beatLog.isEmpty || sticking.isEmpty) {
      return SessionAnalysis(
        detectedHits: _hits.length,
        expectedHits: beatLog.length,
      );
    }

    // Match each hit to the temporally nearest expected beat (within ±250 ms).
    final matched = <MatchedHit>[];
    for (final hit in _hits) {
      double minDist = 250;
      BeatRecord? nearest;

      for (final beat in beatLog) {
        final distMs =
            hit.timestamp.difference(beat.timestamp).inMilliseconds.toDouble();
        if (distMs.abs() < minDist) {
          minDist = distMs.abs();
          nearest = beat;
        }
      }

      if (nearest != null) {
        final patternPos = nearest.beatIndex % sticking.length;
        final hand = sticking[patternPos].hand;
        final devMs = hit.timestamp
            .difference(nearest.timestamp)
            .inMilliseconds
            .toDouble();
        matched.add(MatchedHit(
          hitTimestamp: hit.timestamp,
          amplitude: hit.amplitude,
          deviationMs: devMs,
          hand: hand,
        ));
      }
    }

    if (matched.length < 4) {
      return SessionAnalysis(
        detectedHits: _hits.length,
        expectedHits: beatLog.length,
      );
    }

    final timing = _calcTiming(matched);
    final dynamics = _calcDynamics(matched);

    return SessionAnalysis(
      timing: timing,
      dynamics: dynamics,
      detectedHits: _hits.length,
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

class _HitCandidate {
  final DateTime timestamp;
  final double amplitude;
  _HitCandidate({required this.timestamp, required this.amplitude});
}
