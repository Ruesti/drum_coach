import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../metronome/backing_sounds.dart';
import '../metronome/metronome_engine.dart';
import '../metronome/snare_sample.dart';
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

/// How hard a stroke is played: each recorded kit instrument has one
/// take per layer (velocity layers of the sampled kit), so a ghost note
/// sounds like a soft stroke and an accent like a hard one, not only
/// quieter or louder (Optik-Runde 2, Review Focus 4).
enum StrokeLayer { soft, medium, hard }

/// The takes of one instrument. As a list it is the [medium] take, so code
/// that only knows one sample per sound (crash hits, tests) keeps working;
/// [layer] picks the take of a stroke.
class LayeredSamples extends UnmodifiableListView<double> {
  LayeredSamples({required this.soft, required this.medium, required this.hard})
      : super(medium);

  /// The same take on every layer (an instrument with one recording).
  LayeredSamples.single(List<double> s) : this(soft: s, medium: s, hard: s);

  final List<double> soft;
  final List<double> medium;
  final List<double> hard;

  List<double> layer(StrokeLayer l) => switch (l) {
        StrokeLayer.soft => soft,
        StrokeLayer.medium => medium,
        StrokeLayer.hard => hard,
      };
}

/// The take of [samples] for [layer]: its own take when [samples] is
/// [LayeredSamples], else [samples] itself.
List<double> layerOf(List<double> samples, StrokeLayer layer) =>
    samples is LayeredSamples ? samples.layer(layer) : samples;

/// The one place that holds every sound the guided player needs, as PCM.
/// Every kit instrument is a recording with three velocity layers
/// ([assets], decoded once in [load]); the click is synthetic. A missing or
/// undecodable recording falls back to the closest real instrument
/// ([_closest] — never the snare for a cymbal), and only when none is there
/// to a synthetic sound — never silence.
class SampleBank {
  SampleBank({Map<RunSound, List<double>> recordings = const {}}) {
    for (final s in RunSound.values) {
      _sounds[s] = _resolve(s, recordings);
    }
  }

  /// Decodes every file of [assets] read by [bytesOf] (null or a broken
  /// file: that instrument falls back, see [SampleBank.new]).
  factory SampleBank.fromFiles(Uint8List? Function(String path) bytesOf) =>
      SampleBank(recordings: _recordingsFrom(bytesOf));

  /// The recordings of each sound: one file (the pad snare the practice
  /// engine plays too, for [RunSound.pattern]) or three, soft / medium /
  /// hard — the DRSKit by the DrumGizmo team (CC BY 4.0, see
  /// assets/audio/CREDITS.md). The kit has one rack tom and two floor toms:
  /// the low tom is the first (higher) floor tom.
  static const assets = <RunSound, List<String>>{
    RunSound.pattern: ['assets/audio/snare.wav'],
    RunSound.kick: [
      'assets/audio/kit_kick_soft.wav',
      'assets/audio/kit_kick_medium.wav',
      'assets/audio/kit_kick_hard.wav',
    ],
    RunSound.snare: [
      'assets/audio/kit_snare_soft.wav',
      'assets/audio/kit_snare_medium.wav',
      'assets/audio/kit_snare_hard.wav',
    ],
    RunSound.rim: [
      'assets/audio/kit_rim_soft.wav',
      'assets/audio/kit_rim_medium.wav',
      'assets/audio/kit_rim_hard.wav',
    ],
    RunSound.hihatClosed: [
      'assets/audio/kit_hihat_closed_soft.wav',
      'assets/audio/kit_hihat_closed_medium.wav',
      'assets/audio/kit_hihat_closed_hard.wav',
    ],
    RunSound.hihatOpen: [
      'assets/audio/kit_hihat_open_soft.wav',
      'assets/audio/kit_hihat_open_medium.wav',
      'assets/audio/kit_hihat_open_hard.wav',
    ],
    RunSound.hihatPedal: [
      'assets/audio/kit_hihat_pedal_soft.wav',
      'assets/audio/kit_hihat_pedal_medium.wav',
      'assets/audio/kit_hihat_pedal_hard.wav',
    ],
    RunSound.tomHigh: [
      'assets/audio/kit_tom_high_soft.wav',
      'assets/audio/kit_tom_high_medium.wav',
      'assets/audio/kit_tom_high_hard.wav',
    ],
    RunSound.tomLow: [
      'assets/audio/kit_tom_low_soft.wav',
      'assets/audio/kit_tom_low_medium.wav',
      'assets/audio/kit_tom_low_hard.wav',
    ],
    RunSound.tomFloor: [
      'assets/audio/kit_tom_floor_soft.wav',
      'assets/audio/kit_tom_floor_medium.wav',
      'assets/audio/kit_tom_floor_hard.wav',
    ],
    RunSound.crash: [
      'assets/audio/kit_crash_soft.wav',
      'assets/audio/kit_crash_medium.wav',
      'assets/audio/kit_crash_hard.wav',
    ],
    RunSound.ride: [
      'assets/audio/kit_ride_soft.wav',
      'assets/audio/kit_ride_medium.wav',
      'assets/audio/kit_ride_hard.wav',
    ],
    RunSound.rideBell: [
      'assets/audio/kit_ride_bell_soft.wav',
      'assets/audio/kit_ride_bell_medium.wav',
      'assets/audio/kit_ride_bell_hard.wav',
    ],
  };

  /// Every file of [assets].
  static Iterable<String> get assetPaths => assets.values.expand((p) => p);

  /// Closest real instruments, in order, for a sound without a recording.
  static const _closest = <RunSound, List<RunSound>>{
    RunSound.snare: [RunSound.pattern],
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
    final bytes = <String, Uint8List>{};
    for (final path in assetPaths) {
      try {
        final data = await (bundle ?? rootBundle).load(path);
        bytes[path] =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } catch (_) {
        // missing: falls back
      }
    }
    return SampleBank.fromFiles((p) => bytes[p]);
  }

  /// An instrument whose files do not all decode counts as missing (a
  /// half-loaded set would mix takes of different instruments).
  static Map<RunSound, List<double>> _recordingsFrom(
      Uint8List? Function(String path) bytesOf) {
    final rec = <RunSound, List<double>>{};
    for (final e in assets.entries) {
      final takes = <List<double>>[];
      for (final path in e.value) {
        final b = bytesOf(path);
        if (b == null) break;
        try {
          final s = decodeMonoWav16(b);
          if (s.isEmpty) break;
          takes.add(s);
        } catch (_) {
          break;
        }
      }
      if (takes.length != e.value.length) continue;
      rec[e.key] = takes.length == 1
          ? takes.single
          : LayeredSamples(soft: takes[0], medium: takes[1], hard: takes[2]);
    }
    return rec;
  }

  List<double> of(RunSound s) => _sounds[s]!;

  /// The map [GuidedPlayer] takes as `sounds`.
  Map<RunSound, List<double>> toSoundMap() =>
      {for (final s in RunSound.values) s: of(s)};
}
