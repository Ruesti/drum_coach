import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:drum_coach/measure/timestamp_mapper.dart';
import 'package:drum_coach/midi/midi_port_service.dart';
import 'package:drum_coach/midi/midi_stroke_source.dart';
import 'package:drum_coach/midi/stroke_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/midi_fakes.dart';

void main() {
  MidiNoteOn on(int note, int vel, int us) => MidiNoteOn(
      note: note,
      velocity: vel,
      channel: 9,
      libTimestamp: us,
      arrivalEpochUs: us + 1200);

  MidiStrokeSource make(FakeMidiPort port,
          [MidiTimestampUnit unit = MidiTimestampUnit.epochMicros]) =>
      MidiStrokeSource(
        port: port,
        mapping: KitMapping.gm(),
        mapper: MidiTimestampMapper(unit),
      );

  test('maps notes to instruments, raw velocity, epoch ms', () async {
    final port = FakeMidiPort();
    final StrokeSource src = make(port);
    await src.start();
    port.notes.add(on(38, 127, 1700000000000000));
    port.notes.add(on(36, 64, 1700000000250000));
    port.notes.add(on(99, 64, 1700000000300000)); // unmapped note
    await Future<void>.delayed(Duration.zero);
    await src.stop();
    expect(src.strokes, [
      const Stroke(
          timeMs: 1700000000000.0,
          note: 38,
          velocity: 127,
          instrument: KitInstrument.snare),
      const Stroke(
          timeMs: 1700000000250.0,
          note: 36,
          velocity: 64,
          instrument: KitInstrument.kick),
      const Stroke(
          timeMs: 1700000000300.0,
          note: 99,
          velocity: 64,
          instrument: KitInstrument.unknown),
    ]);
    expect((src as MidiStrokeSource).unmappedNotes, {99});
    expect(src.deviceName, 'Fake Module');
  });

  test('events before start and after stop are ignored', () async {
    final port = FakeMidiPort();
    final src = make(port);
    port.notes.add(on(38, 100, 1));
    await Future<void>.delayed(Duration.zero);
    await src.start();
    port.notes.add(on(38, 100, 2));
    await Future<void>.delayed(Duration.zero);
    await src.stop();
    port.notes.add(on(38, 100, 3));
    await Future<void>.delayed(Duration.zero);
    expect(src.strokes.length, 1);
  });

  test('connection forwards the port; device lost keeps the strokes',
      () async {
    final port = FakeMidiPort();
    final src = make(port);
    final seen = <bool>[];
    src.connection.listen(seen.add);
    await src.start();
    port.notes.add(on(38, 100, 1000));
    port.conn.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [false]);
    await src.stop();
    expect(src.strokes.length, 1);
    src.dispose();
    expect(port.closed, isTrue);
  });

  test('monotonic stamps: strokes use the session-final minimum offset, so '
      'an early late arrival is corrected', () async {
    final port = FakeMidiPort();
    final src = make(port, MidiTimestampUnit.monotonicNanos);
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
    final s = src.strokes;
    expect(s[1].timeMs - s[0].timeMs, closeTo(500, 1e-6));
    expect(s[0].timeMs, closeTo((base + 1000) / 1000.0, 1e-6));
  });
}
