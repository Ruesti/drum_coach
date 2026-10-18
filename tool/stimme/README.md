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
