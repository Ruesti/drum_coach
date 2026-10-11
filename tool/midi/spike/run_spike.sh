#!/usr/bin/env bash
# §0-Lauf: Empfänger (Xvfb, audio-Gruppe) starten, Sender feuern, auswerten.
# Aufruf: run_spike.sh <label> <busy 0|1> [--quick]
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LABEL="$1"; BUSY="$2"; QUICK="${3:-}"
BIN="$HERE/midi_spike/build/linux/x64/release/bundle/midi_spike"
OUT="$HERE/runs/$LABEL"; mkdir -p "$OUT"
EXPECT=256; [ "$QUICK" = "--quick" ] && EXPECT=64

export SPIKE_OUT="$OUT/recv.jsonl" SPIKE_DEVICE="Virtual Raw MIDI 1-0" SPIKE_EXPECT="$EXPECT" SPIKE_BUSY="$BUSY" SPIKE_TIMEOUT_S=240
# Headless-Umgebung: Software-GL, keine Accessibility-Bridge (sonst hängt GTK ohne D-Bus)
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe GDK_BACKEND=x11 NO_AT_BRIDGE=1 GTK_A11Y=none
unset DBUS_SESSION_BUS_ADDRESS
export XDG_RUNTIME_DIR="$HERE/xdg"; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
sg audio -c "xvfb-run -a '$BIN'" > "$OUT/app.log" 2>&1 &
APP_PID=$!
for i in $(seq 1 60); do
  grep -q '^READY' "$OUT/app.log" 2>/dev/null && break
  grep -q '^NO DEVICE' "$OUT/app.log" 2>/dev/null && { cat "$OUT/app.log"; exit 2; }
  sleep 0.5
done
grep -q '^READY' "$OUT/app.log" || { echo "Empfänger nicht bereit"; cat "$OUT/app.log"; kill $APP_PID 2>/dev/null; exit 3; }
sleep 1
sg audio -c "python3 '$HERE/send_pattern.py' /dev/snd/midiC1D0 '$OUT/send.jsonl' $QUICK" | tee "$OUT/send.log"
for i in $(seq 1 120); do
  grep -q '^DONE' "$OUT/app.log" 2>/dev/null && break
  sleep 0.5
done
grep '^DONE' "$OUT/app.log" || { echo "Empfänger nicht fertig"; tail -5 "$OUT/app.log"; }
kill $APP_PID 2>/dev/null; pkill -f "$BIN" 2>/dev/null
python3 "$HERE/analyze.py" "$OUT/send.jsonl" "$OUT/recv.jsonl" "$LABEL" | tee "$OUT/result.txt"
