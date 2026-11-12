import 'package:flutter/foundation.dart';

import '../audio/click_player.dart';
import '../audio/click_track.dart';
import '../measure/latency.dart';
import '../midi/stroke_source.dart';
import 'device_settings.dart';

/// Plays 4 count-in + 20 quarter clicks at 100 BPM and measures the offset
/// between the player's strokes and the clicks after the count-in.
///
/// Use a fresh [StrokeSource] per run (the caller's job). [nowMs] and [wait]
/// are injectable for tests.
class CalibrationController extends ChangeNotifier {
  CalibrationController({
    required this.source,
    required this.out,
    double Function()? nowMs,
    Future<void> Function(Duration)? wait,
  })  : _nowMs = nowMs ?? _realNowMs,
        _wait = wait ?? Future.delayed;

  static double _realNowMs() => DateTime.now().microsecondsSinceEpoch / 1000.0;

  final StrokeSource source;
  final ClickOut out;
  final double Function() _nowMs;
  final Future<void> Function(Duration) _wait;

  MidiLatencyResult? _result;
  MidiLatencyResult? get result => _result;

  bool _running = false;
  bool get running => _running;

  Future<void> run() async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      final track = renderClickTrack(bpm: 100, bars: 5, countInBars: 1);
      await source.start();
      final startMs = await out.play(track);
      final remaining = startMs + track.durationMs - _nowMs();
      if (remaining > 0) {
        await _wait(Duration(microseconds: (remaining * 1000).round()));
      }
      await out.stop();
      await source.stop();
      final clicks = [
        for (final o in track.clickOffsetsMs)
          if (o >= track.firstBeatOffsetMs - 1e-6) startMs + o,
      ];
      _result = estimateMidiLatency(
        clickMs: clicks,
        strokeMs: [for (final s in source.strokes) s.timeMs],
      );
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  /// |current unsaved result − stored calibration of [device]|; null if
  /// either is missing. Call it BEFORE [save], which overwrites the stored one.
  double? differenceToPreviousMs(DeviceSettings s, String device) {
    final r = _result;
    final prev = s.latencyFor(device);
    if (r == null || prev == null) return null;
    return (r.offsetMs - prev.offsetMs).abs();
  }

  /// Stores the result's offset/spread for [device]; no-op without a result.
  Future<void> save(DeviceSettings s, String device) async {
    final r = _result;
    if (r == null) return;
    await s.saveLatency(device, r.offsetMs, r.spreadMs);
  }
}
