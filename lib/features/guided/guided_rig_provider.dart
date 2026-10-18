import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'guided_player.dart';
import 'models/voice_clip.dart';
import 'pcm_sink.dart';
import 'sample_bank.dart';
import 'voice_assets.dart';

/// A guided player plus the clip manifest it plans with (the page needs the
/// manifest for its time estimate).
class GuidedRig {
  const GuidedRig({required this.player, required this.clips});
  final GuidedPlayer player;
  final ClipManifest clips;
}

/// Builds the player once (SoLoud stream sink, decoded samples, voice
/// manifest); disposing the provider stops the run and frees the render
/// isolate.
final guidedRigProvider = FutureProvider.autoDispose<GuidedRig>((ref) async {
  var disposed = false;
  GuidedPlayer? player;
  ref.onDispose(() {
    disposed = true;
    final p = player;
    if (p != null) unawaited(p.dispose());
  });
  final clips = await loadClipManifest();
  final bank = await SampleBank.load();
  final p = GuidedPlayer(
    sink: SoloudPcmSink(),
    clips: clips,
    loadClip: loadVoiceClip,
    sounds: bank.toSoundMap(),
  );
  if (disposed) {
    unawaited(p.dispose());
  } else {
    player = p;
  }
  return GuidedRig(player: p, clips: clips);
});
