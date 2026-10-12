@Tags(['alsa'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/midi/midi_port_service.dart';
import 'package:drum_coach/features/coaching/midi/midi_stroke_source.dart';
import 'package:drum_coach/features/coaching/midi/midi_timestamp_mapper.dart';
import 'package:flutter_midi_command_linux/flutter_midi_command_linux.dart';
import 'package:flutter_midi_command_platform_interface/flutter_midi_command_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end over ALSA virmidi (docs/BERICHT_ETAPPE2_§0.md): the Python
/// sender writes 64 notes to /dev/snd/midiC1D0, the real plugin + source
/// receive them. Runs only with DRUM_COACH_ALSA_TEST=1 on Linux.
void main() {
  final enabled =
      Platform.isLinux && Platform.environment['DRUM_COACH_ALSA_TEST'] == '1';

  test('64 of 64 notes, p95 jitter < 0.5 ms, flams 25 ± 1 ms', () async {
    MidiCommandPlatform.instance = FlutterMidiCommandLinux();
    final service = MidiPortService();
    final devices = await service.inputDevices();
    final virt = devices.where((d) => d.name.contains('Virtual Raw MIDI 1-0'));
    expect(virt, isNotEmpty, reason: 'modprobe snd-virmidi + audio group');
    final port = (await service.open(virt.first.id))!;
    final src = MidiStrokeSource(
      port: port,
      mapping: KitMapping.gm(),
      mapper: MidiTimestampMapper(MidiTimestampUnit.epochMicros),
    );
    await src.start();

    final sendLog = '${Directory.systemTemp.path}/drum_coach_send.jsonl';
    final proc = await Process.run('python3', [
      'tool/midi/spike/send_pattern.py',
      '/dev/snd/midiC1D0',
      sendLog,
      '--quick',
    ]);
    expect(proc.exitCode, 0, reason: proc.stderr.toString());
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await src.stop();
    src.dispose();

    final sent = [
      for (final l in File(sendLog).readAsLinesSync())
        if (l.trim().isNotEmpty) jsonDecode(l) as Map<String, Object?>,
    ];
    final recv = src.events;
    expect(recv.length, sent.length);

    // Jitter: receive interval minus send interval, relative to note 0.
    // Clocks differ (monotonic vs wall) — only the differences matter.
    final s0 = sent.first['send_us'] as int;
    final r0 = recv.first.timeMs;
    final dev = <double>[];
    for (var i = 0; i < sent.length; i++) {
      final ds = ((sent[i]['send_us'] as int) - s0) / 1000.0;
      final dr = recv[i].timeMs - r0;
      dev.add(dr - ds);
    }
    final sorted = List<double>.of(dev)..sort();
    final median = sorted[sorted.length ~/ 2];
    final abs = [for (final d in dev) (d - median).abs()]..sort();
    final p95 = abs[(abs.length * 0.95).floor().clamp(0, abs.length - 1)];
    expect(p95, lessThan(0.5), reason: 'p95 |jitter| ms');

    for (var i = 1; i < sent.length; i++) {
      if (sent[i]['tag'] == 'B2' && sent[i - 1]['tag'] == 'B1') {
        expect(recv[i].timeMs - recv[i - 1].timeMs, closeTo(25, 1));
      }
    }
  }, skip: enabled ? false : 'needs Linux + DRUM_COACH_ALSA_TEST=1');
}
