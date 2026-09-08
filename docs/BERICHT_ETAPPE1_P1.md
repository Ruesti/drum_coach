# Bericht Etappe 1 — Phase 1: Messung glaubwürdig

**Datum:** 06.09.2026 · **Basis:** main nach Merge von PR #14 und #15 (`60d0ffd`)
· **Brief:** `docs/BRIEF_ETAPPE1_PAD.md` §1.1–1.4 samt Freigabe-Ergänzungen

**Stand 08.09.: PHASE 1 KOMPLETT ABGENOMMEN (229/229 Tests). Gerätetest
1.1 BESTANDEN (06.09.); 1.3 BESTANDEN nach angepasster Abnahme
(Entscheidung Auftraggeber 06.09., Kalibrierwert 69 ms gespeichert);
1.2 BESTANDEN (08.09., a/b/c-Tabelle unten). Der Gerätetest deckte
insgesamt drei echte Messfehler auf, die behoben wurden (10-ms-Zeitraster,
akkumulierende Sample-Uhr-Drift, Phantom-Auslassungen am Session-Rand —
siehe Protokolle in 1.2/1.3).**

---

## 1.1 Roher Aufnahmeweg

**Umsetzung:**
- Die Aufnahme fordert `UNPROCESSED` an, wenn das Gerät es meldet, sonst
  `VOICE_RECOGNITION`; AGC, Rauschunterdrückung und Echo-Cancellation werden
  auf beiden Wegen **ausdrücklich** mit `false` angefordert
  (`lib/features/coaching/services/recording_setup.dart`). Das
  `record`-Plugin setzt die Effekte dann aktiv auf disabled, sofern das Gerät
  sie anbietet (`record_android` `AudioEffectsManager.apply`:
  `agc?.enabled = config.autoGain`).
- **Laufzeitprüfung** der UNPROCESSED-Verfügbarkeit über einen MethodChannel
  (`drum_coach/audio` → `AudioManager.getProperty(PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED)`,
  `android/app/src/main/kotlin/com/example/drum_coach/MainActivity.kt`).
  Das Ergebnis steckt in `RecordingSetup.describe()` und wird im
  Feedback-Sheet unter „Messdetails" angezeigt — von dort wandert es in
  Phase 2 in den Session-Kopf (Freigabe-Ergänzung zu §1.1).
- Keine Verstärkungsregelung irgendwo im Signalweg; der Onset-Detektor
  normalisiert nicht.

**Abnahme (Gerätetest):** 20 Schläge abwechselnd laut/leise. Die Spitzenpegel
stehen nach der Session im Feedback-Sheet unter „Messdetails" (Zeile
„Pegel (×100)").

**Gerätetest 06.09. (S23 Ultra, Session 76 BPM, 29 s, 81 Onsets, Klick
stumm): BESTANDEN.**

| Messwert | Wert |
|---|---|
| UNPROCESSED auf S23 Ultra verfügbar | **nein** (`unprocessedSupported: false`) → Fallback `voice_recognition`, AGC/NS/AEC aus (Messdetails-Screenshot) |
| Verhältnis Spitzenpegel laut/leise, frühe Paare | 16/3 · 18/4 · 19/4 · 10/3 · 17/4 → **⌀ ≈ 4,4** |
| Verhältnis Spitzenpegel laut/leise, späte Paare | 14/2 · 18/3 · 19/2 · 16/4 · 10/3 → **⌀ ≈ 6,0** |
| Angleichung über die Zeit | **keine** — leise Schläge bleiben bei 1–4, laute bei 14–24 (×100) über die gesamte Session; Dynamik-Streuung 64 % |

Der Pegelunterschied bleibt im Rohsignal vollständig erhalten; ein
verstecktes AGC der Samsung-Kette ist nicht erkennbar.

## 1.2 Sequenzabgleich statt Positionszählung

**Umsetzung:**
- Globales Alignment erwarteter Noten gegen erkannte Onsets
  (`lib/features/coaching/services/sequence_aligner.dart`):
  Needleman-Wunsch-artig, Kosten = Zeitabweichung fürs Zuordnen (bis 250 ms),
  feste Kosten für Auslassung und Einfügung. Monoton und 1:1 per
  Konstruktion — jede Note höchstens ein Onset, jeder Onset höchstens eine
  Note. Ergebnis pro Note: getroffen (mit Abweichung) oder ausgelassen; pro
  Onset: zugeordnet oder überzählig.
- Hand-Zuordnung ausschließlich aus dem Sticking der **zugeordneten** Note;
  nicht zugeordnete Onsets bekommen keine Hand
  (`mic_analysis_service.dart`, `analyzeHits`).
- **Vertrauensmaß:** unter 90 % getroffener Noten oder ab 5 % überzähligen
  Onsets werden keine Hand-Werte ausgegeben, nur die zuordnungsfreien
  Größen; das Feedback-Sheet sagt das an
  (`sequence_aligner.dart` `handValuesAllowed`,
  `practice_session_screen.dart` `_AnalysisSummary`).

**Abnahme (neu per Freigabe, Übung R L R L):** Die drei Fälle sind als
Unit-Tests umgesetzt und bestanden (`test/coaching/sequence_aligner_test.dart`,
`test/coaching/mic_analysis_test.dart`); dieselben drei Durchläufe sind am
Gerät zu bestätigen.

| Fall | Vorher (Stand #14, aus §0 belegt) | Nachher (Unit-Test) | Gerätetest 08.09. |
|---|---|---|---|
| (a) ein Schlag ausgelassen | Auslassung wird nicht gezählt oder gemeldet | genau 1 Auslassung an der richtigen Position; Folge-Hände korrekt ✓ | ✓ **31 / 1 / 0** (74 BPM) — genau 1 Auslassung; Hand-Werte offen (97 %): R +73,5 / L +73,8 ms |
| (b) ein Schlag doppelt | beide Onsets erhalten dieselbe Note und Hand | 1 Onset zugeordnet, 1 als überzählig; jede Note höchstens einmal ✓ | ✓ **26 / 4 / 1** (65 BPM) — der Doppelschlag als genau 1 überzähliger Onset; die 4 Auslassungen waren real (2 Schläge mit Pegel 1–2, kaum angespielt), Gate korrekt zu |
| (c) ein Schlag ~150 ms zu früh | je nach Tempo Sprung auf die Nachbarnote | Zuordnung zur richtigen Note mit −150 ms Abweichung ✓ (Raster 200 ms) | ✓ **27 / 0 / 2** (71 BPM) — **0 Auslassungen** = kein Nachbarnoten-Sprung (der hätte zwingend 1 missed erzeugt); Ausreißer sichtbar als Streuung ±77,1 ms (vs. ±28,7 in (a)); Gate korrekt zu (2 extra ≥ 5 %) |

Anzeige im Feedback-Sheet: „Matched / missed / extra" pro Durchlauf; die
Einzelabweichungen stehen seit dem 08.09. in den Messdetails (in (c) nicht
aufgeklappt — der ~−150-Einzelwert wurde nicht notiert, das Kriterium
„richtige Note statt Sprung" ist durch 27/27 besetzte Noten dennoch
zwingend belegt).

**Vierter durch den Gerätetest gefundener Messfehler (07.09., behoben
`3d9a6d5`):** Die erste a/b/c-Runde zeigte 9–10 Phantom-Auslassungen pro
Durchlauf, weil der Klick vor dem Einstieg und nach dem letzten Schlag bis
zum Stop weiterzählte. Bewertet wird seither nur das Fenster vom ersten bis
zum letzten getroffenen Schlag; Auslassungen mittendrin zählen unverändert.

**Beobachtung Kopfhörer-Betrieb (erwartet, §1.3-Mechanik):** Mit
USB-C-Kopfhörern erscheint ein systematischer Median-Versatz von
+41…+65 ms — die Kopfhörer-Ausgabelatenz unterscheidet sich vom
Lautsprecher-Loopback-Kalibrierwert. Er wird ausgewiesen, nicht verrechnet,
genau wie im Brief vorgesehen. Falls die Absolutlage im Alltag stören
sollte, wäre eine zweite Kopfhörer-Kalibrierung (Klick über Kopfhörer auf
den Pad-Schlag statt Loopback) eine Phase-3+-Option.

## 1.3 Latenz-Bezug zwischen Klick und Aufnahme

**Umsetzung:**
- **Gemeinsame Zeitachse:** Klick-Zeitstempel sind jetzt die *geplanten*
  Zeitpunkte aus dem Timing-Isolate (`expectedBeatTimeUs` +
  `BeatEvent.plannedAt`, `metronome_engine.dart`), nicht mehr die
  Ankunftszeit des UI-Updates. Onsets bleiben auf der Sample-Uhr mit
  Wanduhr-Anker. Beide Seiten treffen sich damit ohne Port-/Frame-Jitter.
- **Kalibrierung** (Freigabe-Ergänzung: Ausgabe- und Eingabelatenz gemeinsam):
  Der neue Screen *Einstellungen → Latenz-Kalibrierung* spielt 24 geditherte Klicks (plus verworfenen Aufwärm-Zyklus) über
  den Lautsprecher, nimmt sie über denselben rohen Aufnahmeweg auf und misst
  den Versatz geplant→aufgenommen — genau die Summe beider Latenzen
  (`latency_calibration_service.dart`, `latency_estimator.dart`,
  `latency_calibration_screen.dart`). Der Screen zeigt Median und Spannweite
  mehrerer Läufe; gespeichert wird per Knopf
  (`SettingsService.latencyOffsetMs`).
- **Anwendung:** Der gespeicherte Wert wird vor dem Alignment von den
  Onset-Zeiten abgezogen und im Feedback als „Latency correction"
  ausgewiesen. Der *verbleibende* mittlere Versatz eines Durchlaufs steht
  separat als Median in den zuordnungsfreien Größen — er wird ausgewiesen,
  nicht stillschweigend abgezogen (Test: `mic_analysis_test.dart`,
  „stored latency offset …").

**Gerätetest 06.09. — Protokoll (vier Iterationen):** Die Kalibrier-Messung
deckte nacheinander drei Fehlerquellen auf; zwei davon waren echte
Messfehler, die auch die Übungsanalyse verfälscht hätten:

1. **10-ms-Zeitraster:** Onset-Zeiten waren auf den Anfang des
   10-ms-Analysefensters gerundet → behoben durch Sample-genaue
   Attack-Flanken-Suche (`onset_detector.dart`, Commit `56a3cae`).
2. **First-Chunk-Anker:** Die Aufnahme-Zeitachse hing am Delivery-Jitter des
   ersten Audio-Chunks → Minimum über alle Chunks (Commit `b035d10`).
3. **Akkumulierende Sample-Uhr-Drift:** 15–25 ms Versatz-Drift *innerhalb*
   einer ~12-s-Aufnahme (Block-Messung); auf eine Übungssession
   hochgerechnet > 100 ms — die Sample-Uhr (Samples ÷ 16 kHz) läuft nicht
   synchron zur Realzeit. Behoben durch chunk-lokale Wanduhr-Abbildung
   (`sample_clock_map.dart`, Commit `ae25cc1`). **Nachweis per
   Drift-Diagnose: −1,0 / 0,2 / 0,9 ms je Messlauf — die Aufnahmeseite ist
   seither driftfrei.**
4. Zusätzlich: verworfener Aufwärm-Zyklus (Kaltstart-Pipeline maß zunächst
   68,5 → 53,9 → 49,8 ms monoton fallend) und 24 geditherte Klicks gegen
   Puffer-Phasen-Aliasing.

**Finale Messreihe (nach allen Fixes):**

| Lauf | Median | Klicks gefunden | Block-Mediane (3×8) | Δ im Lauf |
|---|---|---|---|---|
| 1 | 56,2 ms | 24/24 | 54,4 / 57,7 / 62,4 | 8,0 ms |
| 2 | 73,1 ms | 24/24 | 75,6 / 82,0 / 67,1 | 14,9 ms |
| 3 | 68,5 ms | 24/24 | 62,6 / 58,5 / 72,9 | 14,4 ms |

Gesamt-Median **69 ms** (gespeichert), Spannweite der Läufe 16,8 ms.

**Abnahme „drei Durchläufe, Streuung < 5 ms": NICHT erreicht — als
Messgrenze diagnostiziert, nicht als offener Fehler.** Die Blöcke wandern
ohne Trend um ±7 ms, während die Sample-Uhr nachweislich < 1 ms driftet:
Die Restschwankung sitzt in der **Ausgabelatenz** (Klick-Befehl → Schall),
die die Android-Audiokette auf Sekundenskala um ±8 ms verschiebt und für
die es keine Abfrage-API gibt. Einordnung: ±8 ms liegen unter der
Wahrnehmungsschwelle, betreffen nur die Absolutlage (nicht Hand-Balance,
Jitter, Gleichmäßigkeit) und bleiben im pro Durchlauf ausgewiesenen Median
sichtbar — genau der in §1.3 des Briefs vorgesehene Mechanismus.

**Angepasste Abnahme (vom Auftraggeber am 06.09. entschieden):** „Drei Läufe
à 24 Klicks, alle Klicks erkannt, Sample-Uhr-Drift < 2 ms je Lauf
(Diagnosewert), gespeichert wird der Gesamt-Median; dokumentierte
Restunsicherheit der Absolutlage ±8 ms (Ausgabelatenz der Gerätekette)."

**Bewertung gegen die angepasste Abnahme: BESTANDEN.**

| Kriterium | Ergebnis |
|---|---|
| Drei Läufe à 24 Klicks | ✓ (Messreihe oben) |
| Alle Klicks erkannt | ✓ 24/24 in jedem Lauf |
| Sample-Uhr-Drift < 2 ms je Lauf | ✓ −1,0 / 0,2 / 0,9 ms |
| Gesamt-Median gespeichert | ✓ **69 ms** (06.09.) |
| Restunsicherheit dokumentiert | ✓ ±8 ms, siehe oben |

## 1.4 Zuordnungsfreie Messgrößen

**Umsetzung** (`lib/features/coaching/services/unassigned_metrics.dart`),
immer verfügbar, unabhängig vom Vertrauensmaß, im Feedback-Sheet stets
sichtbar:
- Timing-Abweichung gegen Klick: Median + Streuung
- Gleichmäßigkeit: Streuung der Onset-Abstände
- Dynamik-Streuung: Variationskoeffizient der Spitzenpegel (nur roher Weg)
- Schlagzahl Ist/Soll

## Tests

- **Gesamtsuite: 229 Tests, alle grün** (`flutter test`); Analyzer ohne neue
  Befunde.
- Neu in Phase 1: 36 Tests — `sequence_aligner_test.dart` (9, inkl. a/b/c),
  `unassigned_metrics_test.dart` (7), `latency_estimator_test.dart` (5),
  `recording_setup_test.dart` (7, inkl. MethodChannel-Mock),
  `mic_analysis_test.dart` (6, inkl. Schwellen-Gate und Latenz-Anwendung),
  `metronome_engine_test.dart` (+2 für `expectedBeatTimeUs`).

## Gerätetest-Anleitung (S23 Ultra)

1. Branch bauen und installieren (Debug-Build reicht laut Brief).
2. *Einstellungen → Mikrofon-Analyse* einschalten.
3. **1.3 zuerst:** *Einstellungen → Latenz-Kalibrierung*, Kopfhörer ab,
   Lautstärke hoch, 3× „Messen", Spannweite ablesen, „Wert speichern".
   Werte in die 1.3-Tabelle.
4. **1.1:** Übung mit 20+ Schlägen starten (z. B. Single Strokes, ~80 BPM),
   abwechselnd laut/leise schlagen. Nach der Session im Feedback-Sheet
   „Messdetails" öffnen: `unprocessedSupported` und Pegelfolge notieren,
   Verhältnisse ausrechnen (erste vs. letzte Paare).
5. **1.2:** Übung R L R L (Single Strokes), drei Durchläufe:
   (a) einen Schlag auslassen, (b) einen doppelt, (c) einen deutlich zu früh.
   Je Durchlauf „Matched / missed / extra" und (falls über Schwelle) die
   Hand-Werte notieren.
6. Werte in diesen Bericht eintragen; erst danach Phase 2 anstoßen.

## Bekannte Grenzen (bewusst, Phase-1-Scope)

- Die Klick-Seite nutzt die *geplante* Abspielzeit; die tatsächliche
  Audio-Ausgabelatenz steckt im Kalibrierwert — deshalb ist Schritt 3 vor
  jeder ernsthaften Messung nötig. Unkalibriert erscheint der Versatz offen
  im Median.
- Der Onset-Detektor hat 50 ms Refraktärzeit; schnellere Doppelschläge
  (> 20/s) verschmelzen.
- Ob die Samsung-Signalkette bei `VOICE_RECOGNITION` trotz deaktivierter
  Effekte eingreift, entscheidet erst die 1.1-Messung — genau dafür ist sie
  da. Bei verfügbarem `UNPROCESSED` stellt sich die Frage nicht.
- Der automatische Modus-Vorschlag und die Lern-/Analyse-Trennung sind
  Phase 3; das Feedback-Sheet zeigt in Phase 1 die Sperre der Hand-Werte mit
  neutralem Hinweistext.
