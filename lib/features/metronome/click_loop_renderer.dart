import 'dart:typed_data';

/// Renders one full pattern cycle as a WAV that loops sample-exactly
/// (§Wiedergabe): played natively with `looping: true`, the click track is
/// completely decoupled from the main-isolate event queue whose congestion
/// caused the audible 20-30 ms firing spikes.
///
/// [tickVolumes] follows the engine's per-tick semantics: 0 = silent grid
/// tick, >=1.2 = accent source (see `MetronomeEngine._onBeat`), value scales
/// the sample amplitude. Sounds crossing the loop boundary wrap into the
/// start so the loop stays seamless.
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
