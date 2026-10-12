import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/platform_support.dart';
import '../../data/local/settings_service.dart';
import '../../shared/widgets/app_card.dart';
import '../coaching/midi/kit_instrument.dart';
import '../coaching/midi/midi_port_service.dart';

/// Settings block "MEASUREMENT" (Brief Etappe 2, A.3/A.6): source choice,
/// MIDI device status, learn step, latency, pad role.
class MeasurementSection extends StatefulWidget {
  const MeasurementSection({super.key, required this.ports});

  final MidiPortService ports;

  @override
  State<MeasurementSection> createState() => _MeasurementSectionState();
}

class _MeasurementSectionState extends State<MeasurementSection> {
  List<({String id, String name, bool hasInput})> _devices = const [];
  late MeasurementSource _source = SettingsService.measurementSource;
  late KitInstrument _padRole = SettingsService.padRoleInstrument;
  StreamSubscription<void>? _setupSub;

  @override
  void initState() {
    super.initState();
    _refresh();
    _setupSub = widget.ports.setupChanges.listen((_) => _refresh());
  }

  @override
  void dispose() {
    _setupSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final devices = await widget.ports.inputDevices();
    if (!mounted) return;
    setState(() => _devices = [for (final d in devices) if (d.hasInput) d]);
  }

  /// Opens a MIDI sub-screen and refreshes the subtitles on return (a new
  /// calibration or mapping was maybe saved).
  Future<void> _openAndRefresh(String route) async {
    await context.push(route);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // The device the practice screen would open (Brief A.3).
    final chosenId =
        chooseMidiDevice(_devices, lastId: SettingsService.midiLastDeviceId);
    final device = chosenId == null
        ? null
        : _devices.firstWhere((d) => d.id == chosenId);
    final desktop = isDesktopPlatform;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<MeasurementSource>(
          segments: [
            const ButtonSegment(
                value: MeasurementSource.auto, label: Text('Auto')),
            ButtonSegment(
                value: MeasurementSource.mic,
                label: Text(desktop ? 'Mic (untested)' : 'Mic')),
            const ButtonSegment(
                value: MeasurementSource.midi, label: Text('MIDI')),
            const ButtonSegment(
                value: MeasurementSource.off, label: Text('Off')),
          ],
          selected: {_source},
          onSelectionChanged: (s) async {
            await SettingsService.setMeasurementSource(s.first);
            if (mounted) setState(() => _source = s.first);
          },
        ),
        const SizedBox(height: 6),
        Text(
          desktop
              ? 'Auto: MIDI when a module is connected; the microphone only '
                  'on the phone.'
              : 'Auto: MIDI when a module is connected, otherwise the '
                  'microphone.',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            children: [
              Icon(device == null ? Icons.usb_off : Icons.piano,
                  size: 20, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  device == null
                      ? 'No MIDI device connected'
                      : 'MIDI: ${device.name}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => _openAndRefresh('/settings/kit-learn'),
          child: const Row(
            children: [
              Icon(Icons.school_outlined, size: 20, color: AppColors.textMuted),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learn kit',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Hit every pad (all zones) so the app knows your module',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => _openAndRefresh('/settings/midi-calibration'),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 20, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MIDI latency',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      device != null &&
                              SettingsService.midiLatencyOffsetMsFor(
                                      device.name) !=
                                  null
                          ? 'Saved: ${SettingsService.midiLatencyOffsetMsFor(device.name)!.round()} ms'
                          : 'Not calibrated yet — play 20 quarters to the click',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textFaint),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text('Pad role at the set',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            DropdownButton<KitInstrument>(
              value: _padRole,
              items: [
                for (final i in KitInstrument.learnOrder)
                  DropdownMenuItem(value: i, child: Text(i.label)),
              ],
              onChanged: (i) async {
                if (i == null) return;
                await SettingsService.setPadRoleInstrument(i);
                if (mounted) setState(() => _padRole = i);
              },
            ),
          ],
        ),
      ],
    );
  }
}
