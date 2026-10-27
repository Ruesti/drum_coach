# Geführte Übungen — Optik-Runde 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ulis Rückmeldung nach dem ersten Test am PC (27.10.) umsetzen: Noten über die volle Breite, Vorschau zeigt Notenzeilen statt Text, realistische Schlagzeug-Klänge (jedes Instrument eigener Klang), kleinerer Fortschrittsbalken, kein Hervorheben der gespielten Noten.

**Architecture:** Kleine Änderungen an den Plan-3a-Screens (`lib/features/guided/screens/`, `widgets/`) plus ein Klang-Ausbau im geführten Spieler: `RunSound` bekommt je Set-Instrument einen eigenen Klang, `buildRun` ordnet Kit-Stimmen danach zu, `SampleBank` lädt echte Aufnahmen (WAV, frei lizenziert).

**Spec:** `docs/superpowers/specs/2026-10-17-gefuehrte-uebungen-design.md`; Plan 3a `docs/superpowers/plans/2026-10-23-gefuehrte-uebungen-plan3a-bildschirme.md`.

## Ulis Wortlaut (27.10.)
„die notenzeile könnte über die volle Bildschirmbreite gehen. Am Startscreen der Übung nicht textlich anzeigen was gespielt wird sondern die verschiedenen Notenzeilen als Vorschau. Die Sounds realistischer. Crash hört sich an wie snare. Der Fortschrittsbalken ein bisschen kleiner und die gespielten Noten nicht highlighten"

Befund: In Set-Zeilen spielen Snare, Toms, Crash, Ride, Glocke alle den Musterklang (= Snare-Aufnahme); nur Kick und Hi-Hat haben eigene (synthetische) Klänge.

## Global Constraints
- Nur Desktop bauen/abnehmen (Linux; PC und Laptop bauen je selbst). Handy-Layout darf nicht brechen (412×915 Test bleibt).
- Optik wie bisher (dunkel, Foto, Akzent #FF6A2B).
- Klänge: nur frei lizenzierte Aufnahmen (CC0/Public Domain, nachweisbar), Eintrag in `assets/audio/CREDITS.md`, WAV 16 bit 44,1 kHz mono, ohne Vorlauf-Stille (Onset ≤ 1 ms — MP3-Falle aus 20.10. vermeiden), gelesen mit `decodeMonoWav16`. Kein Netz zur Laufzeit.
- Die bestehende Übungs-Wiedergabe (MetronomeEngine/Practice) bleibt in dieser Runde unverändert.
- Alle UI-Strings Englisch.

## Review Focus
1. Set-Zeile mit Crash auf der Eins (Backbeat Walk V3) klingt nach Becken, nicht nach Snare → Test in Task 3.
2. Pad-Übungen klingen weiter nach Snare/Pad → Test in Task 3.
3. Sehr breites Fenster (1600): Notenzeile nutzt die Breite, wird aber nicht absurd hoch → Task 1.
4. Vorschau mit 4 Variationen + 2-Takt-Zeilen bei 1280×720: alle Zeilen erreichbar (scrollt), nichts läuft über → Task 2.
5. Ohne Cursor muss trotzdem erkennbar sein, wo man ist → Zeitleiste + Statuszeile bleiben (Task 1 prüft).

---

### Task 1: Übungs-Bildschirm — Noten volle Breite, kein Hervorheben, kleinerer Balken
**Files:** `lib/features/guided/screens/guided_play_screen.dart`, `lib/features/guided/widgets/guided_line_view.dart`, `lib/features/guided/widgets/guided_timeline_bar.dart`, Tests `test/guided/screens/guided_play_test.dart`, Goldens `guided_play_*`.
- Breites Layout: die NOW-Notenzeile (und der Banner) spannen die volle Inhaltsbreite (Rand `AppSpacing.screenPadding`); Zeitleiste + Steuerung wandern in eine Leiste unter den Noten (Zeitleiste horizontal, schmal) bzw. eine schmale Spalte rechts nur, wenn Platz übrig ist — Wahl der Umsetzung, Vorgabe: Notenzeile ≥ 90 % der Fensterbreite bei 1280 und 1600, ohne Scrollen bei 1280×720.
- Kein Cursor/Highlight: `GuidedLineView` bekommt `showCursor` (Standard true für andere Nutzer), der Übungs-Bildschirm übergibt false; auch keine farbige Hervorhebung der aktuellen Note.
- Fortschrittsbalken (horizontal) etwa halb so hoch wie bisher; Beschriftung V1… bleibt lesbar (≥ 12 px).
- Tests: `notes span at least 90 % of the width at 1280 and 1600`, `no cursor on the play screen`, `progress bar height ≤ previous/2` (Wert im Test festhalten), Review Focus 3 + 5; Goldens neu, ansehen.
- Commit `feat(gefuehrt): Noten volle Breite, ohne Cursor, schmaler Fortschrittsbalken`

### Task 2: Vorschau zeigt Notenzeilen statt Text
**Files:** `lib/features/guided/screens/guided_preview_screen.dart`, Tests/Goldens `guided_preview_*`.
- Statt der Text-Zeitleiste: untereinander je eine Notenkarte für **Groove** und **V1…Vn** (`GuidedLineView`, ohne Cursor, ohne Zeilennummer), jede mit kleiner Kopfzeile „GROOVE · 12 bars“ / „V1 · 24 bars“ (Akzentfarbe für V). Kein Erklärtext in der Vorschau (Uli: „nicht textlich anzeigen“). „Ending · 1 bar“ entfällt.
- Breit: Notenkarten nehmen die linke, breite Spalte (scrollt in sich), rechts Tempo/Schalter/Start wie bisher; schmal: Karten untereinander, Start unten fest.
- Tests: `preview shows one staff per section kind (groove + each variation)`, `no explanation text in the preview`, Review Focus 4; Goldens neu, ansehen.
- Commit `feat(gefuehrt): Vorschau mit Notenzeilen`

### Task 3: Realistische Klänge — jedes Set-Instrument eigener Klang
**Files:** `assets/audio/` (neue WAVs), `assets/audio/CREDITS.md`, `lib/features/guided/run_plan.dart` (`RunSound` + Zuordnung), `lib/features/guided/sample_bank.dart`, `lib/features/guided/bar_render_backend.dart` (`_voiceSpec`), Tests `test/guided/run_plan_test.dart`, `sample_bank_test.dart`.
- Aufnahmen beschaffen (frei lizenziert, nachweisbar, ohne Login herunterladbar; Kandidaten prüfen: Wikimedia Commons, CC0-Drum-Sample-Repos auf GitHub — Lizenz auf der Quellseite belegen): **Kick, Snare (Akzent + leise/Ghost), Hi-Hat zu, Hi-Hat offen, Hi-Hat Pedal, Crash, Ride, Ride-Glocke, Tom hoch, Tom tief, Standtom, Rimshot/Sidestick** — wenn für ein Instrument nichts Sauberes zu finden ist: nächstbestes vorhandenes Instrument nehmen und im Bericht nennen, nie die Snare für Becken.
- Verarbeitung mit ffmpeg: mono 44,1 kHz 16 bit, Vorlauf-Stille weg (Onset ≤ 1 ms), Spitze 0,9, sinnvolle Länge (Becken ≤ 2,5 s mit Ausklang).
- `RunSound` erweitern (`snare`, `snareGhost`?, `rimshot`, `tomHigh`, `tomLow`, `floorTom`, `hihatOpen`, `hihatPedal`, `ride`, `rideBell`, `crash` …) — Zuordnung über `KitInstrument` der Stimme (siehe `lib/features/coaching/midi/kit_instrument.dart`); Pad-Zeilen bleiben `pattern` (Snare). `kick`/`hihat` nutzen jetzt Aufnahmen statt Synthese (Synthese bleibt nur Rückfall).
- Tests: `kit crash voice maps to RunSound.crash, not pattern` (Backbeat Walk V3), `every KitInstrument used in the catalog has its own sound`, `pad lines still use the snare`, `every sample loads and starts within 1 ms`, `CREDITS lists every new file`.
- Commit `feat(gefuehrt): echte Schlagzeug-Klänge je Instrument`

### Task 4: Lieferung PC + Laptop
- Push; PC (`ssh pc`, Checkout `~/agent-test-checkouts/drum_coach-guided`, `~/development/flutter/bin/flutter build linux --release`, rsync nach `~/drum-coach-guided/`); Laptop genauso, falls erreichbar. App nicht starten, keine Screenshots von Ulis Bildschirm.
- Kurzer Bericht `docs/BERICHT_GEFUEHRT_OPTIK1.md` (deutsch, einfach): was geändert, Klangquellen mit Lizenz, was als Ersatz gilt.
