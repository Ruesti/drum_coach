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

Facts below are taken from each voice's Piper model card (MODEL_CARD line
"License"). A public-domain dataset carries no conditions, which is why the
rendered audio may ship in a commercial app.

- `en_GB-cori-high` (default). Dataset: LibriVox recordings
  (https://librivox.org), public domain; trained from scratch by Bryce Beattie
  (https://brycebeattie.com/files/tts/). Model card:
  https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_GB/cori/high/MODEL_CARD
- `en_US-ljspeech-high`. Dataset: LJ Speech
  (https://keithito.com/LJ-Speech-Dataset/), public domain; trained from
  scratch by Bryce Beattie. Model card: https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/ljspeech/high/MODEL_CARD

Voices not to use (model card licence lines):

- lessac/high: licence is the Blizzard 2013 licence page
  (https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/license.html);
  card: https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/lessac/high/MODEL_CARD
- amy/medium and alan/medium: "Finetuned from U.S. English lessac voice",
  licence "See URL" (Mycroft mimic3-voices);
  cards: https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/amy/medium/MODEL_CARD, https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_GB/alan/medium/MODEL_CARD
- ryan/high: CC BY-NC-SA 4.0 (non-commercial);
  card: https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/ryan/high/MODEL_CARD

`manifest.json` records `voice`, `license` and `source` of the rendered voice;
an unknown voice (not in `VOICE_INFO` in `render_clips.py`) is rejected.
`--force` re-renders despite an unchanged hash; `--only` requires the same
voice as the existing manifest (otherwise do a full render).
`--prune-prefix g_` removes manifest entries and WAVs whose id starts with the
prefix but is no longer in `SAETZE` (e.g. renamed catalog clips); other ids are
never touched. Catalog clips: `tool/stimme/.venv/bin/python
tool/stimme/render_clips.py --prune-prefix g_`.
