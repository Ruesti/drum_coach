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
  rim(label: 'Rim'),
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
  AudioSource? _rimAccent;
  AudioSource? _rimNormal;
  AudioSource? _snareAccent;
  AudioSource? _snareNormal;

  int _bpm = 100;
  Subdivision _subdivision = Subdivision.quarter;
  SoundType _soundType = SoundType.click;
  List<double>? _beatVolumes; // null = use subdivision-based accent logic
  bool _isPlaying = false;
  int _beatCount = 0;
  final Stopwatch _stopwatch = Stopwatch();
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
    _rimAccent = await SoLoud.instance.loadMem(
      'rim_accent',
      _buildRimWav(amplitude: 0.95),
    );
    _rimNormal = await SoLoud.instance.loadMem(
      'rim_normal',
      _buildRimWav(amplitude: 0.55),
    );
    _snareAccent = await SoLoud.instance.loadMem(
      'snare_accent',
      _buildSnareWav(amplitude: 0.95),
    );
    _snareNormal = await SoLoud.instance.loadMem(
      'snare_normal',
      _buildSnareWav(amplitude: 0.55),
    );
  }

  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _beatCount = 0;
    _stopwatch
      ..reset()
      ..start();
    _scheduleNext();
  }

  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
  }

  void setBpm(int bpm) => _bpm = bpm.clamp(40, 240);
  void setSubdivision(Subdivision subdivision) => _subdivision = subdivision;
  void setSoundType(SoundType soundType) => _soundType = soundType;
  void setBeatVolumes(List<double>? volumes) => _beatVolumes = volumes;

  void dispose() {
    stop();
    if (!_beatController.isClosed) _beatController.close();
    for (final s in [
      _clickAccent, _clickNormal,
      _rimAccent, _rimNormal,
      _snareAccent, _snareNormal,
    ]) {
      s?.let((src) => SoLoud.instance.disposeSource(src).ignore());
    }
  }

  void _scheduleNext() {
    if (!_isPlaying) return;
    final intervalUs = 60000000.0 / _bpm / _subdivision.factor;
    final expectedUs = (_beatCount * intervalUs).round();
    final delayUs = (expectedUs - _stopwatch.elapsedMicroseconds)
        .clamp(500, intervalUs.round() * 2);
    _timer = Timer(Duration(microseconds: delayUs), _onBeat);
  }

  void _onBeat() {
    if (!_isPlaying) return;

    // Pattern-based volume takes priority; fall back to subdivision accent.
    final double volume;
    final bool isAccent;
    if (_beatVolumes != null && _beatVolumes!.isNotEmpty) {
      volume = _beatVolumes![_beatCount % _beatVolumes!.length];
      // Treat any beat louder than the normal threshold as an accent.
      isAccent = volume >= 1.2;
    } else {
      isAccent = _beatCount % _subdivision.factor == 0;
      volume = isAccent ? 2.0 : 0.7;
    }

    final source = switch ((_soundType, isAccent)) {
      (SoundType.click, true)  => _clickAccent,
      (SoundType.click, false) => _clickNormal,
      (SoundType.rim,   true)  => _rimAccent,
      (SoundType.rim,   false) => _rimNormal,
      (SoundType.snare, true)  => _snareAccent,
      (SoundType.snare, false) => _snareNormal,
    };

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

  // Rim shot: shell resonance + rim click — sounds like a practice-pad tap.
  static Uint8List _buildRimWav({double amplitude = 0.8}) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * 0.10).round(); // 100 ms
    return _buildWav(numSamples, (i) {
      final t = i / sampleRate;
      final shell = math.sin(2 * math.pi * 280 * t) * math.exp(-55.0 * t) * 0.45;
      final rim   = math.sin(2 * math.pi * 680 * t) * math.exp(-130.0 * t) * 0.60;
      final snap  = math.sin(2 * math.pi * 2100 * t) * math.exp(-600.0 * t) * 0.35;
      return amplitude * (shell + rim + snap);
    });
  }

  // Snare: colored noise body + sharp transient + tonal crack.
  static Uint8List _buildSnareWav({double amplitude = 0.8}) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * 0.15).round(); // 150 ms

    // Build colored (warm) noise up front so the lambda can close over it.
    final colored = List<double>.filled(numSamples, 0);
    var prev1 = 0.0, prev2 = 0.0;
    final rng = math.Random(42);
    for (var i = 0; i < numSamples; i++) {
      final n = rng.nextDouble() * 2 - 1;
      colored[i] = n * 0.6 + prev1 * 0.3 + prev2 * 0.1;
      prev2 = prev1;
      prev1 = n;
    }
    var mx = 0.0;
    for (final v in colored) {
      if (v.abs() > mx) { mx = v.abs(); }
    }
    if (mx > 0) {
      for (var i = 0; i < numSamples; i++) { colored[i] /= mx; }
    }

    return _buildWav(numSamples, (i) {
      final t = i / sampleRate;
      // Sharp transient in first 8 ms
      final transient = t < 0.008
          ? math.sin(math.pi * t / 0.008) * 0.75
          : 0.0;
      final noise = colored[i] * math.exp(-20.0 * t);
      final body  = math.sin(2 * math.pi * 195 * t) * math.exp(-45.0 * t) * 0.28;
      return amplitude * (transient + 0.55 * noise + body);
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
