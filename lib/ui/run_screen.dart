import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app.dart';
import '../audio/click_player.dart';
import '../audio/click_track.dart';
import '../content/analysis.dart';
import '../content/exercises.dart';
import '../midi/stroke_source.dart';
import '../run/run_controller.dart';
import 'feedback_screen.dart';

/// Remembers when the click started, for the count-in number on screen.
class _StampingClickOut implements ClickOut {
  _StampingClickOut(this._inner);

  final ClickOut _inner;
  double? startMs;

  @override
  Future<void> init() => _inner.init();

  @override
  Future<double> play(ClickTrack t) async {
    final ms = await _inner.play(t);
    startMs = ms;
    return ms;
  }

  @override
  Future<void> stop() => _inner.stop();
}

/// One run of an exercise: Start, count-in number, "Bar n / N"; when the run
/// finishes the record is saved and Feedback opens. A lost device discards
/// the run.
class RunScreen extends ConsumerStatefulWidget {
  const RunScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends ConsumerState<RunScreen> {
  RunController? _controller;
  StrokeSource? _source;
  _StampingClickOut? _out;
  Timer? _ticker;
  bool _handled = false;
  String? _error;

  /// Between tapping Start and the controller running: Start is disabled
  /// so a double tap cannot open two sources.
  bool _starting = false;

  Exercise get _ex => widget.exercise;

  Future<void> _start() async {
    if (_starting) return;
    setState(() {
      _error = null;
      _starting = true;
    });
    _handled = false;
    final settings = ref.read(deviceSettingsProvider);
    try {
      final device = await ref.read(currentDeviceProvider.future);
      if (device == null) {
        _fail('No MIDI device connected.');
        return;
      }
      final mapping = settings.mappingFor(device.name);
      final source =
          await ref.read(openStrokeSourceProvider)(device.id, mapping);
      if (source == null) {
        _fail('Could not open the MIDI device.');
        return;
      }
      if (!mounted) {
        source.dispose();
        return;
      }
      _source = source;
      final out = _out = _StampingClickOut(ref.read(clickOutProvider));
      await out.init();
      if (!mounted) return; // dispose released the source
      final clock = ref.read(runClockProvider);
      final c = RunController(
        exercise: _ex,
        source: source,
        out: out,
        mapping: mapping,
        latencyOffsetMs: settings.latencyFor(device.name)?.offsetMs,
        platform: ref.read(platformNameProvider),
        nowMs: clock.nowMs,
        wait: clock.wait,
      );
      c.addListener(_changed);
      _ticker =
          Timer.periodic(const Duration(milliseconds: 50), (_) => _changed());
      setState(() {
        _controller = c;
        _starting = false;
      });
      await c.start();
    } catch (e) {
      debugPrint('run failed: $e');
      _release();
      _fail('Could not start the run.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _controller = null;
      _starting = false;
    });
  }

  void _release() {
    _ticker?.cancel();
    _ticker = null;
    _controller?.removeListener(_changed);
    _source?.dispose();
    _source = null;
  }

  void _changed() {
    if (!mounted) return;
    final c = _controller;
    if (c != null && !_handled) {
      if (c.phase == RunPhase.finished) {
        _handled = true;
        _finish(c);
      } else if (c.phase == RunPhase.deviceLost) {
        _handled = true;
        _release();
      }
    }
    setState(() {});
  }

  Future<void> _finish(RunController c) async {
    _release();
    final record = c.record!;
    try {
      final file = await ref.read(sessionStoreProvider).save(record);
      final analysis = analyzeSession(record);
      ref.invalidate(lastGateProvider(_ex.id));
      if (!mounted) return;
      context.go('/feedback',
          extra: FeedbackArgs(
              record: record, analysis: analysis, path: file.path));
    } catch (e) {
      debugPrint('saving the session failed: $e');
      _fail('Could not save the session.');
    }
  }

  /// Leaving mid-run: the controller is cancelled (it will not touch the
  /// shared click any more), the click is stopped here once, the source is
  /// disposed once by [_release].
  @override
  void dispose() {
    final c = _controller;
    if (c != null &&
        (c.phase == RunPhase.countIn || c.phase == RunPhase.playing)) {
      c.cancel();
      _out?.stop();
    }
    _release();
    super.dispose();
  }

  Widget _big(String text) => Text(text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700));

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final List<Widget> body;
    if (c == null || c.phase == RunPhase.idle) {
      final device = ref.watch(currentDeviceProvider).valueOrNull;
      final calibrated = device != null &&
          ref.watch(deviceSettingsProvider).latencyFor(device.name) != null;
      body = [
        Text('${_ex.bpm} BPM · ${_ex.bars} bars · 1 bar count-in',
            textAlign: TextAlign.center, style: TextStyle(color: muted)),
        if (device != null && !calibrated)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Not calibrated — this run gets no gate verdict.',
                textAlign: TextAlign.center),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 32),
        Center(
          child: FilledButton(
              onPressed: c == null && !_starting ? _start : null,
              child: const Text('Start')),
        ),
      ];
    } else if (c.phase == RunPhase.countIn) {
      final startMs = _out?.startMs;
      final quarterMs = 60000 / _ex.bpm;
      final beat = startMs == null
          ? null
          : ((ref.read(runClockProvider).nowMs() - startMs) / quarterMs)
                  .floor()
                  .clamp(0, _ex.beatsPerBar - 1) +
              1;
      body = [
        Text('Count-in',
            textAlign: TextAlign.center, style: TextStyle(color: muted)),
        _big(beat == null ? '…' : '$beat'),
      ];
    } else if (c.phase == RunPhase.playing) {
      body = [_big('Bar ${c.currentBar + 1} / ${_ex.bars}')];
    } else if (c.phase == RunPhase.deviceLost) {
      body = [
        const Text('MIDI device disconnected — run discarded',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
        const SizedBox(height: 24),
        Center(
          child: FilledButton(
              onPressed: () => context.go('/'), child: const Text('Home')),
        ),
      ];
    } else {
      body = [
        if (_error != null)
          Text(_error!, textAlign: TextAlign.center)
        else
          const Center(child: CircularProgressIndicator()),
      ];
    }
    return Scaffold(
      appBar: AppBar(title: Text(_ex.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: body,
          ),
        ),
      ),
    );
  }
}
