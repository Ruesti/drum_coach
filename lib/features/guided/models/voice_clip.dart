import 'dart:typed_data';

/// Sample rate of every voice clip (mono).
const int voiceClipSampleRate = 44100;

/// One decoded voice clip: mono float samples at [voiceClipSampleRate].
class VoiceClip {
  const VoiceClip(this.id, this.samples);
  final String id;
  final Float32List samples;

  double get durationMs => samples.length * 1000 / voiceClipSampleRate;
}

/// Clip ids with their durations, parsed from `assets/voice/manifest.json`
/// (`{"clips":[{"id":"cd_three","ms":420}, ...]}`).
class ClipManifest {
  const ClipManifest._(this._ms);

  factory ClipManifest.fromJson(Map<String, dynamic> json) {
    final out = <String, double>{};
    for (final c in (json['clips'] as List)) {
      final m = c as Map<String, dynamic>;
      out[m['id'] as String] = (m['ms'] as num).toDouble();
    }
    return ClipManifest._(Map.unmodifiable(out));
  }

  final Map<String, double> _ms;

  /// Duration of clip [id]; throws [StateError] for an unknown id.
  double durationMs(String id) {
    final ms = _ms[id];
    if (ms == null) throw StateError('Unknown voice clip: $id');
    return ms;
  }

  Iterable<String> get ids => _ms.keys;
}
