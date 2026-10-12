# Bericht Etappe 2 — Phase A: Set-Minimum

**Datum:** (beim Gerätetest eintragen) · **Brief:** `docs/BRIEF_ETAPPE2_SET.md`, Phase A
· **Zeitexperiment:** `docs/BERICHT_ETAPPE2_§0.md`

**Stand:** Umsetzung fertig, Gerätetest am Set offen. Alle Befund-Felder unten sind leer.

---

## Was installiert wird

- **Linux:** `build/linux/x64/release/bundle/drum_coach` (nach `flutter build linux --release`).
- **Android (S23, per OTG):** Debug-APK `~/drum-coach-set-a.apk`
  (aus `build/app/outputs/flutter-apk/app-debug.apk`).
- **Integrationstest (Linux, virtueller Port):** `tool/midi/virtual_port_test.sh`.

## Abnahme Phase A (am Set, erster Tag zuhause)

| Nr. | Erwartung | Befund | Datum |
|---|---|---|---|
| 1 | Modul per USB am Laptop: Gerät erkannt, Lernschritt für das volle Set unter zwei Minuten, Zuordnung nach Neustart noch da. |  |  |
| 2 | Latenz-Abgleich zweimal hintereinander: Versatz-Differenz unter 3 ms. |  |  |
| 3 | Rudiment-Blatt auf der Snare bei sauberem Spiel: Trefferquote mindestens 95 %, Flams werden als Flam gewertet, keine Doppelzählungen. |  |  |
| 4 | Akzent-Übung: erkannte Akzente stimmen mit dem Blatt überein (Velocity-basiert). |  |  |
| 5 | Kick und Hi-Hat während der Übung landen im Rohlog mit richtigem Instrument. |  |  |
| 6 | S23 per OTG: dieselbe Übung läuft, Rohlog gleichwertig. |  |  |
| 7 | Ohne Modul: Übungs-Screen zeigt „nicht messbar“, kein Absturz, Mikrofon-Weg unverändert (Regressionstest am Pad). |  |  |

## Rohdaten und Notizen

(Rohlogs, Latenzwerte, Auffälligkeiten beim Gerätetest hier eintragen.)
