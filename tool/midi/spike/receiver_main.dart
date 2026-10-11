// §0-Vorversuch: Empfänger. Wegwerf-Code.
// Umgebungsvariablen: SPIKE_OUT (JSONL), SPIKE_DEVICE (Teilstring des Gerätenamens),
// SPIKE_EXPECT (Anzahl Note-On), SPIKE_BUSY (1 = Haupt-Isolate mit Animation + Last),
// SPIKE_TIMEOUT_S.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

final _out = Platform.environment['SPIKE_OUT'] ?? 'recv.jsonl';
final _deviceMatch = Platform.environment['SPIKE_DEVICE'] ?? 'VirMIDI 1-0';
final _expect = int.tryParse(Platform.environment['SPIKE_EXPECT'] ?? '') ?? 256;
final _busy = (Platform.environment['SPIKE_BUSY'] ?? '0') == '1';
final _timeoutS = int.tryParse(Platform.environment['SPIKE_TIMEOUT_S'] ?? '') ?? 200;

final _lines = <String>[];
int _count = 0;
final _sw = Stopwatch()..start();

void _finish(String why) {
  final f = File(_out);
  f.writeAsStringSync(_lines.join('\n') + (_lines.isEmpty ? '' : '\n'));
  stdout.writeln('DONE $why count=$_count file=$_out');
  exit(0);
}

Future<void> _setup() async {
  final midi = MidiCommand();
  final devices = await midi.devices ?? <MidiDevice>[];
  for (final d in devices) {
    stdout.writeln('DEVICE id=${d.id} name=${d.name} type=${d.type} '
        'in=${d.inputPorts.length} out=${d.outputPorts.length}');
  }
  MidiDevice? target;
  for (final d in devices) {
    if (d.name.contains(_deviceMatch) || d.id.contains(_deviceMatch)) {
      target = d;
      break;
    }
  }
  if (target == null) {
    stdout.writeln('NO DEVICE matching "$_deviceMatch"');
    exit(2);
  }
  midi.onMidiPacketReceived?.listen((packet) {
    final mainUs = DateTime.now().microsecondsSinceEpoch;
    final swUs = _sw.elapsedMicroseconds;
    final data = packet.data;
    if (data.isEmpty) return;
    final status = data[0] & 0xF0;
    if (status != 0x90 || data.length < 3 || data[2] == 0) return;
    _lines.add(jsonEncode({
      'i': _count,
      'note': data[1],
      'vel': data[2],
      'lib_ts': packet.timestamp, // gepatcht: µs aus dem Rx-Isolate (Wanduhr)
      'main_us': mainUs, // Stempel im Haupt-Isolate (Wanduhr, µs)
      'sw_us': swUs,
    }));
    _count++;
    if (_count >= _expect) _finish('expected');
  });
  await midi.connectToDevice(target);
  stdout.writeln('READY device=${target.name} busy=$_busy expect=$_expect');
  Timer(Duration(seconds: _timeoutS), () => _finish('timeout'));
}

void main() {
  stderr.writeln('MAIN START busy=$_busy expect=$_expect');
  WidgetsFlutterBinding.ensureInitialized();
  stderr.writeln('BINDING OK');
  runApp(const _SpikeApp());
  stderr.writeln('RUNAPP OK');
  unawaited(_setup().catchError((e, st) {
    stderr.writeln('SETUP ERROR $e\n$st');
    exit(3);
  }));
}

class _SpikeApp extends StatefulWidget {
  const _SpikeApp();
  @override
  State<_SpikeApp> createState() => _SpikeAppState();
}

class _SpikeAppState extends State<_SpikeApp> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Ticker? _ticker;
  int _frames = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    if (_busy) {
      _ctrl.repeat();
      // Synthetische Last im Haupt-Isolate: ~4 ms Rechnen pro Frame,
      // ähnlich Notations-Layout + Cursor-Animation im Übungs-Screen.
      _ticker = createTicker((_) {
        final sw = Stopwatch()..start();
        var x = 0.0;
        while (sw.elapsedMicroseconds < 4000) {
          x += (x + 1.0) * 0.5;
        }
        _frames++;
        if (_frames % 300 == 0) stdout.writeln('FRAMES $_frames (x=$x)');
      })
        ..start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: RotationTransition(
            turns: _ctrl,
            child: const Icon(Icons.music_note, size: 200),
          ),
        ),
      ),
    );
  }
}
