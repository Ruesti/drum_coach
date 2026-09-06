# Bericht Etappe 1 — Phase 1: Messung glaubwürdig

**Datum:** 06.09.2026 · **Basis:** main nach Merge von PR #14 und #15 (`60d0ffd`)
· **Brief:** `docs/BRIEF_ETAPPE1_PAD.md` §1.1–1.4 samt Freigabe-Ergänzungen

**Stand: Implementierung komplett, Unit-Abnahmen erfüllt (219/219 Tests).
Die Gerätetest-Abnahmen (S23 Ultra + Pad) stehen aus — die auszufüllenden
Werte sind unten als ☐ markiert.** Der Bericht wird nach dem Gerätetest um
diese Zahlen ergänzt; erst dann gilt Phase 1 als abgenommen.

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

| Messwert | Wert |
|---|---|
| UNPROCESSED auf S23 Ultra verfügbar | ☐ (Messdetails: `unprocessedSupported`) |
| Verhältnis Spitzenpegel laut/leise, erste 5 Paare | ☐ |
| Verhältnis Spitzenpegel laut/leise, letzte 5 Paare | ☐ |
| Angleichung über die Zeit (Verhältnis-Drift) | ☐ (Soll: keine) |

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

| Fall | Vorher (Stand #14, aus §0 belegt) | Nachher (Unit-Test) | Gerätetest |
|---|---|---|---|
| (a) ein Schlag ausgelassen | Auslassung wird nicht gezählt oder gemeldet | genau 1 Auslassung an der richtigen Position; Folge-Hände korrekt ✓ | ☐ |
| (b) ein Schlag doppelt | beide Onsets erhalten dieselbe Note und Hand | 1 Onset zugeordnet, 1 als überzählig; jede Note höchstens einmal ✓ | ☐ |
| (c) ein Schlag ~150 ms zu früh | je nach Tempo Sprung auf die Nachbarnote | Zuordnung zur richtigen Note mit −150 ms Abweichung ✓ (Raster 200 ms) | ☐ |

Anzeige im Feedback-Sheet: „Matched / missed / extra" pro Durchlauf.

## 1.3 Latenz-Bezug zwischen Klick und Aufnahme

**Umsetzung:**
- **Gemeinsame Zeitachse:** Klick-Zeitstempel sind jetzt die *geplanten*
  Zeitpunkte aus dem Timing-Isolate (`expectedBeatTimeUs` +
  `BeatEvent.plannedAt`, `metronome_engine.dart`), nicht mehr die
  Ankunftszeit des UI-Updates. Onsets bleiben auf der Sample-Uhr mit
  Wanduhr-Anker. Beide Seiten treffen sich damit ohne Port-/Frame-Jitter.
- **Kalibrierung** (Freigabe-Ergänzung: Ausgabe- und Eingabelatenz gemeinsam):
  Der neue Screen *Einstellungen → Latenz-Kalibrierung* spielt 8 Klicks über
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

**Abnahme (Gerätetest):** Drei Kalibrierläufe.

| Messwert | Wert |
|---|---|
| Lauf 1 / 2 / 3 (ms, gefundene Klicks je 8) | ☐ / ☐ / ☐ |
| Spannweite (Soll < 5 ms) | ☐ |
| Gespeicherter Wert | ☐ |

## 1.4 Zuordnungsfreie Messgrößen

**Umsetzung** (`lib/features/coaching/services/unassigned_metrics.dart`),
immer verfügbar, unabhängig vom Vertrauensmaß, im Feedback-Sheet stets
sichtbar:
- Timing-Abweichung gegen Klick: Median + Streuung
- Gleichmäßigkeit: Streuung der Onset-Abstände
- Dynamik-Streuung: Variationskoeffizient der Spitzenpegel (nur roher Weg)
- Schlagzahl Ist/Soll

## Tests

- **Gesamtsuite: 219 Tests, alle grün** (`flutter test`); Analyzer ohne neue
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
