import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/platform_support.dart';
import '../../data/local/settings_service.dart';
import '../coaching/midi/kit_instrument.dart';
import '../coaching/midi/midi_latency.dart';
import '../coaching/midi/midi_port_service.dart';
import '../coaching/midi/midi_stroke_source.dart';
import '../coaching/midi/midi_timestamp_mapper.dart';
import '../metronome/metronome_provider.dart';

/// MIDI latency (Brief A.4): the click leaves the app late (audio → AUX →
/// module → headphones), the MIDI note arrives at once. Twenty quarters on
/// the pad-role instrument give the offset; the spread says whether to
/// trust it.
class MidiCalibrationScreen extends ConsumerStatefulWidget {
  const MidiCalibrationScreen({super.key});

  @override
  ConsumerState<MidiCalibrationScreen> createState() =>
      _MidiCalibrationScreenState();
}

class _MidiCalibrationScreenState extends ConsumerState<MidiCalibrationScreen> {
  static const int _clicks = 20;
  static const int _bpm = 100;

  // Cached so dispose() never has to touch ref.
  late final MetronomeNotifier _notifier =
      ref.read(metronomeNotifierProvider.notifier);

  MidiPort? _port;
  MidiStrokeSource? _source;
  String? _error;
  bool _running = false;
  bool _clickOn = false; // we started the metronome and have not stopped it
  final List<double> _clickMs = [];
  MidiLatencyResult? _result;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final ports = MidiPortService();
    final devices = await ports.inputDevices();
    if (!mounted) return;
    final id =
        chooseMidiDevice(devices, lastId: SettingsService.midiLastDeviceId);
    if (id == null) {
      setState(() => _error = 'No MIDI device connected.');
      return;
    }
    final port = await ports.open(id);
    if (!mounted) {
      await port?.close();
      return;
    }
    if (port == null) {
      setState(() => _error = 'Could not open the MIDI device.');
      return;
    }
    setState(() {
      _port = port;
      _source = MidiStrokeSource(
        port: port,
        mapping: SettingsService.kitMappingFor(port.deviceName),
        mapper: MidiTimestampMapper(midiTimestampUnitForPlatform(
            isAndroid: !isDesktopPlatform, isLinux: isDesktopPlatform)),
      );
    });
  }

  Future<void> _start() async {
    final src = _source;
    if (src == null) return;
    _clickMs.clear();
    _result = null;
    await src.start();
    if (!mounted) return;
    _notifier
      ..setBpm(_bpm)
      ..setClickTrack(true)
      ..setBacking(null, beatsPerBar: 4);
    setState(() => _running = true);
    _clickOn = true;
    _notifier.toggle();
  }

  Future<void> _finish() async {
    if (_clickOn) {
      _clickOn = false;
      _notifier.toggle();
    }
    final src = _source;
    if (src == null) return;
    await src.stop();
    if (!mounted) return;
    final role = SettingsService.padRoleInstrument;
    final strokes = [
      for (final e in src.events)
        if (e.instrument == role || e.instrument == KitInstrument.snare)
          e.timeMs,
    ];
    setState(() {
      _running = false;
      _result =
          estimateMidiLatency(clickMs: List.of(_clickMs), strokeMs: strokes);
    });
  }

  Future<void> _save() async {
    final r = _result;
    final port = _port;
    if (r == null || port == null) return;
    await SettingsService.setMidiLatencyOffsetMsFor(
        port.deviceName, r.offsetMs);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('MIDI latency saved: ${r.offsetMs.round()} ms')));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    if (_clickOn) _notifier.toggle();
    _source?.dispose(); // also closes the port
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MetronomeState>(metronomeNotifierProvider, (prev, next) {
      if (!_running) return;
      final newTick = next.isPlaying &&
          next.currentBeatIndex >= 0 &&
          next.currentBeatIndex != (prev?.currentBeatIndex ?? -2);
      if (!newTick || next.lastBeatPlannedAt == null) return;
      _clickMs.add(next.lastBeatPlannedAt!.microsecondsSinceEpoch / 1000.0);
      if (_clickMs.length == _clicks) unawaited(_finish());
    });
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('MIDI latency')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _error != null
            ? Text(_error!, style: const TextStyle(color: AppColors.textMuted))
            : _source == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_port!.deviceName,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 16),
                      const Text(
                        'Play quarter notes on the snare with the click, '
                        '20 clicks at 100 BPM. The app measures how late the '
                        'click reaches your ears.',
                      ),
                      const SizedBox(height: 24),
                      if (_running)
                        Text('Clicks: ${_clickMs.length} / $_clicks',
                            style: const TextStyle(fontSize: 22)),
                      if (!_running && r == null)
                        FilledButton(
                            onPressed: _start, child: const Text('Start')),
                      if (r != null) ...[
                        Text('Offset: ${r.offsetMs.round()} ms',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w700)),
                        Text(
                            'Spread ${r.spreadMs.toStringAsFixed(1)} ms, '
                            '${r.matched} of ${r.clicks} clicks matched',
                            style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        if (r.unsure)
                          const Text(
                              'Too uneven to trust — play it again, relaxed.',
                              style: TextStyle(color: AppColors.accent)),
                        const SizedBox(height: 16),
                        Row(children: [
                          OutlinedButton(
                              onPressed: _start, child: const Text('Repeat')),
                          const SizedBox(width: 12),
                          FilledButton(
                              onPressed: r.unsure ? null : _save,
                              child: const Text('Save')),
                        ]),
                      ],
                    ],
                  ),
      ),
    );
  }
}
