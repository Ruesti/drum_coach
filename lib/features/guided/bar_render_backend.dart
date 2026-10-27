import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

import '../../shared/widgets/kit_layout.dart';
import '../metronome/click_loop_renderer.dart';
import 'bar_renderer.dart';
import 'run_plan.dart';

/// A one-shot sound of a [BarJob]: either a [sound] from the backend's
/// sample table (crash) or its own [samples] (voice clip).
class JobHit {
  const JobHit({required this.tick, this.sound, this.samples, this.gain = 1});
  final int tick;
  final RunSound? sound;
  final Float32List? samples;
  final double gain;
}

/// Everything needed to mix one bar; plain data so it can cross isolates.
class BarJob {
  const BarJob(
      {required this.bpm, required this.tickVolumes, this.hits = const []});
  final int bpm;
  final Map<RunSound, List<double>> tickVolumes;
  final List<JobHit> hits;
}

/// Turns a planned bar into a [BarJob]: [ClipEvent]s take their samples
/// from [clips] (a clip missing there is skipped), a [CrashEvent] plays the
/// crash at [crashGain], a [CountdownEvent] adds nothing (its clicks are in
/// the tick volumes).
BarJob barJobFor(RunBar bar,
    {required Map<String, Float32List> clips, required double crashGain}) {
  final hits = <JobHit>[];
  for (final e in bar.events) {
    switch (e) {
      case ClipEvent(:final clipId):
        final s = clips[clipId];
        if (s != null) hits.add(JobHit(tick: e.tick, samples: s));
      case CrashEvent():
        hits.add(JobHit(tick: e.tick, sound: RunSound.crash, gain: crashGain));
      case CountdownEvent():
        break;
    }
  }
  return BarJob(bpm: bar.bpm, tickVolumes: bar.tickVolumes, hits: hits);
}

/// Loud-sample threshold and track gain per sound. Pattern (pad lines) as
/// the loop's pattern voice. Kit voices: kick and hi-hat come on the band
/// scale (normal 0.7, accent 1.0), the rest on the pattern scale (normal
/// 0.85, accent 2.0, ghost 0.25) — the gains even that out into one kit
/// mix: kick and snare forward, hi-hat back, cymbals not on top (balance
/// measured with tool/render_guided_probe_test.dart, Optik-Runde 1). The snare
/// plays its ghost recording ([_softOf]) below 0.5, i.e. on ghost notes.
const _voiceSpec = <RunSound, ({double loudFrom, double gain})>{
  RunSound.pattern: (loudFrom: 1.2, gain: 1.0),
  RunSound.kick: (loudFrom: 1.0, gain: 1.2),
  RunSound.snare: (loudFrom: 0.5, gain: 0.5),
  RunSound.rim: (loudFrom: 1.0, gain: 0.5),
  RunSound.hihatClosed: (loudFrom: 1.0, gain: 0.7),
  RunSound.hihatOpen: (loudFrom: 1.0, gain: 0.5),
  RunSound.hihatPedal: (loudFrom: 1.0, gain: 0.5),
  RunSound.tomHigh: (loudFrom: 1.0, gain: 0.45),
  RunSound.tomLow: (loudFrom: 1.0, gain: 0.45),
  RunSound.tomFloor: (loudFrom: 1.0, gain: 0.45),
  RunSound.crash: (loudFrom: 1.0, gain: 0.9),
  RunSound.ride: (loudFrom: 1.0, gain: 0.6),
  RunSound.rideBell: (loudFrom: 1.0, gain: 0.65),
  RunSound.click: (loudFrom: 1.0, gain: 1.0),
};

/// The sample a sound plays below its `loudFrom` when it is not its own.
const _softOf = <RunSound, RunSound>{RunSound.snare: RunSound.snareGhost};

/// Mixes [job] with [renderer] (carry kept across calls). Sounds without
/// samples in [sounds] stay silent.
RenderedBar renderBarJob(
    BarRenderer renderer, Map<RunSound, List<double>> sounds, BarJob job) {
  final voices = <LoopVoice>[];
  job.tickVolumes.forEach((sound, vols) {
    final s = sounds[sound];
    final spec = _voiceSpec[sound];
    if (s == null || s.isEmpty || spec == null) return;
    final soft = sounds[_softOf[sound]];
    voices.add(LoopVoice(
      tickVolumes: vols,
      loudSamples: s,
      softSamples: soft == null || soft.isEmpty ? s : soft,
      loudFrom: spec.loudFrom,
      gain: spec.gain,
    ));
  });
  final hits = <SampleHit>[];
  for (final h in job.hits) {
    final s = h.samples ?? (h.sound == null ? null : sounds[h.sound]);
    if (s == null || s.isEmpty) continue;
    hits.add(SampleHit(tick: h.tick, samples: s, gain: h.gain));
  }
  return renderer.renderBar(
      bpm: job.bpm, factor: kitTicksPerQuarter, voices: voices, hits: hits);
}

/// Renders bars in order, keeping the carry between calls.
abstract class BarRenderBackend {
  Future<void> init(Map<RunSound, List<double>> sounds);
  Future<Float32List> render(BarJob job);

  /// The carry left after the last rendered bar (soft-limited, faded at its
  /// end; empty when nothing rings on) — see [BarRenderer.flush]. Empties
  /// the carry.
  Future<Float32List> flush();

  /// false once the backend cannot render any more (its isolate exited or
  /// was disposed); [init] makes it ready again.
  bool get isReady;

  /// Drops the carry (new run).
  void reset();
  Future<void> dispose();
}

/// Renders on the calling isolate (tests, tools).
class InlineBarRenderBackend implements BarRenderBackend {
  final _renderer = BarRenderer();
  Map<RunSound, List<double>> _sounds = const {};
  bool _ready = false;

  @override
  Future<void> init(Map<RunSound, List<double>> sounds) async {
    _sounds = sounds;
    _ready = true;
  }

  @override
  bool get isReady => _ready;

  @override
  Future<Float32List> render(BarJob job) async =>
      renderBarJob(_renderer, _sounds, job).pcm;

  @override
  Future<Float32List> flush() async => _renderer.flush();

  @override
  void reset() => _renderer.reset();

  @override
  Future<void> dispose() async {}
}

class _Init {
  const _Init(this.sounds);
  final Map<RunSound, List<double>> sounds;
}

class _Reset {
  const _Reset();
}

class _Dispose {
  const _Dispose();
}

class _Flush {
  const _Flush();
}

class _RenderError {
  const _RenderError(this.message);
  final String message;
}

/// Renders on a long-lived background isolate so mixing a bar (up to ~37 ms
/// in the spike) never blocks the UI. The sample table is sent once in
/// [init]; each job carries only volumes and clip samples, the result comes
/// back as transferable data (no copy).
class IsolateBarRenderBackend implements BarRenderBackend {
  /// [entry] replaces the isolate's main function (tests: one that never
  /// answers, to hit the handshake timeout).
  IsolateBarRenderBackend({void Function(SendPort)? entry})
      : _entry = entry ?? _renderMain;

  final void Function(SendPort) _entry;
  Isolate? _isolate;
  ReceivePort? _port;
  SendPort? _send;
  final _waiting = Queue<Completer<Float32List>>();

  @override
  Future<void> init(Map<RunSound, List<double>> sounds) async {
    if (_send == null) {
      final port = ReceivePort();
      _port = port;
      final ready = Completer<SendPort>();
      port.listen((m) {
        if (m == null) {
          // onExit: the isolate is gone; nothing pending will be answered.
          // isReady turns false, so the player inits a new one next start.
          port.close();
          if (identical(_port, port)) {
            _port = null;
            _send = null;
            _isolate = null;
            _failPending('render isolate exited');
          }
        } else if (m is List) {
          _failPending('render isolate error: ${m.first}');
        } else if (m is SendPort) {
          ready.complete(m);
        } else if (m is TransferableTypedData) {
          if (_waiting.isNotEmpty) {
            _waiting.removeFirst().complete(m.materialize().asFloat32List());
          }
        } else if (m is _RenderError) {
          if (_waiting.isNotEmpty) {
            _waiting.removeFirst().completeError(StateError(m.message));
          }
        }
      });
      try {
        _isolate = await Isolate.spawn(_entry, port.sendPort,
            onExit: port.sendPort,
            onError: port.sendPort,
            debugName: 'guided-bar-render');
        _send = await ready.future.timeout(handshakeTimeout);
      } catch (_) {
        // No handshake (or no spawn): drop the half-made isolate and port
        // so the next init starts clean.
        _isolate?.kill(priority: Isolate.immediate);
        _isolate = null;
        port.close();
        if (identical(_port, port)) _port = null;
        _send = null;
        rethrow;
      }
    }
    _send!.send(_Init(sounds));
  }

  /// How long [init] waits for the new isolate to answer.
  static const handshakeTimeout = Duration(seconds: 5);

  @override
  bool get isReady => _send != null;

  @override
  Future<Float32List> render(BarJob job) => _ask(job);

  @override
  Future<Float32List> flush() => _ask(const _Flush());

  Future<Float32List> _ask(Object message) {
    final send = _send;
    if (send == null) {
      return Future.error(StateError('render backend not initialized'));
    }
    final c = Completer<Float32List>();
    _waiting.add(c);
    send.send(message);
    return c.future;
  }

  @override
  void reset() => _send?.send(const _Reset());

  @override
  Future<void> dispose() async {
    _send?.send(const _Dispose());
    _send = null;
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _port?.close();
    _port = null;
    _failPending('render backend disposed');
  }

  void _failPending(String why) {
    while (_waiting.isNotEmpty) {
      _waiting.removeFirst().completeError(StateError(why));
    }
  }
}

void _renderMain(SendPort out) {
  final inbox = ReceivePort();
  out.send(inbox.sendPort);
  final renderer = BarRenderer();
  var sounds = const <RunSound, List<double>>{};
  inbox.listen((m) {
    switch (m) {
      case _Init():
        sounds = m.sounds;
      case _Reset():
        renderer.reset();
      case BarJob():
        try {
          final pcm = renderBarJob(renderer, sounds, m).pcm;
          out.send(TransferableTypedData.fromList([pcm]));
        } catch (e) {
          out.send(_RenderError('$e'));
        }
      case _Flush():
        out.send(TransferableTypedData.fromList([renderer.flush()]));
      case _Dispose():
        inbox.close();
    }
  });
}
