import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/midi/kit_learn_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('walks the learn order, assigns notes, finishes', () {
    final s = KitLearnSession(start: KitMapping.gm());
    expect(s.current, KitInstrument.snare);
    expect(s.total, KitInstrument.learnOrder.length);
    s.hit(40);
    expect(s.mapping.instrumentFor(40), KitInstrument.snare);
    expect(s.mapping.notes[KitInstrument.snare], {40});
    expect(s.current, KitInstrument.kick);
    for (var i = 1; i < s.total; i++) {
      s.skip();
    }
    expect(s.done, isTrue);
    expect(s.current, isNull);
  });

  test('a note already used elsewhere moves and leaves a hint', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.skip(); // snare
    s.hit(38); // kick ← 38 was the snare's note
    expect(s.mapping.instrumentFor(38), KitInstrument.kick);
    expect(s.mapping.notes[KitInstrument.snare], isEmpty);
    expect(s.hint, contains('Snare'));
  });

  test('a repeated note for the same instrument is a second zone', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.hit(38);
    s.back();
    s.hit(40);
    expect(s.mapping.notes[KitInstrument.snare], {38, 40});
  });

  test('skip keeps the existing assignment', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.skip();
    expect(s.mapping.instrumentFor(38), KitInstrument.snare);
  });

  test('back from the first step is a no-op; hits after done are ignored', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.back();
    expect(s.index, 0);
    for (var i = 0; i < s.total; i++) {
      s.skip();
    }
    s.hit(60);
    expect(s.mapping.instrumentFor(60), isNull);
  });
}
