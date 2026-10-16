import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/lessons/models/pattern_playback.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:drum_coach/features/metronome/loop_voices.dart';
import 'package:drum_coach/features/practice/kit_backing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/kit_fixtures.dart';

void main() {
  group('kit backing (S23 test 16.10.)', () {
    final r = doubleBassShowcase();
    final plan = SheetPlan.line(r, 1); // hat, snare, kick, pedal
    final tracks = kitBackingTracks(plan.voices, r.gridUnit);

    test('a kit line yields its kick and hi-hat voices, nothing else', () {
      expect(tracks.map((t) => t.sound),
          unorderedEquals([KitSound.hihat, KitSound.kick, KitSound.hihat]));
      final total = buildVoicesPlayback(plan.voices, r.gridUnit).totalTicks;
      for (final t in tracks) {
        expect(t.tickVolumes.length, total);
      }
      // Kick sixteenths in bar 1: every 6th tick sounds at the band level.
      final kick = tracks.firstWhere((t) => t.sound == KitSound.kick);
      expect(kick.tickVolumes[0], 0.7);
      expect(kick.tickVolumes[6], 0.7);
      expect(kick.tickVolumes[3], 0.0);
    });

    test('Backing on: the loop plan carries the line\'s voices; off: none', () {
      List<KitSoundTrack> chosen(bool on) => backingFor(
              isKit: true,
              backingOn: on,
              styleId: 'rock8',
              playsKick: plan.playsKick,
              playsHihat: plan.playsHihat,
              kitTracks: tracks)
          .kitTracks;
      final on = backingFor(
          isKit: true,
          backingOn: true,
          styleId: 'rock8',
          playsKick: true,
          playsHihat: true,
          kitTracks: tracks);
      expect(on.styleId, isNull); // never a style on a kit unit
      expect(chosen(true), same(tracks));
      expect(chosen(false), isEmpty);

      final vols = buildVoicesPlayback(plan.voices, r.gridUnit).tickVolumes;
      LoopPlan loop(bool on) => buildLoopPlan(
            patternVolumes: vols,
            patternLoud: const [0.5],
            patternSoft: const [0.3],
            factor: 24,
            kickSound: const [0.9],
            hihatLoud: const [0.6],
            hihatSoft: const [0.4],
            kitTracks: chosen(on),
          );
      expect(loop(true).voices.length, 1 + tracks.length);
      expect(loop(false).voices.length, 1); // pattern only (+ click if on)
    });

    test('pad units keep the automatic style and the mute flags', () {
      final b = backingFor(
          isKit: false,
          backingOn: true,
          styleId: 'rock8',
          playsKick: false,
          playsHihat: false,
          kitTracks: const []);
      expect(b.styleId, 'rock8');
      expect(b.kick, isTrue);
      expect(b.hihat, isTrue);
      expect(b.kitTracks, isEmpty);
      expect(
          backingFor(
              isKit: false,
              backingOn: false,
              styleId: 'rock8',
              playsKick: false,
              playsHihat: false,
              kitTracks: const []).styleId,
          isNull);
    });

    test('open hi-hat is always loud; snare and toms have no band track', () {
      expect(kitSoundOf(KitInstrument.snare), isNull);
      expect(kitSoundOf(KitInstrument.tom1), isNull);
      expect(kitSoundOf(KitInstrument.hiHatPedal), KitSound.hihat);
      final open = Voice(KitInstrument.hiHatOpen, const [
        StrokeBeat(hand: Hand.right, value: NoteValue.quarter),
      ]);
      expect(
          kitBackingTracks([open], NoteGrid.eighth).single.tickVolumes[0], 1.0);
    });
    test(
        'Backing on: the pattern sound is silent where only kick/hi-hat '
        'sound, the snare keeps it; the clock keeps every onset', () {
      final r = kitShowcase();
      final plan = SheetPlan.line(r, 0); // hat eighths, backbeat, kick 1 + 3
      final playback = buildVoicesPlayback(plan.voices, r.gridUnit);
      final sound = kitPatternSound(plan.voices, r.gridUnit);
      expect(sound.length, playback.totalTicks);
      expect(sound[0], 0.0); // hat + kick
      expect(sound[12], 0.0); // hat alone
      expect(sound[48], 0.0); // hat + kick on 3
      expect(sound[24], greaterThan(0)); // snare on 2
      expect(sound[72], greaterThan(0)); // snare on 4

      ({
        String? styleId,
        bool kick,
        bool hihat,
        List<KitSoundTrack> kitTracks,
        List<double>? patternSound
      }) b(bool on) => backingFor(
          isKit: true,
          backingOn: on,
          styleId: null,
          playsKick: true,
          playsHihat: true,
          kitTracks: kitBackingTracks(plan.voices, r.gridUnit),
          kitPatternSound: sound);
      expect(b(true).patternSound, same(sound));
      expect(b(false).patternSound, isNull); // Backing off: unchanged

      final loop = buildLoopPlan(
        patternVolumes: playback.tickVolumes,
        patternLoud: const [0.5],
        patternSoft: const [0.3],
        factor: 24,
        kickSound: const [0.9],
        hihatLoud: const [0.6],
        hihatSoft: const [0.4],
        kitTracks: b(true).kitTracks,
        patternSound: b(true).patternSound,
      );
      expect(loop.voices.first.tickVolumes[12], 0.0);
      expect(loop.voices.first.tickVolumes[24], greaterThan(0));
      expect(loop.patternVolumes[12], greaterThan(0)); // clock intact
      expect(loop.patternVolumes, playback.tickVolumes);
    });
  });
}
