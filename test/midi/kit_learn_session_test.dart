import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/midi/kit_learn_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  KitLearnSession atSnare() => KitLearnSession(
      start: KitMapping.gm(), order: const [KitInstrument.snare]);

  test('walks the default order, assigns notes, finishes', () {
    final s = KitLearnSession(start: KitMapping.gm());
    expect(s.current, KitInstrument.kick);
    expect(s.total, 4);
    s.hit(35);
    expect(s.mapping.instrumentFor(35), KitInstrument.kick);
    // The first hit of a step replaces the old zones.
    expect(s.mapping.notes[KitInstrument.kick], {35});
    // A hit does not advance — the user moves on with Next.
    expect(s.current, KitInstrument.kick);
    s.next();
    expect(s.current, KitInstrument.snare);
    for (var i = 1; i < s.total; i++) {
      s.skip();
    }
    expect(s.done, isTrue);
    expect(s.current, isNull);
  });

  test('a custom order is walked instead', () {
    final s = atSnare();
    expect(s.total, 1);
    expect(s.current, KitInstrument.snare);
    s.next();
    expect(s.done, isTrue);
  });

  test('several hits on one step collect all zones of the instrument', () {
    final s = atSnare();
    s.hit(38); // head
    s.hit(40); // rimshot
    s.hit(37); // cross-stick, moved away from the rim instrument
    expect(s.mapping.notes[KitInstrument.snare], {37, 38, 40});
    expect(s.mapping.notes[KitInstrument.snareRim], isEmpty);
    expect(s.hint, contains('Snare rim'));
    expect(s.currentNotes, {37, 38, 40});
  });

  test('the same note twice on a step is a no-op', () {
    final s = atSnare();
    s.hit(38);
    s.hit(40);
    final before = s.mapping.encode();
    s.hit(38);
    expect(s.mapping.encode(), before);
    expect(s.hint, isNull);
  });

  test('a note already used elsewhere moves and leaves a hint', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.hit(38); // kick ← 38 was the snare's note
    expect(s.mapping.instrumentFor(38), KitInstrument.kick);
    expect(s.mapping.notes[KitInstrument.snare], {40});
    expect(s.hint, contains('Snare'));
    s.next();
    expect(s.hint, isNull);
  });

  test('back to a step adds zones instead of replacing them', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.hit(35);
    s.next();
    s.back();
    s.hit(41);
    expect(s.mapping.notes[KitInstrument.kick], {35, 41});
  });

  test('skip keeps the existing assignment', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.skip();
    expect(s.mapping.instrumentFor(36), KitInstrument.kick);
    expect(s.current, KitInstrument.snare);
  });

  test('skip after a stray hit restores the step as it was', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.hit(38); // snare note, by mistake
    s.skip();
    expect(s.mapping.notes[KitInstrument.kick], {36});
    expect(s.mapping.notes[KitInstrument.snare], {38, 40});
    expect(s.current, KitInstrument.snare);
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
