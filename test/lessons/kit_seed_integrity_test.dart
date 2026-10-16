import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:drum_coach/shared/widgets/kit_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final kits = rudimentsSeedData.where((r) => r.isKit).toList();

  test('there are kit exercises, all MIDI-only with pattern voices', () {
    expect(kits, isNotEmpty);
    for (final r in kits) {
      expect(r.requiredSensor, SensorLevel.midi, reason: r.id);
      expect(r.voicing, ExerciseVoicing.kit, reason: r.id);
      expect(r.patternVoices, isNotEmpty, reason: r.id);
      expect(r.backing, isNull, reason: '${r.id}: the player is the band');
      expect(
          r.limbs.contains(Limb.allFour) ||
              r.limbs.contains(Limb.feet) ||
              r.limbs.contains(Limb.doubleBass),
          isTrue,
          reason: r.id);
      if (r.limbs.contains(Limb.doubleBass)) {
        expect(r.hasFootSides, isTrue,
            reason: '${r.id} is doubleBass without foot sides');
      }
      // The PATTERN bar: one bar in every voice, sticking = its first voice.
      expect(
          kitBarsOrThrow(r.patternVoices,
              beatsPerBar: r.beatsPerBar, grid: r.gridUnit),
          1,
          reason: r.id);
      expect(r.sticking, same(r.patternVoices.first.beats), reason: r.id);
    }
  });

  test(
      'every kit line: kit voices of equal whole bars (1..8), drawable '
      'layers, sheet ≤ 64 bars; a line never holds the same instrument twice',
      () {
    for (final r in kits) {
      for (var i = 0; i < r.lines.length; i++) {
        final l = r.lines[i];
        expect(l.isKit, isTrue, reason: '${r.id} line ${i + 1}');
        final bars = kitBarsOrThrow(l.kitVoices,
            beatsPerBar: r.beatsPerBar, grid: r.gridUnit);
        expect(bars, inInclusiveRange(1, 8), reason: '${r.id} line ${i + 1}');
        final instruments = l.kitVoices.map((v) => v.instrument).toList();
        expect(instruments.toSet().length, instruments.length,
            reason: '${r.id} line ${i + 1} repeats an instrument');
        expect(
            () => computeKitLineLayout(
                voices: l.kitVoices,
                grid: r.gridUnit,
                beatsPerBar: r.beatsPerBar,
                maxWidth: 360),
            returnsNormally,
            reason: '${r.id} line ${i + 1} is not drawable');
      }
      expect(sheetBars(r), lessThanOrEqualTo(64), reason: r.id);
      expect(
          () => SheetPlan.sequence(
              r, [for (var i = 0; i < r.sheet.length; i++) i]),
          returnsNormally,
          reason: r.id);
    }
  });

  test(
      'the seven groove sheets: 8 lines, 16 bars, hi-hat/ride, '
      'snare and kick in line 1, four lesson sections', () {
    const ids = [
      'groove_rock8',
      'groove_rock16',
      'groove_halftime',
      'groove_shuffle',
      'groove_swing',
      'groove_funk16',
      'groove_hihat_open',
    ];
    for (final id in ids) {
      final r = rudimentsSeedData.firstWhere((r) => r.id == id);
      expect(r.sheet.length, 8, reason: id);
      expect(r.sheet.every((l) => l.repeat), isTrue, reason: id);
      expect(sheetBars(r), 16, reason: id);
      expect(r.skills.contains(Skill.groove), isTrue, reason: id);
      final first = r.sheet.first.kitVoices.map((v) => v.instrument).toSet();
      expect(first.contains(KitInstrument.kick), isTrue, reason: id);
      expect(
          first.contains(KitInstrument.hiHatClosed) ||
              first.contains(KitInstrument.ride),
          isTrue,
          reason: id);
      expect(
          r.technique.map((s) => s.title),
          [
            'Why it matters',
            'How to play it',
            'Practice tips',
            'Where you hear it'
          ],
          reason: id);
    }
    final hats =
        rudimentsSeedData.firstWhere((r) => r.id == 'groove_hihat_open');
    expect(
        hats.lines.every((l) =>
            l.kitVoices.any((v) => v.instrument == KitInstrument.hiHatOpen) ||
            l.kitVoices.any((v) => v.instrument == KitInstrument.hiHatPedal)),
        isTrue,
        reason: 'every hi-hat line opens or pedals');
  });

  test(
      'the eight set fills: 3 bars of groove + 1 bar of fill per line, the '
      'one after the fill on a crash, kick under the fill; around the kit', () {
    const ids = [
      'set_fill_sixteenth_singles',
      'set_fill_doubles',
      'set_fill_paradiddle',
      'set_fill_triplets',
      'set_fill_flams',
      'set_fill_sextuplets',
      'set_fill_six_groups',
      'set_fill_roll',
    ];
    for (final id in ids) {
      final r = rudimentsSeedData.firstWhere((r) => r.id == id);
      expect(r.sheet.length, 8, reason: id);
      expect(sheetBars(r), 32, reason: id);
      expect(r.skills.contains(Skill.fill), isTrue, reason: id);
      for (var i = 0; i < 8; i++) {
        final l = r.sheet[i];
        final crash = l.kitVoices.where(
            (v) => InstrumentClass.anyCrash.members.contains(v.instrument));
        expect(crash, isNotEmpty, reason: '$id line ${i + 1}: no crash');
        expect(crash.first.accepts, InstrumentClass.anyCrash, reason: id);
        expect(crash.first.beats.first.isRest, isFalse,
            reason: '$id line ${i + 1}: the crash is the one');
        final toms = l.kitVoices.where(
            (v) => InstrumentClass.anyTom.members.contains(v.instrument));
        expect(toms.every((v) => v.accepts == InstrumentClass.anyTom), isTrue,
            reason: '$id line ${i + 1}: toms accept any tom');
        expect(
            l.kitVoices.any((v) => v.instrument == KitInstrument.kick), isTrue,
            reason: '$id line ${i + 1}: no kick');
      }
    }
    final around =
        rudimentsSeedData.firstWhere((r) => r.id == 'set_around_the_kit');
    expect(around.sheet.length, 8);
    expect(sheetBars(around), 16);
    final cymbals = {
      for (final l in around.sheet)
        ...l.kitVoices
            .map((v) => v.instrument)
            .where((i) => InstrumentClass.anyCymbal.members.contains(i))
    };
    expect(cymbals.contains(KitInstrument.china), isTrue);
    expect(cymbals.contains(KitInstrument.rideBell), isTrue);
    expect(cymbals.contains(KitInstrument.crash1), isTrue);
  });

  test(
      'the seven feet sheets: form, limbs, foot sides where double bass, '
      'whole-sheet units build', () {
    const ids = {
      'feet_kick_control': Limb.feet,
      'feet_kick_sixteenths': Limb.feet,
      'feet_double_bass_eighths': Limb.doubleBass,
      'feet_double_bass_sixteenths': Limb.doubleBass,
      'feet_double_bass_triplets': Limb.doubleBass,
      'feet_hihat_foot': Limb.feet,
      'feet_ostinatos': Limb.allFour,
    };
    for (final e in ids.entries) {
      final r = rudimentsSeedData.firstWhere((r) => r.id == e.key);
      expect(r.sheet.length, 8, reason: e.key);
      expect(sheetBars(r), 16, reason: e.key);
      expect(r.limbs.contains(e.value), isTrue, reason: e.key);
      expect(r.hasFootSides, e.value == Limb.doubleBass, reason: e.key);
      expect(
          () => SheetPlan.sequence(
              r, [for (var i = 0; i < r.sheet.length; i++) i]),
          returnsNormally,
          reason: e.key);
      expect(
          r.technique.map((s) => s.title),
          [
            'Why it matters',
            'How to play it',
            'Practice tips',
            'Where you hear it'
          ],
          reason: e.key);
      // Every line has a foot voice (kick or pedal): these sheets train the feet.
      for (var i = 0; i < r.lines.length; i++) {
        expect(r.lines[i].kitVoices.any((v) => v.isFoot), isTrue,
            reason: '${e.key} line ${i + 1} has no foot voice');
      }
    }
    final db = rudimentsSeedData
        .firstWhere((r) => r.id == 'feet_double_bass_sixteenths');
    final kick = db.lines.first.kitVoices
        .firstWhere((v) => v.instrument == KitInstrument.kick);
    expect(kick.beats.take(4).map((b) => b.hand).toList(),
        [Hand.right, Hand.left, Hand.right, Hand.left]);
  });

  test('set_more: linear sheets are linear, fills carry their own feet', () {
    bool linear(ExerciseLine l) {
      final ticks = <int>{};
      for (final v in l.kitVoices) {
        for (final o in onsetsOf(v.beats, NoteGrid.sixteenth)) {
          if (!ticks.add(o.tick)) return false;
        }
      }
      return true;
    }

    final lin = rudimentsSeedData.firstWhere((r) => r.id == 'groove_linear');
    expect(lin.sheet.length, 8);
    expect(lin.lines.every(linear), isTrue,
        reason: 'groove_linear is not linear');
    final fill = rudimentsSeedData.firstWhere((r) => r.id == 'set_fill_linear');
    expect(sheetBars(fill), 32);
    // The fill bar (bar 4 of each line) is linear.
    final barTicks = fill.beatsPerBar * kitTicksPerQuarter;
    for (var i = 0; i < fill.sheet.length; i++) {
      const fillBars = {3};
      final ticks = <int>{};
      for (final v in fill.sheet[i].kitVoices) {
        for (final o in onsetsOf(v.beats, fill.gridUnit)) {
          if (!fillBars.contains(o.tick ~/ barTicks)) continue;
          expect(ticks.add(o.tick), isTrue,
              reason:
                  'set_fill_linear sheet line ${i + 1}: fill bar not linear at tick ${o.tick}');
        }
      }
    }
    final db =
        rudimentsSeedData.firstWhere((r) => r.id == 'set_fill_double_bass');
    expect(db.hasFootSides, isTrue);
    expect(db.limbs.contains(Limb.doubleBass), isTrue);
    final k16 =
        rudimentsSeedData.firstWhere((r) => r.id == 'groove_kick_sixteenths');
    expect(sheetBars(k16), 16);
  });
}
