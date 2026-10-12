import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/midi/kit_learn_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('walks the learn order, assigns notes, finishes', () {
    final s = KitLearnSession(start: KitMapping.gm());
    expect(s.current, KitInstrument.snare);
    expect(s.total, KitInstrument.learnOrder.length);
    s.hit(41);
    expect(s.mapping.instrumentFor(41), KitInstrument.snare);
    // The first hit of a step replaces the old zones.
    expect(s.mapping.notes[KitInstrument.snare], {41});
    // A hit does not advance — the user moves on with Next.
    expect(s.current, KitInstrument.snare);
    s.next();
    expect(s.current, KitInstrument.kick);
    for (var i = 1; i < s.total; i++) {
      s.skip();
    }
    expect(s.done, isTrue);
    expect(s.current, isNull);
  });

  test('several hits on one step collect all zones of the instrument', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.hit(38); // head
    s.hit(40); // rimshot
    s.hit(37); // cross-stick, moved away from the rim instrument
    expect(s.mapping.notes[KitInstrument.snare], {37, 38, 40});
    expect(s.mapping.notes[KitInstrument.snareRim], isEmpty);
    expect(s.hint, contains('Snare rim'));
    expect(s.currentNotes, {37, 38, 40});
  });

  test('the same note twice on a step is a no-op', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.hit(38);
    s.hit(40);
    final before = s.mapping.encode();
    s.hit(38);
    expect(s.mapping.encode(), before);
    expect(s.hint, isNull);
  });

  test('a note already used elsewhere moves and leaves a hint', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.skip(); // snare
    s.hit(38); // kick ← 38 was the snare's note
    expect(s.mapping.instrumentFor(38), KitInstrument.kick);
    expect(s.mapping.notes[KitInstrument.snare], {40});
    expect(s.hint, contains('Snare'));
    s.next();
    expect(s.hint, isNull);
  });

  test('back to a step adds zones instead of replacing them', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.hit(38);
    s.next();
    s.back();
    s.hit(41);
    expect(s.mapping.notes[KitInstrument.snare], {38, 41});
  });

  test('skip keeps the existing assignment', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.skip();
    expect(s.mapping.instrumentFor(38), KitInstrument.snare);
    expect(s.mapping.instrumentFor(40), KitInstrument.snare);
  });

  test('skip after a stray hit restores the step as it was', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.next(); // snare
    s.hit(38); // kick, by mistake
    s.skip();
    expect(s.mapping.notes[KitInstrument.kick], {36});
    expect(s.mapping.notes[KitInstrument.snare], {38, 40});
    expect(s.current, KitInstrument.hiHatClosed);
  });

  test('back from the first step is a no-op; hits after done are ignored', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.back();
    expect(s.index, 0);
    for (var i = 0; i < s.total; i++) {
      s.next();
    }
    s.hit(60);
    expect(s.mapping.instrumentFor(60), isNull);
  });
}
