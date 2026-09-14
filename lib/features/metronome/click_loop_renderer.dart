import 'dart:typed_data';

/// Renders one full pattern cycle as a WAV that loops sample-exactly
/// (§Wiedergabe): played natively with `looping: true`, the click track is
/// completely decoupled from the main-isolate event queue whose congestion
/// caused the audible 20-30 ms firing spikes.
///
/// [tickVolumes] follows the engine's per-tick semantics: 0 = silent grid
/// tick, >=1.2 = accent source (see `MetronomeEngine._pollBeat`), value scales
/// the sample amplitude. Sounds crossing the loop boundary wrap into the
/// start so the loop stays seamless.
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

Uint8List buildLoopWav({
  required int bpm,
  required int factor,
  required List<double> tickVolumes,
  required List<double> accentSamples,
  required List<double> normalSamples,
  int sampleRate = 44100,
}) {
  final tickDurSec = 60.0 / bpm / factor;
  final ticks = tickVolumes.length;
  final totalSamples = (ticks * tickDurSec * sampleRate).round();
  final mix = Float64List(totalSamples);

  for (var t = 0; t < ticks; t++) {
    final vol = tickVolumes[t];
    if (vol <= 0) continue;
    final src = vol >= 1.2 ? accentSamples : normalSamples;
    final start = (t * tickDurSec * sampleRate).round();
    for (var i = 0; i < src.length; i++) {
      mix[(start + i) % totalSamples] += src[i] * vol;
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
    final s16 = (mix[i].clamp(-1.0, 1.0) * 32767).round();
    bd.setInt16(44 + i * 2, s16, Endian.little);
  }
  return bd.buffer.asUint8List();
}
