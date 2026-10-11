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
    expect(src.events.length, 2);
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
}
