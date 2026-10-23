import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Where the guided player puts its rendered bars (seam for tests).
abstract class PcmSink {
  /// Prepares a fresh mono Float32 stream at [sampleRate] that can hold
  /// [maxBuffer] of audio (preserved buffering keeps every sample).
  Future<void> open(int sampleRate, {required Duration maxBuffer});

  /// Appends mono Float32 samples; playback starts with the first append.
  /// false = the samples were not taken (no stream, buffer full, engine
  /// error); the caller must stop appending.
  bool append(Float32List pcm);

  /// No more data follows; the stream ends after the appended audio.
  void markEnded();

  /// Play position in ms since the first appended sample.
  double positionMs();
  void pause(bool paused);
  Future<void> close();
}

/// The SoLoud calls [SoloudPcmSink] makes (seam for tests: host tests have
/// no FFI). Sources and handles are opaque.
abstract class SoloudStreamApi {
  bool get isReady;
  Future<void> init();
  Object openStream(int sampleRate, Duration maxBuffer);
  void addData(Object source, Uint8List bytes);
  Future<Object> play(Object source, {required bool paused});
  void setPause(Object handle, bool paused);
  void setDataIsEnded(Object source);
  bool isValidHandle(Object handle);
  Duration position(Object handle);
  Future<void> stop(Object handle);
  Future<void> disposeSource(Object source);
}

/// [SoloudStreamApi] on [SoLoud.instance].
class _RealSoloud implements SoloudStreamApi {
  const _RealSoloud();
  SoLoud get _s => SoLoud.instance;

  @override
  bool get isReady {
    try {
      return _s.isInitialized;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> init() => _s.init();
  @override
  Object openStream(int sampleRate, Duration maxBuffer) => _s.setBufferStream(
        maxBufferSizeDuration: maxBuffer,
        bufferingType: BufferingType.preserved,
        bufferingTimeNeeds: 0.1,
        sampleRate: sampleRate,
        channels: Channels.mono,
        format: BufferType.f32le,
      );
  @override
  void addData(Object source, Uint8List bytes) =>
      _s.addAudioDataStream(source as AudioSource, bytes);
  @override
  Future<Object> play(Object source, {required bool paused}) async =>
      _s.play(source as AudioSource, paused: paused);
  @override
  void setPause(Object handle, bool paused) =>
      _s.setPause(handle as SoundHandle, paused);
  @override
  void setDataIsEnded(Object source) =>
      _s.setDataIsEnded(source as AudioSource);
  @override
  bool isValidHandle(Object handle) =>
      _s.getIsValidVoiceHandle(handle as SoundHandle);
  @override
  Duration position(Object handle) => _s.getPosition(handle as SoundHandle);
  @override
  Future<void> stop(Object handle) => _s.stop(handle as SoundHandle);
  @override
  Future<void> disposeSource(Object source) =>
      _s.disposeSource(source as AudioSource);
}

/// [PcmSink] on a SoLoud buffer stream with the spike's parameters
/// (docs/BERICHT_GEFUEHRT_SPIKE.md): f32le mono, preserved buffering
/// (getPosition is the run clock; Ruling R13), 0.1 s buffering threshold.
/// Every SoLoud call is guarded: a stalled or missing audio engine (host
/// tests have no FFI) must never block or throw.
///
/// SoLoud's buffer stream unpauses its voice when data arrives or the data
/// is marked ended (BufferStream::checkBuffering). The player does not
/// append while paused; as a second guard [append] and [markEnded]
/// re-apply the pause right after the SoLoud call.
class SoloudPcmSink implements PcmSink {
  SoloudPcmSink({SoloudStreamApi? api}) : _api = api ?? const _RealSoloud();

  final SoloudStreamApi _api;
  Object? _source;
  Object? _handle;
  bool _playRequested = false;
  bool _ended = false;
  bool _paused = false;
  int _samples = 0;
  int _sampleRate = 44100;
  double _lastPosMs = 0;
  int _generation = 0;

  bool get _ready => _api.isReady;

  @override
  Future<void> open(int sampleRate, {required Duration maxBuffer}) async {
    await close();
    final gen = _generation;
    _sampleRate = sampleRate;
    try {
      if (!_ready) await _api.init().timeout(const Duration(seconds: 5));
      // A close() (or a second open) came while SoLoud started: that one
      // owns the sink now.
      if (gen != _generation || !_ready) return;
      _source = _api.openStream(sampleRate, maxBuffer);
    } catch (_) {
      _source = null;
    }
  }

  @override
  bool append(Float32List pcm) {
    final src = _source;
    if (src == null || !_ready) return false;
    try {
      _api.addData(
          src, pcm.buffer.asUint8List(pcm.offsetInBytes, pcm.lengthInBytes));
      _samples += pcm.length;
    } catch (_) {
      return false;
    }
    _keepPaused();
    _ensurePlaying();
    return true;
  }

  /// Starts the voice after the first append; also retries a play() that
  /// timed out (on the next append, resume or position read).
  void _ensurePlaying() {
    final src = _source;
    if (_playRequested || _handle != null || src == null || _samples == 0) {
      return;
    }
    _playRequested = true;
    unawaited(_play(src));
  }

  /// Re-applies a pause that the last SoLoud call may have lifted.
  void _keepPaused() {
    final h = _handle;
    if (!_paused || h == null) return;
    try {
      _api.setPause(h, true);
    } catch (_) {}
  }

  Future<void> _play(Object src) async {
    final gen = _generation;
    final startPaused = _paused;
    try {
      final h = await _api
          .play(src, paused: startPaused)
          .timeout(const Duration(seconds: 2));
      if (gen != _generation) {
        unawaited(_api.stop(h).catchError((_) {}));
        return;
      }
      _handle = h;
      // A pause(true/false) that came while play() was pending.
      if (_paused != startPaused) _api.setPause(h, _paused);
    } catch (_) {
      if (gen == _generation) _playRequested = false; // retried later
    }
  }

  @override
  void markEnded() {
    final src = _source;
    _ended = true;
    if (src == null || !_ready) return;
    try {
      _api.setDataIsEnded(src);
    } catch (_) {}
    _keepPaused();
  }

  @override
  double positionMs() {
    if (!_ready) return _lastPosMs;
    final h = _handle;
    if (h == null) {
      _ensurePlaying();
      return _lastPosMs;
    }
    try {
      if (!_api.isValidHandle(h)) {
        // An ended stream drops its voice: it played everything.
        if (_ended) _lastPosMs = _samples * 1000 / _sampleRate;
        return _lastPosMs;
      }
      _lastPosMs = _api.position(h).inMicroseconds / 1000.0;
    } catch (_) {}
    return _lastPosMs;
  }

  @override
  void pause(bool paused) {
    _paused = paused;
    if (!_ready) return;
    final h = _handle;
    if (h == null) {
      // Pausing before the voice exists: play() starts it paused, or
      // applies this once it returns. Resuming retries a timed-out play.
      if (!paused) _ensurePlaying();
      return;
    }
    try {
      _api.setPause(h, paused);
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    _generation++;
    final h = _handle;
    final s = _source;
    _handle = null;
    _source = null;
    _playRequested = false;
    _ended = false;
    _paused = false;
    _samples = 0;
    _lastPosMs = 0;
    if (!_ready) return;
    if (h != null) {
      try {
        await _api.stop(h).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    if (s != null) {
      try {
        unawaited(_api
            .disposeSource(s)
            .timeout(const Duration(seconds: 2))
            .catchError((_) {}));
      } catch (_) {}
    }
  }
}
