import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// The recorded snare as 16-bit mono WAV. Made from the former snare.mp3
/// with ffmpeg, which strips the MP3 encoder delay; SoLoud's MP3 decoding
/// kept it (25 ms of leading silence), so the snare sounded behind the
/// synthetic kick and hi-hat. Read in Dart — no audio engine needed.
const snareWavAsset = 'assets/audio/snare.wav';

/// Decodes a 16-bit PCM mono WAV at [sampleRate] into floats in [-1, 1).
/// Throws [FormatException] for any other format. Pure Dart so it
/// works in host tests (no FFI).
Float32List decodeMonoWav16(Uint8List bytes, {int sampleRate = 44100}) {
  final d = ByteData.sublistView(bytes);
  if (bytes.length < 12 ||
      String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') {
    throw const FormatException('Not a WAV file');
  }
  int? channels, rate, bits, format;
  var pos = 12;
  while (pos + 8 <= bytes.length) {
    final tag = String.fromCharCodes(bytes.sublist(pos, pos + 4));
    final size = d.getUint32(pos + 4, Endian.little);
    final body = pos + 8;
    if (tag == 'fmt ') {
      format = d.getUint16(body, Endian.little);
      channels = d.getUint16(body + 2, Endian.little);
      rate = d.getUint32(body + 4, Endian.little);
      bits = d.getUint16(body + 14, Endian.little);
    } else if (tag == 'data') {
      if (format != 1 || channels != 1 || bits != 16 || rate != sampleRate) {
        throw FormatException('WAV must be 16-bit mono PCM at '
            '$sampleRate Hz (got $format/$channels ch/$bits bit/'
            '$rate Hz)');
      }
      final end = (body + size).clamp(0, bytes.length);
      final n = (end - body) ~/ 2;
      final out = Float32List(n);
      for (var i = 0; i < n; i++) {
        out[i] = d.getInt16(body + 2 * i, Endian.little) / 32768.0;
      }
      return out;
    }
    pos = body + size + (size.isOdd ? 1 : 0);
  }
  throw const FormatException('WAV has no data chunk');
}

/// Loads and decodes [snareWavAsset].
Future<Float32List> loadSnarePcm({AssetBundle? bundle}) async {
  final data = await (bundle ?? rootBundle).load(snareWavAsset);
  return decodeMonoWav16(data.buffer.asUint8List());
}
