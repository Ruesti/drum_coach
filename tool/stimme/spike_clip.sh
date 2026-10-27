#!/usr/bin/env bash
# Spike (Plan 1, Task 0): renders one English teacher sentence with Piper as
# a 44.1 kHz mono 16-bit WAV, plus the countdown words next to it
# (<out>_three.wav, _two, _one, _go).
#
#   tool/stimme/spike_clip.sh [out.wav] ["sentence"]
#   VOICE=en_GB-cori-high tool/stimme/spike_clip.sh /tmp/cori.wav
#
# Default voice en_US-ljspeech-high: trained from scratch on the public-domain
# LJ Speech dataset (no lessac/Blizzard lineage, which is non-commercial).
# Sets up the venv tool/stimme/.venv (gitignored) on first run and downloads
# the voice into tool/stimme/.venv/voices. Needs python3 and ffmpeg.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
out="${1:-$here/spike_clip.wav}"
text="${2:-Next up: add the bass drum on the and of three.}"
voice="${VOICE:-en_US-ljspeech-high}"
venv="$here/.venv"
voices="$venv/voices"

if [[ ! -x "$venv/bin/piper" ]]; then
  python3 -m venv "$venv"
  "$venv/bin/pip" install -q -r "$here/requirements.txt"
fi
mkdir -p "$voices"
if [[ ! -f "$voices/$voice.onnx" ]]; then
  "$venv/bin/python" -m piper.download_voices --download-dir "$voices" "$voice"
fi

raw="$(mktemp --suffix=.wav)"
trap 'rm -f "$raw"' EXIT

render() { # text out
  printf '%s' "$1" | "$venv/bin/piper" -m "$voices/$voice.onnx" -f "$raw"
  # Piper renders at the model's rate (22050 Hz); the app mixes at 44100 Hz
  # mono, so resample once here at build time.
  ffmpeg -loglevel error -y -i "$raw" -ar 44100 -ac 1 -c:a pcm_s16le "$2"
  echo "$2 ($(stat -c %s "$2") bytes)"
}

render "$text" "$out"
for w in three two one go; do
  render "${w^}." "${out%.wav}_$w.wav"
done
