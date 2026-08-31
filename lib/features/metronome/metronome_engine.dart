import 'dart:async';
import 'dart:isolate';
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

/// Playback volume for tick [index]: from the per-tick pattern array if one
/// is set, otherwise a flat accent/normal volume. A tick with volume 0 is
/// silent — no sound, and (per [MetronomeEngine._onBeat]) no [BeatEvent], so
/// grid-filler ticks in fine-grained pattern playback don't drive the UI's
/// beat indicator. Pure so it's unit-testable without SoLoud/isolates.
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

// ── Timing isolate ────────────────────────────────────────────────────────────
// Runs in its own isolate so Flutter's UI frame schedule cannot delay beats.
//
// Commands  (main → isolate): List<int> [cmdId, ...args]
// Beat msgs (isolate → main): List<int> [beatIndex, isAccent 0|1]

const _cmdStart  = 0; // [0, bpm, subdivisionFactor]
const _cmdStop   = 1; // [1]
const _cmdBpm    = 2; // [2, bpm]
const _cmdFactor = 3; // [3, subdivisionFactor]

/// Microsecond delay until beat [idx] should fire, given the current tempo
/// ([bpm]/[factor]) and an anchor point ([anchorUs], [anchorIdx]) the
/// schedule is measured from. Re-anchoring on every bpm/factor change (see
/// `_cmdBpm`/`_cmdFactor` below) is what makes a live tempo change take
/// effect from *now* instead of retroactively rewriting the timing of beats
/// already played — using `idx * interval` unconditionally (anchored at
/// idx=0) would compute a wildly wrong expected time for any idx reached
/// under a *different*, earlier tempo.
///
/// Clamped so a beat never fires earlier than 100 µs from now (avoids a
/// zero/negative `Timer` duration) and never waits longer than one full
/// interval (avoids stalling if the clock is far behind schedule).
///
/// Pure and isolate-independent so it's unit-testable directly.
int computeNextBeatDelayUs({
  required int bpm,
  required int factor,
  required int idx,
  required int anchorUs,
  required int anchorIdx,
  required int elapsedUs,
}) {
  final ivUs = 60000000.0 / bpm / factor;
  final expUs = (anchorUs + (idx - anchorIdx) * ivUs).round();
  return (expUs - elapsedUs).clamp(100, ivUs.ceil());
}

// Top-level required by Isolate.spawn.
void _timingIsolateMain(SendPort replyPort) {
  final port = ReceivePort();
  replyPort.send(port.sendPort); // give main the control port

  var bpm    = 100;
  var factor = 1;
  var playing = false;
  var idx     = 0;
  final sw    = Stopwatch();
  Timer? t;

  // See computeNextBeatDelayUs doc comment.
  var anchorUs  = 0;
  var anchorIdx = 0;

  // Mutual recursion via late variable — required because Dart forbids
  // a local function referencing another that isn't declared yet.
  late void Function() sched;

  void onBeat() {
    if (!playing) return;
    replyPort.send([idx, idx % factor == 0 ? 1 : 0]);
    idx++;
    sched();
  }

  sched = () {
    if (!playing) return;
    final delayUs = computeNextBeatDelayUs(
      bpm: bpm,
      factor: factor,
      idx: idx,
      anchorUs: anchorUs,
      anchorIdx: anchorIdx,
      elapsedUs: sw.elapsedMicroseconds,
    );
    t = Timer(Duration(microseconds: delayUs), onBeat);
  };

  port.listen((msg) {
    if (msg is! List<int>) return;
    switch (msg[0]) {
      case _cmdStart:
        if (playing) return;
        bpm = msg[1]; factor = msg[2];
        playing = true; idx = 0;
        anchorUs = 0; anchorIdx = 0;
        sw..reset()..start();
        onBeat(); // first beat fires immediately, rest are timer-driven
      case _cmdStop:
        playing = false; t?.cancel(); sw.stop();
      case _cmdBpm:
        if (playing) { anchorUs = sw.elapsedMicroseconds; anchorIdx = idx; }
        bpm = msg[1];
      case _cmdFactor:
        if (playing) { anchorUs = sw.elapsedMicroseconds; anchorIdx = idx; }
        factor = msg[1];
    }
  });
}

// ── MetronomeEngine ───────────────────────────────────────────────────────────

class MetronomeEngine {
  final _beatCtrl = StreamController<BeatEvent>.broadcast();
  Stream<BeatEvent> get beatStream => _beatCtrl.stream;

  AudioSource? _clickAccent, _clickNormal;
  AudioSource? _rimAccent,   _rimNormal;
  AudioSource? _snareAccent, _snareNormal;

  int          _bpm        = 100;
  Subdivision  _subdivision = Subdivision.quarter;
  int          _factor      = 1; // active ticks-per-quarter (subdivision or pattern clock)
  SoundType    _soundType   = SoundType.click;
  List<double>? _beatVolumes;
  bool          _isPlaying  = false;
  bool          _disposed   = false;

  Isolate?      _isolate;
  ReceivePort?  _receivePort;
  SendPort?     _controlPort;

  Future<void> init() async {
    _clickAccent = await SoLoud.instance.loadMem(
        'click_accent', _buildClickWav(frequency: 1200, amplitude: 0.95));
    _clickNormal = await SoLoud.instance.loadMem(
        'click_normal', _buildClickWav(frequency: 800,  amplitude: 0.55));
    _rimAccent   = await SoLoud.instance.loadMem(
        'rim_accent',   _buildRimWav(amplitude: 0.95));
    _rimNormal   = await SoLoud.instance.loadMem(
        'rim_normal',   _buildRimWav(amplitude: 0.55));
    _snareAccent = await SoLoud.instance.loadMem(
        'snare_accent', _buildSnareWav(amplitude: 0.95));
    _snareNormal = await SoLoud.instance.loadMem(
        'snare_normal', _buildSnareWav(amplitude: 0.55));

    if (_disposed) return;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_timingIsolateMain, _receivePort!.sendPort);

    final ready = Completer<void>();
    _receivePort!.listen((msg) {
      if (msg is SendPort) {
        _controlPort = msg;
        if (!ready.isCompleted) ready.complete();
      } else if (msg is List<int> && _isPlaying) {
        _onBeat(msg[0], msg[1] == 1);
      }
    });
    await ready.future;
  }

  void _onBeat(int index, bool isAccent) {
    if (!_isPlaying || _disposed) return;

    final volume = resolveTickVolume(
      beatVolumes: _beatVolumes,
      index: index,
      isAccent: isAccent,
    );
    final useAccentSrc = _beatVolumes != null && _beatVolumes!.isNotEmpty
        ? volume >= 1.2
        : isAccent;

    final source = switch ((_soundType, useAccentSrc)) {
      (SoundType.click, true)  => _clickAccent,
      (SoundType.click, false) => _clickNormal,
      (SoundType.rim,   true)  => _rimAccent,
      (SoundType.rim,   false) => _rimNormal,
      (SoundType.snare, true)  => _snareAccent,
      (SoundType.snare, false) => _snareNormal,
    };

    if (volume <= 0) return; // silent grid tick — no sound, no UI trigger

    if (source != null && SoLoud.instance.isInitialized) {
      SoLoud.instance.play(source, volume: volume).ignore();
    }

    _beatCtrl.add(BeatEvent(
      beatIndex: index,
      isAccent: isAccent,
      subdivision: _subdivision,
    ));
  }

  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _controlPort?.send([_cmdStart, _bpm, _factor]);
  }

  void stop() {
    _isPlaying = false;
    _controlPort?.send([_cmdStop]);
  }

  void setBpm(int bpm) {
    _bpm = bpm.clamp(40, 240);
    _controlPort?.send([_cmdBpm, _bpm]);
  }

  void setSubdivision(Subdivision subdivision) {
    _subdivision = subdivision;
    _factor = subdivision.factor;
    _controlPort?.send([_cmdFactor, _factor]);
  }

  /// Set an arbitrary integer tick factor for pattern playback (e.g. 24
  /// ticks/quarter), bypassing the [Subdivision] enum. The timing isolate
  /// already treats `factor` generically.
  void setPatternClock(int ticksPerQuarter) {
    _factor = ticksPerQuarter;
    _controlPort?.send([_cmdFactor, _factor]);
  }

  void setSoundType(SoundType t)      => _soundType   = t;
  void setBeatVolumes(List<double>? v) => _beatVolumes = v;

  void dispose() {
    _disposed  = true;
    _isPlaying = false;
    _controlPort?.send([_cmdStop]);
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    if (!_beatCtrl.isClosed) _beatCtrl.close();
    for (final s in [
      _clickAccent, _clickNormal,
      _rimAccent,   _rimNormal,
      _snareAccent, _snareNormal,
    ]) {
      s?.let((src) => SoLoud.instance.disposeSource(src).ignore());
    }
  }

  // ── Sound synthesis ─────────────────────────────────────────────────────────

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

  static Uint8List _buildRimWav({double amplitude = 0.8}) {
    const sr = 44100;
    final n  = (sr * 0.10).round();
    return _buildWav(n, (i) {
      final t     = i / sr;
      final shell = math.sin(2 * math.pi * 280  * t) * math.exp( -55.0 * t) * 0.45;
      final rim   = math.sin(2 * math.pi * 680  * t) * math.exp(-130.0 * t) * 0.60;
      final snap  = math.sin(2 * math.pi * 2100 * t) * math.exp(-600.0 * t) * 0.35;
      return amplitude * (shell + rim + snap);
    });
  }

  static Uint8List _buildSnareWav({double amplitude = 0.8}) {
    const sr = 44100;
    final n  = (sr * 0.15).round();

    // Coloured noise: simple IIR low-pass for warmth.
    final noise = List<double>.filled(n, 0);
    var p1 = 0.0, p2 = 0.0;
    final rng = math.Random(42);
    for (var i = 0; i < n; i++) {
      final x = rng.nextDouble() * 2 - 1;
      noise[i] = x * 0.6 + p1 * 0.3 + p2 * 0.1;
      p2 = p1; p1 = x;
    }
    var mx = 0.0;
    for (final v in noise) { if (v.abs() > mx) { mx = v.abs(); } }
    if (mx > 0) { for (var i = 0; i < n; i++) { noise[i] /= mx; } }

    return _buildWav(n, (i) {
      final t         = i / sr;
      final transient = t < 0.008 ? math.sin(math.pi * t / 0.008) * 0.75 : 0.0;
      final body      = math.sin(2 * math.pi * 195 * t) * math.exp(-45.0 * t) * 0.28;
      return amplitude * (transient + 0.55 * noise[i] + body);
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

extension _NullableExt<T> on T? {
  void let(void Function(T) fn) {
    if (this != null) fn(this as T);
  }
}
