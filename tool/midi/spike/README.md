# §0-Vorversuch: MIDI-Zeitstempel unter Linux

Wegwerf-Aufbau zum Bericht `docs/BERICHT_ETAPPE2_§0.md`. Nicht Teil der App;
Grundlage für den Linux-Integrationstest aus Phase A (`tool/midi/virtual_port_test.sh`).

## Dateien

- `send_pattern.py` — Sender: schreibt Note-On roh auf ein virmidi-Rawmidi-Gerät
  in bekanntem Raster (Viertel, Flam-Paare 25 ms, Sechzehntel 200 BPM, 10-ms-Burst)
  und protokolliert die Sendezeit.
- `receiver_main.dart` — Empfänger: `lib/main.dart` einer leeren Flutter-Linux-App
  mit `flutter_midi_command ^1.4.0`; stempelt im Haupt-Isolate und liest den
  Bibliotheks-Stempel; `SPIKE_BUSY=1` erzeugt Last im Haupt-Isolate.
- `patch_plugin.py` — patcht eine Kopie von `flutter_midi_command_linux` 1.4.0:
  Stempel (µs) im Empfangs-Isolate direkt nach `snd_seq_event_input`.
- `patch_plugin2.py` — lockert den Hardware-Filter der Geräte-Erkennung, damit
  virtuelle Ports erscheinen.
- `analyze.py` — Auswertung Sender ↔ Empfänger (Versatz relativ zur ersten Note,
  Drift, Flam-Abstände, Burst).
- `run_spike.sh` — ein Lauf unter Xvfb mit den nötigen Umgebungsvariablen.
- `runs/` — Ergebnisse der beiden Läufe vom 11.10.2026.

## Nachstellen

1. Voraussetzungen (NUC, 11.10.): `clang cmake ninja-build pkg-config libgtk-3-dev
   libasound2-dev alsa-utils xvfb`, Benutzer in der Gruppe `audio`,
   `modprobe snd-virmidi`.
2. `flutter create --platforms=linux midi_spike`, `flutter pub add
   flutter_midi_command:^1.4.0`, `receiver_main.dart` nach `lib/main.dart`.
3. Plugin-Kopie: `cp -r ~/.pub-cache/hosted/pub.dev/flutter_midi_command_linux-1.4.0
   fmc_linux_patched`, beide Patch-Skripte darauf anwenden, in `pubspec.yaml`
   `dependency_overrides: flutter_midi_command_linux: {path: ../fmc_linux_patched}`.
4. `flutter build linux --release`, dann `./run_spike.sh <label> <0|1> [--quick]`
   (Pfad zur App im Skript anpassen).

Headless-Fallen: ohne `NO_AT_BRIDGE=1 GTK_A11Y=none` hängt die GTK-App beim Start
(Accessibility-Bus), ohne `LIBGL_ALWAYS_SOFTWARE=1` scheitert EGL an der GPU-Berechtigung.
