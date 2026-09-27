# K2 Schritt 2 „Practice" — Design-Spec (25.09.2026)

Der Übungs-Screen wird nach dem K2-Entwurf umgebaut: Notenblatt und Zählwerk
sind das großflächige Herz, die Steuerung darunter ist kompakt, alles Seltene
wandert hinter „⋯". Der Screen bleibt dunkel (Entscheidung 15.09., Mischung).
Messung, Mikro, Bewertungs- und Feedback-Blatt bleiben unverändert; die gehören
zu K2 Schritt 3 „Result".

Grundlagen: `docs/design/ENTWURF_K2_LEICHT_UND_KLAR.md` (Branch
k2-design-entwuerfe, Draft-PR #22), Mockup `docs/design/k2-entwuerfe/Practice.dc.html`,
Brief `docs/BRIEF_NEUKONZEPT_OPTIK_INHALTE.md` §3 und §9 (PR #20).
Entscheidungen des Auftraggebers am 25.09.: Stop pausiert und ein Finish-Knopf
erscheint (nicht: Stop beendet direkt); Bauplan freigegeben.

## 1. Ziel und Nicht-Ziele

**Ziel.** Ein Drummer am Pad sieht aus 60 cm Entfernung Noten und Zählwerk,
findet Tempo und Start/Stop ohne Suchen, und wird von nichts anderem abgelenkt.
Abnahme wie im Brief: Screenshots vom S23, Urteil „leicht / luftig / klar".

**Nicht-Ziele.**
- Kein neues Messverhalten, keine Änderung an Aufnahme, Alignment, Latenz.
- Bewertungs-Blatt (`_RatingSheet`) und Feedback-Blatt (`_FeedbackSheet`)
  bleiben, wie sie sind. Ihr Umbau ist Schritt 3.
- Keine neue Übungslogik (Leiter-Plan, Gate, Auto-Ende bleiben).
- Kein Umbau von `NotationStaffWidget`, `BeatIndicator`, `BpmStepButtons`.

## 2. Aufbau des Screens (von oben nach unten)

Kein `AppBar`. Der Screen ist eine `Column` in `SafeArea`, ohne Scrollen; das
Notenblatt nimmt den freien Platz (`Expanded`). Statusleisten-Symbole hell
(`AnnotatedRegion<SystemUiOverlayStyle>(SystemUiOverlayStyle.light)`), weil der
Screen dunkel ist und ohne AppBar niemand sonst das setzt.

### 2.1 Kopfzeile

`Row`, Höhe 44, Innenabstand 12/16:
- Zurück-Knopf (44×44, `Icons.arrow_back`), `Navigator.pop`.
- Titelblock (flexibel): Übungsname (`PracticeTypography.title`, eine Zeile,
  Ellipsis) und darunter die **Kontextzeile** (`subtitle`, `textMuted`).
- Rechts der **Modus-Chip** (44 hoch, Pillenform, Rahmen `textFaint`,
  Mono-Label 11 px, Versalien): Mikro-Symbol + „ANALYSIS" oder „LEARN".
  Tipp schaltet `_analysisMode` um und speichert wie heute über
  `SettingsService.setAnalysisModeFor`. Mikro-Symbol orange, wenn
  `_micRecording`, sonst `textFaint`. Der Chip erscheint nur, wenn
  `SettingsService.micAnalysisEnabled`; sonst bleibt die Stelle leer.

**Kontextzeile.** Die Route bekommt einen optionalen Query-Parameter `ctx`
(URL-kodiert). Today übergibt seine `PathStep.detail`-Zeile (zum Beispiel
„Day 9 · Step 2 of 3 · 84 BPM"); `practiceRouteFor(block)` bekommt dafür einen
optionalen Parameter `ctx`. Fehlt `ctx`, zeigt die Zeile die Stufe der Übung
(`rudiment.difficulty.label`, zum Beispiel „Beginner"). Der Programm-Screen ändert sich nicht.

Was aus der Kopfzeile verschwindet: der Info-Knopf (Erklärung; wandert nach
„⋯"), das Modus-Symbol und das Mikro-Symbol (jetzt der Chip), die Restzeit
(jetzt im Hauptknopf) und die Sitzungsuhr (kumulierte Tageszeit; sie bleibt im
`sessionTimerNotifierProvider` für Today/Progress, wird hier nicht mehr gezeigt).

### 2.2 Notenblatt

`Expanded` → Papierkarte (Radius 14, `PracticeColors.paper`, Außenabstand
16/14/16/0, Innenabstand 16/16/6/16) mit `NotationStaffWidget` wie heute
(`activeIndex`, `autoScroll: true`). Nichts am Widget ändern.

### 2.3 Zählwerk → ersetzt durch die Klick-Spur (Auftraggeber 27.09.)

**Entscheidung 27.09. nach dem Emulator-Test:** „Das Zählwerk mag ich nicht.
Fände es besser, wenn ein Metronom-Klick mitlaufen würde, natürlich wählbar."
Das Zählwerk entfällt komplett (Widget, Takt-Rechnung, Tests gelöscht); der
Platz geht ans Notenblatt. Stattdessen:

- **Klick-Spur:** ein Puls auf jedem Viertel, der neben den Muster-Noten
  läuft. Im Motor eine zweite Stimme im gerenderten Loop
  (`buildLoopWav(pulseSamples:, pulseEvery: factor)`), mit eigenem, kurzem,
  hellem Klang (`MetronomeEngine.pulseSamples()`: 2,6 kHz, 12 ms, leiser als
  der Übungs-Klick), damit das Ohr Puls und Muster unterscheidet. Nur im
  Muster-Modus; im reinen Metronom sind die Ticks selbst der Puls.
- **Wählbar:** Schalter „Click track" im „⋯"-Blatt, gemerkt in
  `SettingsService.clickTrackEnabled` (Standard an).
- **Analyse-Modus:** Puls immer aus (Auftraggeber: „An, im Analyse-Modus
  aus"), weil das Mikro ihn sonst als Schläge hört; der Schalter ist dann
  deaktiviert mit Hinweis. Die Einstellung selbst bleibt unangetastet.
- **Messung unberührt:** die Puls-Stimme ist nur Audio; Beat-Log und Alignment
  kennen weiterhin nur die Muster-Noten (`tickVolumes`).
- Kein Akzent auf der Eins (bewusst): Muster kürzer als ein Takt würden den
  Akzent an die falsche Stelle setzen; ein gleichmäßiger Puls ist ehrlich.

Der ursprüngliche Abschnitt bleibt als Historie stehen:

### 2.3 (alt) Zählwerk

Eigenes Widget `BeatCounter` (`lib/features/practice/widgets/beat_counter.dart`):
- Zeigt die Schläge eines Taktes als Zahlen `1 … beatsPerBar`
  (`rudiment.beatsPerBar`), Mono 56 px fett, gleichmäßig verteilt
  (`Expanded` je Zahl), darunter je ein 22×4-Strich.
- Aktiver Schlag: Zahl und Strich `PracticeColors.accent`; alle anderen
  Zahl `textFaint`, Strich transparent. Im Stand (nicht spielend) ist kein
  Schlag aktiv.
- Eingabe: `activeBeat` (0-basiert oder null). Der Screen berechnet ihn aus
  dem Metronom über einen selektiven Watch aus dem **globalen, nicht
  umgebrochenen** Tick des Motors:
  `activeBeat = (currentBeatIndex ~/ _playback.ticksPerQuarter) % rudiment.beatsPerBar`,
  null, wenn nicht spielend oder `currentBeatIndex < 0`.
  Korrektur 26.09. (Review): die erste Fassung brach den Tick am Muster um
  (`% _playback.totalTicks`, wie der Notenblatt-Cursor). Viele Muster sind
  aber kürzer als ein Takt (2, 3 oder 6 Schläge) — dann blieben Ziffern
  dauerhaft grau. Der Drummer zählt 1 2 3 4 im Takt der Übung, egal wie lang
  die Figur ist; nur der Cursor auf dem Blatt folgt der Schleife.
- Reine Funktion `beatOfTick(tick, ticksPerQuarter, beatsPerBar)` neben dem
  Widget, damit die Rechnung ohne Widget testbar ist.

### 2.4 Steuerung

`Padding` 16, `Column` mit Abstand 14:

1. **Leiter-Zeile** (nur bei aktivem Leiter-Plan, wie heute): Mono-Label
   „LADDER" + `AppSelectableChip` je Stufe, aktive Stufe markiert. Verhalten
   unverändert (`_LadderStepRow` bleibt, nur das Label wird „LADDER").
2. **Tempo-Zeile:** links runder Minus-Knopf (44), Mitte die BPM-Zahl
   (`PracticeTypography.numericXl` 48 px) mit kleinem „BPM"-Label, rechts
   runder Plus-Knopf (44). Minus/Plus ändern um **4 BPM** (eine Leiterstufe),
   geklemmt auf 40–240, über `_onUserBpmChanged` (Leiter-Logik bleibt). Tipp
   auf die Zahl öffnet `editBpmDialog` für den genauen Wert. Der Schieberegler
   und die ±1/±5-Knöpfe entfallen auf diesem Screen.
3. **Fußzeile:** Hauptknopf (56 hoch, flexibel, orange) + „⋯"-Feld (56×56,
   Rahmen `textFaint`). Bei pausierter Sitzung steht links vom „⋯"-Feld
   zusätzlich ein zweiter Knopf „Finish" (Geist-Stil, 56 hoch, flexibel).

### 2.5 Zustände des Hauptknopfs

| Zustand | Bedingung | Hauptknopf | Zweiter Knopf |
|---|---|---|---|
| Bereit | nicht spielend, `_elapsedSeconds == 0` | ▶ „Start · 8 min" (Dauer aus `_goalSeconds`; „Start" allein bei ∞) | – |
| Laufend | spielend | ■ „Stop 7:32" (Restzeit; bei ∞ die verstrichene Zeit) | – |
| Pausiert | nicht spielend, `_elapsedSeconds > 0` | ▶ „Resume 7:32" | „Finish" → `_showRatingSheet()` |

Start/Stop/Resume rufen `notifier.toggle` wie heute; Ticker, Mikro und
Sitzungsuhr hängen unverändert am Metronom-Zustand. Zeitablauf beendet die
Sitzung automatisch wie heute (`_showRatingSheet` aus dem Ticker). Die
bisherige Umfärbung der Restzeit bei ≤ 30 s entfällt: der Knopf ist ohnehin
orange, die Zahl bleibt weiß und tabellarisch.

### 2.6 Das „⋯"-Blatt

`showModalBottomSheet` im Practice-Theme, Titel „Options", drei Gruppen:
1. **Duration** — Chips 5 min, 10 min, 15 min, ∞ und, falls vorhanden, der
   Vorschlag „8 min ✦" (Logik aus `_TimerGoalRow`, Widget bleibt). Nur wählbar,
   solange `_elapsedSeconds == 0`; danach ausgegraut mit Hinweis
   „Duration is set once the session runs".
2. **Sound** — Chips Click / Rim / Snare, `notifier.setSoundType`.
3. **About this exercise** — Zeile mit Pfeil, öffnet `LessonDetailScreen` per
   `Navigator.push` (wie heute, nicht `context.push`, siehe Kommentar im Code).

Das Blatt schließt nach jeder Auswahl nicht automatisch; „Done"-Knopf unten.

## 3. Änderungen an Dateien

- `lib/features/practice/practice_session_screen.dart`: `build` neu
  (Kopfzeile, Papierkarte, Zählwerk, Steuerung, Fußzeile), `_CompactMetronome`
  entfällt, `_TimerGoalRow` und `_LadderStepRow` bleiben (Label „LADDER"),
  neues `_OptionsSheet`, neuer Konstruktor-Parameter `context` (String?).
  Rating-/Feedback-Blätter unangetastet.
- Neu `lib/features/practice/widgets/beat_counter.dart`: `BeatCounter`,
  `beatOfTick`.
- Neu `lib/features/practice/widgets/tempo_row.dart`: `TempoRow` (Minus,
  Zahl, Plus, Dialog).
- `lib/app/router.dart`: `ctx`-Query lesen, an den Screen geben.
- `lib/features/program/practice_route.dart`: optionaler `ctx`.
- `lib/features/today/next_step.dart`: `practiceRouteFor(block, ctx: detail)`.
- `test/features/practice/practice_session_screen_test.dart`: an neue Texte
  und Knöpfe anpassen; neue Tests siehe §4.
- `docs/BERICHT_K2_PRACTICE.md`: kurzer Bericht mit Screenshots vom Gerät.

## 4. Tests

Alle Widget-Tests mit Handy-Fläche 1080×2340, dpr 3 (wie Today-Test), damit
Überläufe auffallen.

- `beatOfTick`: Tick 0 → 0; Tick 24 → 1 (bei 24 Ticks/Viertel); Tick 96 bei
  4/4 → 0; Tick 48 bei 2/4 → 0; 3/4 zählt bis 2.
- `BeatCounter`: zeigt `beatsPerBar` Zahlen; aktiver Schlag orange, andere
  nicht; null → keine orange Zahl.
- Screen bereit: mit `targetMinutes: 4` zeigt der Hauptknopf „Start · 4 min";
  ohne `targetMinutes` ist `_goalSeconds` null und der Knopf zeigt „Start".
  Kontextzeile zeigt `ctx`, ohne `ctx` das Stufen-Label.
- Screen laufend (Metronom-Override wie im bestehenden Test): Hauptknopf
  „Stop 03:20" nach 40 s bei 4-min-Ziel; kein Finish-Knopf.
- Screen pausiert: nach Stop erscheint „Resume …" und „Finish"; „Finish" öffnet
  das Bewertungs-Blatt (Text „How did it feel?").
- Tempo: Plus erhöht um 4 (Text 52 → 56), Minus senkt um 4; Tipp auf die Zahl
  öffnet den Dialog (Titel wie `editBpmDialog`).
- Modus-Chip: mit `micAnalysisEnabled` sichtbar, Tipp wechselt „ANALYSIS" ↔
  „LEARN"; ohne Mikro-Analyse kein Chip.
- „⋯"-Blatt: öffnet, Dauer-Chip „10 min" setzt den Hauptknopf auf
  „Start · 10 min"; Klang-Chip ruft `setSoundType`; nach Start sind Dauer-Chips
  deaktiviert.
- Kein Überlauf: `tester.takeException()` null nach Pump in allen Zuständen.
- Bestehende Tests, die ‚+5', ‚Tempo ladder', ‚Finish Session', ‚04:00' erwarten,
  werden auf die neuen Texte umgestellt; ihre Absicht (Leiter-Anzeige,
  Restzeit, Vorschlag-Dauer) bleibt.

## 5. Gerätetest und Abnahme

Release-Build auf dem S23 über den Laptop-Checkout. Vor jedem adb-Tipp prüfen,
dass `com.example.drum_coach` im Vordergrund ist (Regel seit 25.09.).
Screenshots: bereit, laufend, pausiert, „⋯"-Blatt. Abnahme durch den
Auftraggeber mit dem Urteil „leicht / luftig / klar".

## 6. Offen gelassen (bewusst)

- Feinschritte ±1 gibt es nur über den Dialog. Falls das am Pad stört, kommt
  ein Langdruck auf Plus/Minus.
- Wortlaut der Kontextzeile ohne Programm (freies Üben aus der Bibliothek):
  vorerst das Stufen-Label; Schritt K4 (Bibliothek) darf das ändern.
