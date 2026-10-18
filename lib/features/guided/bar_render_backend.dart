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

/// Loud-sample threshold and track gain per sound: pattern like the loop's
/// pattern voice (accent ≥ 1.2), kick/hi-hat at the loop's backing level.
const _voiceSpec = <RunSound, ({double loudFrom, double gain})>{
  RunSound.pattern: (loudFrom: 1.2, gain: 1.0),
  RunSound.kick: (loudFrom: 1.0, gain: 0.7),
  RunSound.hihatLoud: (loudFrom: 0.9, gain: 0.7),
  RunSound.hihatSoft: (loudFrom: 0.9, gain: 0.7),
  RunSound.click: (loudFrom: 1.0, gain: 1.0),
};

/// Mixes [job] with [renderer] (carry kept across calls). Sounds without
/// samples in [sounds] stay silent.
RenderedBar renderBarJob(
    BarRenderer renderer, Map<RunSound, List<double>> sounds, BarJob job) {
  final voices = <LoopVoice>[];
  job.tickVolumes.forEach((sound, vols) {
    final s = sounds[sound];
    final spec = _voiceSpec[sound];
    if (s == null || s.isEmpty || spec == null) return;
    voices.add(LoopVoice(
      tickVolumes: vols,
      loudSamples: s,
      softSamples: s,
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

  /// Drops the carry (new run).
  void reset();
  Future<void> dispose();
}

/// Renders on the calling isolate (tests, tools).
class InlineBarRenderBackend implements BarRenderBackend {
  final _renderer = BarRenderer();
  Map<RunSound, List<double>> _sounds = const {};

  @override
  Future<void> init(Map<RunSound, List<double>> sounds) async =>
      _sounds = sounds;

  @override
  Future<Float32List> render(BarJob job) async =>
      renderBarJob(_renderer, _sounds, job).pcm;

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

class _RenderError {
  const _RenderError(this.message);
  final String message;
}

/// Renders on a long-lived background isolate so mixing a bar (up to ~37 ms
/// in the spike) never blocks the UI. The sample table is sent once in
/// [init]; each job carries only volumes and clip samples, the result comes
/// back as transferable data (no copy).
class IsolateBarRenderBackend implements BarRenderBackend {
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
        if (m is SendPort) {
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
      _isolate = await Isolate.spawn(_renderMain, port.sendPort,
          debugName: 'guided-bar-render');
      _send = await ready.future.timeout(const Duration(seconds: 5));
    }
    _send!.send(_Init(sounds));
  }

  @override
  Future<Float32List> render(BarJob job) {
    final send = _send;
    if (send == null) {
      return Future.error(StateError('render backend not initialized'));
    }
    final c = Completer<Float32List>();
    _waiting.add(c);
    send.send(job);
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
    while (_waiting.isNotEmpty) {
      _waiting
          .removeFirst()
          .completeError(StateError('render backend disposed'));
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
      case _Dispose():
        inbox.close();
    }
  });
}
