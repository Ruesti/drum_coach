# Audio credits

- `snare.wav` — "acoustic snare.wav" by [KEVOY](https://freesound.org/people/KEVOY/sounds/82249/),
  licensed [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) (public domain).
  Shipped as 16-bit 44.1 kHz mono WAV (decoded from the former snare.mp3 with ffmpeg,
  MP3 encoder delay removed). Pad snare (practice engine + guided pad exercises).

## Guided kit (one acoustic kit, one recording session)

All kit sounds of the guided player come from the pack
["Gui_DRUM" by menegass](https://freesound.org/people/menegass/packs/6393/) on Freesound,
each sound page licensed [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)
(public domain). Taken from the trimmed FLAC copies Sonic Pi ships in
[sonic-pi-net/sonic-pi `etc/samples`](https://github.com/sonic-pi-net/sonic-pi/tree/main/etc/samples)
(their [README](https://github.com/sonic-pi-net/sonic-pi/blob/main/etc/samples/README.md) lists the
Freesound origin of each file and states CC0). Converted with ffmpeg to 16-bit 44.1 kHz mono WAV,
starting on the first millisecond, faded out at the end, peak-normalised (drums 0.9, cymbals and
hi-hats 0.8).

- `kick.wav` — Gui_DRUM_BD_soft.wav, <https://freesound.org/people/menegass/sounds/100052/>
  (Sonic Pi `drum_bass_soft`; the "hard" take is clipped in the source, the soft one is clean).
- `kit_snare.wav` — Gui_DRUM_SNARE_hard.wav, <https://freesound.org/people/menegass/sounds/100058/>
  (Sonic Pi `drum_snare_hard`).
- `snare_ghost.wav` — Gui_DRUM_SNARE_soft.wav, <https://freesound.org/people/menegass/sounds/100059/>
  (Sonic Pi `drum_snare_soft`), played for ghost notes.
- `hihat_closed.wav` — Gui_DRUM_CC.wav "Closed Cymbal", <https://freesound.org/people/menegass/sounds/100053/>
  (Sonic Pi `drum_cymbal_closed`).
- `hihat_open.wav` — Gui_DRUM_CO.wav "Open Cymbal", <https://freesound.org/people/menegass/sounds/100055/>
  (Sonic Pi `drum_cymbal_open`).
- `crash.wav` — Gui_DRUM_SPLASH_hard.wav "Crash hard", <https://freesound.org/people/menegass/sounds/100060/>
  (Sonic Pi `drum_splash_hard`), cut to 2.5 s with a 0.5 s fade-out. Replaces the former
  Wikimedia crash (RyGuy, PD-self).
- `ride.wav` — Gui_DRUM_CYN_hard.wav "Ride hard", <https://freesound.org/people/menegass/sounds/100056/>
  (Sonic Pi `drum_cymbal_hard`).
- `tom_high.wav` — Gui_DRUM_TOM_HI_hard.wav, <https://freesound.org/people/menegass/sounds/100062/>
  (Sonic Pi `drum_tom_hi_hard`).
- `tom_low.wav` — Gui_DRUM_TOM_MID_hard.wav, <https://freesound.org/people/menegass/sounds/100066/>
  (Sonic Pi `drum_tom_mid_hard`), the low rack tom.
- `tom_floor.wav` — Gui_DRUM_TOM_LO_hard.wav, <https://freesound.org/people/menegass/sounds/100064/>
  (Sonic Pi `drum_tom_lo_hard`), the floor tom.

No free recording of this kit for rim/cross-stick, hi-hat pedal or ride bell: the player uses
the kit snare, the closed hi-hat and the ride for those.
