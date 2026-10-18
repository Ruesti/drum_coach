# Voice clips (Piper, English)

Renders the teacher's sentences (`saetze.py`) into `assets/voice/*.wav` plus
`assets/voice/manifest.json`. Build-time only; the app ships the WAVs.

    tool/stimme/spike_clip.sh                      # once: creates .venv + voices
    tool/stimme/.venv/bin/python tool/stimme/render_clips.py [--only id,...] [--voice NAME]
    tool/stimme/.venv/bin/python -m pytest tool/stimme

Default voice `en_GB-cori-high` (public domain); `--voice en_US-ljspeech-high`
also works. Output: 44.1 kHz mono 16-bit, silence trimmed to <= 30 ms, peak
-1 dBFS. Unchanged text + voice (hash in the manifest) is not re-rendered.
Single count words are rendered with Piper `--length-scale 0.8` so they stay
under 600 ms.

## Voices and licences

Both are Piper voices trained from scratch on public-domain speech (no
lessac/Blizzard lineage, which is research-only). Public domain carries no
conditions, so shipping the rendered audio in a commercial app is allowed.
Voices to avoid: en_US-lessac/amy, en_GB-alan/joe, de_DE-thorsten (lessac
lineage), en_US-ryan, hfc_* (CC BY-NC-SA). Details: `docs/BERICHT_GEFUEHRT_SPIKE.md`.

| Voice | Dataset | Licence | Source |
|---|---|---|---|
| `en_GB-cori-high` (default) | LibriVox recordings (Cori Samuel) | Public Domain | https://huggingface.co/rhasspy/piper-voices/tree/main/en/en_GB/cori/high (model card: MODEL_CARD there; LibriVox: https://librivox.org/pages/public-domain/) |
| `en_US-ljspeech-high` | LJ Speech (Linda Johnson, LibriVox readings) | Public Domain | https://huggingface.co/rhasspy/piper-voices/tree/main/en/en_US/ljspeech/high (dataset: https://keithito.com/LJ-Speech-Dataset/) |

`manifest.json` records `voice`, `license` and `source` of the rendered voice.
`--force` re-renders despite an unchanged hash; `--only` requires the same
voice as the existing manifest (otherwise do a full render).
