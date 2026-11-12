import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../audio/click_player.dart';
import '../audio/click_track.dart';
import '../measure/latency.dart';
import '../midi/stroke_source.dart';
import 'device_settings.dart';

/// Plays 4 count-in + 20 quarter clicks at 100 BPM and measures the offset
/// between the player's strokes and the clicks after the count-in. Strokes
/// earlier than half a beat before the first counted click (count-in
/// playing) are ignored.
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

  static const bpm = 100;

  final StrokeSource source;
  final ClickOut out;
  final double Function() _nowMs;
  final Future<void> Function(Duration) _wait;

  bool _cancelled = false;

  /// The screen went away: [run] ends at its next poll without a result and
  /// never stops [out] (the click is shared; the caller stops it). Only the
  /// source is stopped.
  void cancel() => _cancelled = true;

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
      final track = renderClickTrack(bpm: bpm, bars: 5, countInBars: 1);
      await source.start();
      if (_cancelled) return await source.stop();
      final startMs = await out.play(track);
      if (_cancelled) {
        // Started after the caller's stop: ours to stop.
        await out.stop();
        return await source.stop();
      }
      final endMs = startMs + track.durationMs;
      while (!_cancelled) {
        final remaining = endMs - _nowMs();
        if (remaining <= 0) break;
        await _wait(
            Duration(microseconds: (math.min(remaining, 50) * 1000).round()));
      }
      if (_cancelled) return await source.stop();
      await out.stop();
      await source.stop();
      final clicks = [
        for (final o in track.clickOffsetsMs)
          if (o >= track.firstBeatOffsetMs - 1e-6) startMs + o,
      ];
      const halfBeatMs = 60000 / bpm / 2;
      final fromMs = startMs + track.firstBeatOffsetMs - halfBeatMs;
      _result = estimateMidiLatency(
        clickMs: clicks,
        strokeMs: [
          for (final s in source.strokes)
            if (s.timeMs >= fromMs) s.timeMs,
        ],
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
