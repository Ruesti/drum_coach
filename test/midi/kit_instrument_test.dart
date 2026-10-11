import 'dart:convert';

import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KitInstrument', () {
    test('carries the General MIDI defaults from the brief', () {
      expect(KitInstrument.kick.gmNote, 36);
      expect(KitInstrument.snare.gmNote, 38);
      expect(KitInstrument.snareRim.gmNote, 37);
      expect(KitInstrument.hiHatClosed.gmNote, 42);
      expect(KitInstrument.hiHatOpen.gmNote, 46);
      expect(KitInstrument.hiHatPedal.gmNote, 44);
      expect(KitInstrument.tom1.gmNote, 48);
      expect(KitInstrument.tom2.gmNote, 47);
      expect(KitInstrument.floorTom1.gmNote, 45);
      expect(KitInstrument.floorTom2.gmNote, 43);
      expect(KitInstrument.crash1.gmNote, 49);
      expect(KitInstrument.crash2.gmNote, 57);
      expect(KitInstrument.ride.gmNote, 51);
      expect(KitInstrument.rideBell.gmNote, 53);
      expect(KitInstrument.china.gmNote, 52);
      expect(KitInstrument.splash.gmNote, 55);
      expect(KitInstrument.pad.gmNote, isNull);
    });

    test('learn order starts with snare and kick and never contains pad', () {
      expect(KitInstrument.learnOrder.first, KitInstrument.snare);
      expect(KitInstrument.learnOrder[1], KitInstrument.kick);
      expect(KitInstrument.learnOrder, isNot(contains(KitInstrument.pad)));
      expect(KitInstrument.learnOrder.length, 16);
    });

    test('fromName round-trips and rejects unknown names', () {
      expect(KitInstrument.fromName('floorTom2'), KitInstrument.floorTom2);
      expect(KitInstrument.fromName('bongo'), isNull);
    });
  });

  group('KitMapping', () {
    test('GM default maps every instrument note and nothing else', () {
      final m = KitMapping.gm();
      expect(m.instrumentFor(38), KitInstrument.snare);
      expect(m.instrumentFor(36), KitInstrument.kick);
      expect(m.instrumentFor(99), isNull);
      expect(m.notes[KitInstrument.pad], isNull);
    });

    test('assign moves a note away from its previous instrument', () {
      // The module sends 38 for the snare head AND the user maps 38 to the
      // rim by mistake: the note must live in exactly one place.
      final m = KitMapping.gm().assign(KitInstrument.snareRim, 38);
      expect(m.instrumentFor(38), KitInstrument.snareRim);
      expect(m.notes[KitInstrument.snare], isEmpty);
      // Original mapping is untouched (value semantics).
      expect(KitMapping.gm().instrumentFor(38), KitInstrument.snare);
    });

    test('assign adds a second zone to the same instrument', () {
      final m = KitMapping.gm().assign(KitInstrument.snare, 40);
      expect(m.notes[KitInstrument.snare], {38, 40});
      expect(m.instrumentFor(40), KitInstrument.snare);
    });

    test('remove clears an instrument', () {
      final m = KitMapping.gm().remove(KitInstrument.splash);
      expect(m.notes[KitInstrument.splash], isEmpty);
      expect(m.instrumentFor(55), isNull);
    });

    test('json round-trip keeps every note', () {
      final m = KitMapping.gm().assign(KitInstrument.snare, 40);
      final back = KitMapping.decode(m.encode());
      expect(back.notes, m.notes);
      expect(jsonDecode(m.encode()), isA<Map<String, Object?>>());
    });

    test('decode tolerates unknown instrument names and bad values', () {
      final back = KitMapping.decode('{"snare":[38,"x"],"bongo":[60]}');
      expect(back.notes[KitInstrument.snare], {38});
      expect(back.instrumentFor(60), isNull);
    });
  });
}
