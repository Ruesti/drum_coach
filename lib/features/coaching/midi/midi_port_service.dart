import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart' as fmc;

/// One Note-On as it left the module: note, velocity, channel, the library's
/// timestamp (unit per platform) and when it reached Dart (epoch µs).
class MidiNoteOn {
  final int note;
  final int velocity;
  final int channel;
  final int libTimestamp;
  final int arrivalEpochUs;

  const MidiNoteOn({
    required this.note,
    required this.velocity,
    required this.channel,
    required this.libTimestamp,
    required this.arrivalEpochUs,
  });
}

/// Note-On with velocity > 0 only. Note-Off, velocity 0, aftertouch,
/// controllers (hi-hat pedal position), SysEx: null (Brief A.1).
MidiNoteOn? parseNoteOn(
  Uint8List data, {
  required int libTimestamp,
  required int arrivalEpochUs,
}) {
  if (data.length < 3) return null;
  final status = data[0] & 0xF0;
  if (status != 0x90) return null;
  final velocity = data[2] & 0x7F;
  if (velocity == 0) return null;
  return MidiNoteOn(
    note: data[1] & 0x7F,
    velocity: velocity,
    channel: data[0] & 0x0F,
    libTimestamp: libTimestamp,
    arrivalEpochUs: arrivalEpochUs,
  );
}

/// Port choice (Brief A.3): exactly one input → that one; several → the
/// last used if still present, else the first; none → null.
String? chooseMidiDevice(
  List<({String id, String name, bool hasInput})> devices, {
  String? lastId,
}) {
  final inputs = [for (final d in devices) if (d.hasInput) d];
  if (inputs.isEmpty) return null;
  if (inputs.length == 1) return inputs.single.id;
  for (final d in inputs) {
    if (d.id == lastId) return d.id;
  }
  return inputs.first.id;
}

/// An open input port: parsed Note-Ons, connection state, identity.
abstract class MidiPort {
  Stream<MidiNoteOn> get noteOns;

  /// false when the device disappears (unplugged / client exit).
  Stream<bool> get connection;
  String get deviceName;
  String get deviceId;
  Future<void> close();
}

class _CommandPort implements MidiPort {
  _CommandPort(this._midi, this._device)
      : deviceId = _device.id,
        deviceName = _device.name {
    _packets = _midi.onMidiPacketReceived?.listen((packet) {
      if (packet.device.id != _device.id) return;
      final arrival = DateTime.now().microsecondsSinceEpoch;
      final note = parseNoteOn(packet.data,
          libTimestamp: packet.timestamp, arrivalEpochUs: arrival);
      if (note != null) _notes.add(note);
    });
    _setup = _midi.onMidiSetupChanged?.listen((_) async {
      final still = (await _midi.devices ?? const <fmc.MidiDevice>[])
          .any((d) => d.id == _device.id);
      if (!still && !_connection.isClosed) _connection.add(false);
    });
  }

  final fmc.MidiCommand _midi;
  final fmc.MidiDevice _device;
  final _notes = StreamController<MidiNoteOn>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  StreamSubscription<fmc.MidiPacket>? _packets;
  StreamSubscription<fmc.MidiSetupChange>? _setup;

  @override
  final String deviceId;
  @override
  final String deviceName;
  @override
  Stream<MidiNoteOn> get noteOns => _notes.stream;
  @override
  Stream<bool> get connection => _connection.stream;

  @override
  Future<void> close() async {
    await _packets?.cancel();
    await _setup?.cancel();
    await _notes.close();
    await _connection.close();
    try {
      _midi.disconnectDevice(_device);
    } catch (_) {}
  }
}

/// Thin wrapper over `flutter_midi_command` (Brief A.3): device list,
/// open/close, hot-plug notifications. Everything testable lives in the
/// pure functions above and in `MidiStrokeSource`.
class MidiPortService {
  MidiPortService({fmc.MidiCommand? midi}) : _midi = midi ?? fmc.MidiCommand();

  final fmc.MidiCommand _midi;

  Future<List<({String id, String name, bool hasInput})>> inputDevices() async {
    List<fmc.MidiDevice> devices;
    try {
      devices = await _midi.devices ?? const <fmc.MidiDevice>[];
    } catch (_) {
      return const [];
    }
    return [
      for (final d in devices)
        (id: d.id, name: d.name, hasInput: d.inputPorts.isNotEmpty),
    ];
  }

  Future<MidiPort?> open(String deviceId) async {
    final devices = await _midi.devices ?? const <fmc.MidiDevice>[];
    for (final d in devices) {
      if (d.id != deviceId) continue;
      try {
        await _midi.connectToDevice(d);
      } catch (_) {
        return null;
      }
      return _CommandPort(_midi, d);
    }
    return null;
  }

  Stream<void> get setupChanges =>
      _midi.onMidiSetupChanged?.map((_) {}) ?? const Stream.empty();
}
