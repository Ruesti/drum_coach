import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/local/settings_service.dart';
import '../coaching/midi/kit_learn_session.dart';
import '../coaching/midi/midi_port_service.dart';

/// "Hit the …" (Brief A.2): one instrument after another, under two minutes
/// for a full kit. Saved per device name.
class KitLearnScreen extends StatefulWidget {
  const KitLearnScreen({super.key, this.ports});

  final MidiPortService? ports;

  @override
  State<KitLearnScreen> createState() => _KitLearnScreenState();
}

class _KitLearnScreenState extends State<KitLearnScreen> {
  MidiPort? _port;
  KitLearnSession? _session;
  StreamSubscription<MidiNoteOn>? _sub;
  int? _lastNote;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final ports = widget.ports ?? MidiPortService();
    final devices = await ports.inputDevices();
    final id =
        chooseMidiDevice(devices, lastId: SettingsService.midiLastDeviceId);
    if (id == null) {
      setState(() => _error = 'No MIDI device connected. Plug in the module.');
      return;
    }
    final port = await ports.open(id);
    if (port == null) {
      setState(() => _error = 'Could not open the MIDI device.');
      return;
    }
    if (!mounted) {
      await port.close();
      return;
    }
    setState(() {
      _port = port;
      _session = KitLearnSession(
          start: SettingsService.kitMappingFor(port.deviceName));
    });
    _sub = port.noteOns.listen((n) {
      final s = _session;
      if (s == null || s.done) return;
      setState(() {
        _lastNote = n.note;
        s.hit(n.note);
      });
    });
  }

  Future<void> _save() async {
    final port = _port;
    final s = _session;
    if (port == null || s == null) return;
    await SettingsService.setKitMappingFor(port.deviceName, s.mapping);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Kit mapping saved')));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _port?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return Scaffold(
      appBar: AppBar(title: const Text('Learn kit')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _error != null
            ? Text(_error!, style: const TextStyle(color: AppColors.textMuted))
            : s == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_port!.deviceName,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 24),
                      if (!s.done) ...[
                        Text('Hit the ${s.current!.label}',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('${s.index + 1} of ${s.total}',
                            style: const TextStyle(color: AppColors.textMuted)),
                        if (_lastNote != null)
                          Text('Last note: $_lastNote',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        if (s.hint != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(s.hint!,
                                style: const TextStyle(
                                    color: AppColors.accent, fontSize: 12)),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            TextButton(
                                onPressed: () => setState(s.back),
                                child: const Text('Back')),
                            const Spacer(),
                            OutlinedButton(
                                onPressed: () => setState(s.skip),
                                child: const Text('Skip')),
                          ],
                        ),
                      ] else ...[
                        const Text('All done.',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        for (final e in s.mapping.notes.entries)
                          if (e.value.isNotEmpty)
                            Text('${e.key.label}: ${e.value.join(', ')}',
                                style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: _save, child: const Text('Save')),
                      ],
                      const Spacer(),
                      TextButton(
                        onPressed: s.done ? null : _save,
                        child: const Text('Save what I have so far'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
