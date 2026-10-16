import '../coaching/midi/kit_instrument.dart';
import '../lessons/models/pattern_playback.dart';
import '../lessons/models/rudiment.dart';
import '../metronome/loop_voices.dart';

/// Kit exercises (S23 test 16.10.: "Backing makes no difference"): with
/// Backing on, the band plays the unit's own kick and hi-hat voices with
/// the real backing samples — the player hears the groove and plays along.
/// Snare, toms and cymbals have no samples of their own; they stay in the
/// pattern sound as before.

/// Volume of a kit stroke on the band's scale (`BackingHit.level`): accent
/// 1.0 (from 0.9 the hi-hat uses its loud, slightly open sample), normal
/// 0.7, ghost 0.35; an open hi-hat is always loud.
double kitBandVolume(StrokeBeat b) {
  if (b.isRest) return 0.0;
  if (b.isAccent) return 1.0;
  if (b.isGhost) return 0.35;
  return 0.7;
}

KitSound? kitSoundOf(KitInstrument i) => switch (i) {
      KitInstrument.kick => KitSound.kick,
      KitInstrument.hiHatClosed ||
      KitInstrument.hiHatOpen ||
      KitInstrument.hiHatPedal =>
        KitSound.hihat,
      _ => null,
    };

/// The band tracks of a kit unit: one per kick or hi-hat voice, tick
/// volumes on the 24-tick pattern clock (same length as
/// `buildVoicesPlayback`). Empty for a pad unit.
List<KitSoundTrack> kitBackingTracks(List<Voice> voices, NoteGrid grid) => [
      for (final v in voices)
        if (kitSoundOf(v.instrument) case final sound?)
          KitSoundTrack(
            buildPatternPlayback(v.beats, grid,
                    volumeOf: v.instrument == KitInstrument.hiHatOpen
                        ? (b) => b.isRest ? 0.0 : 1.0
                        : kitBandVolume)
                .tickVolumes,
            sound,
          ),
    ];

/// What the band plays: pad units get the automatic style with the band
/// silent in voices the player covers (Brief B.4, unchanged); kit units
/// get no style but their own kick/hi-hat tracks — all of them with
/// Backing on, none with it off (click only).
({String? styleId, bool kick, bool hihat, List<KitSoundTrack> kitTracks})
    backingFor({
  required bool isKit,
  required bool backingOn,
  required String? styleId,
  required bool playsKick,
  required bool playsHihat,
  required List<KitSoundTrack> kitTracks,
}) {
  if (isKit) {
    return (
      styleId: null,
      kick: true,
      hihat: true,
      kitTracks: backingOn ? kitTracks : const <KitSoundTrack>[],
    );
  }
  return (
    styleId: backingOn ? styleId : null,
    kick: !playsKick,
    hihat: !playsHihat,
    kitTracks: const <KitSoundTrack>[],
  );
}
