import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../metronome/backing_sounds.dart';
import '../metronome/metronome_engine.dart';
import 'run_plan.dart';
import 'voice_assets.dart';

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
/// Every kit instrument is a recording ([assets], decoded once in [load]);
/// the click is synthetic. A missing or undecodable recording falls back to
/// the closest real instrument ([_closest] — never the snare for a cymbal),
/// and only when none is there to a synthetic sound — never silence.
class SampleBank {
  SampleBank({Map<RunSound, List<double>> recordings = const {}}) {
    for (final s in RunSound.values) {
      _sounds[s] = _resolve(s, recordings);
    }
  }

  /// The recording of each sound. [RunSound.pattern] (pad lines) is the pad
  /// snare the practice engine plays too; the kit has its own snare. No
  /// rim, hi-hat pedal or ride bell recording: those use [_closest].
  static const assets = <RunSound, String>{
    RunSound.pattern: 'assets/audio/snare.wav',
    RunSound.kick: 'assets/audio/kick.wav',
    RunSound.snare: 'assets/audio/kit_snare.wav',
    RunSound.snareGhost: 'assets/audio/snare_ghost.wav',
    RunSound.hihatClosed: 'assets/audio/hihat_closed.wav',
    RunSound.hihatOpen: 'assets/audio/hihat_open.wav',
    RunSound.tomHigh: 'assets/audio/tom_high.wav',
    RunSound.tomLow: 'assets/audio/tom_low.wav',
    RunSound.tomFloor: 'assets/audio/tom_floor.wav',
    RunSound.crash: 'assets/audio/crash.wav',
    RunSound.ride: 'assets/audio/ride.wav',
  };

  /// Closest real instruments, in order, for a sound without a recording.
  static const _closest = <RunSound, List<RunSound>>{
    RunSound.snare: [RunSound.pattern],
    RunSound.snareGhost: [RunSound.snare, RunSound.pattern],
    RunSound.rim: [RunSound.snare, RunSound.pattern],
    RunSound.pattern: [RunSound.snare],
    RunSound.hihatPedal: [RunSound.hihatClosed],
    RunSound.hihatOpen: [RunSound.hihatClosed],
    RunSound.hihatClosed: [RunSound.hihatPedal],
    RunSound.tomHigh: [RunSound.tomLow, RunSound.tomFloor],
    RunSound.tomLow: [RunSound.tomHigh, RunSound.tomFloor],
    RunSound.tomFloor: [RunSound.tomLow, RunSound.tomHigh],
    RunSound.crash: [RunSound.ride],
    RunSound.ride: [RunSound.crash],
    RunSound.rideBell: [RunSound.ride, RunSound.crash],
  };

  /// Breadth-first through [_closest]: the nearest instrument that has a
  /// recording, else the synthetic sound of [s].
  static List<double> _resolve(RunSound s, Map<RunSound, List<double>> rec) {
    final queue = [s];
    final seen = {s};
    for (var k = 0; k < queue.length; k++) {
      final r = rec[queue[k]];
      if (r != null && r.isNotEmpty) return r;
      for (final c in _closest[queue[k]] ?? const <RunSound>[]) {
        if (seen.add(c)) queue.add(c);
      }
    }
    return _synthetic(s);
  }

  static List<double> _synthetic(RunSound s) => switch (s) {
        RunSound.kick => _kick,
        RunSound.hihatClosed || RunSound.hihatPedal => _hihatSoft,
        RunSound.hihatOpen => _hihatLoud,
        RunSound.crash || RunSound.ride || RunSound.rideBell => _crash,
        RunSound.click => _click,
        _ => _synthSnare,
      };

  final _sounds = <RunSound, List<double>>{};
  static final List<double> _kick = kickSamples();
  static final List<double> _hihatLoud = hihatSamples(accent: true);
  static final List<double> _hihatSoft = hihatSamples(accent: false);
  static final List<double> _click = MetronomeEngine.pulseSamples();
  static final List<double> _crash = crashFallbackSamples();
  static final List<double> _synthSnare =
      MetronomeEngine.synthSamples(SoundType.click, accent: true);

  /// Loads the recordings as 16-bit WAV and parses them in Dart. Not via
  /// SoLoud's MP3 decoder: it keeps the MP3 encoder delay (25 ms of leading
  /// silence), which put the snare audibly behind kick and hi-hat. The WAVs
  /// start on their first millisecond. A missing or broken file falls back
  /// to the closest instrument (see [SampleBank.new]).
  static Future<SampleBank> load({AssetBundle? bundle}) async {
    final rec = <RunSound, List<double>>{};
    for (final e in assets.entries) {
      rec[e.key] = await _decode(e.value, bundle);
    }
    return SampleBank(recordings: rec);
  }

  static Future<List<double>> _decode(String asset, AssetBundle? bundle) async {
    try {
      final data = await (bundle ?? rootBundle).load(asset);
      return decodeVoiceWav(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (_) {
      return const [];
    }
  }

  List<double> of(RunSound s) => _sounds[s]!;

  /// The map [GuidedPlayer] takes as `sounds`.
  Map<RunSound, List<double>> toSoundMap() =>
      {for (final s in RunSound.values) s: of(s)};
}
