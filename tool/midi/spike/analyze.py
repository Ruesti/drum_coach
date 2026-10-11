#!/usr/bin/env python3
"""Auswertung §0: send.jsonl (Sender) + recv.jsonl (Empfänger) → Kennzahlen.
Aufruf: analyze.py send.jsonl recv.jsonl [label]
Vergleich über Intervalle: d_i = (recv_i - recv_0) - (send_i - send_0)
(Uhren dürfen verschieden sein, nur Drift/Jitter zählt).
"""
import json
import statistics as st
import sys

send = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
recv = [json.loads(l) for l in open(sys.argv[2]) if l.strip()]
label = sys.argv[3] if len(sys.argv) > 3 else ""

print(f"== {label} ==  gesendet {len(send)}  empfangen {len(recv)}")
n = min(len(send), len(recv))
if len(send) != len(recv):
    print("!! Anzahl weicht ab — Zuordnung über Reihenfolge nur bis zum ersten Verlust gültig")

def pct(xs, p):
    xs = sorted(xs)
    k = int(round((len(xs) - 1) * p))
    return xs[k]

def report(kind, key):
    s0 = send[0]["send_us"]
    r0 = recv[0][key]
    d = []  # ms
    tags = []
    for i in range(n):
        ds = (send[i]["send_us"] - s0) / 1000.0
        dr = (recv[i][key] - r0) / 1000.0
        d.append(dr - ds)
        tags.append(send[i]["tag"])
    med = st.median(d)
    dev = [x - med for x in d]
    absdev = [abs(x) for x in dev]
    print(f"  [{kind}] Versatz ggü. Sender (ms): median {med:+.3f}  "
          f"p50 |abw| {pct(absdev,0.5):.3f}  p95 |abw| {pct(absdev,0.95):.3f}  "
          f"max |abw| {max(absdev):.3f}  spanne {max(d)-min(d):.3f}")
    # Drift: lineare Steigung über die Zeit (ms pro Minute)
    ts = [(send[i]["send_us"] - s0) / 60e6 for i in range(n)]
    if n > 2:
        mt = st.mean(ts); md = st.mean(d)
        num = sum((ts[i]-mt)*(d[i]-md) for i in range(n))
        den = sum((ts[i]-mt)**2 for i in range(n))
        if den > 0:
            print(f"  [{kind}] Drift: {num/den:+.3f} ms/min")
    # je Segment
    for seg in ("A", "B1", "B2", "C", "D"):
        xs = [absdev[i] for i in range(n) if tags[i] == seg]
        if xs:
            print(f"  [{kind}]   Segment {seg:2s} n={len(xs):3d}  p50 {pct(xs,0.5):.3f}  p95 {pct(xs,0.95):.3f}  max {max(xs):.3f}")
    # Flam-Abstände: B2 - B1 empfangen vs gesendet
    fl_s, fl_r = [], []
    for i in range(1, n):
        if tags[i] == "B2" and tags[i-1] == "B1":
            fl_s.append((send[i]["send_us"] - send[i-1]["send_us"]) / 1000.0)
            fl_r.append((recv[i][key] - recv[i-1][key]) / 1000.0)
    if fl_r:
        print(f"  [{kind}] Flam-Abstand gesendet median {st.median(fl_s):.3f} ms, "
              f"empfangen median {st.median(fl_r):.3f} ms, min {min(fl_r):.3f}, max {max(fl_r):.3f}")
    # Burst D: Abstände
    bd = [(recv[i][key] - recv[i-1][key]) / 1000.0 for i in range(1, n) if tags[i] == "D" and tags[i-1] == "D"]
    if bd:
        print(f"  [{kind}] Burst 10 ms: empfangene Abstände min {min(bd):.3f}  max {max(bd):.3f}  n={len(bd)}")

report("Rx-Isolate", "lib_ts")
report("Haupt-Isolate", "main_us")
# Zusatz: Wie lange braucht der Weg Rx-Isolate → Haupt-Isolate?
hop = [(recv[i]["main_us"] - recv[i]["lib_ts"]) / 1000.0 for i in range(n)]
print(f"  Hop Rx→Haupt (ms): median {st.median(hop):.3f}  p95 {pct(hop,0.95):.3f}  max {max(hop):.3f}")
