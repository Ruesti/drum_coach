import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Where the guided player puts its rendered bars (seam for tests).
abstract class PcmSink {
  /// Prepares a fresh mono Float32 stream at [sampleRate].
  Future<void> open(int sampleRate);

  /// Appends mono Float32 samples; playback starts with the first append.
  void append(Float32List pcm);

  /// No more data follows; the stream ends after the appended audio.
  void markEnded();

  /// Play position in ms since the first appended sample.
  double positionMs();
  void pause(bool paused);
  Future<void> close();
}

/// [PcmSink] on a SoLoud buffer stream with the spike's parameters
/// (docs/BERICHT_GEFUEHRT_SPIKE.md): f32le mono, preserved buffering,
/// 0.1 s buffering threshold. Every SoLoud call is guarded: a stalled or
/// missing audio engine (host tests have no FFI) must never block or throw.
class SoloudPcmSink implements PcmSink {
  AudioSource? _source;
  SoundHandle? _handle;
  bool _playRequested = false;
  bool _ended = false;
  bool _paused = false;
  int _samples = 0;
  int _sampleRate = 44100;
  double _lastPosMs = 0;
  int _generation = 0;

  static bool get _soloudReady {
    try {
      return SoLoud.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> open(int sampleRate) async {
    await close();
    _sampleRate = sampleRate;
    try {
      if (!_soloudReady) {
        await SoLoud.instance.init().timeout(const Duration(seconds: 5));
      }
      if (!_soloudReady) return;
      _source = SoLoud.instance.setBufferStream(
        maxBufferSizeDuration: const Duration(minutes: 10),
        bufferingType: BufferingType.preserved,
        bufferingTimeNeeds: 0.1,
        sampleRate: sampleRate,
        channels: Channels.mono,
        format: BufferType.f32le,
      );
    } catch (_) {
      _source = null;
    }
  }

  @override
  void append(Float32List pcm) {
    final src = _source;
    if (src == null || !_soloudReady) return;
    try {
      SoLoud.instance.addAudioDataStream(
          src, pcm.buffer.asUint8List(pcm.offsetInBytes, pcm.lengthInBytes));
      _samples += pcm.length;
    } catch (_) {
      return;
    }
    if (!_playRequested) {
      _playRequested = true;
      unawaited(_play(src));
    }
  }

  Future<void> _play(AudioSource src) async {
    final gen = _generation;
    try {
      final h = await SoLoud.instance
          .play(src, paused: _paused)
          .timeout(const Duration(seconds: 2));
      if (gen != _generation) {
        unawaited(SoLoud.instance.stop(h).catchError((_) {}));
        return;
      }
      _handle = h;
    } catch (_) {
      _playRequested = false; // retried on the next append
    }
  }

  @override
  void markEnded() {
    final src = _source;
    _ended = true;
    if (src == null || !_soloudReady) return;
    try {
      SoLoud.instance.setDataIsEnded(src);
    } catch (_) {}
  }

  @override
  double positionMs() {
    final h = _handle;
    if (h == null || !_soloudReady) return _lastPosMs;
    try {
      if (!SoLoud.instance.getIsValidVoiceHandle(h)) {
        // An ended stream drops its voice: it played everything.
        if (_ended) _lastPosMs = _samples * 1000 / _sampleRate;
        return _lastPosMs;
      }
      _lastPosMs = SoLoud.instance.getPosition(h).inMicroseconds / 1000.0;
    } catch (_) {}
    return _lastPosMs;
  }

  @override
  void pause(bool paused) {
    _paused = paused;
    final h = _handle;
    if (h == null || !_soloudReady) return;
    try {
      SoLoud.instance.setPause(h, paused);
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
    if (!_soloudReady) return;
    if (h != null) {
      try {
        await SoLoud.instance.stop(h).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    if (s != null) {
      try {
        unawaited(SoLoud.instance
            .disposeSource(s)
            .timeout(const Duration(seconds: 2))
            .catchError((_) {}));
      } catch (_) {}
    }
  }
}
