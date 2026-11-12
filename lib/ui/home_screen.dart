import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app.dart';
import '../content/exercises.dart';
import '../skill/gate.dart';

String lastGateText(GateStatus? s) => switch (s) {
      null => 'Not played yet',
      GateStatus.passed => 'Last: PASSED',
      GateStatus.failed => 'Last: NOT PASSED',
      GateStatus.notMeasurable => 'Last: NOT MEASURABLE',
    };

/// Device line, Setup, and the two exercises with their last gate status.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(currentDeviceProvider);
    final hasDevice = device.valueOrNull != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Drum Coach')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.piano),
            title: Text(device.when(
              data: (d) => d?.name ?? 'No MIDI device',
              loading: () => 'Looking for MIDI device…',
              error: (_, __) => 'No MIDI device',
            )),
            trailing: IconButton(
              tooltip: 'Look again',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(currentDeviceProvider),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: () => context.push('/setup'),
              child: const Text('Setup'),
            ),
          ),
          const SizedBox(height: 24),
          for (final e in exercises)
            Card(
              child: ListTile(
                enabled: hasDevice,
                title: Text(e.title),
                subtitle: Text(lastGateText(
                    ref.watch(lastGateProvider(e.id)).valueOrNull)),
                trailing: Text('${e.bpm} BPM · ${e.bars} bars'),
                onTap: () => context.push('/run/${e.id}'),
              ),
            ),
        ],
      ),
    );
  }
}
