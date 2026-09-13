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

## Nachtrag 12./13.09. — Release-Build (Auftrag: Aussetzer-Test)

Anlass: Aussetzer treten mit laufender Mikrofon-Analyse ~7×/5 min auf
(ohne ~1×) — Verdacht Debug-Overhead. Der Brief nannte ein bekanntes
Release-Problem mit Isar; beim ersten `flutter build apk --release`
traten nacheinander **zwei** Blocker auf, beide behoben:

1. **isar_flutter_libs scheiterte an `verifyReleaseResources`**
   (`android:attr/lStar not found` — das Plugin baut mit eigenem, altem
   compileSdk 30). Fix (`952490b`): Root-Gradle hebt Plugin-compileSdks
   < 31 aufs App-compileSdk.
2. **App hing im Release dauerhaft am Start-Screen** (vom Auftraggeber
   gemeldet). Logcat: `Missing type parameter.` aus
   `flutter_local_notifications` — R8 entfernt Gson-TypeToken-
   Signaturen; die Exception in `NotificationService.init()` verhinderte
   `runApp`. Fix (`9f5c676`): ProGuard-Regeln (Ursache) + `main()`
   kapselt die Notification-Init in try/catch mit 5-s-Timeout, damit
   Reminder-Probleme den App-Start nie wieder blockieren können.
   (Kein Host-Test möglich — reines R8/Release-Verhalten; Verifikation
   am Gerät, s. u.)

**Verifikation 13.09. am Gerät:** Kaltstart des Release-Builds → Logcat
ohne Exception, Dashboard vollständig gerendert, Nutzerdaten intakt
(Release ist mit Debug-Keys signiert, `install -r` erhält die Daten).
**Der eigentliche Aussetzer-Vergleichstest (5 min Double Stroke mit
Mikro, Referenz Debug ~7×) steht beim Auftraggeber aus.** ☐

## Nachtrag 13.09. — „Übung läuft nicht an" nach Kalibrierung (behoben, `eef96e6`)

Vom Auftraggeber zweimal gemeldet (11.09. Debug, 13.09. Release), fern
reproduziert: **Nach einer Latenz-Kalibrierung startete keine Übung mehr**
— Play zeigte „läuft", aber kein Ton, Cursor blieb auf Note 1; erst ein
App-Neustart half. Ursache: Das Starten/Stoppen der Aufnahme (Kalibrierung
wie Mikrofon-Analyse) feuert Android-`AudioDeviceCallback`s, die keine
Kopfhörer-Ereignisse sind; der Kopfhörer-Handler reagierte darauf mit
`SoLoud.changeDevice()` — lief dabei kein Klick-Loop, blieb SoLoud ohne
lebendes Ausgabegerät zurück (Belegkette: AAudio-Streams im Logcat nach
Kalibrierung geschlossen, nie wieder geöffnet; `play()` liefert dann ein
Handle, dessen `getPosition` bei 0 stehen bleibt).

Fix auf zwei Ebenen: (1) `MainActivity` meldet nur noch Änderungen an
**Ausgabe**-Geräten (`isSink`) nach Flutter; (2) ein Watchdog in der
Engine prüft 450 ms nach jedem Loop-Start, ob die Wiedergabeposition
fortschreitet — wenn nicht, einmalig `changeDevice()` + Loop-Neustart
(heilt jeden stillen Ausgabe-Tod, auch künftige Routing-Fälle).

**Verifikation am Gerät (Debug mit Traces, dann Release):** Kalibrierung
→ direkt Übung → Klick läuft, Cursor wandert (zwei Screenshots), kein
Route-Ereignis mehr während der Kalibrierzyklen, Watchdog musste nicht
eingreifen. Kalibrierwert des Auftraggebers heute: 71 → 73 ms (plausibel,
Vor-bufferSize-Niveau ~70 ms). ✓

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
| Hörtest/Aussetzer im Release mit Mikro | ✓ 13.09.: **1 „Verschlucken" in 8 min** (Debug-Referenz ~7 in 5 min) — Debug-Overhead war der Haupttreiber; Rest-Aussetzer ~1/8 min dokumentiert |
| Jitter-Ansage im echten Spiel | ✓ 13.09.: 8-min-Session absichtlich unregelmäßig (1603/1915 Schläge, 77 % zugeordnet) → „Zu unruhig für eine Hand-Analyse — das sitzt noch nicht." erschien |
| Neu-Kalibrierung nach bufferSize-Revert | ✓ 13.09.: 71 bzw. 73 ms gespeichert (Vor-bufferSize-Niveau ~70 ms) |
| Kopfhörer rein/raus während des Klicks: Ton wechselt und bleibt | ☐ |

**Hinweis:** Die Ansage kommt konzeptgemäß nach Session-Ende im
Feedback-Sheet, nicht live während des Spielens (Live-Hinweis wäre eine
Erweiterung → Entscheidung Auftraggeber). Nebenbefund: Die
Spread-Anzeigen (±2184/±3184 ms) sind bei stark lückigem Spiel
ausreißergetrieben — kosmetisch, Glättung optional.

## Nachtrag 13.09. (3) — Einbruch-Erkennung (Auftraggeber-Entscheidung, `ace89ca`)

Einwand des Auftraggebers zur Jitter-Abnahme: *„Wenn ich 10 Minuten
spiele und davon 1 Minute schlecht, bin ich noch bei 90 % — das geht
nicht."* Alle bisherigen Schwellen (90 %-Trefferquote, 50-ms-Jitter)
sind Session-Globalwerte und verwässern lokale Schwächephasen.

**Umsetzung:** Gleitende Fenster (8 s, Schritt 2 s) über die bewerteten
Noten; ein Fenster mit Trefferquote < 70 % ODER Streuung > 50 ms ist ein
Einbruch; überlappende Fenster verschmelzen und werden auf die
erste/letzte schlechte Note getrimmt. **Jeder Einbruch sperrt die
Hand-Analyse**, die Ansage nennt die Stelle: *„Bei 6:10 für ~12 s
rausgekommen — das sitzt noch nicht."* Kurzläufe unter einer
Fensterlänge deckt weiter das globale Gate ab. Keine Schema-Änderung
(das Log speichert Rohdaten; Einbrüche sind daraus reberechenbar).
Parameter (8 s / 70 % / 50 ms) sind Startwerte → Feinjustierung nach
Nutzertest.

TDD: 6 Detektor- + 2 Integrationstests (u. a. 96,7-%-Lauf mit 10-s-Loch
→ gesperrt mit korrekt lokalisiertem Einbruch), Gesamtsuite 253/253.
**Geräteverifikation durch den Auftraggeber ausstehend** (Vorschlag:
30 s spielen, ~15 s aussetzen, 30 s weiterspielen → Ansage mit
Ortsangabe). Fern-Verifikation wurde nach zwei fehlgeschlagenen
Stummschalt-Versuchen abgebrochen — Blindtap-Risiko überstieg den
Nutzen (dabei versehentlich die Standard-SMS-App des Testgeräts
verstellt; Rückstellung an den Auftraggeber übergeben, s. Protokoll).

## Nachtrag 13.09. (2) — Wurzel der „Übung startet nicht"-Serie (behoben, `e78fd82`)

Nach dem Kalibrier-Fix trat das Symptom erneut auf (App war im
Hintergrund gewesen bzw. USB getrennt). Wurzel: `loadMem`/`play` in
`_startLoop` hatten kein Zeitlimit, und sämtliche Wächter entstehen erst
NACH `play()` — eine tote Audio-Engine (Stream vom System einkassiert)
ließ den Startpfad ewig hängen, bevor irgendeine Selbstheilung existierte;
`changeDevice()` lief über dieselbe tote Engine. Fix: Zeitlimits auf alle
Audio-Aufrufe im Startpfad; **Start-Supervisor** (reiner Dart-Timer, 3 s)
außerhalb der Audio-Kette; Eskalation zum **harten Engine-Neustart**
(`deinit()`/`init()` + Neuladen) — max. 2 Versuche pro Start. Zusätzlich
(`8b90de0`): Stillstands-Detektor prüft Positions-BEWEGUNG (eingefrorene
Position ≠ 0 bestand den alten „> 0"-Check), und ein leeres Snare-PCM
fällt hörbar auf den synthetischen Click zurück statt auf Stille.
**Nutzerbestätigung 13.09.: 8-min-Session lief durch** (1 Verschlucken,
s. Tabelle).
