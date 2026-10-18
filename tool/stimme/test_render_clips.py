import array
import io
import json
import math
import wave

import pytest

import render_clips as rc


def tone(ms, amp=8000):
    n = int(rc.RATE * ms / 1000)
    return array.array("h", (int(amp * math.sin(2 * math.pi * 440 * i / rc.RATE))
                             for i in range(n)))


def wav_bytes(samples):
    b = io.BytesIO()
    with wave.open(b, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rc.RATE)
        w.writeframes(samples.tobytes())
    return b.getvalue()


def fake_synth(calls=None):
    def synth(text, voice, scale):
        if calls is not None:
            calls.append(text)
        pad = array.array("h", [0] * int(rc.RATE * 0.3))
        return wav_bytes(pad + tone(200 + 10 * len(text)) + pad)
    return synth


def test_trim_keeps_speech():
    pad = array.array("h", [0] * int(rc.RATE * 0.3))
    speech = tone(200)
    out = rc.trim_and_normalize(pad + speech + pad)
    pad_max = int(rc.RATE * rc.MAX_PAD_MS / 1000)
    assert len(speech) <= len(out) <= len(speech) + 2 * pad_max
    assert max(abs(v) for v in out) == pytest.approx(
        10 ** (rc.PEAK_DBFS / 20) * 32767, abs=2)
    # speech body survives (same shape, scaled)
    assert max(abs(v) for v in out[pad_max + 100:pad_max + 400]) > 20000


def test_manifest_ms_equals_wav_length(tmp_path):
    rc.render(tmp_path, "v", synth=fake_synth(), saetze={"a": "Hello", "b": "World peace"})
    m = json.loads((tmp_path / "manifest.json").read_text())
    assert m["lang"] == "en" and m["voice"] == "v"
    for c in m["clips"]:
        with wave.open(str(tmp_path / f"{c['id']}.wav")) as w:
            assert w.getframerate() == 44100 and w.getnchannels() == 1
            assert w.getsampwidth() == 2
            ms = w.getnframes() * 1000 / w.getframerate()
        assert abs(ms - c["ms"]) <= 1


def test_unchanged_text_skips_rerender(tmp_path):
    calls = []
    s = {"a": "Hello", "b": "World"}
    rc.render(tmp_path, "v", synth=fake_synth(calls), saetze=s)
    assert len(calls) == 2
    rc.render(tmp_path, "v", synth=fake_synth(calls), saetze=s)
    assert len(calls) == 2
    s["b"] = "Changed"
    rc.render(tmp_path, "v", synth=fake_synth(calls), saetze=s)
    assert calls[2:] == ["Changed"]
    rc.render(tmp_path, "w", synth=fake_synth(calls), saetze=s)  # other voice
    assert len(calls) == 5


def test_only_renders_subset_and_keeps_others(tmp_path):
    calls = []
    s = {"a": "Hello", "b": "World"}
    rc.render(tmp_path, "v", synth=fake_synth(calls), saetze=s)
    s["a"] = "Hi"
    rc.render(tmp_path, "v", only={"b"}, synth=fake_synth(calls), saetze=s)
    ids = [c["id"] for c in json.loads((tmp_path / "manifest.json").read_text())["clips"]]
    assert sorted(ids) == ["a", "b"] and len(calls) == 2
