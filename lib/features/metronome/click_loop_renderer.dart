import 'dart:math' as math;
import 'dart:typed_data';

/// Renders one full loop cycle as a WAV that loops sample-exactly
/// (§Wiedergabe): played natively with `looping: true`, the click track is
/// completely decoupled from the main-isolate event queue whose congestion
/// caused the audible 20-30 ms firing spikes.
///
/// Since Engine part 1 the cycle is a list of [LoopVoice]s (pattern, click
/// track, kick, hi-hat); each voice's `tickVolumes` follows the engine's
/// per-tick semantics: 0 = silent grid tick, ≥ `loudFrom` = loud sound,
/// value scales the sample amplitude. Sounds crossing the loop boundary wrap
/// into the start so the loop stays seamless.
/// Tick state derived from the loop's audio position — THE clock: cursor
/// and planned click times come from what is actually sounding, so display
/// and measurement can never drift against the ear (device test: isolate
/// clock vs. loop phase diverged by up to a full note after tempo changes).
({int tickInLoop, double inTickMs}) tickAtPosition({
  required double positionMs,
  required double tickDurMs,
  required int ticksInLoop,
}) {
  final loopMs = tickDurMs * ticksInLoop;
  final wrapped = positionMs % loopMs;
  var tick = (wrapped / tickDurMs).floor();
  if (tick >= ticksInLoop) tick = ticksInLoop - 1;
  return (tickInLoop: tick, inTickMs: wrapped - tick * tickDurMs);
}

/// Monotone global tick counter across loop wraps: the in-loop tick from
/// [tickAtPosition] plus as many full cycles as needed to never go
/// backwards relative to [lastGlobalTick].
int advanceGlobalTick({
  required int lastGlobalTick,
  required int tickInLoop,
  required int ticksInLoop,
}) {
  var cycleBase = (lastGlobalTick ~/ ticksInLoop) * ticksInLoop;
  var candidate = cycleBase + tickInLoop;
  while (candidate < lastGlobalTick) {
    candidate += ticksInLoop;
  }
  return candidate;
}

/// One voice of the rendered loop: per-tick volumes over the cycle, a loud
/// and a soft sound, the volume from which the loud sound is used, and a
/// track gain. Pattern: loudFrom 1.2 (accent), hi-hat: 0.9, pulse/kick: 1.0.
class LoopVoice {
  const LoopVoice({
    required this.tickVolumes,
    required this.loudSamples,
    required this.softSamples,
    this.loudFrom = 1.0,
    this.gain = 1.0,
  });
  final List<double> tickVolumes;
  final List<double> loudSamples;
  final List<double> softSamples;
  final double loudFrom;
  final double gain;
}

/// Ticks of one rendered cycle when a backing bar of [barTicks] runs next to
/// a pattern of [patternTicks]: the least common multiple, so both repeat
/// whole. Without backing the cycle is just the pattern.
int loopCycleTicks({required int patternTicks, required int barTicks}) {
  int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);
  return patternTicks ~/ gcd(patternTicks, barTicks) * barTicks;
}

double _tanh(double x) {
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

/// Soft limiter: linear up to ±0.8, then a tanh knee towards an explicit
/// ceiling of ±0.98 (tanh alone reaches 1.0 numerically for a loud sum, i.e.
/// int16 32767 — the hard-clip ceiling this is meant to avoid). Four voices
/// on one tick stay loud without the crackle of hard clipping; a single
/// voice below 0.8 is bit-identical to the old output.
double softLimit(double x) {
  const knee = 0.8;
  const ceiling = 0.98;
  final a = x.abs();
  if (a <= knee) return x;
  final y = knee + (ceiling - knee) * _tanh((a - knee) / (ceiling - knee));
  return x < 0 ? -y : y;
}

/// Renders one loop cycle from [voices] as a mono 16-bit WAV that loops
/// sample-exactly. All voices span the same cycle (same `tickVolumes`
/// length); each hit is `sound × tickVolume × gain`, summed, then soft
/// limited. Sounds crossing the loop boundary wrap into the start.
Uint8List buildLoopWav({
  required int bpm,
  required int factor,
  required List<LoopVoice> voices,
  int sampleRate = 44100,
}) {
  if (voices.isEmpty) throw ArgumentError('buildLoopWav needs a voice');
  final ticks = voices.first.tickVolumes.length;
  for (final v in voices) {
    if (v.tickVolumes.length != ticks) {
      throw ArgumentError('all voices must span the same cycle: '
          '${v.tickVolumes.length} vs $ticks ticks');
    }
  }
  final tickDurSec = 60.0 / bpm / factor;
  final totalSamples = (ticks * tickDurSec * sampleRate).round();
  final mix = Float64List(totalSamples);

  for (final v in voices) {
    if (v.gain <= 0) continue;
    for (var t = 0; t < ticks; t++) {
      final vol = v.tickVolumes[t];
      if (vol <= 0) continue;
      final src = vol >= v.loudFrom ? v.loudSamples : v.softSamples;
      final start = (t * tickDurSec * sampleRate).round();
      final scale = vol * v.gain;
      for (var i = 0; i < src.length; i++) {
        mix[(start + i) % totalSamples] += src[i] * scale;
      }
    }
  }

  final dataSize = totalSamples * 2;
  final bd = ByteData(44 + dataSize);
  void str(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      bd.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  bd.setUint32(4, 36 + dataSize, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little);
  bd.setUint16(22, 1, Endian.little);
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * 2, Endian.little);
  bd.setUint16(32, 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  str(36, 'data');
  bd.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < totalSamples; i++) {
    final s16 = (softLimit(mix[i]) * 32767).round();
    bd.setInt16(44 + i * 2, s16, Endian.little);
  }
  return bd.buffer.asUint8List();
}
