#!/usr/bin/env python3
"""Renders the teacher sentences with Piper into assets/voice/*.wav + manifest.

    tool/stimme/.venv/bin/python tool/stimme/render_clips.py [--only id,...] [--voice NAME]

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
        return array.array("h")
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
           saetze=SAETZE):
    """Renders all (or `only`) clips into out_dir and updates manifest.json.

    Returns the list of ids that were actually synthesised."""
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    mpath = out_dir / "manifest.json"
    old = {}
    if mpath.exists():
        m = json.loads(mpath.read_text())
        if m.get("voice") == voice:
            old = {c["id"]: c for c in m["clips"]}
    rendered = []
    clips = []
    for cid, text in saetze.items():
        scale = SHORT_WORD_LENGTH_SCALE if cid in SHORT_WORD_IDS else 1.0
        h = text_hash(text, voice, scale)
        prev = old.get(cid)
        wav = out_dir / f"{cid}.wav"
        skip = (only is not None and cid not in only) or (
            prev and prev.get("hash") == h and wav.exists())
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
    mpath.write_text(json.dumps(
        {"voice": voice, "lang": "en", "clips": clips},
        ensure_ascii=False, indent=2) + "\n")
    return rendered


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="comma-separated clip ids")
    ap.add_argument("--voice", default=DEFAULT_VOICE)
    a = ap.parse_args()
    only = set(a.only.split(",")) if a.only else None
    done = render(OUT_DIR, a.voice, only)
    print(f"rendered {len(done)}: {', '.join(done) or '-'}")


if __name__ == "__main__":
    main()
