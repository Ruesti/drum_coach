import 'dart:math' as math;
import 'dart:typed_data';

/// One detected stroke, timestamped on the sample clock (ms since the first
/// sample fed in). [amplitude] is the peak RMS window energy of the attack.
class OnsetHit {
  final double timeMs;
  double amplitude;
  OnsetHit({required this.timeMs, required this.amplitude});
}

/// Pure stroke-onset detector over mono PCM16.
///
/// Timestamps are derived from the sample position, not the wall clock:
/// audio arrives in batched chunks, so processing time says nothing about
/// when a stroke actually happened — wall-clock stamping collapsed all
/// windows of a chunk onto one instant and let the double-trigger gap
/// swallow every hit but the first per chunk.
class OnsetDetector {
  OnsetDetector({this.sampleRate = 16000});

  final int sampleRate;

  /// 10 ms analysis windows.
  late final int _windowSamples = sampleRate ~/ 100;

  /// Refractory period between hits; 50 ms still allows 20 strokes/s.
  static const double _minGapMs = 50;

  /// Onset must exceed this multiple of the recent median energy…
  static const double _medianRatio = 2.5;

  /// …and rise against the previous window (attack edge).
  static const double _risingRatio = 1.4;

  /// Absolute floor so the noise floor alone can never trigger.
  static const double _minEnergy = 0.008;

  /// Ring of recent window energies for the median baseline. 15 windows
  /// (150 ms) span troughs between strokes even at 10+ hits/s, and a median
  /// is robust against the few loud attack windows in the ring.
  static const int _ringSize = 15;

  final List<OnsetHit> hits = [];

  final List<double> _ring = [];
  final List<int> _pending = [];
  double _prevEnergy = 0;
  int _windowsProcessed = 0;
  double _lastHitMs = double.negativeInfinity;

  void addSamples(Int16List samples) {
    for (final s in samples) {
      _pending.add(s);
      if (_pending.length == _windowSamples) {
        _processWindow();
        _pending.clear();
      }
    }
  }

  void _processWindow() {
    var sumSq = 0.0;
    for (final s in _pending) {
      final norm = s / 32768.0;
      sumSq += norm * norm;
    }
    final energy = math.sqrt(sumSq / _pending.length);
    final windowStartMs =
        _windowsProcessed * _windowSamples * 1000.0 / sampleRate;
    _windowsProcessed++;

    final baseline = _median(_ring);
    final warmedUp = _ring.length >= 3;
    _ring.add(energy);
    if (_ring.length > _ringSize) _ring.removeAt(0);

    final sinceHit = windowStartMs - _lastHitMs;
    if (sinceHit < 30 && hits.isNotEmpty && energy > hits.last.amplitude) {
      // Attack peak often lands one window after the trigger — keep the
      // louder value so dynamics (L/R levels) reflect the real stroke.
      hits.last.amplitude = energy;
    }

    if (warmedUp &&
        sinceHit >= _minGapMs &&
        energy > _minEnergy &&
        energy > baseline * _medianRatio &&
        energy > _prevEnergy * _risingRatio) {
      hits.add(OnsetHit(timeMs: windowStartMs, amplitude: energy));
      _lastHitMs = windowStartMs;
    }
    _prevEnergy = energy;
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.of(values)..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
