import 'dart:async';

import '../guided/models/voice_clip.dart';
import '../guided/pcm_sink.dart';
import '../guided/voice_assets.dart';

/// Voice clip id of an exercise's spoken lesson ("How to play").
String lessonClipId(String rudimentId) => 'h_$rudimentId';

/// The spoken lesson behind "How to play" — only ever played on request.
abstract class LessonVoice {
  /// Whether the clip manifest lists [clipId].
  Future<bool> has(String clipId);
  Future<void> play(String clipId);
  Future<void> stop();
}

/// [LessonVoice] on the voice assets ([loadClipManifest], [loadVoiceClip])
/// and the guided player's SoLoud stream ([SoloudPcmSink]).
class AssetLessonVoice implements LessonVoice {
  AssetLessonVoice({PcmSink? sink}) : _sink = sink ?? SoloudPcmSink();

  final PcmSink _sink;
  Future<Set<String>>? _ids;

  @override
  Future<bool> has(String clipId) async {
    try {
      _ids ??= loadClipManifest().then((m) => m.ids.toSet());
      return (await _ids!).contains(clipId);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> play(String clipId) async {
    try {
      final clip = await loadVoiceClip(clipId);
      await _sink.open(voiceClipSampleRate,
          maxBuffer: Duration(milliseconds: clip.durationMs.ceil() + 500));
      if (_sink.append(clip.samples)) _sink.markEnded();
    } catch (_) {
      // No sound is better than a crash; the text stays on screen.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _sink.close();
    } catch (_) {}
  }
}
