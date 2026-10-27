import 'dart:math' as math;
import 'dart:typed_data';

import '../metronome/click_loop_renderer.dart';

/// A one-shot sound (crash, spoken clip) placed at [tick] of the bar being
/// rendered ([tick] is relative to the bar start). May be longer than the bar.
class SampleHit {
  const SampleHit({required this.tick, required this.samples, this.gain = 1.0});
  final int tick;
  final List<double> samples;
  final double gain;
}

/// One rendered 4/4 bar, mono Float32, already soft-limited (±0.98).
class RenderedBar {
  const RenderedBar(this.pcm);
  final Float32List pcm;
  int get samples => pcm.length;
}

/// Mixes one 4/4 bar at a time so a player can append bars to a stream.
/// Sound that runs past the bar end is kept in an internal carry and added
/// to the following bar(s) instead of wrapping to the start.
///
/// Plain Dart (no Flutter/SoLoud) so it can run off the main isolate.
class BarRenderer {
  BarRenderer({this.sampleRate = 44100});

  final int sampleRate;

  /// Running position in seconds; bar edges are rounded from this so bars of
  /// mixed tempo never accumulate rounding drift.
  double _posSec = 0;
  Float32List _carry = Float32List(0);

  /// Carry of the choke group (open hi-hat), kept apart from [_carry] so a
  /// choke in a later bar can still stop it.
  Float32List _chokeCarry = Float32List(0);

  /// Drops the carry and the running position (stop/seek).
  void reset() {
    _posSec = 0;
    _carry = Float32List(0);
    _chokeCarry = Float32List(0);
  }

  /// How fast a choke stops the choke group (a hand/foot closing the
  /// hi-hat): linear fade to silence over this time.
  static const chokeFadeMs = 15.0;

  /// Fade at the end of [flush] so a cut-off tail does not click.
  static const flushFadeMs = 10.0;

  /// Returns what is left in the carry (sound past the last rendered bar),
  /// soft-limited, with a short linear fade over its last [flushFadeMs] so
  /// the end of the stream does not click; empties the carry. Called once
  /// after the last bar so a final crash rings out.
  Float32List flush() {
    final c = Float32List(math.max(_carry.length, _chokeCarry.length));
    for (var i = 0; i < _carry.length; i++) {
      c[i] += _carry[i];
    }
    for (var i = 0; i < _chokeCarry.length; i++) {
      c[i] += _chokeCarry[i];
    }
    _carry = Float32List(0);
    _chokeCarry = Float32List(0);
    final out = Float32List(c.length);
    final fade = math.min(c.length, (flushFadeMs * sampleRate / 1000).round());
    final fadeFrom = c.length - fade;
    for (var i = 0; i < c.length; i++) {
      var v = softLimit(c[i]);
      if (i >= fadeFrom) v *= (c.length - i) / (fade + 1);
      out[i] = v;
    }
    return out;
  }

  /// Mixes one bar of [voices] (each `tickVolumes` spans exactly one bar,
  /// i.e. 4 * [factor] ticks) plus [hits] at [bpm]/[factor].
  ///
  /// [choked] voices form a choke group (an open hi-hat): at every tick in
  /// [chokeTicks] (a closed hi-hat or pedal stroke) whatever the group is
  /// still sounding — from this bar or carried over from earlier ones —
  /// fades out over [chokeFadeMs]; a group stroke on a choke tick starts
  /// after the choke.
  RenderedBar renderBar({
    required int bpm,
    required int factor,
    required List<LoopVoice> voices,
    List<SampleHit> hits = const [],
    List<LoopVoice> choked = const [],
    Iterable<int> chokeTicks = const [],
  }) {
    final ticks = 4 * factor;
    for (final v in [...voices, ...choked]) {
      if (v.tickVolumes.length != ticks) {
        throw ArgumentError('voice must span one bar: '
            '${v.tickVolumes.length} vs $ticks ticks');
      }
    }
    final tickDurSec = 60.0 / bpm / factor;
    final startSample = (_posSec * sampleRate).round();
    _posSec += ticks * tickDurSec;
    final len = (_posSec * sampleRate).round() - startSample;

    // Tail extent: how far sound reaches past this bar.
    var tailLen = math.max(0, _carry.length - len);
    int tickStart(int t) => (t * tickDurSec * sampleRate).round();
    for (final v in voices) {
      if (v.gain <= 0) continue;
      for (var t = 0; t < ticks; t++) {
        final vol = v.tickVolumes[t];
        if (vol <= 0) continue;
        final src = vol >= v.loudFrom ? v.loudSamples : v.softSamples;
        tailLen = math.max(tailLen, tickStart(t) + src.length - len);
      }
    }
    for (final h in hits) {
      if (h.gain <= 0) continue;
      tailLen = math.max(tailLen, tickStart(h.tick) + h.samples.length - len);
    }
    // The choke group mixes into this bar only; its tail stays apart.
    final group = _renderChokeGroup(choked, chokeTicks, ticks, tickStart);

    // One buffer for bar + new carry; samples are only added.
    final mix = Float32List(len + tailLen);
    final n = math.min(_carry.length, mix.length);
    for (var i = 0; i < n; i++) {
      mix[i] += _carry[i];
    }

    for (final v in voices) {
      if (v.gain <= 0) continue;
      for (var t = 0; t < ticks; t++) {
        final vol = v.tickVolumes[t];
        if (vol <= 0) continue;
        final src = vol >= v.loudFrom ? v.loudSamples : v.softSamples;
        final start = tickStart(t);
        final scale = vol * v.gain;
        for (var i = 0; i < src.length; i++) {
          mix[start + i] += src[i] * scale;
        }
      }
    }
    for (final h in hits) {
      if (h.gain <= 0) continue;
      final start = tickStart(h.tick);
      for (var i = 0; i < h.samples.length; i++) {
        mix[start + i] += h.samples[i] * h.gain;
      }
    }
    for (var i = 0; i < math.min(len, group.length); i++) {
      mix[i] += group[i];
    }

    // Unlimited, copied; the choke group's tail on its own.
    _carry = Float32List.fromList(Float32List.sublistView(mix, len));
    _chokeCarry = group.length > len
        ? Float32List.fromList(Float32List.sublistView(group, len))
        : Float32List(0);
    final pcm = Float32List(len);
    for (var i = 0; i < len; i++) {
      pcm[i] = softLimit(mix[i]);
    }
    return RenderedBar(pcm);
  }

  /// The choke group of one bar (carry from earlier bars included), in
  /// time order: a choke fades out what sounds so far, a stroke adds on.
  Float32List _renderChokeGroup(List<LoopVoice> choked,
      Iterable<int> chokeTicks, int ticks, int Function(int) tickStart) {
    final strokes = <({int tick, List<double> src, double scale})>[];
    var end = _chokeCarry.length;
    for (final v in choked) {
      if (v.gain <= 0) continue;
      for (var t = 0; t < ticks; t++) {
        final vol = v.tickVolumes[t];
        if (vol <= 0) continue;
        final src = vol >= v.loudFrom ? v.loudSamples : v.softSamples;
        strokes.add((tick: t, src: src, scale: vol * v.gain));
        end = math.max(end, tickStart(t) + src.length);
      }
    }
    if (end == 0) return Float32List(0);
    final buf = Float32List(end);
    buf.setRange(0, _chokeCarry.length, _chokeCarry);
    final chokes = chokeTicks.where((t) => t >= 0 && t < ticks).toSet().toList()
      ..sort();
    final fade = math.max(1, (chokeFadeMs * sampleRate / 1000).round());
    var si = 0;
    strokes.sort((a, b) => a.tick.compareTo(b.tick));
    void choke(int at) {
      for (var i = at; i < buf.length; i++) {
        final k = i - at;
        buf[i] = k < fade ? buf[i] * (1 - (k + 1) / fade) : 0.0;
      }
    }

    for (final c in chokes) {
      while (si < strokes.length && strokes[si].tick < c) {
        _addStroke(buf, strokes[si++], tickStart);
      }
      choke(tickStart(c));
    }
    while (si < strokes.length) {
      _addStroke(buf, strokes[si++], tickStart);
    }
    return buf;
  }

  static void _addStroke(Float32List buf,
      ({int tick, List<double> src, double scale}) s, int Function(int) at) {
    final start = at(s.tick);
    for (var i = 0; i < s.src.length; i++) {
      buf[start + i] += s.src[i] * s.scale;
    }
  }
}
