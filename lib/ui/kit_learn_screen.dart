import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app.dart';
import '../midi/kit_learn_session.dart';
import '../midi/midi_port_service.dart';

/// "Hit the …": one instrument after another. Every zone hit on a step
/// belongs to that instrument; Next moves on, Skip keeps the instrument as
/// it was. Saved per device name.
class KitLearnScreen extends ConsumerStatefulWidget {
  const KitLearnScreen({super.key});

  @override
  ConsumerState<KitLearnScreen> createState() => _KitLearnScreenState();
}

class _KitLearnScreenState extends ConsumerState<KitLearnScreen> {
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
    MidiPort? port;
    try {
      final device = await ref.read(currentDeviceProvider.future);
      if (!mounted) return;
      if (device == null) {
        setState(
            () => _error = 'No MIDI device connected. Plug in the module.');
        return;
      }
      port = await ref.read(midiPortsProvider).open(device.id);
    } catch (e) {
      debugPrint('kit learn: opening the MIDI device failed: $e');
      if (mounted) setState(() => _error = 'Could not open the MIDI device.');
      return;
    }
    if (!mounted) {
      await port?.close();
      return;
    }
    final opened = port;
    if (opened == null) {
      setState(() => _error = 'Could not open the MIDI device.');
      return;
    }
    setState(() {
      _port = opened;
      _session = KitLearnSession(
          start:
              ref.read(deviceSettingsProvider).mappingFor(opened.deviceName));
    });
    _sub = opened.noteOns.listen((n) {
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
    await ref
        .read(deviceSettingsProvider)
        .saveMapping(port.deviceName, s.mapping);
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Learn kit')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _error != null
            ? Text(_error!, style: TextStyle(color: muted))
            : s == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_port!.deviceName,
                          style: TextStyle(color: muted, fontSize: 12)),
                      const SizedBox(height: 24),
                      if (!s.done) ...[
                        Text(
                            'Hit the ${s.current!.label} (all zones), then Next',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('${s.index + 1} of ${s.total}',
                            style: TextStyle(color: muted)),
                        if (_lastNote != null)
                          Text('Last note: $_lastNote',
                              style: TextStyle(color: muted, fontSize: 12)),
                        if (s.currentNotes.isNotEmpty)
                          Text('Notes for this instrument: '
                              '${(s.currentNotes.toList()..sort()).join(', ')}'),
                        if (s.hint != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(s.hint!,
                                style: TextStyle(color: accent, fontSize: 12)),
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
                            const SizedBox(width: 12),
                            FilledButton(
                                onPressed: () => setState(s.next),
                                child: const Text('Next')),
                          ],
                        ),
                      ] else ...[
                        const Text('All instruments done.',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            TextButton(
                                onPressed: () => setState(s.back),
                                child: const Text('Back')),
                            const Spacer(),
                            FilledButton(
                                onPressed: _save, child: const Text('Save')),
                          ],
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}
