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

enum SoundType {
  click(label: 'Click'),
  snare(label: 'Snare');

  final String label;
  const SoundType({required this.label});
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
  AudioSource? _snareAccent;
  AudioSource? _snareNormal;

  int _bpm = 100;
  Subdivision _subdivision = Subdivision.quarter;
  SoundType _soundType = SoundType.click;
  bool _isPlaying = false;
  int _beatCount = 0;
  DateTime? _startTime;
  Timer? _timer;

  Future<void> init() async {
    _clickAccent = await SoLoud.instance.loadMem(
      'click_accent',
      _buildClickWav(frequency: 1200, amplitude: 0.95),
    );
    _clickNormal = await SoLoud.instance.loadMem(
      'click_normal',
      _buildClickWav(frequency: 800, amplitude: 0.55),
    );
    _snareAccent = await SoLoud.instance.loadMem(
      'snare_accent',
      _buildSnareWav(amplitude: 0.95),
    );
    _snareNormal = await SoLoud.instance.loadMem(
      'snare_normal',
      _buildSnareWav(amplitude: 0.50),
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
  void setSoundType(SoundType soundType) => _soundType = soundType;

  void dispose() {
    stop();
    if (!_beatController.isClosed) _beatController.close();
    for (final s in [_clickAccent, _clickNormal, _snareAccent, _snareNormal]) {
      s?.let((src) => SoLoud.instance.disposeSource(src).ignore());
    }
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

    final source = switch ((_soundType, isAccent)) {
      (SoundType.click, true) => _clickAccent,
      (SoundType.click, false) => _clickNormal,
      (SoundType.snare, true) => _snareAccent,
      (SoundType.snare, false) => _snareNormal,
    };

    // Accents are notably louder than normal beats
    final volume = isAccent ? 2.0 : 0.7;

    if (source != null && SoLoud.instance.isInitialized) {
      SoLoud.instance.play(source, volume: volume).ignore();
    }

    _beatController.add(BeatEvent(
      beatIndex: _beatCount,
      isAccent: isAccent,
      subdivision: _subdivision,
    ));
    _beatCount++;
    _scheduleNext();
  }

  // Short decaying sine wave (click sound).
  static Uint8List _buildClickWav({
    required double frequency,
    double durationSeconds = 0.030,
    double amplitude = 0.8,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationSeconds).round();
    return _buildWav(numSamples, (i) {
      final t = i / sampleRate;
      final decay = math.exp(-140.0 * t);
      return amplitude * decay * math.sin(2 * math.pi * frequency * t);
    });
  }

  // Noise burst + tonal body + attack click (snare-like sound).
  static Uint8List _buildSnareWav({double amplitude = 0.8}) {
    const sampleRate = 44100;
    const durationSeconds = 0.07;
    final numSamples = (sampleRate * durationSeconds).round();
    final rng = math.Random(42);
    return _buildWav(numSamples, (i) {
      final t = i / sampleRate;
      final noise = (rng.nextDouble() * 2 - 1) * math.exp(-55.0 * t);
      final body = math.sin(2 * math.pi * 220 * t) * math.exp(-90.0 * t) * 0.3;
      final crack =
          math.sin(2 * math.pi * 1600 * t) * math.exp(-200.0 * t) * 0.45;
      return amplitude * (0.5 * noise + body + crack);
    });
  }

  static Uint8List _buildWav(int numSamples, double Function(int i) sample) {
    final dataSize = numSamples * 2;
    final bd = ByteData(44 + dataSize);
    void str(int off, String s) {
      for (var i = 0; i < s.length; i++) {
        bd.setUint8(off + i, s.codeUnitAt(i));
      }
    }

    const sampleRate = 44100;
    str(0, 'RIFF');
    bd.setUint32(4, 36 + dataSize, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    str(36, 'data');
    bd.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < numSamples; i++) {
      final s16 = (sample(i) * 32767).round().clamp(-32768, 32767);
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
