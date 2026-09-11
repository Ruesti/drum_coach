# Bericht Etappe 1 — Phase 3: Lern- und Analysemodus

**Datum:** 10.09.2026 · **Basis:** main nach Merge von PR #17 (`2bfba95`)
· **Brief:** `docs/BRIEF_ETAPPE1_PAD.md` Phase 3 · **Branch/PR:** #18

**Stand 11.09.: Implementierung komplett (245/245 Tests) inkl.
Jitter-Gate-Erweiterung; alle fern-prüfbaren Abnahmen ✓ (Tabellen unten).
Offen sind nur noch die Nutzer-Abnahmen Hörtest, Kopfhörer rein/raus und
die Neu-Kalibrierung. Vorgelagert wurden sechs vom Auftraggeber gemeldete
Wiedergabe-Probleme diagnostiziert und behoben (eigene Abschnitte unten)
— Leitprinzip „Messung glaubwürdig vor Features".**

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
- **Jitter-Gate (Nachtrag 11.09., Auftraggeber-Entscheidung):** Das
  Vertrauensmaß sperrt die Hand-Analyse zusätzlich, wenn die
  Timing-Streuung der bewerteten Noten (Standardabweichung) über
  **50 ms** liegt — „schlampig, aber vollzählig" bekommt damit ebenfalls
  die „sitzt noch nicht"-Ansage statt Hand-Werten. Eigener Wortlaut im
  Feedback-Sheet: *„Zu unruhig für eine Hand-Analyse — das sitzt noch
  nicht."* (unterscheidbar von der Aussetzer-Ansage). Greift erst ab
  4 bewerteten Treffern; `jitterLimitExceeded` wird im Alignment
  festgehalten. TDD: 2 neue Tests (hoher Jitter sperrt, moderater
  ±15 ms lässt offen).
- **Nicht enthalten (laut Brief):** automatischer Modus-Vorschlag.

## Tests

Gesamtsuite **245/245 grün** (Stand 11.09.: Isolate-Engine-Tests mit dem
Isolate entfernt, 2 Jitter-Gate-Tests neu); Analyzer ohne Befunde.

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
gespielte Durchläufe lagen per Brief-Definition ÜBER der Schwelle (sie
zählt Auslassungen/Überzählige, nicht Timing-Streuung; das Alignment
toleriert ±250 ms) — es erschienen Hand-Werte, keine Ansage. Der
Auftraggeber entschied daraufhin die Jitter-Gate-Erweiterung (Abschnitt
oben).

**Fern-Verifikation 11.09. (nach Jitter-Gate, per adb gesteuerte
Sessions, Lautsprecher-Klicks als Onsets):**

| Prüfpunkt | Ergebnis |
|---|---|
| Jitter-Gate: vollzählig, aber unruhig → eigene Ansage | ✓ 131/131 Schläge, 130/1/1 gematcht, Streuung ±64,4 ms > 50 ms → „Zu unruhig für eine Hand-Analyse — das sitzt noch nicht.", keine Hand-Werte (die ±64 ms stammen aus der Chunk-Quantisierung der Lautsprecher-Onsets bei 200 BPM — als Gate-Auslöser genau richtig) |
| Lernmodus: keine Hand-Werte + Hinweis | ✓ 142/143 gematcht (99 %, weit über Schwelle) → trotzdem keine R/L-Zeilen, Hinweis „Lernmodus — Timing und Gleichmäßigkeit ohne Hand-Analyse. Fehler sind hier normal."; zuordnungsfreie Größen bleiben sichtbar |
| Modus-Persistenz über App-Neustart | ✓ force-stop + Neustart → Insights-Symbol wieder orange |
| Modus-Persistenz beim Screen verlassen/neu öffnen | ✓ Übung verlassen und neu geöffnet → Symbol weiterhin orange; nach Umschalten grau |
| Session-Log `mode`-Feld im JSONL | ✓ `"mode":"analysis"` und `"mode":"learn"` in den zwei exportierten Sessions (aus `cache/session_*.jsonl` gelesen) |

**Verbleibende Nutzer-Abnahmen:**

| Prüfpunkt | Ergebnis |
|---|---|
| Hörtest ~2 min: Klick gleichmäßig (erster Test: „Abstände absolut gleich", aber gelegentliches Rest-Stottern — Eingrenzung läuft: Release-Build-Test) | ☐ |
| Kopfhörer rein/raus während des Klicks: Ton wechselt und bleibt | ☐ |
| Neu-Kalibrierung (der gespeicherte 136-ms-Wert entstand auf dem verlangsamten System; Soll wieder ~70 ms) | ☐ |
