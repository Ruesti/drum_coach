import 'dart:math';
import 'dart:typed_data';

/// A rendered click track: 16-bit mono PCM WAV plus the musical timing of
/// every click.
class ClickTrack {
  final Uint8List wav;

  /// Onset of every click (count-in included) in ms from the start of [wav].
  /// These are the exact musical times `i * 60000 / bpm`; the rendered
  /// onsets are rounded to the nearest sample, so they differ by at most
  /// half a sample (<= 0.011 ms at 48 kHz).
  final List<double> clickOffsetsMs;

  /// `countInBars * beatsPerBar * 60000 / bpm`.
  final double firstBeatOffsetMs;

  /// Last click offset + one beat + 500 ms silence.
  final double durationMs;

  const ClickTrack({
    required this.wav,
    required this.clickOffsetsMs,
    required this.firstBeatOffsetMs,
    required this.durationMs,
  });
}

/// Renders [countInBars] + [bars] bars of clicks. A click is a 20 ms
/// exponentially decaying sine: 1.5 kHz, beat 1 of each bar 2.0 kHz and louder.
ClickTrack renderClickTrack({
  required int bpm,
  required int bars,
  int beatsPerBar = 4,
  int countInBars = 1,
  int sampleRate = 48000,
}) {
  final beatMs = 60000.0 / bpm;
  final totalBeats = (countInBars + bars) * beatsPerBar;
  final offsets = [for (var i = 0; i < totalBeats; i++) i * beatMs];
  final durationMs = offsets.last + beatMs + 500;
  final n = (durationMs * sampleRate / 1000).round();
  final pcm = Int16List(n);
  final clickLen = (sampleRate * 0.020).round();

  for (var i = 0; i < totalBeats; i++) {
    final accent = i % beatsPerBar == 0;
    final freq = accent ? 2000.0 : 1500.0;
    final amp = accent ? 0.9 : 0.5;
    final start = (offsets[i] * sampleRate / 1000).round();
    for (var k = 0; k < clickLen && start + k < n; k++) {
      final t = k / sampleRate;
      final v = amp * sin(2 * pi * freq * t) * exp(-t / 0.006);
      pcm[start + k] = (v * 32767).round();
    }
  }

  final dataLen = n * 2;
  final wav = Uint8List(44 + dataLen);
  final b = ByteData.sublistView(wav);
  void tag(int o, String s) {
    for (var i = 0; i < 4; i++) {
      wav[o + i] = s.codeUnitAt(i);
    }
  }

  tag(0, 'RIFF');
  b.setUint32(4, 36 + dataLen, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  b.setUint32(40, dataLen, Endian.little);
  for (var i = 0; i < n; i++) {
    b.setInt16(44 + i * 2, pcm[i], Endian.little);
  }

  return ClickTrack(
    wav: wav,
    clickOffsetsMs: offsets,
    firstBeatOffsetMs: countInBars * beatsPerBar * beatMs,
    durationMs: durationMs,
  );
}
