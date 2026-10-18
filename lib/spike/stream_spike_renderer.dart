// SPIKE (Plan 1 Task 0) — throwaway, never merged.
//
// Renders a 4/4 groove bar by bar as Float32 PCM on an ABSOLUTE sample
// timeline: every sound instance (kick, snare, hi-hat, voice clip) is placed
// at an absolute sample index and each bar is just the window
// [barStart, barStart + barLen) of that timeline. Tails and clips that cross
// a bar boundary simply continue in the next window, so concatenated bars are
// bit-identical to a one-shot render (no seam by construction). Bar lengths
// are integer samples; tempo changes only take effect at the next bar start.
import 'dart:math' as math;
import 'dart:typed_data';

import '../features/metronome/backing_sounds.dart';
import '../features/metronome/click_loop_renderer.dart' show softLimit;

const spikeSampleRate = 44100;

class _Instance {
  _Instance(this.samples, this.start, this.gain);
  final Float32List samples;
  final int start; // absolute sample
  final double gain;
  int get end => start + samples.length;
}

class SpikeBar {
  SpikeBar(this.index, this.bpm, this.start, this.length, this.pcm,
      this.clipStarts);
  final int index;
  final int bpm;
  final int start; // absolute sample of beat 1
  final int length; // samples
  final Float32List pcm;
  final bool clipStarts;
}

class SpikeStreamRenderer {
  SpikeStreamRenderer({
    required List<double> snarePcm,
    required Float32List clipPcm,
    this.countPcm = const [],
    this.clipFirstBar = 4,
    this.clipEveryBars = 8,
    this.clipGain = 0.9,
  })  : _snare = Float32List.fromList(
            snarePcm.isEmpty ? hihatSamples(accent: true) : snarePcm),
        _clip = clipPcm,
        _kick = Float32List.fromList(kickSamples()),
        _hat = Float32List.fromList(hihatSamples(accent: false)),
        _hatAcc = Float32List.fromList(hihatSamples(accent: true));

  final Float32List _snare, _clip, _kick, _hat, _hatAcc;

  /// Countdown words "three, two, one, go": beats 2-4 of bar clip+3 and
  /// beat 1 of bar clip+4 (each word starts on its beat, never stretched).
  final List<Float32List> countPcm;
  static const countGain = 0.9;
  final int clipFirstBar, clipEveryBars;
  final double clipGain;

  final List<_Instance> _active = [];
  int nextBarIndex = 0;
  int nextBarStart = 0;

  /// Renders the next bar at [bpm].
  SpikeBar renderNext(int bpm) {
    final idx = nextBarIndex;
    final start = nextBarStart;
    final barLen = (4 * 60.0 / bpm * spikeSampleRate).round();
    final eighth = barLen / 8.0;
    // Groove: hi-hat eighths (accent on beats), kick 1 + 3 + "3&",
    // snare 2 + 4.
    for (var e = 0; e < 8; e++) {
      final at = start + (e * eighth).round();
      _active.add(_Instance(e.isEven ? _hatAcc : _hat, at, 0.55));
      if (e == 0 || e == 4 || e == 5) _active.add(_Instance(_kick, at, 0.9));
      if (e == 2 || e == 6) _active.add(_Instance(_snare, at, 0.8));
    }
    final clipStarts =
        idx >= clipFirstBar && (idx - clipFirstBar) % clipEveryBars == 0;
    if (clipStarts) _active.add(_Instance(_clip, start, clipGain));
    if (countPcm.length == 4 && idx >= clipFirstBar + 3) {
      final k = (idx - clipFirstBar - 3) % clipEveryBars;
      final beat = barLen / 4.0;
      if (k == 0) {
        for (var w = 0; w < 3; w++) {
          _active.add(
              _Instance(countPcm[w], start + ((w + 1) * beat).round(), countGain));
        }
      } else if (k == 1) {
        _active.add(_Instance(countPcm[3], start, countGain));
      }
    }

    final pcm = Float32List(barLen);
    final end = start + barLen;
    for (final inst in _active) {
      final from = math.max(inst.start, start);
      final to = math.min(inst.end, end);
      for (var a = from; a < to; a++) {
        pcm[a - start] += inst.samples[a - inst.start] * inst.gain;
      }
    }
    for (var i = 0; i < barLen; i++) {
      pcm[i] = softLimit(pcm[i]);
    }
    _active.removeWhere((i) => i.end <= end);
    nextBarIndex++;
    nextBarStart = end;
    return SpikeBar(idx, bpm, start, barLen, pcm, clipStarts);
  }
}

/// Decodes a mono/stereo 16-bit PCM WAV into mono Float32.
Float32List decodeWav16(Uint8List bytes) {
  final bd = ByteData.sublistView(bytes);
  var off = 12;
  var channels = 1;
  while (off + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(off, off + 4));
    final size = bd.getUint32(off + 4, Endian.little);
    if (id == 'fmt ') channels = bd.getUint16(off + 10, Endian.little);
    if (id == 'data') {
      final frames = size ~/ (2 * channels);
      final out = Float32List(frames);
      for (var i = 0; i < frames; i++) {
        out[i] = bd.getInt16(off + 8 + i * 2 * channels, Endian.little) /
            32768.0;
      }
      return out;
    }
    off += 8 + size + (size & 1);
  }
  throw const FormatException('no data chunk');
}

/// Tempo plan for the automatic run: bar index -> bpm (applies from that bar).
const spikeAutoTempo = <int, int>{
  0: 100,
  16: 110,
  32: 120,
  48: 90,
  64: 140,
  80: 160,
  96: 70,
  112: 100,
  128: 180,
  140: 100,
};
