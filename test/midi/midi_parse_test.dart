import 'dart:typed_data';

import 'package:drum_coach/features/coaching/midi/midi_port_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MidiNoteOn? parse(List<int> bytes) => parseNoteOn(Uint8List.fromList(bytes),
      libTimestamp: 7, arrivalEpochUs: 9);

  test('note on with velocity on channel 10', () {
    final n = parse([0x99, 38, 100])!;
    expect(n.note, 38);
    expect(n.velocity, 100);
    expect(n.channel, 9);
    expect(n.libTimestamp, 7);
    expect(n.arrivalEpochUs, 9);
  });

  test('note off, velocity 0, aftertouch, controller, short: null', () {
    expect(parse([0x89, 38, 0]), isNull);
    expect(parse([0x99, 38, 0]), isNull);
    expect(parse([0xA9, 38, 40]), isNull);
    expect(parse([0xB9, 4, 127]), isNull);
    expect(parse([0x99, 38]), isNull);
    expect(parse([]), isNull);
  });

  test('chooseMidiDevice: single input wins, last id preferred, else first',
      () {
    final one = [(id: '20:0', name: 'Millenium', hasInput: true)];
    expect(chooseMidiDevice(one), '20:0');
    final two = [
      (id: '20:0', name: 'Millenium', hasInput: true),
      (id: '24:0', name: 'Keyboard', hasInput: true),
    ];
    expect(chooseMidiDevice(two, lastId: '24:0'), '24:0');
    expect(chooseMidiDevice(two, lastId: '99:0'), '20:0');
    expect(chooseMidiDevice(two), '20:0');
    final outputOnly = [(id: '1:0', name: 'Synth', hasInput: false)];
    expect(chooseMidiDevice(outputOnly), isNull);
    expect(chooseMidiDevice(const []), isNull);
  });

  group('devicePresentAfterSetupChange', () {
    test('present / absent from one answer', () async {
      expect(
          await devicePresentAfterSetupChange(
              deviceIds: () async => ['20:0', '24:0'], deviceId: '20:0'),
          isTrue);
      expect(
          await devicePresentAfterSetupChange(
              deviceIds: () async => ['24:0'], deviceId: '20:0'),
          isFalse);
    });

    test('one failure is re-checked once', () async {
      var calls = 0;
      final present = await devicePresentAfterSetupChange(
        deviceIds: () async {
          if (calls++ == 0) throw StateError('busy');
          return ['20:0'];
        },
        deviceId: '20:0',
      );
      expect(present, isTrue);
      expect(calls, 2);
    });

    test('a device that cannot be confirmed counts as gone', () async {
      var calls = 0;
      final present = await devicePresentAfterSetupChange(
        deviceIds: () async {
          calls++;
          throw StateError('plugin gone');
        },
        deviceId: '20:0',
      );
      expect(present, isFalse);
      expect(calls, 2);
    });
  });
}
