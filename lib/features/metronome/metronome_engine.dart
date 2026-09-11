import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_soloud/flutter_soloud.dart';

import 'click_loop_renderer.dart';

enum Subdivision {
  quarter(factor: 1, label: '♩', name: '1/4'),
  eighth(factor: 2, label: '♪', name: '1/8'),
  triplet(factor: 3, label: '♪♪♪', name: 'Trip.'),
  sixteenth(factor: 4, label: '♬', name: '1/16');

  final int factor;
  final String label;
  final String name;
  const Subdivision({required this.factor, required this.label, required this.name});
}

enum SoundType {
  click(label: 'Click'),
  rim(label: 'Rim'),
  snare(label: 'Snare');

  final String label;
  const SoundType({required this.label});
}

class BeatEvent {
  final int beatIndex;
  final bool isAccent;
  final Subdivision subdivision;

  /// Wall-clock instant this beat was *scheduled* for, computed inside the
  /// timing isolate from its monotonic schedule (§1.3). Free of port/UI
  /// latency — unlike stamping DateTime.now() when the event reaches a
  /// listener.
  final DateTime plannedAt;

  const BeatEvent({
    required this.beatIndex,
    required this.isAccent,
    required this.subdivision,
    required this.plannedAt,
  });
}

/// Playback volume for tick [index]: from the per-tick pattern array if one
/// is set, otherwise a flat accent/normal volume. A tick with volume 0 is
/// silent — no sound and (per [MetronomeEngine._pollBeat]) no [BeatEvent],
/// so grid-filler ticks in fine-grained pattern playback don't drive the
/// UI's beat indicator. Pure so it's unit-testable without SoLoud.
double resolveTickVolume({
  required List<double>? beatVolumes,
  required int index,
  required bool isAccent,
}) {
  if (beatVolumes != null && beatVolumes.isNotEmpty) {
    return beatVolumes[index % beatVolumes.length];
  }
  return isAccent ? 2.0 : 0.7;
}

// ── MetronomeEngine ───────────────────────────────────────────────────────────

class MetronomeEngine {
  final _beatCtrl = StreamController<BeatEvent>.broadcast();
  Stream<BeatEvent> get beatStream => _beatCtrl.stream;

  /// Decoded PCM of the recorded snare sample for the loop renderer.
  List<double> _snarePcm = const [];

  /// The click track: one pattern cycle rendered as WAV, played natively
  /// with looping — sample-exact and immune to main-isolate congestion
  /// (§Wiedergabe-Diagnose: per-tick play() showed 20-30 ms firing spikes).
  AudioSource? _loopSource;
  SoundHandle? _loopHandle;
  int _loopGeneration = 0;
  Timer? _loopRebuildDebounce;

  int          _bpm        = 100;
  Subdivision  _subdivision = Subdivision.quarter;
  int          _factor      = 1; // active ticks-per-quarter (subdivision or pattern clock)
  SoundType    _soundType   = SoundType.click;
  List<double>? _beatVolumes;
  bool          _isPlaying  = false;
  bool          _disposed   = false;

  // Beat derivation from the loop's audio position (single clock).
  Timer? _beatPoller;
  int _lastGlobalTick = -1;
  double _loopTickDurMs = 500;
  List<double> _loopVolumesActive = const [2.0];

  Future<void> init() async {
    // All beat timing derives from the loop's audio position — there is no
    // separate clock to start. Audio preparation runs decoupled; every call
    // in it is timeout-guarded (a stalled audio engine must never block
    // anything else).
    unawaited(_prepareAudio());
  }

  /// Snare-PCM decoding and, if a start already happened, the loop start.
  /// Every SoLoud call is timeout-guarded: a stalled audio engine must never
  /// silence the metronome forever — the loop is retried on the next start.
  Future<void> _prepareAudio() async {
    try {
      final snareBytes = (await rootBundle.load('assets/audio/snare.mp3'))
          .buffer
          .asUint8List();
      final snareSource = await SoLoud.instance
          .loadMem('snare_len_probe', snareBytes)
          .timeout(const Duration(seconds: 5));
      final snareLen = SoLoud.instance.getLength(snareSource);
      unawaited(SoLoud.instance.disposeSource(snareSource));
      final snareSampleCount =
          (snareLen.inMicroseconds * 44100 / 1000000).round();
      if (snareSampleCount > 0) {
        final floats = await SoLoud.instance
            .readSamplesFromMem(snareBytes, snareSampleCount)
            .timeout(const Duration(seconds: 5));
        _snarePcm = List<double>.from(floats);
      }
    } catch (_) {
      // Loop rendering for the snare falls back to an empty sample; click
      // and rim stay synthetic and unaffected.
    }
    if (_disposed) return;
    // A start may have happened while audio was not ready — the loop start
    // back then bailed on !_soloudReady. Catch up now.
    if (_isPlaying && _loopHandle == null) {
      unawaited(_startLoop());
    }
  }

  // ── Click-track loop ────────────────────────────────────────────────────────

  /// SoLoud reachable and initialized? Merely touching [SoLoud.instance]
  /// throws in host tests (no FFI bindings), so every audio path goes
  /// through this guard.
  static bool get _soloudReady {
    try {
      return SoLoud.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  /// Per-tick volumes of one loop cycle: the pattern's own volumes, or a
  /// single quarter (accent + normal subdivisions) in plain metronome mode —
  /// matching the old per-tick logic (accent when idx % factor == 0).
  List<double> _loopVolumes() =>
      _beatVolumes != null && _beatVolumes!.isNotEmpty
          ? _beatVolumes!
          : [2.0, for (var i = 1; i < _factor; i++) 0.7];

  Future<void> _startLoop() async {
    if (_disposed || !_soloudReady) return;
    final generation = ++_loopGeneration;
    await _stopLoop();
    final synthetic = _soundType != SoundType.snare;
    final wav = buildLoopWav(
      bpm: _bpm,
      factor: _factor,
      tickVolumes: _loopVolumes(),
      accentSamples: synthetic
          ? synthSamples(_soundType, accent: true)
          : _snarePcm,
      normalSamples: synthetic
          ? synthSamples(_soundType, accent: false)
          : _snarePcm,
    );
    final source =
        await SoLoud.instance.loadMem('click_loop_$generation', wav);
    // A newer rebuild or stop may have superseded this one while awaiting.
    if (_disposed || !_isPlaying || generation != _loopGeneration) {
      unawaited(SoLoud.instance.disposeSource(source));
      return;
    }
    _loopSource = source;
    final volumes = List<double>.of(_loopVolumes());
    _loopTickDurMs = 60000.0 / _bpm / _factor;
    _loopVolumesActive = volumes;
    // Keep the global tick counter monotone across rebuilds: the new loop
    // starts at its pattern beginning, so continue at the next multiple of
    // the loop length.
    final ticks = volumes.length;
    _lastGlobalTick = _lastGlobalTick < 0
        ? -1
        : ((_lastGlobalTick + ticks) ~/ ticks) * ticks - 1;
    _loopHandle = await SoLoud.instance.play(source, looping: true);
    _beatPoller?.cancel();
    _beatPoller =
        Timer.periodic(const Duration(milliseconds: 10), (_) => _pollBeat());
    assert(() {
      // ignore: avoid_print
      print('click loop start #$generation');
      return true;
    }());
  }

  /// Derives beat events from the loop's playback position — display and
  /// planned click times share the audio clock, so they cannot drift against
  /// what the ear hears (isolate clock vs. loop phase previously diverged by
  /// up to a full note after tempo changes). plannedAt is back-computed from
  /// the in-tick offset, so the 10-ms poll cadence does not blur it.
  void _pollBeat() {
    final handle = _loopHandle;
    if (handle == null || !_isPlaying || _disposed) return;
    double posMs;
    try {
      posMs = SoLoud.instance.getPosition(handle).inMicroseconds / 1000.0;
    } catch (_) {
      return;
    }
    final ticks = _loopVolumesActive.length;
    final t = tickAtPosition(
        positionMs: posMs, tickDurMs: _loopTickDurMs, ticksInLoop: ticks);
    final global = advanceGlobalTick(
        lastGlobalTick: _lastGlobalTick < 0 ? 0 : _lastGlobalTick,
        tickInLoop: t.tickInLoop,
        ticksInLoop: ticks);
    if (_lastGlobalTick >= 0 && global == _lastGlobalTick) return;
    final now = DateTime.now();
    final from = _lastGlobalTick < 0 ? global : _lastGlobalTick + 1;
    for (var g = from; g <= global; g++) {
      if (_loopVolumesActive[g % ticks] <= 0) continue;
      final agoMs = t.inTickMs + (global - g) * _loopTickDurMs;
      assert(() {
        // ignore: avoid_print
        print('emit g=$g inLoop=${g % ticks} '
            'at=${now.millisecondsSinceEpoch % 100000} agoMs=${agoMs.toStringAsFixed(1)}');
        return true;
      }());
      _beatCtrl.add(BeatEvent(
        beatIndex: g,
        isAccent: g % _factor == 0,
        subdivision: _subdivision,
        plannedAt:
            now.subtract(Duration(microseconds: (agoMs * 1000).round())),
      ));
    }
    _lastGlobalTick = global;
  }

  Future<void> _stopLoop() async {
    final handle = _loopHandle;
    final source = _loopSource;
    _loopHandle = null;
    _loopSource = null;
    if ((handle == null && source == null) || !_soloudReady) return;
    if (handle != null) {
      await SoLoud.instance.stop(handle);
    }
    if (source != null) {
      unawaited(SoLoud.instance.disposeSource(source));
    }
  }

  /// Rebuild the running loop shortly after the last parameter change —
  /// debounced so a BPM slider drag doesn't re-render dozens of loops.
  void _scheduleLoopRebuild() {
    if (!_isPlaying) return;
    _loopRebuildDebounce?.cancel();
    _loopRebuildDebounce = Timer(
        const Duration(milliseconds: 150), () => unawaited(_startLoop()));
  }

  Timer? _routeChangeDebounce;

  /// Headphones were plugged or unplugged: SoLoud's output stream does not
  /// survive the Android routing change on its own — switch the engine to
  /// the (new) default device and restart a running loop. Debounced because
  /// one plug event fires several add/remove callbacks.
  void handleAudioRouteChanged() {
    if (_disposed) return;
    assert(() {
      // ignore: avoid_print
      print('audio route change event');
      return true;
    }());
    _routeChangeDebounce?.cancel();
    _routeChangeDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_disposed || !_soloudReady) return;
      try {
        SoLoud.instance.changeDevice();
      } catch (_) {
        // Device list mid-transition — the retry rides on the next event.
      }
      if (_isPlaying) unawaited(_startLoop());
    });
  }

  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _lastGlobalTick = -1;
    unawaited(_startLoop());
  }

  void stop() {
    _isPlaying = false;
    _loopRebuildDebounce?.cancel();
    _beatPoller?.cancel();
    _beatPoller = null;
    unawaited(_stopLoop());
  }

  void setBpm(int bpm) {
    _bpm = bpm.clamp(40, 240);
    _scheduleLoopRebuild();
  }

  void setSubdivision(Subdivision subdivision) {
    _subdivision = subdivision;
    _factor = subdivision.factor;
    _scheduleLoopRebuild();
  }

  /// Set an arbitrary integer tick factor for pattern playback (e.g. 24
  /// ticks/quarter), bypassing the [Subdivision] enum.
  void setPatternClock(int ticksPerQuarter) {
    _factor = ticksPerQuarter;
    _scheduleLoopRebuild();
  }

  void setSoundType(SoundType t) {
    _soundType = t;
    _scheduleLoopRebuild();
  }

  void setBeatVolumes(List<double>? v) {
    _beatVolumes = v;
    _scheduleLoopRebuild();
  }

  @visibleForTesting
  int get debugBpm => _bpm;
  @visibleForTesting
  int get debugFactor => _factor;

  void dispose() {
    _disposed  = true;
    _isPlaying = false;
    _loopRebuildDebounce?.cancel();
    _routeChangeDebounce?.cancel();
    _beatPoller?.cancel();
    if (!_beatCtrl.isClosed) _beatCtrl.close();
    unawaited(_stopLoop());
  }

  // ── Sound synthesis ─────────────────────────────────────────────────────────

  /// The accent click as WAV bytes — reused by the latency calibration
  /// (§1.3) so the measured loopback matches the sound used in practice.
  static Uint8List calibrationClickWav() =>
      _buildClickWav(frequency: 1200, amplitude: 0.95);

  /// Raw float samples of one stroke sound — shared by the per-tick sources
  /// and the loop renderer so both playback paths sound identical.
  static List<double> synthSamples(
    SoundType type, {
    required bool accent,
    int sampleRate = 44100,
  }) {
    final amplitude = accent ? 0.95 : 0.55;
    switch (type) {
      case SoundType.click:
        final frequency = accent ? 1200.0 : 800.0;
        final n = (sampleRate * 0.030).round();
        return [
          for (var i = 0; i < n; i++)
            amplitude *
                math.exp(-140.0 * (i / sampleRate)) *
                math.sin(2 * math.pi * frequency * (i / sampleRate)),
        ];
      case SoundType.rim:
        final n = (sampleRate * 0.10).round();
        return [
          for (var i = 0; i < n; i++)
            _rimSample(i / sampleRate, amplitude),
        ];
      case SoundType.snare:
        // The snare is a real recorded sample (assets/audio/snare.mp3); its
        // PCM is decoded once at init via readSamplesFromMem and kept in
        // [_snarePcm] for the loop renderer.
        throw ArgumentError('snare is sample-based; use the decoded PCM');
    }
  }

  static double _rimSample(double t, double amplitude) {
    final shell = math.sin(2 * math.pi * 280 * t) * math.exp(-55.0 * t) * 0.45;
    final rim = math.sin(2 * math.pi * 680 * t) * math.exp(-130.0 * t) * 0.60;
    final snap = math.sin(2 * math.pi * 2100 * t) * math.exp(-600.0 * t) * 0.35;
    return amplitude * (shell + rim + snap);
  }

  static Uint8List _buildClickWav({
    required double frequency,
    double durationSeconds = 0.030,
    double amplitude = 0.8,
  }) {
    const sr = 44100;
    final n  = (sr * durationSeconds).round();
    return _buildWav(n, (i) {
      final t = i / sr;
      return amplitude * math.exp(-140.0 * t) * math.sin(2 * math.pi * frequency * t);
    });
  }

  static Uint8List _buildWav(int n, double Function(int) sample) {
    final dataSize = n * 2;
    final bd = ByteData(44 + dataSize);
    void str(int off, String s) {
      for (var i = 0; i < s.length; i++) { bd.setUint8(off + i, s.codeUnitAt(i)); }
    }
    const sr = 44100;
    str(0, 'RIFF'); bd.setUint32(4, 36 + dataSize, Endian.little);
    str(8, 'WAVE'); str(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1,  Endian.little);
    bd.setUint16(22, 1,  Endian.little);
    bd.setUint32(24, sr, Endian.little);
    bd.setUint32(28, sr * 2, Endian.little);
    bd.setUint16(32, 2,  Endian.little);
    bd.setUint16(34, 16, Endian.little);
    str(36, 'data'); bd.setUint32(40, dataSize, Endian.little);
    for (var i = 0; i < n; i++) {
      final s16 = (sample(i) * 32767).round().clamp(-32768, 32767);
      bd.setInt16(44 + i * 2, s16, Endian.little);
    }
    return bd.buffer.asUint8List();
  }
}
