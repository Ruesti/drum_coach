# Bericht: Etappe 2 / §0 — Vorversuch MIDI-Zeitstempel unter Linux

**Datum:** 11.10.2026 · **Bezug:** `BRIEF_ETAPPE2_SET.md` §0 · **Maschine:** NUC
(Debian 13, Kernel 6.17, kein Bildschirm, Xvfb) · **Bibliothek:**
`flutter_midi_command` 1.4.0 mit `flutter_midi_command_linux` 1.4.0

## Frage

Liefert die Bibliothek unter Linux Zeitstempel, die für Timing-Messung taugen
(Streuung unter 2 ms, kein Drift, Flams als zwei Noten)? Und: Wo im Weg
Kernel → App muss der Stempel genommen werden?

## Aufbau

- **Sender:** Python-Skript schreibt Note-On roh auf das Rawmidi-Gerät des
  virtuellen Ports (`/dev/snd/midiC1D0`, Kernel-Modul `snd-virmidi`) und
  protokolliert die Sendezeit (monotone Uhr, µs). Muster: 120 Viertel bei 500 ms,
  32 Flam-Paare mit 25 ms Abstand, 64 Sechzehntel bei 75 ms (200 BPM), ein Burst
  von 8 Noten mit 10 ms Abstand. 256 Noten, 83 s.
- **Empfänger:** Wegwerf-Flutter-App (Linux-Build, läuft unter Xvfb) verbindet sich
  mit dem Port und stempelt jede Note an zwei Stellen: (1) direkt im Empfangs-Isolate
  der Bibliothek nach `snd_seq_event_input` (dafür lokal gepatchte Plugin-Kopie,
  µs-Wanduhr) und (2) im Haupt-Isolate im Listener, also dort, wo die Bibliothek
  unverändert ihren Stempel nimmt (sie nimmt dort `DateTime.now()` in ms).
- **Zwei Bedingungen:** Haupt-Isolate ruhig; Haupt-Isolate beschäftigt (Animation
  mit 60 Bildern pro Sekunde plus 4 ms Rechenlast je Bild, ähnlich Notationslayout und
  Cursor im Übungs-Screen).
- **Auswertung:** Versatz jeder Note gegen den Sender, relativ zur ersten Note,
  also unabhängig vom Uhrenunterschied. Angegeben ist der Betrag der Abweichung vom
  Median.

Alle Skripte liegen unter `tool/midi/spike/`, die Ergebnisdateien unter
`tool/midi/spike/runs/`.

## Ergebnis

256 von 256 Noten kamen in beiden Läufen an. Kein Drift (unter 0,2 ms pro Minute).

| Stempel | Bedingung | p50 | p95 | max | Flam 25 ms empfangen | Burst 10 ms empfangen |
|---|---|---|---|---|---|---|
| Empfangs-Isolate | ruhig | 0,002 ms | 0,022 ms | 0,035 ms | 24,97–25,02 ms | 9,97–10,03 ms |
| Empfangs-Isolate | **Last** | 0,009 ms | **0,053 ms** | 0,610 ms | 24,87–25,22 ms | 9,67–10,31 ms |
| Haupt-Isolate | ruhig | 0,008 ms | 0,106 ms | 0,456 ms | 24,88–25,11 ms | 9,85–10,10 ms |
| Haupt-Isolate | **Last** | 2,9 ms | **8,1 ms** | **13,1 ms** | **12,2–34,8 ms** | **0,03–19,0 ms** |

Der Weg vom Empfangs-Isolate ins Haupt-Isolate dauert ruhig konstant 1,2 ms, unter
Last im Median 4,8 ms und bis 17,9 ms.

## Befund

1. **Der Kernel-Weg ist sauber.** ALSA-Sequencer plus Empfangs-Isolate der
   Bibliothek liefern Zeitstempel mit Streuung unter 0,1 ms, auch unter Last.
   Flams und 10-ms-Bursts kommen vollständig und unverfälscht an.
2. **Der Stempel der Bibliothek ist unbrauchbar für Messung.** Unverändert stempelt
   `flutter_midi_command_linux` erst im Haupt-Isolate und nur in Millisekunden.
   Sobald die Oberfläche arbeitet, streut das auf 8 ms (95 %) bis 13 ms, Flam-Paare
   werden auf 12 bis 35 ms verzerrt. Das wäre gegen das Leitprinzip „eine Zahl, die
   manchmal falsch ist, ist schlechter als keine".
3. **Virtuelle Ports sind unsichtbar.** Die Geräte-Erkennung der Bibliothek filtert
   auf Ports mit dem Kennzeichen „Hardware". Der virtuelle Port hat es nicht. Ein
   echtes Modul per USB hat es, der Linux-Integrationstest aus Phase A braucht aber
   die Lockerung.
4. **Headless-Fallen** (für den NUC-Test, nicht für den Nutzer): Unter Xvfb hängt
   die GTK-App ohne `NO_AT_BRIDGE=1` und `GTK_A11Y=none` beim Start (wartet auf den
   Accessibility-Bus); EGL braucht `LIBGL_ALWAYS_SOFTWARE=1`. Steht in
   `tool/midi/spike/run_spike.sh`.

## Festlegung für Phase A

- **Zeitbasis:** Stempel im Empfangs-Isolate, Mikrosekunden, direkt nach
  `snd_seq_event_input`. Bezug auf die Metronom-Uhr beim Sitzungsstart (Wanduhr ↔
  monotone Uhr einmal abgleichen), wie im Brief A.4.
- **Bibliothek:** `flutter_midi_command` bleibt, `flutter_midi_command_linux` wird
  als **gepatchte Kopie im Repo** eingebunden (`dependency_overrides`, Pfad), mit zwei
  Änderungen: Stempel im Empfangs-Isolate (vier Zeilen) und Lockerung des
  Hardware-Filters auf „Hardware oder MIDI-Generic". Beides als Pull Request
  stromaufwärts anbieten; bis dahin trägt der Patch. Die eigene FFI-Anbindung
  (Rückfall aus dem Brief) ist nicht nötig.
- **Android:** nur Quellen gesichtet, nicht gemessen. Die Android-Umsetzung
  (`flutter_midi_command_android` 1.4.0) reicht den Zeitstempel des Systems durch:
  `onSend(…, timestamp)` aus `android.media.midi` geht über den Parser unverändert
  ins Paket (Nanosekunden, monotone Uhr des Systems, gestempelt im USB-Treiber).
  Das ist die bessere Quelle als jeder App-Stempel; kein Patch nötig. Einheit und
  Uhrenbezug prüft der Gerätetest zuhause.
- **Integrationstest Linux** (`tool/midi/virtual_port_test.sh` in Phase A) baut auf
  `send_pattern.py` und `analyze.py` auf. Abnahmewerte: p95 unter 0,5 ms, Flams
  25 ± 1 ms, 256 von 256 Noten, unter Last.

## Nicht geprüft

- Echtes Modul per USB (erst zuhause). Erwartung: zusätzliche, konstante Latenz des
  USB-Treibers unter 1 ms, kein Jitter-Problem, da der Kernel stempelt.
- Android-OTG-Weg und Windows.
