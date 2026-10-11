#!/usr/bin/env python3
"""Sender für den §0-Vorversuch: schreibt Note-On/Off roh auf ein ALSA-Rawmidi-Gerät
(virmidi) in bekanntem Zeitraster und protokolliert die Sendezeit (monotonic, µs).

Aufruf: send_pattern.py /dev/snd/midiC1D0 out.jsonl [--quick]
Muster (Note 38 = Snare, Velocity 100):
  A  120 Viertel bei 500 ms Abstand
  B  32 Flam-Paare (25 ms), Paare 500 ms auseinander
  C  64 Sechzehntel bei 75 ms (200 BPM)
  D  8 Noten bei 10 ms (Burst)
Jede Note bekommt eine laufende Nummer als Velocity-Kodierung? Nein: Velocity bleibt
100; die Zuordnung erfolgt über die Reihenfolge (Empfänger zählt mit).
"""
import json
import os
import sys
import time

dev = sys.argv[1]
out = sys.argv[2]
quick = "--quick" in sys.argv

def pattern():
    seq = []
    t = 0.0
    n_a = 24 if quick else 120
    for _ in range(n_a):
        seq.append(("A", t)); t += 0.500
    t += 0.5
    n_b = 8 if quick else 32
    for _ in range(n_b):
        seq.append(("B1", t)); seq.append(("B2", t + 0.025)); t += 0.500
    t += 0.5
    n_c = 16 if quick else 64
    for _ in range(n_c):
        seq.append(("C", t)); t += 0.075
    t += 0.5
    for _ in range(8):
        seq.append(("D", t)); t += 0.010
    return seq

NOTE_ON = bytes([0x99, 38, 100])   # Kanal 10, Note 38, Velocity 100
NOTE_OFF = bytes([0x89, 38, 0])

fd = os.open(dev, os.O_WRONLY)
seq = pattern()
log = open(out, "w")
t0 = time.monotonic()
idx = 0
for tag, rel in seq:
    target = t0 + rel + 0.2
    # grob schlafen, dann fein warten
    while True:
        now = time.monotonic()
        d = target - now
        if d <= 0:
            break
        if d > 0.002:
            time.sleep(d - 0.0015)
    send_us = int(time.monotonic() * 1e6)
    os.write(fd, NOTE_ON)
    log.write(json.dumps({"i": idx, "tag": tag, "planned_us": int((t0 + rel + 0.2) * 1e6), "send_us": send_us}) + "\n")
    idx += 1
    # Note-Off kurz danach (wird vom Empfänger ignoriert)
    time.sleep(0.003)
    os.write(fd, NOTE_OFF)
log.close()
os.close(fd)
print(f"gesendet: {idx} Noten, Dauer {time.monotonic() - t0:.1f} s")
