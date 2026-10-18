// SPIKE (Plan 1 Task 0) — throwaway, never merged.
//
// /debug/stream-spike: a SoLoud buffer stream (f32le mono 44100, preserved,
// bufferingTimeNeeds 0.1) fed bar by bar with ~1 bar lookahead. BPM ±10
// applies from the next rendered bar. "Auto 150" runs the fixed tempo plan
// (spikeAutoTempo) over 150 bars and logs measurements (tag SPIKE) to
// debugPrint and to <documents>/drum_coach_spike_log.txt.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path_provider/path_provider.dart';

import 'stream_spike_renderer.dart';

class StreamSpikeScreen extends StatefulWidget {
  const StreamSpikeScreen({super.key, this.autoStart = false});
  final bool autoStart;
  @override
  State<StreamSpikeScreen> createState() => _StreamSpikeScreenState();
}

class _StreamSpikeScreenState extends State<StreamSpikeScreen> {
  static const _totalBars = 150;
  static const _lookaheadBars = 1;

  SpikeStreamRenderer? _renderer;
  AudioSource? _source;
  SoundHandle? _handle;
  Timer? _pump;
  Timer? _ui;
  bool _auto = false;
  bool _running = false;
  int _bpm = 100;
  String _status = 'loading…';

  final List<SpikeBar> _bars = []; // metadata only (pcm dropped after push)
  int _pushedSamples = 0;
  int _bufferingEvents = 0;
  final List<String> _bufferingLog = [];
  double _lastPosMs = -1;
  int _positionPolls = 0;
  int _positionRegressions = 0;
  double _maxBackstepMs = 0;
  int _shownBar = 0;
  double _shownBeat = 0;
  double _posMs = 0;
  int _rssStartMb = 0;
  final Map<int, int> _rssAtBar = {};
  final List<String> _log = [];
  final Stopwatch _wall = Stopwatch();
  double _maxPushMs = 0;
  double _minLeadMs = double.infinity;
  bool _ended = false;

  List<double> _snare = const [];
  Float32List _clip = Float32List(0);
  List<Float32List> _count = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  int _rssMb() => ProcessInfo.currentRss ~/ (1024 * 1024);

  void _l(String s) {
    final line = '[${(_wall.elapsedMilliseconds / 1000).toStringAsFixed(2)}s] $s';
    _log.add(line);
    debugPrint('SPIKE $line');
  }

  Future<void> _load() async {
    try {
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init().timeout(const Duration(seconds: 5));
      }
      final snareBytes = (await rootBundle.load('assets/audio/snare.mp3'))
          .buffer
          .asUint8List();
      final probe = await SoLoud.instance
          .loadMem('spike_snare_probe', snareBytes)
          .timeout(const Duration(seconds: 5));
      final len = SoLoud.instance.getLength(probe);
      unawaited(SoLoud.instance.disposeSource(probe));
      final n = (len.inMicroseconds * 44100 / 1000000).round();
      _snare = List<double>.from(await SoLoud.instance
          .readSamplesFromMem(snareBytes, n)
          .timeout(const Duration(seconds: 5)));
      _clip = decodeWav16((await rootBundle.load('assets/audio/spike_clip.wav'))
          .buffer
          .asUint8List());
      _count = [
        for (final w in ['three', 'two', 'one', 'go'])
          decodeWav16((await rootBundle.load('assets/audio/spike_count_$w.wav'))
              .buffer
              .asUint8List())
      ];
      setState(() => _status =
          'ready (snare ${_snare.length} smp, clip ${(_clip.length / 44100).toStringAsFixed(2)} s)');
      if (widget.autoStart) unawaited(_start(auto: true));
    } catch (e) {
      setState(() => _status = 'load failed: $e');
    }
  }

  Future<void> _start({required bool auto}) async {
    await _stop();
    _auto = auto;
    _bpm = auto ? spikeAutoTempo[0]! : _bpm;
    _renderer = SpikeStreamRenderer(
        snarePcm: _snare, clipPcm: _clip, countPcm: _count);
    _bars.clear();
    _pushedSamples = 0;
    _bufferingEvents = 0;
    _bufferingLog.clear();
    _lastPosMs = -1;
    _positionPolls = 0;
    _positionRegressions = 0;
    _maxBackstepMs = 0;
    _rssAtBar.clear();
    _log.clear();
    _maxPushMs = 0;
    _minLeadMs = double.infinity;
    _ended = false;
    _wall
      ..reset()
      ..start();
    _rssStartMb = _rssMb();
    _l('start auto=$auto bpm=$_bpm rss=${_rssStartMb}MB');

    final src = SoLoud.instance.setBufferStream(
      maxBufferSizeDuration: const Duration(minutes: 10),
      bufferingType: BufferingType.preserved,
      bufferingTimeNeeds: 0.1,
      sampleRate: 44100,
      channels: Channels.mono,
      format: BufferType.f32le,
      onBuffering: (isBuffering, handle, time) {
        _bufferingEvents++;
        final s = 'onBuffering isBuffering=$isBuffering t=${time.toStringAsFixed(3)}s';
        _bufferingLog.add(s);
        _l(s);
      },
    );
    _source = src;
    // Prime: bar 0 + lookahead before play.
    for (var i = 0; i <= _lookaheadBars; i++) {
      _pushNextBar();
    }
    _handle = await SoLoud.instance.play(src).timeout(const Duration(seconds: 2));
    _running = true;
    _pump = Timer.periodic(const Duration(milliseconds: 20), (_) => _tick());
    _ui = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  void _pushNextBar() {
    final r = _renderer!;
    if (r.nextBarIndex >= _totalBars) {
      if (!_ended) {
        SoLoud.instance.setDataIsEnded(_source!);
        _ended = true;
        _l('setDataIsEnded after ${r.nextBarIndex} bars');
      }
      return;
    }
    if (_auto) _bpm = spikeAutoTempo[r.nextBarIndex] ?? _bpm;
    final sw = Stopwatch()..start();
    final bar = r.renderNext(_bpm);
    SoLoud.instance.addAudioDataStream(_source!, bar.pcm.buffer.asUint8List());
    final ms = sw.elapsedMicroseconds / 1000;
    if (ms > _maxPushMs) _maxPushMs = ms;
    _pushedSamples += bar.length;
    _bars.add(SpikeBar(bar.index, bar.bpm, bar.start, bar.length,
        Float32List(0), bar.clipStarts));
    if (bar.index == 0 || bar.index == 64 || bar.index == 149 || bar.index % 25 == 0) {
      _rssAtBar[bar.index] = _rssMb();
    }
    if (bar.index > 0 && (_bars[bar.index - 1].bpm != bar.bpm)) {
      _l('tempo ${_bars[bar.index - 1].bpm} -> ${bar.bpm} at bar ${bar.index}');
    }
  }

  ({int bar, double beat}) _barAt(int sample) {
    var lo = 0, hi = _bars.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_bars[mid].start <= sample) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final b = _bars[lo];
    return (bar: b.index, beat: (sample - b.start) / (b.length / 4.0));
  }

  void _tick() {
    final h = _handle;
    if (h == null || !_running) return;
    if (!SoLoud.instance.getIsValidVoiceHandle(h)) {
      _finish('handle ended');
      return;
    }
    final posMs = SoLoud.instance.getPosition(h).inMicroseconds / 1000.0;
    _positionPolls++;
    if (_lastPosMs >= 0 && posMs < _lastPosMs) {
      _positionRegressions++;
      final back = _lastPosMs - posMs;
      if (back > _maxBackstepMs) _maxBackstepMs = back;
      _l('position went back by ${back.toStringAsFixed(2)} ms at $posMs');
    }
    _lastPosMs = posMs;
    _posMs = posMs;
    final playedSample = (posMs * 44.1).round();
    final at = _barAt(playedSample);
    _shownBar = at.bar;
    _shownBeat = at.beat;
    // Keep >= lookahead bars rendered ahead of the play position.
    final lead = (_pushedSamples - playedSample) / 44.1;
    if (lead < _minLeadMs && _pushedSamples > 0 && !_ended) _minLeadMs = lead;
    while (!_ended &&
        _renderer!.nextBarIndex <= at.bar + _lookaheadBars) {
      _pushNextBar();
    }
    if (_ended && playedSample >= _pushedSamples - 441) {
      _finish('reached end');
    }
  }

  void _finish(String why) {
    if (!_running) return;
    _running = false;
    _rssAtBar[-1] = _rssMb();
    _l('finish ($why) bars=${_bars.length} pos=${_posMs.toStringAsFixed(0)} ms');
    _l('SUMMARY buffering=$_bufferingEvents polls=$_positionPolls '
        'regressions=$_positionRegressions maxBack=${_maxBackstepMs.toStringAsFixed(2)}ms '
        'maxRenderPush=${_maxPushMs.toStringAsFixed(1)}ms '
        'minLead=${_minLeadMs.toStringAsFixed(0)}ms '
        'rssStart=${_rssStartMb}MB rssAtBar=$_rssAtBar '
        'wall=${(_wall.elapsedMilliseconds / 1000).toStringAsFixed(1)}s '
        'audio=${(_pushedSamples / 44100).toStringAsFixed(1)}s');
    unawaited(_writeLog());
    if (mounted) setState(() {});
  }

  Future<void> _writeLog() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/drum_coach_spike_log.txt');
      await f.writeAsString('${_log.join('\n')}\n');
      _l('log written to ${f.path}');
    } catch (e) {
      _l('log write failed: $e');
    }
  }

  Future<void> _stop() async {
    _pump?.cancel();
    _ui?.cancel();
    if (_running) _finish('stopped');
    _running = false;
    final h = _handle;
    final s = _source;
    _handle = null;
    _source = null;
    if (h != null) {
      try {
        await SoLoud.instance.stop(h).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    if (s != null) unawaited(SoLoud.instance.disposeSource(s));
  }

  @override
  void dispose() {
    unawaited(_stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rendered = _renderer?.nextBarIndex ?? 0;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Stream spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_status, style: t.bodySmall),
          const SizedBox(height: 12),
          Text('$_bpm BPM', style: t.displayMedium),
          Text('bar ${_shownBar + 1} · beat ${(_shownBeat + 1).toStringAsFixed(2)}',
              style: t.headlineSmall),
          Text('rendered bars: $rendered / $_totalBars'),
          Text('getPosition: ${(_posMs / 1000).toStringAsFixed(3)} s'),
          Text('onBuffering events: $_bufferingEvents'),
          Text('position regressions: $_positionRegressions '
              '(polls $_positionPolls)'),
          Text('max render+push: ${_maxPushMs.toStringAsFixed(1)} ms · '
              'min lead: ${_minLeadMs.isFinite ? _minLeadMs.toStringAsFixed(0) : '-'} ms'),
          Text('RSS: start ${_rssStartMb} MB · now ${_rssMb()} MB · $_rssAtBar'),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            FilledButton(
                onPressed: _status.startsWith('ready')
                    ? () => _start(auto: true)
                    : null,
                child: const Text('Auto 150')),
            FilledButton(
                onPressed: _status.startsWith('ready')
                    ? () => _start(auto: false)
                    : null,
                child: const Text('Manual')),
            OutlinedButton(
                onPressed: () => setState(() => _bpm = (_bpm - 10).clamp(40, 240)),
                child: const Text('BPM −10')),
            OutlinedButton(
                onPressed: () => setState(() => _bpm = (_bpm + 10).clamp(40, 240)),
                child: const Text('BPM +10')),
            OutlinedButton(onPressed: _stop, child: const Text('Stop')),
          ]),
          const SizedBox(height: 16),
          for (final s in _log.reversed.take(30))
            Text(s, style: t.bodySmall?.copyWith(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
