import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/settings_service.dart';
import '../coaching/services/recording_setup.dart';
import 'backing_styles.dart';
import 'metronome_engine.dart';

part 'metronome_provider.g.dart';

@immutable
class MetronomeState {
  final bool isPlaying;
  final int bpm;
  final Subdivision subdivision;
  final SoundType soundType;
  final int currentBeatIndex;
  final bool isAccent;

  /// Scheduled wall-clock instant of the current beat (from the timing
  /// isolate), null before the first beat. Used as the click side of the
  /// shared time axis (§1.3).
  final DateTime? lastBeatPlannedAt;

  /// Click track next to a pattern (practice screen, K2 step 2): a
  /// quarter-note pulse. Off until a screen asks for it.
  final bool clickTrack;

  /// Backing loop (Engine part 1): chosen style id (null = off) and the
  /// backing track's own level 0..1.
  final String? backingStyleId;
  final double backingLevel;

  /// Bumped on every headphone plug/unplug so the practice screen can
  /// re-check headphones (the analysis-mode rule) without owning the single
  /// platform callback this notifier already holds.
  final int audioRouteChanges;

  const MetronomeState({
    this.isPlaying = false,
    this.bpm = 100,
    this.subdivision = Subdivision.quarter,
    this.soundType = SoundType.click,
    this.currentBeatIndex = -1,
    this.isAccent = false,
    this.lastBeatPlannedAt,
    this.clickTrack = false,
    this.backingStyleId,
    this.backingLevel = 0.7,
    this.audioRouteChanges = 0,
  });

  MetronomeState copyWith({
    bool? isPlaying,
    int? bpm,
    Subdivision? subdivision,
    SoundType? soundType,
    int? currentBeatIndex,
    bool? isAccent,
    DateTime? lastBeatPlannedAt,
    bool? clickTrack,
    String? backingStyleId,
    bool clearBackingStyle = false,
    double? backingLevel,
    int? audioRouteChanges,
  }) {
    return MetronomeState(
      isPlaying: isPlaying ?? this.isPlaying,
      bpm: bpm ?? this.bpm,
      subdivision: subdivision ?? this.subdivision,
      soundType: soundType ?? this.soundType,
      currentBeatIndex: currentBeatIndex ?? this.currentBeatIndex,
      isAccent: isAccent ?? this.isAccent,
      lastBeatPlannedAt: lastBeatPlannedAt ?? this.lastBeatPlannedAt,
      clickTrack: clickTrack ?? this.clickTrack,
      backingStyleId:
          clearBackingStyle ? null : (backingStyleId ?? this.backingStyleId),
      backingLevel: backingLevel ?? this.backingLevel,
      audioRouteChanges: audioRouteChanges ?? this.audioRouteChanges,
    );
  }
}

@Riverpod(keepAlive: true)
class MetronomeNotifier extends _$MetronomeNotifier {
  MetronomeEngine? _engine;
  StreamSubscription<BeatEvent>? _beatSub;
  bool _disposed = false;
  final List<DateTime> _tapTimestamps = [];
  List<double>? _pendingVolumes;

  @override
  MetronomeState build() {
    ref.onDispose(_cleanup);
    // Construct synchronously: commands arriving before the async init
    // finishes (practice screen's post-frame callback on a cold start) must
    // land in the engine's fields instead of being dropped on a null target —
    // otherwise the isolate keeps ticking at its 100-BPM default while the
    // UI shows the requested tempo.
    _engine = MetronomeEngine();
    // Headphone plug/unplug: reroute the audio engine (it does not survive
    // Android routing changes on its own). The notifier is keepAlive, so
    // this listener lives for the app's lifetime.
    AudioCapabilities.onDevicesChanged(notifyAudioRouteChanged);
    Future.microtask(_initAsync);
    return const MetronomeState();
  }

  Future<void> _initAsync() async {
    try {
      await _engine!.init();
    } catch (_) {
      return;
    }
    if (_disposed) return;
    if (_pendingVolumes != null) _engine!.setBeatVolumes(_pendingVolumes);
    _beatSub = _engine!.beatStream.listen((event) {
      if (_disposed) return;
      if (event.isAccent && SettingsService.hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
      state = state.copyWith(
        currentBeatIndex: event.beatIndex,
        isAccent: event.isAccent,
        lastBeatPlannedAt: event.plannedAt,
      );
    });
  }

  @visibleForTesting
  MetronomeEngine? get debugEngine => _engine;

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

  void setSoundType(SoundType soundType) {
    _engine?.setSoundType(soundType);
    state = state.copyWith(soundType: soundType);
  }

  /// Click track next to a pattern; the engine ignores it in plain
  /// metronome mode.
  void setClickTrack(bool on) {
    _engine?.setPulse(on);
    state = state.copyWith(clickTrack: on);
  }

  void setPatternVolumes(List<double>? volumes) {
    _pendingVolumes = volumes;
    _engine?.setBeatVolumes(volumes);
  }

  int _beatsPerBar = 4;

  /// Headphone plug/unplug: reroute the engine and tell listening screens.
  @visibleForTesting
  void notifyAudioRouteChanged() {
    _engine?.handleAudioRouteChanged();
    if (_disposed) return;
    state = state.copyWith(audioRouteChanges: state.audioRouteChanges + 1);
  }

  /// Backing loop next to a pattern (Engine part 1). Unknown ids mean off.
  void setBacking(String? styleId, {required int beatsPerBar}) {
    final style = backingStyleById(styleId);
    _beatsPerBar = beatsPerBar;
    _engine?.setBacking(style,
        level: state.backingLevel, beatsPerBar: beatsPerBar);
    state = style == null
        ? state.copyWith(clearBackingStyle: true)
        : state.copyWith(backingStyleId: style.id);
  }

  void setBackingLevel(double level) {
    final clamped = level.clamp(0.0, 1.0).toDouble();
    _engine?.setBacking(backingStyleById(state.backingStyleId),
        level: clamped, beatsPerBar: _beatsPerBar);
    state = state.copyWith(backingLevel: clamped);
  }

  void setSubdivision(Subdivision subdivision) {
    final wasPlaying = state.isPlaying;
    if (wasPlaying) _engine?.stop();
    _engine?.setSubdivision(subdivision);
    if (wasPlaying) _engine?.start();
    state = state.copyWith(subdivision: subdivision, currentBeatIndex: -1);
  }

  /// Set an arbitrary integer tick factor (ticks per quarter) for pattern
  /// playback — used by exercises with mixed note values via [PatternPlayback].
  void setPatternClock(int ticksPerQuarter) {
    final wasPlaying = state.isPlaying;
    if (wasPlaying) _engine?.stop();
    _engine?.setPatternClock(ticksPerQuarter);
    if (wasPlaying) _engine?.start();
    state = state.copyWith(currentBeatIndex: -1);
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
