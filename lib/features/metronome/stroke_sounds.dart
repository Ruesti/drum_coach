import 'dart:math' as math;

/// The exercise sounds as pure functions (no Flutter, no SoLoud) — shared by
/// the engine, the loop renderer tests and the backing-demo tool.

/// Click: 30 ms decaying sine, 1200 Hz accent / 800 Hz normal.
List<double> clickSamples({required bool accent, int sampleRate = 44100}) {
  final amplitude = accent ? 0.95 : 0.55;
  final frequency = accent ? 1200.0 : 800.0;
  final n = (sampleRate * 0.030).round();
  return [
    for (var i = 0; i < n; i++)
      amplitude *
          math.exp(-140.0 * (i / sampleRate)) *
          math.sin(2 * math.pi * frequency * (i / sampleRate)),
  ];
}

/// Rim: 100 ms, three damped partials (shell, rim, snap).
List<double> rimSamples({required bool accent, int sampleRate = 44100}) {
  final amplitude = accent ? 0.95 : 0.55;
  final n = (sampleRate * 0.10).round();
  return [for (var i = 0; i < n; i++) _rimSample(i / sampleRate, amplitude)];
}

/// The click track's own voice: a short, high, dry tick — clearly apart
/// from the exercise sounds so the ear can tell the pulse from the pattern.
List<double> pulseSamples({int sampleRate = 44100}) {
  final n = (sampleRate * 0.012).round();
  return [
    for (var i = 0; i < n; i++)
      0.45 *
          math.exp(-350.0 * (i / sampleRate)) *
          math.sin(2 * math.pi * 2600.0 * (i / sampleRate)),
  ];
}

double _rimSample(double t, double amplitude) {
  final shell = math.sin(2 * math.pi * 280 * t) * math.exp(-55.0 * t) * 0.45;
  final rim = math.sin(2 * math.pi * 680 * t) * math.exp(-130.0 * t) * 0.60;
  final snap = math.sin(2 * math.pi * 2100 * t) * math.exp(-600.0 * t) * 0.35;
  return amplitude * (shell + rim + snap);
}
