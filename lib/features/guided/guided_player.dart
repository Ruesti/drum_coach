import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../shared/widgets/kit_layout.dart';
import 'bar_render_backend.dart';
import 'models/guided_exercise.dart';
import 'models/voice_clip.dart';
import 'pcm_sink.dart';
import 'run_clock.dart';
import 'run_plan.dart';

const int guidedMinBpm = 40;
const int guidedMaxBpm = 240;
const int guidedSampleRate = 44100;

/// Countdown click accent with the teacher off (buildRun's value).
const double _teacherOffAccent = 1.5;

/// Crash level per package: quieter on the pad (Spec §3.5).
double crashGainFor(GuidedPackage p) => p == GuidedPackage.pad ? 0.4 : 1.0;

/// Plays a guided exercise: renders the planned bars one at a time (on a
/// background isolate by default), appends them to a [PcmSink] ahead of
/// the play position and publishes the position (section / bar / beat)
/// from the sink's play clock.
///
/// Lookahead: at least [minQueuedMs] of audio past the play position, so
/// the queue covers the worst render time at any tempo (1 bar = 1 s at
/// 240 bpm). [lookaheadBars] (default 0, Ruling R16) can demand whole bars
/// on top; with 0 the lookahead is purely time-based, so a tempo change
/// lands on the next bar (Spec §3.3) whenever that bar is not rendered yet.
///
/// Pause (user or frozen): nothing is appended while paused — SoLoud's
/// buffer stream would unpause the voice on new data. A bar whose render
/// was in flight is held and appended on [resume].
///
/// Tempo / option changes (Ruling R7): bars already rendered are never
/// touched. The not yet rendered bars of the section that is playing are
/// kept and re-stamped with the new tempo; turning the teacher off drops
/// their voice clips, turning play-along off swaps their line for a quarter
/// click. Turning teacher or play-along ON takes effect from the next
/// section (the kept bars cannot gain clips or a line without replanning
/// the section). Everything after the section is replanned with [buildRun].
class GuidedPlayer {
  GuidedPlayer({
    required PcmSink sink,
    required ClipManifest clips,
    required Future<VoiceClip> Function(String id) loadClip,
    required Map<RunSound, List<double>> sounds,
    this.lookaheadBars = 0,
    this.minQueuedMs = 1200,
    BarRenderBackend? renderer,
    bool autoPoll = true,
    DateTime Function()? now,
  })  : _sink = sink,
        _clips = clips,
        _loadClip = loadClip,
        _sounds = sounds,
        _renderer = renderer ?? IsolateBarRenderBackend(),
        _autoPoll = autoPoll,
        _now = now ?? DateTime.now;

  final PcmSink _sink;
  final ClipManifest _clips;
  final Future<VoiceClip> Function(String id) _loadClip;
  final Map<RunSound, List<double>> _sounds;
  final BarRenderBackend _renderer;
  final bool _autoPoll;
  final DateTime Function() _now;
  final int lookaheadBars;
  final double minQueuedMs;

  /// Debug builds only (the listening page turns it on inside an assert):
  /// prints the render time of every bar.
  static bool debugLogRenderTimes = false;

  static const _pollInterval = Duration(milliseconds: 10);
  static const _frozenAfter = Duration(seconds: 1);

  final _positionCtrl = StreamController<RunPosition>.broadcast();
  final _finishedCtrl = StreamController<void>.broadcast();
  final _errorCtrl = StreamController<Object>.broadcast();
  final _stateCtrl = StreamController<void>.broadcast();

  GuidedExercise? _ex;
  int _bpm = 100;
  RunOptions _options = const RunOptions();
  bool _rendererReady = false;

  /// Planned, not yet rendered bars (front = next to render).
  final _queue = <RunBar>[];

  /// Last bar taken for rendering; its section is "the current section".
  RunBar? _committed;
  var _clock = RunClock();
  int _appendedSamples = 0;
  int _lastRenderedBar = -1;
  bool _running = false;
  bool _paused = false;
  bool _frozen = false;
  bool _ended = false;
  bool _finished = false;
  bool _failed = false;
  int _generation = 0;

  /// Counts start() calls, so a superseded start knows it is stale.
  int _starts = 0;
  Future<void>? _filling;
  Timer? _timer;

  /// Rendered while paused, appended on resume. [bar] null = the final
  /// carry flush (appended, then the stream is marked ended).
  ({RunBar? bar, Float32List pcm})? _held;

  double _lastPosMs = -1;
  DateTime _lastMoveAt = DateTime(0);
  RunPosition? _lastPosition;

  final _clipCache = <String, Float32List>{};
  final _clipLoads = <String, Future<void>>{};

  Stream<RunPosition> get positions => _positionCtrl.stream;
  Stream<void> get finished => _finishedCtrl.stream;

  /// A render error or a bar the sink refused. The run stops appending and
  /// polling (the audio already queued plays out); call [stop].
  Stream<Object> get errors => _errorCtrl.stream;
  int get bpm => _bpm;
  RunOptions get options => _options;
  bool get isPaused => _paused;
  bool get isRunning => _running;

  /// Paused because the play position stood still (stream reclaimed);
  /// [resume] continues. [stateChanges] fires when it turns on.
  bool get isFrozen => _frozen;

  /// Fires when the player changes state on its own (a frozen position
  /// paused the run), so a page can re-read [isFrozen] / [isPaused].
  Stream<void> get stateChanges => _stateCtrl.stream;

  double get _appendedMs => _appendedSamples * 1000 / guidedSampleRate;

  /// 40..240, narrowed to the exercise's range once one is set (Ruling R13:
  /// the stream is sized for a whole run at the exercise's minBpm).
  int _clampBpm(int bpm) {
    final ex = _ex;
    final lo = ex == null ? guidedMinBpm : math.max(guidedMinBpm, ex.minBpm);
    final hi = ex == null ? guidedMaxBpm : math.min(guidedMaxBpm, ex.maxBpm);
    return bpm.clamp(lo, math.max(lo, hi));
  }

  /// Stream capacity (Ruling R13): the whole run at the slowest allowed
  /// tempo, teacher on, × 1.25 + 30 s.
  Duration _bufferFor(GuidedExercise ex) {
    final slow = _clampBpm(ex.minBpm);
    final bars =
        buildRun(ex, bpm: slow, options: const RunOptions(), clips: _clips)
            .length;
    final ms = bars * guidedBeatsPerBar * 60000 / slow;
    return Duration(milliseconds: (ms * 1.25 + 30000).ceil());
  }

  Future<void> start(GuidedExercise ex,
      {required int bpm, required RunOptions options}) async {
    final myStart = ++_starts;
    // Set before awaiting: a setBpm/setOptions while start() runs is kept.
    _ex = ex;
    _bpm = _clampBpm(bpm);
    _options = options;
    await stop();
    final gen = _generation;
    var plannedBpm = _bpm;
    var plannedOptions = _options;
    _queue.addAll(buildRun(ex, bpm: _bpm, options: _options, clips: _clips));
    _preloadClips();
    try {
      // A render isolate that exited is not ready any more: init again.
      if (!_rendererReady || !_renderer.isReady) {
        _rendererReady = false;
        await _renderer.init(_sounds);
        _rendererReady = true;
      }
      _renderer.reset();
      await _sink.open(guidedSampleRate, maxBuffer: _bufferFor(ex));
    } catch (e) {
      if (gen == _generation) _fail(e);
      return;
    }
    if (gen != _generation) {
      // stop() came while we were opening: its close() ran before this
      // open finished, so close the stream we just made. A newer start()
      // opens the sink itself; leave that one alone.
      if (myStart == _starts) await _sink.close();
      return;
    }
    if (_bpm != plannedBpm ||
        _options.teacher != plannedOptions.teacher ||
        _options.playAlong != plannedOptions.playAlong) {
      // Changed while we were opening: nothing is rendered yet, replan all.
      plannedBpm = _bpm;
      plannedOptions = _options;
      _queue
        ..clear()
        ..addAll(buildRun(ex, bpm: _bpm, options: _options, clips: _clips));
      _preloadClips();
    }
    _running = true;
    _lastPosMs = -1;
    _lastMoveAt = _now();
    await _fill();
    _startTimer();
  }

  void setBpm(int bpm) {
    final b = _clampBpm(bpm);
    if (b == _bpm) return;
    _bpm = b;
    _replan();
  }

  void setOptions(RunOptions options) {
    if (options.teacher == _options.teacher &&
        options.playAlong == _options.playAlong) {
      return;
    }
    _options = options;
    _replan();
  }

  void pause() {
    if (!_running || _paused) return;
    _paused = true;
    _timer?.cancel();
    _sink.pause(true);
  }

  /// Ends a user pause or a pause forced by a frozen position. A bar
  /// rendered during the pause is appended first (the sink is still
  /// paused), then the sink resumes.
  void resume() {
    if (!_running || (!_paused && !_frozen)) return;
    _paused = false;
    _frozen = false;
    _appendHeld();
    _sink.pause(false);
    _lastMoveAt = _now();
    _startTimer();
  }

  Future<void> stop() async {
    _generation++;
    _timer?.cancel();
    _timer = null;
    final wasOpen = _running || _ex != null;
    _running = false;
    _paused = false;
    _frozen = false;
    _ended = false;
    _finished = false;
    _failed = false;
    _queue.clear();
    _committed = null;
    _clock = RunClock();
    _appendedSamples = 0;
    _lastRenderedBar = -1;
    _lastPosition = null;
    _filling = null;
    _held = null;
    if (wasOpen) await _sink.close();
  }

  /// Stops and releases the render isolate.
  Future<void> dispose() async {
    await stop();
    await _renderer.dispose();
    _rendererReady = false;
    await _positionCtrl.close();
    await _finishedCtrl.close();
    await _errorCtrl.close();
    await _stateCtrl.close();
  }

  void _fail(Object error) {
    if (_failed) return;
    _failed = true;
    _timer?.cancel();
    _errorCtrl.add(error);
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_autoPoll) return;
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(poll()));
  }

  /// One clock step: reads the play position, publishes a new tick, detects
  /// a frozen clock and the end, and tops up the lookahead. Runs every
  /// 10 ms; tests call it directly.
  @visibleForTesting
  Future<void> poll() async {
    if (!_running || _paused || _frozen || _finished || _failed) return;
    final pos = _sink.positionMs();
    final now = _now();
    if (pos != _lastPosMs) {
      _lastPosMs = pos;
      _lastMoveAt = now;
    } else if (now.difference(_lastMoveAt) >= _frozenAfter) {
      // Android reclaimed the stream (app in background, device switch):
      // the clock stands still while we would keep queueing. Pause and
      // wait for resume().
      _frozen = true;
      _timer?.cancel();
      _sink.pause(true);
      final last = _lastPosition;
      if (last != null) _positionCtrl.add(last);
      _stateCtrl.add(null);
      return;
    }
    final p = _clock.at(pos, now: now);
    final last = _lastPosition;
    if (p != null &&
        (last == null || p.bar != last.bar || p.tick != last.tick)) {
      _lastPosition = p;
      _positionCtrl.add(p);
    }
    if (_ended && pos >= _appendedMs - 0.5) {
      _finished = true;
      _timer?.cancel();
      _finishedCtrl.add(null);
      return;
    }
    await _fill();
  }

  /// Renders and appends bars until the lookahead is covered. Serial: a
  /// fill in progress is awaited instead of starting a second one.
  Future<void> _fill() {
    final f = _filling;
    if (f != null) return f;
    late final Future<void> next;
    next = _fillLoop().whenComplete(() {
      // A stale run's loop must not clear a newer run's fill.
      if (identical(_filling, next)) _filling = null;
    });
    _filling = next;
    return next;
  }

  Future<void> _fillLoop() async {
    final gen = _generation;
    while (_running && gen == _generation && !_ended && !_failed) {
      // Appending while paused would let SoLoud unpause the voice.
      if (_paused || _frozen) return;
      if (_held != null) {
        if (!_appendHeld()) return;
        continue;
      }
      final pos = math.max(0.0, _lastPosMs);
      final playing = _clock.at(pos)?.bar ?? 0;
      final needBars = _lastRenderedBar < playing + lookaheadBars;
      final needTime = _appendedMs - pos < minQueuedMs;
      if (!needBars && !needTime) return;
      if (_queue.isEmpty) {
        await _flushTail(gen);
        return;
      }
      final bar = _queue.removeAt(0); // committed: later changes skip it
      _committed = bar;
      final Float32List pcm;
      try {
        final job = await _jobFor(bar);
        if (gen != _generation) return;
        Stopwatch? sw;
        assert(() {
          if (debugLogRenderTimes) sw = Stopwatch()..start();
          return true;
        }());
        pcm = await _renderer.render(job);
        assert(() {
          final w = sw;
          if (w != null) {
            debugPrint('guided render bar ${bar.globalBar} '
                '(section ${bar.sectionIndex}, ${bar.bpm} bpm): '
                '${(w.elapsedMicroseconds / 1000).toStringAsFixed(1)} ms, '
                'queued ${(_appendedMs - pos).toStringAsFixed(0)} ms');
          }
          return true;
        }());
      } catch (e) {
        if (gen == _generation) _fail(e);
        return;
      }
      if (gen != _generation) return;
      if (_paused || _frozen) {
        // Paused while rendering: keep the bar (the renderer's carry has
        // moved on) and append it on resume.
        _held = (bar: bar, pcm: pcm);
        return;
      }
      if (!_appendBar(bar, pcm)) return;
      if (_queue.isEmpty) {
        await _flushTail(gen);
        return;
      }
    }
  }

  /// Appends [pcm] of [bar] and registers it on the run clock.
  bool _appendBar(RunBar bar, Float32List pcm) {
    if (!_sink.append(pcm)) {
      _fail(StateError('audio stream refused bar ${bar.globalBar}'));
      return false;
    }
    _clock.addBar(bar.globalBar, _appendedMs, bar.bpm, runTicksPerBar,
        sectionIndex: bar.sectionIndex, barInSection: bar.barInSection);
    _appendedSamples += pcm.length;
    _lastRenderedBar = bar.globalBar;
    return true;
  }

  /// After the last bar: appends what still rings past it (the final
  /// crash) and marks the stream ended. Held when a pause came meanwhile.
  Future<void> _flushTail(int gen) async {
    final Float32List tail;
    try {
      tail = await _renderer.flush();
    } catch (e) {
      if (gen == _generation) _fail(e);
      return;
    }
    if (gen != _generation) return;
    if (_paused || _frozen) {
      _held = (bar: null, pcm: tail);
      return;
    }
    _appendTail(tail);
  }

  /// The tail counts in [_appendedSamples] (the end is reached after it)
  /// but not on the run clock: it is no bar.
  bool _appendTail(Float32List tail) {
    if (tail.isNotEmpty) {
      if (!_sink.append(tail)) {
        _fail(StateError('audio stream refused the final tail'));
        return false;
      }
      _appendedSamples += tail.length;
    }
    _ended = true;
    _sink.markEnded();
    return true;
  }

  /// Appends the held bar or tail, if any; false on a refused append.
  bool _appendHeld() {
    final h = _held;
    if (h == null) return true;
    _held = null;
    final bar = h.bar;
    return bar == null ? _appendTail(h.pcm) : _appendBar(bar, h.pcm);
  }

  Future<BarJob> _jobFor(RunBar bar) async {
    final ids = [
      for (final e in bar.events)
        if (e is ClipEvent) e.clipId
    ];
    for (final id in ids) {
      await _loadOne(id);
      // A preload that failed is retried once for the bar that needs it.
      if (!_clipCache.containsKey(id)) await _loadOne(id);
    }
    return barJobFor(bar,
        clips: _clipCache, crashGain: crashGainFor(_ex!.package));
  }

  void _preloadClips() {
    for (final bar in _queue) {
      for (final e in bar.events) {
        if (e is ClipEvent && !_clipLoads.containsKey(e.clipId)) {
          unawaited(_loadOne(e.clipId));
        }
      }
    }
  }

  /// Loads a clip once. A failed load is forgotten (retried next time);
  /// the bar it was for plays without the clip.
  Future<void> _loadOne(String id) {
    final running = _clipLoads[id];
    if (running != null) return running;
    late final Future<void> load;
    load = Future<void>(() async {
      try {
        _clipCache[id] = (await _loadClip(id)).samples;
      } catch (_) {
        if (identical(_clipLoads[id], load)) _clipLoads.remove(id);
      }
    });
    _clipLoads[id] = load;
    return load;
  }

  /// Keeps the unrendered rest of the current section (re-stamped with the
  /// current tempo/options), replans everything after it.
  void _replan() {
    final ex = _ex;
    final cur = _committed;
    if (!_running || ex == null || cur == null || _ended) return;
    final section = cur.sectionIndex;
    final kept = [
      for (final b in _queue)
        if (b.sectionIndex == section) _restamp(b)
    ];
    final lastOfSection = kept.isEmpty ? cur : kept.last;
    final rest = buildRun(ex,
        bpm: _bpm,
        options: _options,
        clips: _clips,
        from: RunCursor(
          sectionIndex: section,
          barInSection: lastOfSection.barInSection,
          globalBar: lastOfSection.globalBar,
          sectionBars: lastOfSection.barInSection + 1,
        ));
    _queue
      ..clear()
      ..addAll(kept)
      ..addAll(rest);
    _preloadClips();
  }

  RunBar _restamp(RunBar b) {
    var events = b.events;
    var vols = b.tickVolumes;
    if (!_options.teacher) {
      events = List.unmodifiable(events.where((e) => e is! ClipEvent));
      // Without the voice the countdown clicks are accented, as in
      // buildRun's teacher-off path.
      final cd = [
        for (final e in b.events)
          if (e is CountdownEvent) e.tick
      ];
      final click = vols[RunSound.click];
      if (cd.isNotEmpty && click != null) {
        final c = List<double>.of(click);
        for (final t in cd) {
          if (c[t] > 0) c[t] = _teacherOffAccent;
        }
        vols = {...vols, RunSound.click: c};
      }
    }
    if (!_options.playAlong && !b.isCountIn) {
      final click = List<double>.of(
          vols[RunSound.click] ?? List<double>.filled(runTicksPerBar, 0.0));
      for (var q = 0; q < guidedBeatsPerBar; q++) {
        final t = q * kitTicksPerQuarter;
        if (click[t] <= 0) click[t] = 1.0;
      }
      vols = {RunSound.click: click};
    }
    return RunBar(
      globalBar: b.globalBar,
      sectionIndex: b.sectionIndex,
      barInSection: b.barInSection,
      bpm: _bpm,
      isCountIn: b.isCountIn,
      isCountdown: b.isCountdown,
      tickVolumes: vols,
      events: events,
    );
  }
}
