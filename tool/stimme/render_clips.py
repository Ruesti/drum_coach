#!/usr/bin/env python3
"""Renders the teacher sentences with Piper into assets/voice/*.wav + manifest.

    tool/stimme/.venv/bin/python tool/stimme/render_clips.py [--only id,...] [--voice NAME]
        [--force] [--prune-prefix PREFIX]

Output: 44100 Hz mono 16-bit WAV, leading/trailing silence trimmed to <= 30 ms,
peak -1 dBFS. Clips whose text+voice hash is unchanged are not re-rendered.
Needs the venv (see spike_clip.sh) and ffmpeg; the synth function is injectable
so the tests run without Piper.
"""
import argparse
import array
import hashlib
import io
import json
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from saetze import SAETZE, SHORT_WORD_IDS, SHORT_WORD_LENGTH_SCALE  # noqa: E402

RATE = 44100
DEFAULT_VOICE = "en_GB-cori-high"
MAX_PAD_MS = 30
PEAK_DBFS = -1.0
SILENCE_THRESHOLD = 0.02  # fraction of full scale

# Provenance written into manifest.json (see README.md for the reasoning).
VOICE_INFO = {
    "en_GB-cori-high": {
        "license": "Public Domain (LibriVox recordings)",
        "source": "https://huggingface.co/rhasspy/piper-voices/tree/main/en/en_GB/cori/high",
    },
    "en_US-ljspeech-high": {
        "license": "Public Domain (LJ Speech dataset)",
        "source": "https://huggingface.co/rhasspy/piper-voices/tree/main/en/en_US/ljspeech/high",
    },
}

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OUT_DIR = ROOT / "assets" / "voice"
VOICES_DIR = HERE / ".venv" / "voices"
PIPER = HERE / ".venv" / "bin" / "piper"


def trim_and_normalize(samples, rate=RATE, max_pad_ms=MAX_PAD_MS,
                       peak_dbfs=PEAK_DBFS, threshold=SILENCE_THRESHOLD):
    """Trims silence to max_pad_ms at both ends and scales peak to peak_dbfs."""
    limit = int(32768 * threshold)
    first = next((i for i, v in enumerate(samples) if abs(v) > limit), None)
    if first is None:
        raise ValueError("synth output is silent: nothing to trim")
    last = len(samples) - 1 - next(
        i for i, v in enumerate(reversed(samples)) if abs(v) > limit)
    pad = int(rate * max_pad_ms / 1000)
    out = samples[max(0, first - pad):min(len(samples), last + 1 + pad)]
    peak = max(abs(v) for v in out)
    gain = (10 ** (peak_dbfs / 20) * 32767) / peak
    return array.array("h", (max(-32768, min(32767, round(v * gain)))
                             for v in out))


def read_wav(data):
    with wave.open(io.BytesIO(data)) as w:
        assert w.getnchannels() == 1 and w.getsampwidth() == 2
        assert w.getframerate() == RATE
        s = array.array("h")
        s.frombytes(w.readframes(w.getnframes()))
        return s


def write_wav(path, samples):
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(samples.tobytes())


def piper_synth(text, voice, length_scale):
    """Real synth: Piper (22.05 kHz) -> ffmpeg resample to 44.1 kHz mono WAV bytes."""
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.wav"
        cmd = [str(PIPER), "-m", str(VOICES_DIR / f"{voice}.onnx"),
               "-f", str(raw), "--length-scale", str(length_scale)]
        subprocess.run(cmd, input=text.encode(), check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        res = subprocess.run(
            ["ffmpeg", "-loglevel", "error", "-i", str(raw), "-ar", str(RATE),
             "-ac", "1", "-c:a", "pcm_s16le", "-f", "wav", "-"],
            check=True, stdout=subprocess.PIPE)
        return res.stdout


def text_hash(text, voice, length_scale):
    return hashlib.sha256(f"{voice}|{length_scale}|{text}".encode()).hexdigest()[:16]


def render(out_dir, voice=DEFAULT_VOICE, only=None, synth=piper_synth,
           saetze=SAETZE, force=False, prune_prefix=None):
    """Renders all (or `only`) clips into out_dir and updates manifest.json.

    With prune_prefix, every manifest clip whose id starts with it and is not
    in `saetze` is removed (manifest entry and WAV); other ids are never touched
    (old clips outside `saetze` without the prefix are kept as they are).

    Returns the list of ids that were actually synthesised."""
    if voice not in VOICE_INFO:
        raise ValueError(f"unknown voice {voice!r}: add its licence and source "
                         f"to VOICE_INFO first")
    if prune_prefix and not any(cid.startswith(prune_prefix) for cid in saetze):
        raise ValueError(
            f"--prune-prefix {prune_prefix!r}: no id in saetze starts with it; "
            f"refusing to prune (did the import of the generated sentences fail?)")
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    mpath = out_dir / "manifest.json"
    old = {}
    if mpath.exists():
        m = json.loads(mpath.read_text())
        if m.get("voice") == voice:
            old = {c["id"]: c for c in m["clips"]}
        elif only is not None:
            raise ValueError(
                f"--only with voice {voice!r} differs from manifest voice "
                f"{m.get('voice')!r}: do a full render")
    rendered = []
    clips = []
    for cid, text in saetze.items():
        scale = SHORT_WORD_LENGTH_SCALE if cid in SHORT_WORD_IDS else 1.0
        h = text_hash(text, voice, scale)
        prev = old.get(cid)
        wav = out_dir / f"{cid}.wav"
        skip = (only is not None and cid not in only) or (
            not force and prev and prev.get("hash") == h and wav.exists())
        if skip and prev:
            clips.append(prev)
            continue
        if skip:  # excluded by --only and never rendered
            continue
        samples = trim_and_normalize(read_wav(synth(text, voice, scale)))
        write_wav(wav, samples)
        clips.append({"id": cid, "ms": round(len(samples) * 1000 / RATE),
                      "text": text, "hash": h})
        rendered.append(cid)
    if prune_prefix:
        for cid, prev in old.items():
            if cid in saetze:
                continue
            if cid.startswith(prune_prefix):
                (out_dir / f"{cid}.wav").unlink(missing_ok=True)
            else:
                clips.append(prev)
        for wav in out_dir.glob(f"{prune_prefix}*.wav"):
            if wav.stem not in saetze:
                wav.unlink()
    mpath.write_text(json.dumps(
        {"voice": voice, "lang": "en", **VOICE_INFO.get(voice, {}),
         "clips": clips},
        ensure_ascii=False, indent=2) + "\n")
    return rendered


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="comma-separated clip ids")
    ap.add_argument("--voice", default=DEFAULT_VOICE)
    ap.add_argument("--force", action="store_true",
                    help="re-render even if text+voice hash is unchanged")
    ap.add_argument("--prune-prefix", metavar="PREFIX",
                    help="remove manifest entries and WAVs with this id prefix "
                         "that are no longer in SAETZE (e.g. g_)")
    a = ap.parse_args()
    only = set(a.only.split(",")) if a.only else None
    try:
        done = render(OUT_DIR, a.voice, only, force=a.force,
                     prune_prefix=a.prune_prefix)
    except ValueError as e:
        sys.exit(f"error: {e}")
    print(f"rendered {len(done)}: {', '.join(done) or '-'}")


if __name__ == "__main__":
    main()
