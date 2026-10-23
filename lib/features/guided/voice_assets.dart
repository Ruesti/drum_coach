import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../metronome/snare_sample.dart';
import 'models/voice_clip.dart';

/// Decodes a 16-bit PCM mono WAV at [voiceClipSampleRate] into floats in
/// [-1, 1). Throws [FormatException] for any other format.
Float32List decodeVoiceWav(Uint8List bytes) =>
    decodeMonoWav16(bytes, sampleRate: voiceClipSampleRate);

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
