import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app.dart';
import '../audio/click_player.dart';
import '../midi/stroke_source.dart';
import '../run/calibration_controller.dart';

/// Latency calibration: 4 count-in + 20 clicks at 100 BPM, quarters on the
/// snare. Shows offset, spread and the difference to the stored calibration;
/// Save stores it for the device.
class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  MidiDeviceRef? _device;
  CalibrationController? _controller;
  StrokeSource? _source;
  ClickOut? _out;

  /// Between tapping Start and the controller running: Start is disabled
  /// so a double tap cannot open two sources.
  bool _starting = false;
  double? _differenceMs;
  bool _finished = false;
  String? _error;

  Future<void> _start() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _error = null;
      _finished = false;
      _differenceMs = null;
    });
    final settings = ref.read(deviceSettingsProvider);
    StrokeSource? source;
    try {
      final device = await ref.read(currentDeviceProvider.future);
      if (device == null) {
        if (mounted) setState(() => _error = 'No MIDI device connected.');
        return;
      }
      _device = device;
      source = await ref.read(openStrokeSourceProvider)(
          device.id, settings.mappingFor(device.name));
      if (source == null) {
        if (mounted) setState(() => _error = 'Could not open the MIDI device.');
        return;
      }
      if (!mounted) {
        source.dispose();
        return;
      }
      _source = source;
      final out = ref.read(clickOutProvider);
      _out = out;
      await out.init();
      if (!mounted) return; // dispose released the source
      final clock = ref.read(runClockProvider);
      _controller?.removeListener(_changed);
      final c = CalibrationController(
          source: source, out: out, nowMs: clock.nowMs, wait: clock.wait);
      c.addListener(_changed);
      setState(() {
        _controller = c;
        _starting = false;
      });
      await c.run();
      if (!mounted) return;
      setState(() {
        _finished = true;
        _differenceMs = c.differenceToPreviousMs(settings, device.name);
      });
    } catch (e) {
      debugPrint('calibration failed: $e');
      if (mounted) setState(() => _error = 'Could not start the calibration.');
    } finally {
      // Dispose the source once: here, unless dispose() already did.
      if (source != null && identical(_source, source)) {
        _source = null;
        source.dispose();
      }
      if (mounted && _starting) setState(() => _starting = false);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final c = _controller;
    final d = _device;
    if (c == null || d == null) return;
    await c.save(ref.read(deviceSettingsProvider), d.name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Latency saved: ${c.result!.offsetMs.toStringAsFixed(1)} ms')));
    Navigator.of(context).pop();
  }

  /// Leaving mid-calibration: the controller is cancelled (it will not
  /// touch the shared click any more), the click is stopped here once, the
  /// source is disposed once.
  @override
  void dispose() {
    final c = _controller;
    c?.removeListener(_changed);
    if (c != null && c.running) {
      c.cancel();
      _out?.stop();
    }
    _source?.dispose();
    _source = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final r = c?.result;
    final running = c?.running ?? false;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Calibrate latency')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_device != null)
            Text(_device!.name, style: TextStyle(color: muted, fontSize: 12)),
          const Text(
            'After 4 count-in clicks, play quarter notes on the snare with '
            'the click: 20 clicks at 100 BPM. The app measures how late your '
            'strokes reach it compared to the click.',
          ),
          const SizedBox(height: 24),
          if (_error != null) Text(_error!, style: TextStyle(color: accent)),
          if (running)
            const Text('Listening… play with the click.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          if (_finished && r == null)
            const Text(
                'No usable strokes. Play quarter notes on the snare with the '
                'click and try again.'),
          if (r != null) ...[
            Text('Offset: ${r.offsetMs.toStringAsFixed(1)} ms',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            Text(
                'Spread ${r.spreadMs.toStringAsFixed(1)} ms, '
                '${r.matched} of ${r.clicks} clicks matched',
                style: TextStyle(color: muted)),
            if (_differenceMs != null)
              Text('Differs from the stored calibration by '
                  '${_differenceMs!.toStringAsFixed(1)} ms'),
            if (_differenceMs != null && _differenceMs! > 3)
              Text('More than 3 ms — repeat the calibration',
                  style: TextStyle(color: accent)),
            if (r.unsure)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Too uneven to trust — play it again, relaxed.',
                    style: TextStyle(color: accent)),
              ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: running || _starting ? null : _start,
                child: Text(_finished || _error != null ? 'Repeat' : 'Start'),
              ),
              const SizedBox(width: 12),
              if (r != null)
                FilledButton(
                    onPressed: running || r.unsure ? null : _save,
                    child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}
