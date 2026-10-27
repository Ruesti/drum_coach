# Audio credits

Every sound file the app ships, with author, source and licence. The app shows
the same list under Settings → Credits (`lib/features/settings/audio_credits.dart`;
`test/features/settings/credits_test.dart` checks that both agree).

## DRSKit 2.1 (drum kit of the guided exercises)

- Author: the DrumGizmo team (Deva and Lars Muldjord); drums by Jes Eiler, DRSDrums
- Source: <https://drumgizmo.org/wiki/doku.php?id=kits:drskit>
  (download `https://drumgizmo.org/kits/DRSKit/DRSKit2_1.zip`, md5 8c4d4b61ad9d354b3b845edd5da9c133)
- Licence: CC BY 4.0, <https://creativecommons.org/licenses/by/4.0/>.
  Kit page: "The DRSKit drumkit source files are released under the Creative Commons
  Attribution 4.0 International License." README in the download: "This kit is distributed
  under the Creative Commons Attribution 4.0 International license
  (https://creativecommons.org/licenses/by/4.0/)."
- Changes: Mixed down to mono from the close, overhead and room microphones, trimmed,
  shortened with a fade-out and level-matched; three velocity takes per instrument.
  Same microphone gains for every instrument (own close mic(s) + overheads 0.7 + room 0.45;
  kick back/front 0.8, snare top 1.0 / bottom −0.5 (reverse polarity), toms 1.0,
  hi-hat and ride mic 0.6). 16-bit 44.1 kHz mono WAV, starting on the first millisecond,
  hard take of each instrument peak 0.9, soft/medium takes at their natural level.

| File (soft / medium / hard) | DRSKit instrument | Takes |
|---|---|---|
| `assets/audio/kit_kick_soft.wav` / `assets/audio/kit_kick_medium.wav` / `assets/audio/kit_kick_hard.wav` | Kdrum_without_contact | Kdrum_without_contact-8 (power 1.79), Kdrum_without_contact-20 (power 12.7), Kdrum_without_contact-29 (power 32.2) |
| `assets/audio/kit_snare_soft.wav` / `assets/audio/kit_snare_medium.wav` / `assets/audio/kit_snare_hard.wav` | Snare | Snare-8 (power 2.44), Snare-19 (power 14.6), Snare-29 (power 37.9) |
| `assets/audio/kit_rim_soft.wav` / `assets/audio/kit_rim_medium.wav` / `assets/audio/kit_rim_hard.wav` | Snare_rim | Snare_rim-4 (power 0.0433), Snare_rim-11 (power 0.238), Snare_rim-17 (power 0.577) |
| `assets/audio/kit_hihat_closed_soft.wav` / `assets/audio/kit_hihat_closed_medium.wav` / `assets/audio/kit_hihat_closed_hard.wav` | Hihat_closed | Hihat_closed-8 (power 0.171), Hihat_closed-17 (power 1.07), Hihat_closed-24 (power 2.8) |
| `assets/audio/kit_hihat_open_soft.wav` / `assets/audio/kit_hihat_open_medium.wav` / `assets/audio/kit_hihat_open_hard.wav` | Hihat_open | Hihat_open-5 (power 0.47), Hihat_open-12 (power 3.82), Hihat_open-18 (power 9.25) |
| `assets/audio/kit_hihat_pedal_soft.wav` / `assets/audio/kit_hihat_pedal_medium.wav` / `assets/audio/kit_hihat_pedal_hard.wav` | Hihat_foot | Hihat_foot-1 (power 0.0112), Hihat_foot-4 (power 0.0948), Hihat_foot-6 (power 0.211) |
| `assets/audio/kit_tom_high_soft.wav` / `assets/audio/kit_tom_high_medium.wav` / `assets/audio/kit_tom_high_hard.wav` | Tom1 | Tom1-7 (power 2.03), Tom1-19 (power 13.3), Tom1-27 (power 32.5) |
| `assets/audio/kit_tom_low_soft.wav` / `assets/audio/kit_tom_low_medium.wav` / `assets/audio/kit_tom_low_hard.wav` | Tom2 | Tom2-9 (power 12.1), Tom2-21 (power 76.9), Tom2-30 (power 192) |
| `assets/audio/kit_tom_floor_soft.wav` / `assets/audio/kit_tom_floor_medium.wav` / `assets/audio/kit_tom_floor_hard.wav` | Tom3 | Tom3-7 (power 8.51), Tom3-19 (power 69.3), Tom3-30 (power 166) |
| `assets/audio/kit_crash_soft.wav` / `assets/audio/kit_crash_medium.wav` / `assets/audio/kit_crash_hard.wav` | Crash_left_shank | Crash_left_shank-4 (power 0.14), Crash_left_shank-7 (power 0.71), Crash_left_shank-11 (power 1.86) |
| `assets/audio/kit_ride_soft.wav` / `assets/audio/kit_ride_medium.wav` / `assets/audio/kit_ride_hard.wav` | Ride_tip | Ride_tip-7 (power 0.0306), Ride_tip-11 (power 0.162), Ride_tip-15 (power 0.482) |
| `assets/audio/kit_ride_bell_soft.wav` / `assets/audio/kit_ride_bell_medium.wav` / `assets/audio/kit_ride_bell_hard.wav` | Ride_shank_bell | Ride_shank_bell-3 (power 0.778), Ride_shank_bell-6 (power 3.52), Ride_shank_bell-10 (power 9.99) |
The kit has one rack tom and two floor toms: the low tom of the app is the first (higher)
floor tom.

## Acoustic snare (pad exercises)

- `assets/audio/snare.wav` — "acoustic snare.wav"
- Author: KEVOY
- Source: <https://freesound.org/people/KEVOY/sounds/82249/>
- Licence: CC0 1.0, <https://creativecommons.org/publicdomain/zero/1.0/> (public domain)
- Changes: Converted to WAV, encoder delay removed. Shipped as 16-bit 44.1 kHz mono WAV
  (decoded from the former snare.mp3 with ffmpeg). Pad snare (practice engine + guided pad
  exercises).

## Coach voice (Piper voice en_GB cori, high)

- `assets/voice/` — every spoken clip of the guided exercises
- Author: Bryce Beattie (voice model), from LibriVox recordings
- Source: <https://huggingface.co/rhasspy/piper-voices/tree/main/en/en_GB/cori/high>
- Licence: Public domain, <https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_GB/cori/high/MODEL_CARD>
  (model card: "Dataset … License: public domain")
- Changes: Spoken clips generated offline with Piper.
