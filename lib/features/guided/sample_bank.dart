import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_soloud/flutter_soloud.dart';

import '../metronome/backing_sounds.dart';
import '../metronome/metronome_engine.dart';
import 'run_plan.dart';

/// Synthetic crash: 1.2 s of high-passed noise with an exponential decay,
/// peak exactly 0.9. Used whenever the recorded crash cannot be decoded —
/// the start/end of an exercise is never silent.
List<double> crashFallbackSamples({int sampleRate = 44100}) {
  final n = (sampleRate * 1.2).round();
  var seed = 29;
  double next() {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  }

  final out = List<double>.filled(n, 0.0);
  var prev = 0.0;
  var maxAbs = 0.0;
  for (var i = 0; i < n; i++) {
    final white = next() * 2 - 1;
    final v = (white - prev) * math.exp(-(i / sampleRate) / 0.25);
    prev = white;
    out[i] = v;
    if (v.abs() > maxAbs) maxAbs = v.abs();
  }
  if (maxAbs > 0) {
    final scale = 0.9 / maxAbs;
    for (var i = 0; i < n; i++) {
      out[i] *= scale;
    }
  }
  return out;
}

/// The one place that holds every sound the guided player needs, as PCM.
/// Snare and crash are recordings decoded once ([load]); kick, hi-hat and
/// click are synthetic. A missing or undecodable recording falls back to a
/// synthetic sound — never silence.
class SampleBank {
  SampleBank({List<double> snare = const [], List<double> crash = const []})
      : _pattern = snare.isNotEmpty
            ? snare
            : MetronomeEngine.synthSamples(SoundType.click, accent: true),
        _crash = crash.isNotEmpty ? crash : crashFallbackSamples();

  final List<double> _pattern;
  final List<double> _crash;
  static final List<double> _kick = kickSamples();
  static final List<double> _hihatLoud = hihatSamples(accent: true);
  static final List<double> _hihatSoft = hihatSamples(accent: false);
  static final List<double> _click = MetronomeEngine.pulseSamples();

  /// Decodes the recordings (rootBundle → SoLoud). Every step is
  /// timeout-guarded and failures fall back; host tests (no FFI) get the
  /// synthetic sounds.
  static Future<SampleBank> load() async {
    final snare = await _decode('assets/audio/snare.mp3');
    final crash = await _decode('assets/audio/crash.mp3');
    return SampleBank(snare: snare, crash: crash);
  }

  static Future<List<double>> _decode(String asset) async {
    try {
      final bytes = (await rootBundle.load(asset)).buffer.asUint8List();
      final source = await SoLoud.instance
          .loadMem('${asset}_len_probe', bytes)
          .timeout(const Duration(seconds: 5));
      final length = SoLoud.instance.getLength(source);
      unawaited(SoLoud.instance.disposeSource(source));
      final count = (length.inMicroseconds * 44100 / 1000000).round();
      if (count <= 0) return const [];
      final floats = await SoLoud.instance
          // ignore: experimental_member_use
          .readSamplesFromMem(bytes, count)
          .timeout(const Duration(seconds: 5));
      return List<double>.from(floats);
    } catch (_) {
      return const [];
    }
  }

  List<double> of(RunSound s) => switch (s) {
        RunSound.pattern => _pattern,
        RunSound.kick => _kick,
        RunSound.hihatLoud => _hihatLoud,
        RunSound.hihatSoft => _hihatSoft,
        RunSound.click => _click,
        RunSound.crash => _crash,
      };

  /// The map [GuidedPlayer] takes as `sounds`.
  Map<RunSound, List<double>> toSoundMap() =>
      {for (final s in RunSound.values) s: of(s)};
}
