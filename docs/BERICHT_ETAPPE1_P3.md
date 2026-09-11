# Bericht Etappe 1 — Phase 3: Lern- und Analysemodus

**Datum:** 10.09.2026 · **Basis:** main nach Merge von PR #17 (`2bfba95`)
· **Brief:** `docs/BRIEF_ETAPPE1_PAD.md` Phase 3 · **Branch/PR:** #18

**Stand: Implementierung komplett (247/247 Tests). Der Gerätetest (beide
Modi an derselben Übung) steht aus. Vorgelagert wurden zwei vom Auftraggeber
gemeldete Wiedergabe-Probleme diagnostiziert und behoben (eigener Abschnitt
unten) — Leitprinzip „Messung glaubwürdig vor Features".**

---

## Wiedergabe-Untersuchung (Anlass: hörbares Stottern, falsches Tempo)

Gemeldet: kleine hörbare Geschwindigkeitsunterschiede, gelegentlich
deutliches „Verschlucken"; nach App-Neuinstallationen lief das Tempo
sichtbar falsch, bis die Übung neu geöffnet wurde.

**Diagnose-Infrastruktur:** Debug-Statistik in `metronome_engine.dart`
(assert-basiert, kostet im Release nichts): Auslöse-Verspätung jedes Beats
gegen die geplante Isolate-Zeit, alle 200 Ticks p50/p90/max + maximale
SoLoud-Stimmenzahl ins Log.

**Befund 1 — Kaltstart-Race (behoben, `0e6c6fb`):** `setBpm`/
`setPatternClock` verpufften auf `_engine == null`, wenn eine Übung
schneller geöffnet wurde, als die asynchrone Engine-Initialisierung lief.
Das UI zeigte das Wunschtempo, der Timing-Isolate tickte mit seinen
100-BPM-Defaults (Fern-Reproduktion: „197 BPM" lieferte 200 Ticks in
2 min statt 2,54 s). Fix: synchrone Engine-Konstruktion + Nachholen eines
vor dem Isolate-Handshake angeforderten Starts; Regressionstest
`metronome_command_race_test.dart`. **Nachher: 200 Ticks in exakt 2,54 s;
vom Auftraggeber am Gerät bestätigt.**

**Befund 2 — Klick hing an der Main-Isolate-Queue (behoben, `4415417`):**
Auch bei pünktlichem Isolate kam der hörbare Klick über
`SoLoud.play()` im Main-Isolate — gemessen: in jedem 2,5-s-Fenster
mindestens ein Klick 20–30 ms verspätet, 130–260 ms beim Screen-Aufbau;
Stimmenzahl stets ≤ 2 (Voice-Stealing ausgeschlossen), UI-Events bereits
notenbasiert (eine Rebuild-Reduktion änderte messbar nichts — der Stau lag
am per-Klick-Abspielweg selbst). Fix: **nativ geloopte Klick-Spur** —
`buildLoopWav` (`click_loop_renderer.dart`, TDD: 5 Tests) rendert einen
kompletten Pattern-Zyklus (synthetischer Click/Rim bzw. per
`readSamplesFromMem` dekodiertes Snare-PCM) als WAV; SoLoud loopt ihn
sample-genau, unabhängig von Dart/UI. Isolate-Beats treiben nur noch
Cursor/Anzeige und die Sollzeiten des beatLogs; Parameterwechsel bauen den
Loop debounced (150 ms) neu.

**Messkette (§1.3) unverändert gültig:** Sollzeiten bleiben die geplanten
Isolate-Zeiten; der konstante Versatz zur Loop-Ausgabe steckt wie jede
Ausgabelatenz im Kalibrierwert bzw. im pro Durchlauf ausgewiesenen Median.
Langsame Drift zwischen Audio-Uhr und Isolate-Uhr liegt für übliche
Durchlauflängen innerhalb der dokumentierten ±8-ms-Restunsicherheit des
P1-Berichts.

**Abnahme Wiedergabe (Gerätetest):** Übung ~2 min am Stück; Erwartung:
keine hörbaren Tempo-Schwankungen oder Aussetzer mehr. ☐

## Phase 3 — Umsetzung

- **Modus pro Übung gemerkt:** `SettingsService.analysisModeFor(exerciseId)`
  (Standard: Lernmodus).
- **Analyse:** `analyzeHits(..., analysisMode:)` — Hand-Werte (Timing und
  Pegel pro Hand) gibt es ausschließlich im Analysemodus **und** über der
  strengen §1.2-Schwelle (90 % getroffen, < 5 % überzählig). Im Lernmodus
  bleiben auch bei perfektem Durchlauf nur die zuordnungsfreien Größen;
  das Vertrauensmaß selbst wird weiter berechnet und geloggt. Geloggte
  Ereignisse tragen im Lernmodus keine Hand (Tests in
  `mic_analysis_test.dart`).
- **UI:** Umschalter in der AppBar des Übungs-Screens (Insights-Symbol,
  pro Übung persistiert). Feedback-Sheet: im Lernmodus der Hinweis
  *„Lernmodus — Timing und Gleichmäßigkeit ohne Hand-Analyse. Fehler sind
  hier normal."*; im Analysemodus unter der Schwelle der Brief-Wortlaut
  *„Zu viele Aussetzer für eine Hand-Analyse — das sitzt noch nicht."*
- **Session-Log:** `mode` = `learn` | `analysis` wird pro Session
  festgehalten (Phase-2-Schema war dafür vorbereitet).
- **Nicht enthalten (laut Brief):** automatischer Modus-Vorschlag.

## Tests

Gesamtsuite **247/247 grün**; neu: 5 Loop-Renderer, 1 Kommando-Race,
2 Modus-Gate. Analyzer ohne Befunde.

## Nachtrag 10.09. — Kopfhörer-Routing (behoben, `43bee59`)

Gerätetest deckte auf: Kopfhörer einstecken tötete die Audio-Ausgabe
dauerhaft (auch nach Ausstecken still) — SoLoud überlebt Android-
Routing-Wechsel nicht von selbst. Fix: `AudioDeviceCallback` in
`MainActivity` meldet Gerätewechsel nach Flutter; die Engine wechselt
debounced per `changeDevice()` aufs Default-Gerät und startet einen
laufenden Loop neu.

## Nachtrag 11.09. — Eine Uhr für Ton, Cursor und Messung

- **Cursor-Drift behoben (`d1e4070`):** Balken-Cursor und Mess-Sollzeiten
  wichen nach Tempowechseln um bis zu eine Note vom Ton ab (Isolate-Uhr vs.
  Loop-Phase). Beats entstehen jetzt per Positions-Poller direkt aus
  `SoLoud.getPosition` — Anzeige und geplante Klickzeiten teilen die Uhr
  des hörbaren Tons; der Timing-Isolate wurde komplett entfernt.
  **Vom Auftraggeber bestätigt: „Balken läuft korrekt immer bis zur letzten
  Note."** (Zwischenzeitlicher Cursor-Bündelungs-Bug am Loop-Ende per
  Emit-Trace diagnostiziert.)
- **Puffer-Lektion (`e4cc88f`):** Der Versuch, aufnahme-induzierte Aussetzer
  mit `bufferSize: 8192` zu bändigen, verlangsamte die Wiedergabe am Gerät
  um ~24 % (Emit-Raster 186 statt 150 ms) — revertiert und im Code
  dokumentiert. **Folge: Nach diesem Stand einmal neu kalibrieren** (der
  zwischenzeitliche 136-ms-Wert entstand auf dem verlangsamten System).
- **Offen (bekannt):** Vereinzelte hörbare Aussetzer, deutlich häufiger bei
  laufender Mikrofon-Aufnahme (~7/5 min, ohne Mikro ~1/5 min) — nächste
  Kandidaten: Aufnahme-DSP in eigenen Isolate verlagern und/oder
  Release-Build-Verhalten prüfen (Debug-Overhead als CPU-Spitzen-Treiber).

## Abnahme Phase 3 (Gerätetest)

**Fern-Verifikation 10.09. (Analysemodus-Pfad, per adb gesteuerte
Sessions, Lautsprecher-Klicks als Onsets):**

| Prüfpunkt | Ergebnis |
|---|---|
| Analysemodus über Schwelle → Hand-Werte | ✓ 213/0/9 bzw. 164/0/1 → R/L-Zeilen erscheinen (z. B. R −43,5 / L −45,9 ms) |
| Analysemodus unter Schwelle → Brief-Ansage, keine Hand-Werte | ✓ erzwungene Stille-Lücke: 145/63/2 (70 %) → „Zu viele Aussetzer für eine Hand-Analyse — das sitzt noch nicht." |
| Umschalter sichtbar/persistiert (orange = aktiv) | ✓ |

**Wichtige Einordnung aus dem Nutzertest:** „Schlampig, aber vollzählig"
gespielte Durchläufe liegen per Brief-Definition ÜBER der Schwelle (sie
zählt Auslassungen/Überzählige, nicht Timing-Streuung; das Alignment
toleriert ±250 ms) — es erscheinen dann Hand-Werte, keine Ansage. Falls
zusätzlich hoher Timing-Jitter die Hand-Analyse sperren soll, wäre das
eine Erweiterung des Vertrauensmaßes → Entscheidung Auftraggeber.

**Verbleibende Nutzer-Abnahmen:**

| Prüfpunkt | Ergebnis |
|---|---|
| Lernmodus (Standard): keine Hand-Werte im Feedback, Lernmodus-Hinweis sichtbar | ☐ |
| Hörtest ~2 min: Klick gleichmäßig (erster Test: „Abstände absolut gleich", aber gelegentliches Rest-Stottern — Eingrenzung läuft: tritt es ohne Mikrofon-Analyse ebenfalls auf?) | ☐ |
| Kopfhörer rein/raus während des Klicks: Ton wechselt und bleibt | ☐ |
| Modus bleibt pro Übung gemerkt (Screen verlassen und neu öffnen) | ☐ |
| Session-Log `mode`-Feld korrekt (`learn`/`analysis`, im JSONL-Export sichtbar) | ☐ |
