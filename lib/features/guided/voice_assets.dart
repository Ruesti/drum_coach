import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'models/voice_clip.dart';

/// Decodes a 16-bit PCM mono WAV at [voiceClipSampleRate] into floats in
/// [-1, 1). Throws [FormatException] for any other format. Pure Dart so it
/// works in host tests (no FFI).
Float32List decodeVoiceWav(Uint8List bytes) {
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
      if (format != 1 ||
          channels != 1 ||
          bits != 16 ||
          rate != voiceClipSampleRate) {
        throw FormatException('Voice WAV must be 16-bit mono PCM at '
            '$voiceClipSampleRate Hz (got $format/$channels ch/$bits bit/'
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

/// Loads and parses `assets/voice/manifest.json`.
Future<ClipManifest> loadClipManifest({AssetBundle? bundle}) async {
  final text = await (bundle ?? rootBundle).loadString(_manifestPath);
  return ClipManifest.fromJson(jsonDecode(text) as Map<String, dynamic>);
}

/// Loads clip [id] from `assets/voice/<id>.wav`. Matches the
/// `loadClip` argument of the guided player.
Future<VoiceClip> loadVoiceClip(String id) async {
  final data = await rootBundle.load('assets/voice/$id.wav');
  return VoiceClip(
      id,
      decodeVoiceWav(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)));
}

const _manifestPath = 'assets/voice/manifest.json';
