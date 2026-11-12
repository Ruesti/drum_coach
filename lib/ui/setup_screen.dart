import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app.dart';
import '../measure/kit.dart';

String _notes(KitMapping m, KitInstrument i) {
  final n = (m.notes[i]?.toList() ?? <int>[])..sort();
  return n.isEmpty ? '–' : n.join(', ');
}

/// Per device: learn the kit, calibrate the latency.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  Future<void> _open(String route) async {
    await context.push(route);
    // Mapping or calibration may have changed.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(currentDeviceProvider).valueOrNull;
    final settings = ref.watch(deviceSettingsProvider);
    String mappingText(KitMapping m) => [
          for (final i in const [
            KitInstrument.kick,
            KitInstrument.snare,
            KitInstrument.hiHatClosed,
            KitInstrument.hiHatOpen,
          ])
            '${i.label} ${_notes(m, i)}',
        ].join(' · ');
    final latency = device == null ? null : settings.latencyFor(device.name);
    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.piano),
            title: Text(device?.name ?? 'No MIDI device'),
            subtitle: device == null
                ? const Text('Plug in the module, then look again.')
                : null,
            trailing: IconButton(
              tooltip: 'Look again',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(currentDeviceProvider),
            ),
          ),
          const Divider(),
          ListTile(
            enabled: device != null,
            title: const Text('Learn kit'),
            subtitle: Text(device == null
                ? 'Needs a MIDI device'
                : mappingText(settings.mappingFor(device.name))),
            onTap: () => _open('/setup/kit'),
          ),
          ListTile(
            enabled: device != null,
            title: const Text('Calibrate latency'),
            subtitle: Text(device == null
                ? 'Needs a MIDI device'
                : latency == null
                    ? 'Not calibrated — no gate verdict without it'
                    : 'Offset ${latency.offsetMs.toStringAsFixed(1)} ms · '
                        'spread ${latency.spreadMs.toStringAsFixed(1)} ms'),
            onTap: () => _open('/setup/calibrate'),
          ),
        ],
      ),
    );
  }
}
