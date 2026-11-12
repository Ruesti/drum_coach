import 'dart:async';

import 'package:flutter/foundation.dart';

import '../audio/click_player.dart';
import '../audio/click_track.dart';
import '../content/exercises.dart';
import '../measure/kit.dart';
import '../measure/session_record.dart';
import '../midi/stroke_source.dart';

enum RunPhase { idle, countIn, playing, finished, deviceLost }

/// Runs one exercise: click out, strokes in, then a [SessionRecord].
///
/// Use a fresh [StrokeSource] per run (the caller's job): the controller
/// stops it at the end and a lost device cannot be resumed. [nowMs] and
/// [wait] are injectable for tests; the run polls every 50 ms via [wait].
class RunController extends ChangeNotifier {
  RunController({
    required this.exercise,
    required this.source,
    required this.out,
    required this.mapping,
    required this.latencyOffsetMs,
    required this.platform,
    double Function()? nowMs,
    Future<void> Function(Duration)? wait,
  })  : _nowMs = nowMs ?? _realNowMs,
        _wait = wait ?? Future.delayed;

  static double _realNowMs() => DateTime.now().microsecondsSinceEpoch / 1000.0;

  final Exercise exercise;
  final StrokeSource source;
  final ClickOut out;
  final KitMapping mapping;
  final double? latencyOffsetMs;
  final String platform;
  final double Function() _nowMs;
  final Future<void> Function(Duration) _wait;

  RunPhase _phase = RunPhase.idle;
  int _currentBar = 0;
  SessionRecord? _record;

  RunPhase get phase => _phase;
  int get currentBar => _currentBar;
  SessionRecord? get record => _record;

  void _set(RunPhase p) {
    if (_phase == p) return;
    _phase = p;
    notifyListeners();
  }

  /// The device vanished before the click was running: make sure nothing
  /// keeps playing.
  Future<void> _abort() async {
    await out.stop();
    await source.stop();
  }

  Future<void> start() async {
    if (_phase != RunPhase.idle) return;
    final track = renderClickTrack(
      bpm: exercise.bpm,
      bars: exercise.bars,
      beatsPerBar: exercise.beatsPerBar,
    );
    // Subscribe before starting so no early disconnect is missed.
    final sub = source.connection.listen((ok) {
      if (!ok && (_phase == RunPhase.countIn || _phase == RunPhase.playing)) {
        _set(RunPhase.deviceLost);
        out.stop();
        source.stop();
      }
    });
    try {
      _set(RunPhase.countIn);
      await source.start();
      if (_phase == RunPhase.deviceLost) return _abort();
      final startMs = await out.play(track);
      if (_phase == RunPhase.deviceLost) return _abort();
      final firstBeatMs = startMs + track.firstBeatOffsetMs;
      final endMs = startMs + track.durationMs;
      while (_phase != RunPhase.deviceLost && _nowMs() < endMs) {
        final now = _nowMs();
        if (now >= firstBeatMs) _set(RunPhase.playing);
        final bar = now < firstBeatMs
            ? 0
            : ((now - firstBeatMs) / exercise.barMs)
                .floor()
                .clamp(0, exercise.bars - 1);
        if (bar != _currentBar) {
          _currentBar = bar;
          notifyListeners();
        }
        await _wait(const Duration(milliseconds: 50));
      }
      if (_phase == RunPhase.deviceLost) return;
      await out.stop();
      await source.stop();
      _record = SessionRecord(
        exerciseId: exercise.id,
        bpm: exercise.bpm,
        firstBeatMs: firstBeatMs,
        latencyOffsetMs: latencyOffsetMs,
        deviceName: source.deviceName,
        mapping: mapping,
        platform: platform,
        recordedAt:
            DateTime.fromMicrosecondsSinceEpoch((_nowMs() * 1000).round()),
        strokes: List.of(source.strokes),
      );
      _set(RunPhase.finished);
    } catch (_) {
      // Allow a retry after a failed start.
      if (_phase != RunPhase.deviceLost) {
        _phase = RunPhase.idle;
        notifyListeners();
      }
      rethrow;
    } finally {
      await sub.cancel();
    }
  }
}
