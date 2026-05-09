import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/settings_service.dart';
import 'metronome_engine.dart';

part 'metronome_provider.g.dart';

@immutable
class MetronomeState {
  final bool isPlaying;
  final int bpm;
  final Subdivision subdivision;
  final int currentBeatIndex;
  final bool isAccent;

  const MetronomeState({
    this.isPlaying = false,
    this.bpm = 100,
    this.subdivision = Subdivision.quarter,
    this.currentBeatIndex = -1,
    this.isAccent = false,
  });

  MetronomeState copyWith({
    bool? isPlaying,
    int? bpm,
    Subdivision? subdivision,
    int? currentBeatIndex,
    bool? isAccent,
  }) {
    return MetronomeState(
      isPlaying: isPlaying ?? this.isPlaying,
      bpm: bpm ?? this.bpm,
      subdivision: subdivision ?? this.subdivision,
      currentBeatIndex: currentBeatIndex ?? this.currentBeatIndex,
      isAccent: isAccent ?? this.isAccent,
    );
  }
}

@Riverpod(keepAlive: true)
class MetronomeNotifier extends _$MetronomeNotifier {
  MetronomeEngine? _engine;
  StreamSubscription<BeatEvent>? _beatSub;
  bool _disposed = false;
  final List<DateTime> _tapTimestamps = [];

  @override
  MetronomeState build() {
    ref.onDispose(_cleanup);
    Future.microtask(_initAsync);
    return const MetronomeState();
  }

  Future<void> _initAsync() async {
    _engine = MetronomeEngine();
    try {
      await _engine!.init();
    } catch (_) {
      return;
    }
    if (_disposed) return;
    _beatSub = _engine!.beatStream.listen((event) {
      if (_disposed) return;
      if (event.isAccent && SettingsService.hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
      state = state.copyWith(
        currentBeatIndex: event.beatIndex,
        isAccent: event.isAccent,
      );
    });
  }

  void _cleanup() {
    _disposed = true;
    _beatSub?.cancel();
    _engine?.dispose();
  }

  void start() {
    _engine?.start();
    state = state.copyWith(isPlaying: true);
  }

  void stop() {
    _engine?.stop();
    state = state.copyWith(isPlaying: false, currentBeatIndex: -1);
  }

  void toggle() => state.isPlaying ? stop() : start();

  void setBpm(int bpm) {
    _engine?.setBpm(bpm);
    state = state.copyWith(bpm: bpm);
  }

  void setSubdivision(Subdivision subdivision) {
    final wasPlaying = state.isPlaying;
    if (wasPlaying) _engine?.stop();
    _engine?.setSubdivision(subdivision);
    if (wasPlaying) _engine?.start();
    state = state.copyWith(subdivision: subdivision, currentBeatIndex: -1);
  }

  void tap() {
    final now = DateTime.now();
    if (_tapTimestamps.isNotEmpty &&
        now.difference(_tapTimestamps.last) > const Duration(seconds: 3)) {
      _tapTimestamps.clear();
    }
    _tapTimestamps.add(now);
    if (_tapTimestamps.length > 4) _tapTimestamps.removeAt(0);

    if (_tapTimestamps.length >= 2) {
      final totalMs =
          _tapTimestamps.last.difference(_tapTimestamps.first).inMilliseconds;
      final avgIntervalMs = totalMs / (_tapTimestamps.length - 1);
      final newBpm = (60000.0 / avgIntervalMs).round().clamp(40, 240);
      setBpm(newBpm);
    }
  }
}
