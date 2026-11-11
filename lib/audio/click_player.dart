import 'package:flutter_soloud/flutter_soloud.dart';

import 'click_track.dart';

abstract class ClickOut {
  Future<void> init();

  /// Starts [t] and returns the epoch ms taken right after the backend's
  /// `play()` returned.
  ///
  /// The constant error of this stamp is part of the calibrated latency, so
  /// calibration and runs must use the same [ClickOut].
  Future<double> play(ClickTrack t);

  Future<void> stop();
}

class SoloudClickOut implements ClickOut {
  AudioSource? _source;
  SoundHandle? _handle;

  @override
  Future<void> init() async {
    final s = SoLoud.instance;
    if (!s.isInitialized) await s.init();
  }

  @override
  Future<double> play(ClickTrack t) async {
    await stop();
    final s = SoLoud.instance;
    final source = await s.loadMem('click_track.wav', t.wav);
    _source = source;
    _handle = await s.play(source);
    return DateTime.now().microsecondsSinceEpoch / 1000.0;
  }

  @override
  Future<void> stop() async {
    final s = SoLoud.instance;
    final h = _handle;
    final src = _source;
    _handle = null;
    _source = null;
    if (h != null) await s.stop(h);
    if (src != null) await s.disposeSource(src);
  }
}
