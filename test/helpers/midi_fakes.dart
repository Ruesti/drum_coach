import 'dart:async';

import 'package:drum_coach/features/coaching/midi/midi_port_service.dart';

/// An open MIDI port the test drives: push notes, drop the connection.
class FakeMidiPort implements MidiPort {
  FakeMidiPort({this.deviceName = 'Fake Module', this.deviceId = '20:0'});

  final notes = StreamController<MidiNoteOn>.broadcast();
  final conn = StreamController<bool>.broadcast();
  bool closed = false;

  @override
  final String deviceName;
  @override
  final String deviceId;
  @override
  Stream<MidiNoteOn> get noteOns => notes.stream;
  @override
  Stream<bool> get connection => conn.stream;
  @override
  Future<void> close() async => closed = true;

  void hit(int note, {int velocity = 100}) {
    final now = DateTime.now().microsecondsSinceEpoch;
    notes.add(MidiNoteOn(
        note: note,
        velocity: velocity,
        channel: 9,
        libTimestamp: now,
        arrivalEpochUs: now));
  }
}

/// A port service with a fixed device list; [open] hands out [port] (or
/// throws [openError]).
class FakeMidiPorts implements MidiPortService {
  FakeMidiPorts({this.port, this.listError, this.openError});

  final FakeMidiPort? port;
  final Object? listError;
  final Object? openError;
  int opened = 0;

  @override
  Future<List<({String id, String name, bool hasInput})>> inputDevices() async {
    if (listError != null) throw listError!;
    final p = port;
    return p == null
        ? const []
        : [(id: p.deviceId, name: p.deviceName, hasInput: true)];
  }

  @override
  Future<MidiPort?> open(String deviceId) async {
    if (openError != null) throw openError!;
    opened++;
    return port;
  }

  @override
  Stream<void> get setupChanges => const Stream.empty();
}
