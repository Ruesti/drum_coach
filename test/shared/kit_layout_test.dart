import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/kit_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<StrokeBeat> hh8() => eighths([R, R, R, R, R, R, R, R]);
  List<StrokeBeat> backbeat() => [
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
      ];
  List<StrokeBeat> kick13() => [
        foot(NoteValue.quarter),
        rest(NoteValue.quarter),
        foot(NoteValue.quarter),
        rest(NoteValue.quarter),
      ];
  Voice hh() => voice(KitInstrument.hiHatClosed, hh8());
  Voice sn() => voice(KitInstrument.snare, backbeat());
  Voice bd() => voice(KitInstrument.kick, kick13());

  group('valueForGap', () {
    test('largest drawable value that fits the gap; 0 and 1 tick undrawable',
        () {
      ({NoteValue v, bool d, Tuplet t}) f(int ticks) {
        final r = valueForGap(ticks)!;
        return (v: r.value, d: r.dotted, t: r.tuplet);
      }

      expect(f(24), (v: NoteValue.quarter, d: false, t: Tuplet.none));
      expect(f(18), (v: NoteValue.eighth, d: true, t: Tuplet.none));
      expect(f(16), (v: NoteValue.quarter, d: false, t: Tuplet.triplet));
      expect(f(12), (v: NoteValue.eighth, d: false, t: Tuplet.none));
      expect(f(9), (v: NoteValue.sixteenth, d: true, t: Tuplet.none));
      expect(f(8), (v: NoteValue.eighth, d: false, t: Tuplet.triplet));
      expect(f(6), (v: NoteValue.sixteenth, d: false, t: Tuplet.none));
      expect(f(4), (v: NoteValue.sixteenth, d: false, t: Tuplet.sextuplet));
      expect(f(3), (v: NoteValue.thirtySecond, d: false, t: Tuplet.none));
      expect(f(2), (v: NoteValue.thirtySecond, d: false, t: Tuplet.triplet));
      // Gaps between table entries take the next smaller value.
      expect(f(30).v, NoteValue.quarter);
      expect(f(5), (v: NoteValue.sixteenth, d: false, t: Tuplet.sextuplet));
      expect(valueForGap(1), isNull);
      expect(valueForGap(0), isNull);
      for (final ticks in [24, 18, 16, 12, 9, 8, 6, 4, 3, 2]) {
        expect(ticksOfNote(valueForGap(ticks)!), ticks);
      }
    });
  });

  group('onsetsOf / ticksOf', () {
    test('rests are no onsets; ticks add up', () {
      final o = onsetsOf(backbeat(), NoteGrid.eighth);
      expect(o.map((e) => e.tick), [24, 72]);
      expect(o.first.beat.isAccent, isTrue);
      expect(ticksOf(backbeat(), NoteGrid.eighth), 96);
      expect(ticksOf(hh8(), NoteGrid.eighth), 96);
    });
  });

  group('layerTrack', () {
    test(
        'hi-hat eighths + backbeat: eight eighths, no letter where the hands '
        'differ (shared column), accent carried', () {
      final layer =
          layerTrack([hh(), sn()], grid: NoteGrid.eighth, totalTicks: 96);
      expect(layer.track.length, 8);
      expect(layer.track.every((b) => !b.isRest && b.value == NoteValue.eighth),
          isTrue);
      expect(layer.track.map((b) => b.hand).toList(),
          [R, R, null, R, R, R, null, R]);
      expect(layer.track[2].isAccent, isTrue);
      expect(layer.track[0].isAccent, isFalse);
      expect(layer.indexOfTick,
          {0: 0, 12: 1, 24: 2, 36: 3, 48: 4, 60: 5, 72: 6, 84: 7});
    });

    test('kick on 1 and 3: quarter, rest, quarter, rest — no hand', () {
      final layer = layerTrack([bd()], grid: NoteGrid.eighth, totalTicks: 96);
      expect(layer.track.map((b) => b.isRest).toList(),
          [false, true, false, true]);
      expect(layer.track.every((b) => b.value == NoteValue.quarter), isTrue);
      expect(layer.track[0].hand, isNull);
      expect(layer.indexOfTick, {0: 0, 48: 2});
    });

    test(
        'gap of 42 ticks (kick on 1 and the "a" of 2): capped at the beat, '
        'rests fill up, nothing drifts', () {
      final kickBeats = [
        foot(NoteValue.quarter), // 0..24
        rest(NoteValue.eighth, dotted: true), // 24..42
        foot(NoteValue.sixteenth), // 42..48
        rest(NoteValue.quarter),
        rest(NoteValue.quarter),
      ];
      expect(ticksOf(kickBeats, NoteGrid.eighth), 96);
      final layer = layerTrack([voice(KitInstrument.kick, kickBeats)],
          grid: NoteGrid.eighth, totalTicks: 96);
      expect(layer.track.map((b) => (b.isRest, b.value, b.dotted)).toList(), [
        (false, NoteValue.quarter, false), // 0..24
        (true, NoteValue.eighth, true), // 24..42
        (false, NoteValue.sixteenth, false), // 42..48
        (true, NoteValue.quarter, false), // 48..72
        (true, NoteValue.quarter, false), // 72..96
      ]);
      expect(ticksOf(layer.track, NoteGrid.eighth), 96);
      expect(layer.indexOfTick, {0: 0, 42: 2});
    });

    test('a hole of two beats is two quarter rests, never a half rest', () {
      final beats = [
        note(R, NoteValue.quarter), // 0..24
        rest(NoteValue.half), // 24..72
        note(R, NoteValue.quarter), // 72..96
      ];
      final layer = layerTrack([voice(KitInstrument.snare, beats)],
          grid: NoteGrid.eighth, totalTicks: 96);
      expect(layer.track.map((b) => (b.isRest, b.value)).toList(), [
        (false, NoteValue.quarter),
        (true, NoteValue.quarter),
        (true, NoteValue.quarter),
        (false, NoteValue.quarter),
      ]);
      expect(layer.indexOfTick, {0: 0, 72: 3});
    });

    test('no voices: rests only, full length', () {
      final layer = layerTrack(const [], grid: NoteGrid.eighth, totalTicks: 96);
      expect(layer.track.length, 4);
      expect(layer.track.every((b) => b.isRest && b.value == NoteValue.quarter),
          isTrue);
      expect(layer.indexOfTick, isEmpty);
    });

    test('a one-tick gap between two voices is not drawable and throws', () {
      // Snare: 32nd on tick 3. Tom: 32nd triplet on tick 4.
      final a = [
        rest(NoteValue.thirtySecond),
        note(R, NoteValue.thirtySecond),
        rest(NoteValue.sixteenth),
        rest(NoteValue.eighth),
        rest(NoteValue.half),
        rest(NoteValue.quarter),
      ];
      final b = [
        rest(NoteValue.thirtySecond, tuplet: Tuplet.triplet),
        rest(NoteValue.thirtySecond, tuplet: Tuplet.triplet),
        note(L, NoteValue.thirtySecond, tuplet: Tuplet.triplet),
        for (var i = 0; i < 9; i++)
          rest(NoteValue.thirtySecond, tuplet: Tuplet.triplet),
        rest(NoteValue.half),
        rest(NoteValue.quarter),
      ];
      expect(ticksOf(a, NoteGrid.eighth), 96);
      expect(ticksOf(b, NoteGrid.eighth), 96);
      expect(
          () => layerTrack([
                voice(KitInstrument.snare, a),
                voice(KitInstrument.tom1, b),
              ], grid: NoteGrid.eighth, totalTicks: 96),
          throwsArgumentError);
    });
  });

  group('computeKitLineLayout', () {
    test('columns = union of onsets; both layers share the scale; x by tick',
        () {
      final kl = computeKitLineLayout(
          voices: [hh(), sn(), bd()],
          grid: NoteGrid.eighth,
          beatsPerBar: 4,
          maxWidth: 360);
      expect(kl.columns.map((c) => c.tick), [0, 12, 24, 36, 48, 60, 72, 84]);
      expect(kl.columns[0].notes.length, 2); // hi-hat + kick
      expect(kl.columns[0].feet.length, 1);
      expect(kl.columns[2].notes.length, 2); // hi-hat + snare
      expect(kl.columns[2].feet, isEmpty);
      expect(kl.columns[1].hands.length, 1);
      expect(kl.hands.pxPerQuarter, kl.feet.pxPerQuarter);
      expect(kl.hands.barsPerRow, kl.feet.barsPerRow);
      expect(
          kl.xOfTick(24) - kl.xOfTick(0), closeTo(kl.scale.pxPerQuarter, 1e-6));
      expect(kl.feet.xOfTick(48), closeTo(kl.hands.xOfTick(48), 1e-6));
      expect(kl.hands.placements[2].xCenter, closeTo(kl.xOfTick(24), 1e-6));
      expect(kl.rowCount, 1);
      expect(kl.rowOfTick(95), 0);
      expect(kl.totalTicks, 96);
      expect(kl.handsTrack.length, 8);
      expect(kl.feetTrack.length, 4);
      expect(kl.handsIndexOfTick[24], 2);
      expect(kl.feetIndexOfTick[48], 2);
    });

    test('rows wrap like a pad line: 2 bars = 1 row, 4 bars = 2 rows', () {
      Voice twice(Voice v) => voice(v.instrument, [...v.beats, ...v.beats]);
      final two = computeKitLineLayout(
          voices: [twice(hh()), twice(sn()), twice(bd())],
          grid: NoteGrid.eighth,
          beatsPerBar: 4,
          maxWidth: 360);
      expect(two.rowCount, 1);
      expect(two.scale.barsPerRow, 2);
      final four = computeKitLineLayout(
          voices: [twice(twice(hh())), twice(twice(sn())), twice(twice(bd()))],
          grid: NoteGrid.eighth,
          beatsPerBar: 4,
          maxWidth: 360);
      expect(four.rowCount, 2);
      expect(four.rowOfTick(0), 0);
      expect(four.rowOfTick(2 * 96), 1);
      expect(four.rowOfTick(4 * 96 - 1), 1);
      expect(four.xOfTick(2 * 96), closeTo(four.xOfTick(0), 1e-6));
    });

    test('voices of different length throw', () {
      expect(
          () => computeKitLineLayout(voices: [
                hh(),
                voice(KitInstrument.tom1, [note(R, NoteValue.half)])
              ], grid: NoteGrid.eighth, beatsPerBar: 4, maxWidth: 360),
          throwsArgumentError);
    });

    test('the finest voice sets the scale, even when it is a foot voice', () {
      final hhQuarters = voice(KitInstrument.hiHatClosed,
          [for (var i = 0; i < 4; i++) note(R, NoteValue.quarter)]);
      final kick16 = voice(KitInstrument.kick,
          [for (var i = 0; i < 16; i++) foot(NoteValue.sixteenth)]);
      final kl = computeKitLineLayout(
          voices: [hhQuarters, kick16],
          grid: NoteGrid.eighth,
          beatsPerBar: 4,
          maxWidth: 120);
      // Legibility floor of a sixteenth-note piece: 9 px / 0.25 q = 36 px/q.
      expect(kl.scale.pxPerQuarter, 36);
      expect(kl.scale.barsPerRow, 1);
    });
  });
}
