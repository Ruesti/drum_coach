import 'dart:math' as math;

/// Synthetic backing-loop sounds (Engine part 1). Pure Dart, deterministic —
/// no assets, no licences, identical on every call so tests and renders are
/// stable. Same style as the click/rim synthesis in `stroke_sounds.dart`.

/// Kick: a sine whose pitch glides from 150 Hz down to 48 Hz within the
/// first ~60 ms, decaying over ~180 ms, plus a 2 ms high "beater" click so
/// the thump stays audible on small phone speakers. Peak ≤ 0.9.
List<double> kickSamples({int sampleRate = 44100}) {
  final n = (sampleRate * 0.180).round();
  final out = List<double>.filled(n, 0.0);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final f = 48.0 + 102.0 * math.exp(-t / 0.020); // 150 Hz → 48 Hz
    phase += 2 * math.pi * f / sampleRate;
    final body = math.sin(phase) * math.exp(-12.0 * t);
    final beater =
        math.sin(2 * math.pi * 1800.0 * t) * math.exp(-t / 0.0007) * 0.35;
    out[i] = 0.85 * body + beater;
  }
  return out;
}

/// Hi-hat: white noise through a first-order high-pass (difference filter)
/// with an exponential decay. Closed: ~60 ms, peak 0.5. Accent ("slightly
/// open"): ~160 ms, slower decay, peak 0.65. The peak is normalised exactly.
List<double> hihatSamples({required bool accent, int sampleRate = 44100}) {
  final lengthSec = accent ? 0.160 : 0.060;
  final tau = accent ? 0.035 : 0.012;
  final peak = accent ? 0.65 : 0.5;
  final n = (sampleRate * lengthSec).round();
  final rng = _Lcg(accent ? 11 : 3);
  final out = List<double>.filled(n, 0.0);
  var prev = 0.0;
  var maxAbs = 0.0;
  for (var i = 0; i < n; i++) {
    final white = rng.next() * 2 - 1;
    final highPassed = white - prev;
    prev = white;
    final v = highPassed * math.exp(-(i / sampleRate) / tau);
    out[i] = v;
    if (v.abs() > maxAbs) maxAbs = v.abs();
  }
  if (maxAbs > 0) {
    final scale = peak / maxAbs;
    for (var i = 0; i < n; i++) {
      out[i] *= scale;
    }
  }
  return out;
}

/// Tiny linear congruential generator: deterministic noise without dart:math
/// Random's platform-dependent sequences.
class _Lcg {
  _Lcg(int seed) : _s = seed & 0x7fffffff;
  int _s;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }
}
