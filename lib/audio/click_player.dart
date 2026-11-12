import 'package:flutter_soloud/flutter_soloud.dart';

import 'click_track.dart';
import 'start_estimator.dart';

abstract class ClickOut {
  Future<void> init();

  /// Starts [t] and returns the estimated epoch ms at which playback of [t]
  /// began (offset 0 of the WAV).
  ///
  /// The constant error of this stamp is part of the calibrated latency, so
  /// calibration and runs must use the same [ClickOut]. Only a varying error
  /// hurts: calibration cannot absorb it.
  Future<double> play(ClickTrack t);

  Future<void> stop();
}

/// Stamps the start as the minimum of (now − play position) over samples
/// taken every [sampleEvery] for [sampleFor] right after `play()` (see
/// [estimateStartMs]). The plain "now after play()" stamp varied by up to
/// one audio buffer per run.
class SoloudClickOut implements ClickOut {
  static const sampleEvery = Duration(milliseconds: 5);
  static const sampleFor = Duration(milliseconds: 250);

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
    final handle = await s.play(source);
    _handle = handle;
    final after = _nowMs();
    final samples = <({double nowMs, double positionMs})>[];
    final until = after + sampleFor.inMicroseconds / 1000.0;
    while (true) {
      // A stop() meanwhile ends sampling early; the stamp no longer matters.
      if (_handle != handle) break;
      final pos = s.getPosition(handle).inMicroseconds / 1000.0;
      final now = _nowMs();
      samples.add((nowMs: now, positionMs: pos));
      if (now >= until) break;
      await Future<void>.delayed(sampleEvery);
    }
    return estimateStartMs(samples) ?? after;
  }

  static double _nowMs() => DateTime.now().microsecondsSinceEpoch / 1000.0;

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
