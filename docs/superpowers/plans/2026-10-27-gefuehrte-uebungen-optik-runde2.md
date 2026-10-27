# Geführte Übungen — Optik-Runde 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development.

**Goal:** Ulis zweiter Test am PC (Fenster 2560×1440, 27.10. abends): Foto und Übung über das ganze Fenster, eine dünne Laufanzeige über den Noten, und ein professionell aufgenommenes Schlagzeug-Set (CC BY erlaubt).

## Ulis Wortlaut + Antworten (27.10.)
„jetzt gibt es garkeinen laufenden balken mehr. die notenzeile ist auch nicht über die ganze Bildschirmbreite. Das Hintergrundbild wird überdeckt und sollte nicht so abgeschnitten sein seitlich. die sounds sind nicht gut"
Rückfragen: Laufanzeige = **dünne Linie über den Noten** (Noten nicht einfärben). Klänge = **CC BY mit Namensnennung erlaubt** (z. B. DrumGizmo-Set mit mehreren Anschlagstärken).

Befund (Bildschirmfoto): der globale Desktop-Deckel (`capContentWidth`: 900 bzw. 1440 mit `UncappedContent`) schließt das Hintergrundfoto mit ein → Foto nur als Streifen in der Mitte, links/rechts schwarz; Übung höchstens 1440 breit.

## Global Constraints
- Nur Desktop bauen/abnehmen (PC 2560×1440, Laptop); Handy-Layout darf nicht brechen (412×915-Tests bleiben).
- Optik wie bisher (dunkel, Foto, Akzent #FF6A2B). Bibliothek bleibt hell.
- Klänge: Lizenz CC0/PD **oder CC BY (jede Version)** — Urheber, Quelle, Lizenz in `assets/audio/CREDITS.md` UND in der App sichtbar (Einstellungen → „Credits"). Keine NC/ND/SA-Lizenzen. WAV 16 bit 44,1 kHz mono, Onset ≤ 1 ms, ohne Laufzeit-Netz.
- Die normale Übungs-Wiedergabe (MetronomeEngine/Practice) bleibt unverändert.
- UI-Strings Englisch.

## Review Focus
1. Fenster 2560×1440 und 1920×1080: Foto füllt das ganze Fenster ohne seitliche Ränder; Übung nutzt die volle Breite (Gutter `AppSpacing.screenPadding`).
2. Laufanzeige: dünne Linie (≤ 3 px) bewegt sich über die Notenzeile, keine Note wird eingefärbt; auch nach Tempowechsel synchron.
3. Bibliothek und andere Seiten bleiben im 900er-Deckel (nur ihr Inhalt; ihr Hintergrund war schon ok).
4. Leise/laute Schläge (Ghost, normal, Akzent) wählen unterschiedliche Aufnahmen (Anschlagstufen), nicht nur Lautstärke.
5. Credits-Seite listet jede verwendete Aufnahmequelle mit Lizenz.

---

### Task 1: Foto übers ganze Fenster, Übung ohne Deckel, Vorschau breiter, dünne Laufanzeige
**Files:** `lib/app/platform_support.dart` (`capContentWidth`, `UncappedContent`), `lib/features/guided/widgets/guided_backdrop.dart`, `lib/features/guided/screens/guided_play_screen.dart`, `guided_preview_screen.dart`, `lib/features/guided/widgets/guided_line_view.dart`, shared notation (`LineView`/`SheetStaffWidget` — opt-in cursor style), Tests unter `test/guided/screens/` + `test/app/`.
- Der Deckel gilt nur für den **Inhalt**, nie für den Hintergrund: Guided-Screens zeichnen `GuidedBackdrop` über die volle Fensterfläche (Deckel-Opt-out für den Hintergrund) und begrenzen nur ihren Inhalt. Mechanismus frei (z. B. `UncappedContent(maxWidth: double.infinity)` für die ganze Route und eigene Inhaltsbegrenzung im Screen).
- Übungs-Bildschirm: Inhalt volle Fensterbreite (nur Gutter), kein 1440-Deckel. Vorschau: Inhalt bis 1440 breit, Foto voll.
- Laufanzeige: `GuidedLineView` bekommt `cursorStyle` (`none`/`box`/`line`); der Übungs-Bildschirm nutzt `line` = dünne senkrechte Linie (Akzentfarbe, ≤ 3 px, volle Notenhöhe) an der Position der aktuellen Zählzeit; keine Notenfärbung. Andere Nutzer unverändert (Standard `box`).
- Tests: Review Focus 1–3 (Fotobreite = Fensterbreite bei 2560 und 1920, Notenzeile ≥ 90 % der Fensterbreite bei 2560, Bibliothek weiter 900), Linie vorhanden + wandert mit `activeTick`, keine Notenfärbung. Goldens neu, ansehen.
- Commit `feat(gefuehrt): Foto übers ganze Fenster, Übung volle Breite, Laufanzeige als Linie`

### Task 2: Profi-Schlagzeug-Set (CC BY) mit Anschlagstufen + Credits-Seite
**Files:** `assets/audio/` (neue WAVs, alte Gui_DRUM-Dateien ersetzen/entfernen), `assets/audio/CREDITS.md`, `lib/features/guided/sample_bank.dart`, `run_plan.dart`/`bar_render_backend.dart` (Anschlagstufen), neue Credits-Seite (Einstellungen → „Credits", rendert die Liste), Tests.
- Quelle: ein DrumGizmo-Set (z. B. DRSKit, CrocellKit, MuldjordKit — Lizenz auf der Projektseite prüfen, nur CC BY/CC0) oder gleichwertig. Download in frisches Verzeichnis unter `/home/uli/.claude/jobs/9e32c137/tmp/`, nur mit ffmpeg/sox verarbeiten, nichts ausführen.
- Mehrkanal-Aufnahmen (Nah- + Overhead-Mikros) per ffmpeg zu Mono mischen (Nahmikro + Overheads + Raum ausgewogen, nicht nur Nahmikro), 44,1 kHz, 16 bit, Onset ≤ 1 ms, Spitze ~0,9, Becken ≤ 3 s mit natürlichem Ausklang.
- Je Instrument **3 Anschlagstufen** (leise/mittel/laut) aus den Velocity-Ebenen des Sets; Zuordnung über die Tick-Lautstärke (Ghost → leise, normal → mittel, Akzent → laut). Instrumente: Kick, Snare, Rimshot/Sidestick, Hi-Hat zu/offen/Pedal, Crash, Ride, Ride-Glocke, Toms (hoch/tief/Stand) — was das Set hat; Ersatzregel wie Runde 1 (nie Snare für Becken).
- Hi-Hat-Abdämpfen und `kitMixLevel`-Reserve beibehalten (Spitzen ≤ 0,9 neu messen und einstellen).
- Credits-Seite: listet je Datei Urheber, Quelle, Lizenz (aus einer Dart-Konstante, die zur CREDITS.md passt; Test vergleicht beide).
- Hörproben neu nach `~/gefuehrt-klang-probe/` (alle Set-Übungen Groove + letzte Variation) und auf den PC kopieren.
- Tests: Review Focus 4–5, alle Samples laden + Onset ≤ 1 ms, Credits vollständig, Pad unverändert, Mix-Spitzen ≤ 0,9.
- Commit `feat(gefuehrt): Profi-Schlagzeug-Set mit Anschlagstufen + Credits`

### Task 3: Lieferung
- Push; PC bauen + installieren (laufende App vorher beenden mit `pkill -x drum_coach`, NICHT `pkill -f` mit Pfad), App starten (DISPLAY=:0); Laptop falls erreichbar. Bericht `docs/BERICHT_GEFUEHRT_OPTIK2.md`.
