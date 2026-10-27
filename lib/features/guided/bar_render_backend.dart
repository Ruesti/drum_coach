import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../shared/widgets/kit_layout.dart';
import '../metronome/click_loop_renderer.dart';
import 'bar_renderer.dart';
import 'run_plan.dart';
import 'sample_bank.dart';

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

/// Headroom of the kit mix: every kit gain (and the kit's structural
/// crash, `crashGainFor`) is scaled by this, so kick + crash + snare on
/// one tick stay below the soft limiter's knee (probe kit mix peaks ≤ 0.82
/// with the DRSKit takes, Optik-Runde 2; test: ≤ 0.9).
const double kitMixLevel = 0.7;

/// Sounds with one sample, mixed as the loop's voices: the pad line's snare
/// (the loop's pattern voice, linear in the tick volume) and the click.
const _plainSpec = <RunSound, ({double loudFrom, double gain})>{
  RunSound.pattern: (loudFrom: 1.2, gain: 1.0),
  RunSound.click: (loudFrom: 1.0, gain: 1.0),
};

/// Ticks below this volume are ghost strokes on both scales (band ghost
/// 0.35 / normal 0.7, pattern ghost and grace 0.25 / normal 0.85).
const double softStrokeBelow = 0.6;

/// Volume of a ghost / normal / accent stroke on the band scale
/// (`kitBandVolume`: kick and hi-hat) and on the pattern scale
/// (`buildVoicesPlayback`: every other kit voice).
const _band = (soft: 0.35, medium: 0.7, hard: 1.0);
const _pattern = (soft: 0.25, medium: 0.85, hard: 2.0);

/// Kit voices: their volume scale, the volume from which a stroke takes
/// the hard take (an accent: 1.0 on the band scale, 2.0 on the pattern
/// scale, so from 1.2) and the track gain of a normal stroke. The gains
/// even the takes out into one kit mix: kick and snare forward, hi-hat
/// back, cymbals not on top (balance measured with
/// tool/render_guided_probe_test.dart). The open hi-hat comes always at
/// 1.0 (the band scale has no accent for it), so it never takes the hard
/// take.
const _kitSpec = <RunSound,
    ({
  ({double soft, double medium, double hard}) scale,
  double hardFrom,
  double gain
})>{
  RunSound.kick: (scale: _band, hardFrom: 1.0, gain: 1.3 * kitMixLevel),
  RunSound.snare: (scale: _pattern, hardFrom: 1.2, gain: 1.2 * kitMixLevel),
  RunSound.rim: (scale: _pattern, hardFrom: 1.2, gain: 1.0 * kitMixLevel),
  RunSound.hihatClosed: (scale: _band, hardFrom: 1.0, gain: 0.5 * kitMixLevel),
  RunSound.hihatOpen: (
    scale: _band,
    hardFrom: double.infinity,
    gain: 0.75 * kitMixLevel
  ),
  RunSound.hihatPedal: (scale: _band, hardFrom: 1.0, gain: 0.5 * kitMixLevel),
  RunSound.tomHigh: (scale: _pattern, hardFrom: 1.2, gain: 1.0 * kitMixLevel),
  RunSound.tomLow: (scale: _pattern, hardFrom: 1.2, gain: 1.0 * kitMixLevel),
  RunSound.tomFloor: (scale: _pattern, hardFrom: 1.2, gain: 1.0 * kitMixLevel),
  RunSound.crash: (scale: _pattern, hardFrom: 1.2, gain: 0.7 * kitMixLevel),
  RunSound.ride: (scale: _pattern, hardFrom: 1.2, gain: 0.6 * kitMixLevel),
  RunSound.rideBell: (scale: _pattern, hardFrom: 1.2, gain: 0.65 * kitMixLevel),
};

/// The take a kit stroke of [volume] plays: ghost → soft, accent → hard,
/// else medium. Null for a sound without takes (pad snare, click).
StrokeLayer? strokeLayerOf(RunSound sound, double volume) {
  final spec = _kitSpec[sound];
  if (spec == null) return null;
  if (volume < softStrokeBelow) return StrokeLayer.soft;
  if (volume >= spec.hardFrom) return StrokeLayer.hard;
  return StrokeLayer.medium;
}

/// Within a take the volume still shapes the stroke, but only moderately
/// (the take already carries the dynamics): the square root of the volume
/// relative to the take's nominal stroke, so a normal stroke plays the
/// medium take at the track gain.
double _layerVolume(
    double v, StrokeLayer l, ({double soft, double medium, double hard}) s) {
  final nominal = switch (l) {
    StrokeLayer.soft => s.soft,
    StrokeLayer.medium => s.medium,
    StrokeLayer.hard => s.hard,
  };
  return math.sqrt(v / nominal);
}

/// Sounds that stop the open hi-hat (the hi-hat closes), like a real hat.
const _chokers = {RunSound.hihatClosed, RunSound.hihatPedal};

/// Mixes [job] with [renderer] (carry kept across calls). Sounds without
/// samples in [sounds] stay silent. The open hi-hat is a choke group: a
/// closed or pedal hi-hat stroke stops it, also one in a later bar.
RenderedBar renderBarJob(
    BarRenderer renderer, Map<RunSound, List<double>> sounds, BarJob job) {
  final voices = <LoopVoice>[];
  final choked = <LoopVoice>[];
  final chokeTicks = <int>{
    for (final e in job.tickVolumes.entries)
      if (_chokers.contains(e.key))
        for (var t = 0; t < e.value.length; t++)
          if (e.value[t] > 0) t,
  };
  job.tickVolumes.forEach((sound, vols) {
    final s = sounds[sound];
    if (s == null || s.isEmpty) return;
    final into = sound == RunSound.hihatOpen ? choked : voices;
    final plain = _plainSpec[sound];
    if (plain != null) {
      into.add(LoopVoice(
        tickVolumes: vols,
        loudSamples: s,
        softSamples: s,
        loudFrom: plain.loudFrom,
        gain: plain.gain,
      ));
      return;
    }
    final spec = _kitSpec[sound];
    if (spec == null) return;
    // One voice per take, each with only the strokes of its layer.
    for (final layer in StrokeLayer.values) {
      final lv = [
        for (final v in vols)
          v > 0 && strokeLayerOf(sound, v) == layer
              ? _layerVolume(v, layer, spec.scale)
              : 0.0
      ];
      if (!lv.any((v) => v > 0)) continue;
      final take = layerOf(s, layer);
      if (take.isEmpty) continue;
      into.add(LoopVoice(
          tickVolumes: lv,
          loudSamples: take,
          softSamples: take,
          gain: spec.gain));
    }
  });
  final hits = <SampleHit>[];
  for (final h in job.hits) {
    // A structural crash (start of the groove, the ending) is a hard hit.
    final table = h.sound == null ? null : sounds[h.sound];
    final s =
        h.samples ?? (table == null ? null : layerOf(table, StrokeLayer.hard));
    if (s == null || s.isEmpty) continue;
    hits.add(SampleHit(tick: h.tick, samples: s, gain: h.gain));
  }
  return renderer.renderBar(
      bpm: job.bpm,
      factor: kitTicksPerQuarter,
      voices: voices,
      hits: hits,
      choked: choked,
      chokeTicks: chokeTicks);
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
