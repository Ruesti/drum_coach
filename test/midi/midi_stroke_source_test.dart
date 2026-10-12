import 'dart:async';

import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/midi/midi_port_service.dart';
import 'package:drum_coach/features/coaching/midi/midi_stroke_source.dart';
import 'package:drum_coach/features/coaching/midi/midi_timestamp_mapper.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePort implements MidiPort {
  final notes = StreamController<MidiNoteOn>.broadcast();
  final conn = StreamController<bool>.broadcast();
  bool closed = false;
  @override
  Stream<MidiNoteOn> get noteOns => notes.stream;
  @override
  Stream<bool> get connection => conn.stream;
  @override
  String get deviceName => 'Fake Module';
  @override
  String get deviceId => '20:0';
  @override
  Future<void> close() async => closed = true;
}

void main() {
  MidiNoteOn on(int note, int vel, int us) => MidiNoteOn(
      note: note,
      velocity: vel,
      channel: 9,
      libTimestamp: us,
      arrivalEpochUs: us + 1200);

  test('maps notes to instruments, velocity to 0–1, time to epoch ms',
      () async {
    final port = FakePort();
    final src = MidiStrokeSource(
      port: port,
      mapping: KitMapping.gm(),
      mapper: MidiTimestampMapper(MidiTimestampUnit.epochMicros),
    );
    await src.start();
    port.notes.add(on(38, 127, 1700000000000000));
    port.notes.add(on(36, 64, 1700000000250000));
    port.notes.add(on(99, 64, 1700000000300000)); // unmapped note
    await Future<void>.delayed(Duration.zero);
    await src.stop();
    // The unmapped note is kept as an `unknown` event with its raw note
    // (Brief A.9: the raw log holds all events).
    expect(src.events.length, 3);
    expect(src.events[2].instrument, KitInstrument.unknown);
    expect(src.events[2].rawNote, 99);
    expect(src.events[0].instrument, KitInstrument.snare);
    expect(src.events[0].velocity, closeTo(1.0, 1e-9));
    expect(src.events[0].timeMs, closeTo(1700000000000.0, 1e-6));
    expect(src.events[0].rawNote, 38);
    expect(src.events[0].source, StrokeSourceKind.midi);
    expect(src.events[1].instrument, KitInstrument.kick);
    expect(src.events[1].velocity, closeTo(64 / 127, 1e-9));
    expect(src.unmappedNotes, {99});
    expect(src.velocityExact, isTrue);
    expect(src.deviceName, 'Fake Module');
    expect(src.describeSetup()!['audioSource'], 'midi');
  });

  test('events before start and after stop are ignored', () async {
    final port = FakePort();
    final src = MidiStrokeSource(
      port: port,
      mapping: KitMapping.gm(),
      mapper: MidiTimestampMapper(MidiTimestampUnit.epochMicros),
    );
    port.notes.add(on(38, 100, 1));
    await Future<void>.delayed(Duration.zero);
    await src.start();
    port.notes.add(on(38, 100, 2));
    await Future<void>.delayed(Duration.zero);
    await src.stop();
    port.notes.add(on(38, 100, 3));
    await Future<void>.delayed(Duration.zero);
    expect(src.events.map((e) => e.rawNote), [38]);
    expect(src.events.length, 1);
  });

  test('device lost mid-session: status notMeasurable, events kept', () async {
    final port = FakePort();
    final src = MidiStrokeSource(
      port: port,
      mapping: KitMapping.gm(),
      mapper: MidiTimestampMapper(MidiTimestampUnit.epochMicros),
    );
    final seen = <StrokeSourceStatus>[];
    src.statusChanges.listen(seen.add);
    await src.start();
    expect(src.status, StrokeSourceStatus.ready);
    port.notes.add(on(38, 100, 1000));
    port.conn.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(src.status, StrokeSourceStatus.notMeasurable);
    expect(src.deviceLost, isTrue);
    expect(seen, [StrokeSourceStatus.notMeasurable]);
    await src.stop();
    expect(src.events.length, 1);
    src.dispose();
    expect(port.closed, isTrue);
  });

  test('monotonic stamps: events are converted with the session-wide '
      'minimum offset, so an early late arrival is corrected', () async {
    final port = FakePort();
    final src = MidiStrokeSource(
      port: port,
      mapping: KitMapping.gm(),
      mapper: MidiTimestampMapper(MidiTimestampUnit.monotonicNanos),
    );
    await src.start();
    const base = 1700000000000000;
    // First stroke reached Dart 9 ms late, the second only 1 ms.
    port.notes.add(const MidiNoteOn(
        note: 38,
        velocity: 100,
        channel: 9,
        libTimestamp: 5000000000,
        arrivalEpochUs: base + 9000));
    port.notes.add(const MidiNoteOn(
        note: 38,
        velocity: 100,
        channel: 9,
        libTimestamp: 5500000000,
        arrivalEpochUs: base + 501000));
    await Future<void>.delayed(Duration.zero);
    await src.stop();
    final e = src.events;
    expect(e[1].timeMs - e[0].timeMs, closeTo(500, 1e-6));
    expect(e[0].timeMs, closeTo((base + 1000) / 1000.0, 1e-6));
  });
}
