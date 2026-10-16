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
      expect(r.limbs.contains(Limb.allFour) || r.limbs.contains(Limb.feet),
          isTrue,
          reason: r.id);
      // The PATTERN bar: one bar in every voice, sticking = its first voice.
      expect(
          kitBarsOrThrow(r.patternVoices,
              beatsPerBar: r.beatsPerBar, grid: r.gridUnit),
          1,
          reason: r.id);
      expect(r.sticking, same(r.patternVoices.first.beats), reason: r.id);
    }
  });

  test('every kit line: kit voices of equal whole bars (1..8), drawable '
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
      expect(() => SheetPlan.wholeSheet(r), returnsNormally, reason: r.id);
    }
  });

  test('the seven groove sheets: 8 lines + Challenge, 24 bars, hi-hat/ride, '
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
      expect(r.sheet.length, 9, reason: id);
      expect(r.sheet.take(8).every((l) => l.repeat), isTrue, reason: id);
      expect(r.sheet.last.repeat, isFalse, reason: id);
      expect(r.sheet.last.title, 'Challenge', reason: id);
      expect(sheetBars(r), 24, reason: id);
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
          ['Why it matters', 'How to play it', 'Practice tips', 'Where you hear it'],
          reason: id);
    }
    final hats = rudimentsSeedData.firstWhere((r) => r.id == 'groove_hihat_open');
    expect(
        hats.lines.every((l) =>
            l.kitVoices.any((v) => v.instrument == KitInstrument.hiHatOpen) ||
            l.kitVoices.any((v) => v.instrument == KitInstrument.hiHatPedal)),
        isTrue,
        reason: 'every hi-hat line opens or pedals');
  });
}
