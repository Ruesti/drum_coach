import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

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

class BeatEvent {
  final int beatIndex;
  final bool isAccent;
  final Subdivision subdivision;

  const BeatEvent({
    required this.beatIndex,
    required this.isAccent,
    required this.subdivision,
  });
}

class MetronomeEngine {
  final _beatController = StreamController<BeatEvent>.broadcast();
  Stream<BeatEvent> get beatStream => _beatController.stream;

  AudioSource? _clickAccent;
  AudioSource? _clickNormal;

  int _bpm = 100;
  Subdivision _subdivision = Subdivision.quarter;
  bool _isPlaying = false;
  int _beatCount = 0;
  DateTime? _startTime;
  Timer? _timer;

  Future<void> init() async {
    _clickAccent = await SoLoud.instance.loadMem(
      'click_accent',
      _buildClickWav(frequency: 1200, amplitude: 0.9),
    );
    _clickNormal = await SoLoud.instance.loadMem(
      'click_normal',
      _buildClickWav(frequency: 800, amplitude: 0.6),
    );
  }

  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _beatCount = 0;
    _startTime = DateTime.now();
    _scheduleNext();
  }

  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
  }

  void setBpm(int bpm) => _bpm = bpm.clamp(40, 240);

  void setSubdivision(Subdivision subdivision) => _subdivision = subdivision;

  void dispose() {
    stop();
    if (!_beatController.isClosed) _beatController.close();
    _clickAccent?.let((s) => SoLoud.instance.disposeSource(s).ignore());
    _clickNormal?.let((s) => SoLoud.instance.disposeSource(s).ignore());
  }

  void _scheduleNext() {
    if (!_isPlaying) return;
    final intervalMs = 60000.0 / _bpm / _subdivision.factor;
    final expectedMs = _beatCount * intervalMs;
    final elapsedMs =
        DateTime.now().difference(_startTime!).inMicroseconds / 1000.0;
    final delayMs = (expectedMs - elapsedMs).clamp(1.0, intervalMs);
    _timer = Timer(Duration(milliseconds: delayMs.round()), _onBeat);
  }

  void _onBeat() {
    if (!_isPlaying) return;
    final isAccent = _beatCount % _subdivision.factor == 0;
    final source = isAccent ? _clickAccent : _clickNormal;
    if (source != null) {
      SoLoud.instance.play(source).then((handle) {
        Future.delayed(const Duration(milliseconds: 30), () {
          SoLoud.instance.stop(handle).ignore();
        });
      }).ignore();
    }
    _beatController.add(BeatEvent(
      beatIndex: _beatCount,
      isAccent: isAccent,
      subdivision: _subdivision,
    ));
    _beatCount++;
    _scheduleNext();
  }

  // Generates a short decaying sine wave as a WAV byte buffer.
  static Uint8List _buildClickWav({
    required double frequency,
    double durationSeconds = 0.025,
    double amplitude = 0.8,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationSeconds).round();
    final dataSize = numSamples * 2;
    final bd = ByteData(44 + dataSize);

    void str(int off, String s) {
      for (var i = 0; i < s.length; i++) {
        bd.setUint8(off + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    bd.setUint32(4, 36 + dataSize, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little); // PCM
    bd.setUint16(22, 1, Endian.little); // mono
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    str(36, 'data');
    bd.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final decay = math.exp(-150.0 * t);
      final sample = amplitude * decay * math.sin(2 * math.pi * frequency * t);
      final s16 = (sample * 32767).round().clamp(-32768, 32767);
      bd.setInt16(44 + i * 2, s16, Endian.little);
    }

    return bd.buffer.asUint8List();
  }
}

extension _NullableExt<T> on T? {
  void let(void Function(T) fn) {
    if (this != null) fn(this as T);
  }
}
