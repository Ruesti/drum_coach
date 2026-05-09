# DrumCoach – Phasenmodell

Jede Phase hat einen klaren Scope, einen copy-paste Claude Code Prompt,
und eine Definition of Done. Phasen nacheinander abarbeiten –
nicht zur nächsten wechseln bevor die aktuelle abgeschlossen ist.

---

## Phase 1 – Projekt-Foundation
**Ziel:** Lauffähiges Flutter-Projekt mit Navigation, Theme und leeren Screens.

### Was wird gebaut
- [ ] `pubspec.yaml` mit allen Dependencies
- [ ] Ordnerstruktur gemäß `CLAUDE.md`
- [ ] Material 3 Dark Theme (`app/theme.dart`)
- [ ] `go_router` Setup mit allen Routen (`app/router.dart`)
- [ ] Bottom Navigation (Dashboard | Routine | Lessons | Stats)
- [ ] Placeholder-Screens für alle 6 Routen
- [ ] Isar initialisieren vor `runApp()`

### Claude Code Prompt
```
Read CLAUDE.md carefully. Implement Phase 1 – Foundation:

1. Set up pubspec.yaml with all required dependencies:
   riverpod + riverpod_annotation, go_router, isar + isar_flutter_libs,
   flutter_soloud, fl_chart, build_runner, riverpod_generator

2. Create the complete folder structure from CLAUDE.md

3. Implement the Material 3 dark theme in app/theme.dart
   Primary: deep orange (Colors.deepOrange), dark background

4. Set up go_router in app/router.dart with all routes from CLAUDE.md

5. Create placeholder screens for: Dashboard, DailyRoutine, Lessons,
   LessonDetail, PracticeSession, Stats – each just shows its name

6. Add bottom navigation shell with 4 tabs: Dashboard | Routine | Lessons | Stats

7. Initialize Isar in data/local/isar_service.dart before runApp()

The app must run on Android with no errors before this phase is complete.
```

### Definition of Done
- `flutter run` startet ohne Fehler
- Alle 4 Tabs navigierbar
- Dark Theme sichtbar
- Isar initialisiert (kein Crash)

---

## Phase 2 – Metronom
**Ziel:** Voll funktionsfähiges Metronom mit präzisem Audio-Timing.

### Was wird gebaut
- [ ] `flutter_soloud` Audio-Engine setup
- [ ] Metronom-Logik in Isolate (kein UI-Jank)
- [ ] BPM Slider (40–240) mit Zahlenanzeige
- [ ] Tap Tempo (Durchschnitt letzter 4 Taps, Reset nach 3s)
- [ ] Subdivision-Auswahl: ♩ ♪ ♪♪♪ ♬ (Viertel / Achtel / Triole / Sechzehntel)
- [ ] Visueller Beat-Indikator (blinkt/pulst im Takt)
- [ ] Start / Stop Button
- [ ] MetronomeProvider (Riverpod)

### Claude Code Prompt
```
Implement Phase 2 – Metronome. See CLAUDE.md for constraints.

Use flutter_soloud for audio (NOT just_audio or audioplayers).
Run the tick engine in an Isolate or background timer to avoid UI jank.

Implement:
1. MetronomeEngine in features/metronome/metronome_engine.dart
   - Start/stop, BPM control, subdivision support
   - Emits beat events via Stream<BeatEvent>
   - BeatEvent contains: beatIndex, subdivision, isAccent

2. MetronomeProvider (Riverpod @riverpod codegen) wrapping the engine

3. MetronomeScreen with:
   - Large BPM display (readable from 1m distance)
   - Slider 40–240 BPM
   - Tap Tempo button (avg of last 4 taps, reset after 3s)
   - Subdivision selector (quarter / eighth / triplet / sixteenth)
   - Visual beat indicator (pulsing circle, synced to audio not frame rate)
   - Start/Stop button

The metronome must not drift at 200+ BPM. Test this manually.
```

### Definition of Done
- Metronom startet/stoppt zuverlässig
- Kein hörbares Drift bei 200 BPM über 2 Minuten
- Tap Tempo funktioniert mit 4-Tap-Durchschnitt
- Alle Subdivisions hörbar unterschiedlich

---

## Phase 3 – Rudiment Library & Sticking Display
**Ziel:** Alle Rudiments mit R/L-Anzeige, animiert im Takt.

### Was wird gebaut
- [ ] `StrokeBeat` und `Hand` Modelle
- [ ] `Rudiment` Modell (vollständig mit Sticking-Daten)
- [ ] Seed-Daten für alle 6 Kategorien (mind. 15 Rudiments)
- [ ] `StickingPatternWidget` (statisch + animiert)
- [ ] `LessonsScreen` – Liste nach Kategorie gruppiert
- [ ] `LessonDetailScreen` – Beschreibung + statisches Sticking + Metronom-Integration

### Claude Code Prompt
```
Implement Phase 3 – Rudiment Library and Sticking Display.

1. Create data models: StrokeBeat, Hand (enum), Rudiment
   as defined in CLAUDE.md

2. Create seed data in features/lessons/data/rudiments_seed.dart
   with at least 15 rudiments across all 6 categories:
   Rolls, Paradiddles, Flams, Ruffs, Ghost Notes, Linear Patterns
   Every rudiment must have a complete sticking List<StrokeBeat>
   Example patterns:
   - Single Stroke Roll: R L R L R L R L
   - Double Stroke Roll: R R L L R R L L
   - Single Paradiddle: R● L R R L● R L L  (● = accent)
   - Flam: lR● rL●  (lowercase = grace note / ghost)

3. Implement StickingPatternWidget in shared/widgets/sticking_pattern_widget.dart
   - Static mode: shows full pattern, no animation
   - Live mode: activeBeatIndex highlights current beat
   - Accent: small dot above beat box
   - Ghost note: 60% opacity, smaller
   - Active beat: amber highlight + scale 1.15 animation
   - Scrollable horizontally for long patterns

4. LessonsScreen: grouped list by category, shows rudiment name + difficulty chip

5. LessonDetailScreen:
   - Rudiment name, description, target BPM range
   - Static StickingPatternWidget
   - "Start Practice" button → navigates to PracticeSession
```

### Definition of Done
- Alle Rudiments mit korrekten R/L Patterns
- Sticking Widget zeigt Akzente und Ghost Notes korrekt
- Animation läuft flüssig, kein Ruckeln
- Navigation Lessons → Detail → Practice funktioniert

---

## Phase 4 – Practice Session
**Ziel:** Vollständige Übungs-Session mit Metronom + Live-Sticking + Bewertung.

### Was wird gebaut
- [ ] `PracticeSessionScreen` (Metronom + Sticking kombiniert)
- [ ] Live `StickingPatternWidget` synchronisiert mit Metronom-Beats
- [ ] Session-Timer (Countdown oder Stoppuhr)
- [ ] Rating-Dialog am Ende (1 Struggled / 2 OK / 3 Solid)
- [ ] `PracticeSession` Isar-Modell
- [ ] Session speichern nach Rating

### Claude Code Prompt
```
Implement Phase 4 – Practice Session.

PracticeSessionScreen receives a rudimentId via go_router parameter.

The screen combines:
1. Compact metronome controls (BPM slider + start/stop, no full metronome UI)
2. Live StickingPatternWidget connected to MetronomeProvider's beat stream
   - activeBeatIndex cycles through the sticking pattern on each beat
   - pattern length may differ from metronome subdivision count – handle this
3. Session timer: elapsed time display (MM:SS), runs while metronome is playing
4. "Finish Session" button → opens rating bottom sheet

Rating bottom sheet:
- Title: "How did it feel?"
- 3 large buttons: 😓 Struggled / 😐 OK / 💪 Solid
- On selection: save PracticeSession to Isar, navigate back

PracticeSession Isar model (data/local/models/practice_session.dart):
  id, rudimentId, durationSeconds, achievedBpm, rating (1/2/3), date

After saving, pop back to wherever the user came from (lessons or routine).
```

### Definition of Done
- Sticking-Anzeige läuft synchron mit Metronom-Beats
- Session-Timer läuft genau
- Rating wird gespeichert (in Isar prüfen mit Isar Inspector)
- Kein State-Leak wenn Screen verlassen wird (Metronom stoppt)

---

## Phase 5 – Learning System
**Ziel:** Spaced Repetition + BPM Progression + tägliche Routine.

### Was wird gebaut
- [ ] `RudimentProgress` Isar-Modell
- [ ] `SpacedRepetitionService` (pure Dart, testbar)
- [ ] `BpmProgressionService` (pure Dart, testbar)
- [ ] `RoutineProvider` – generiert `DailyRoutine`
- [ ] `DailyRoutineScreen` – heutiger Plan mit Rudiment-Cards
- [ ] Unit Tests für SR- und BPM-Logik
- [ ] Integration: nach jeder Session Progress updaten

### Claude Code Prompt
```
Implement Phase 5 – Learning System. Full spec in CLAUDE.md.

1. RudimentProgress Isar model (data/local/models/rudiment_progress.dart):
   id, rudimentId, currentBpm, bestBpm, masteryLevel (enum),
   srInterval, srRepetitions, lastPracticed, nextReviewDate

2. SpacedRepetitionService (features/learning/spaced_repetition_service.dart):
   Pure Dart class (no Flutter imports).
   Method: RudimentProgress updateAfterSession(RudimentProgress progress, int rating)
   Intervals: rating 1 → 1 day (reset reps), rating 2 → unchanged,
   rating 3 → reps++, interval: 1→3→7→14→30→60 days

3. BpmProgressionService (features/learning/bpm_progression_service.dart):
   Pure Dart class.
   Method: int nextSuggestedBpm(RudimentProgress progress, int rating, int targetBpm)
   rating 3 → +5 BPM, rating 2 → +2 BPM, rating 1 → no change, never exceed targetBpm
   Also updates masteryLevel based on bestBpm / targetBpm ratio

4. RoutineProvider: generates List<DailyRoutineItem> for today
   Priority: overdue reviews → active progressions → 1 new rudiment
   Max 5 items, cap ~30 min total

5. DailyRoutineScreen: shows today's plan as cards
   Each card: rudiment name, type badge (Review/Progression/New),
   suggested BPM, estimated duration, "Start" button

6. Write unit tests for SpacedRepetitionService and BpmProgressionService
   (test/learning/ folder)

7. Hook into PracticeSession save: after saving, call both services
   and update RudimentProgress in Isar
```

### Definition of Done
- Unit Tests für SR und BPM Progression: alle grün
- Routine generiert sich korrekt (manuell mit Testdaten prüfen)
- Nach einer Session wird `nextReviewDate` korrekt gesetzt
- Mastery Level ändert sich bei BPM-Fortschritt

---

## Phase 6 – Stats & Dashboard
**Ziel:** Fortschritt sichtbar machen. Dashboard als Einstiegspunkt der App.

### Was wird gebaut
- [ ] `StatsScreen` mit fl_chart
  - Tägliche Übungszeit (Balkendiagramm, letzte 14 Tage)
  - BPM-Verlauf pro Rudiment (Liniendiagramm)
  - Streak-Kalender
- [ ] `DashboardScreen` finalisieren
  - Heutige Routine-Zusammenfassung
  - Aktuelle Streak
  - Letztes geübtes Rudiment mit aktuellem BPM
- [ ] StatsProvider (liest aus Isar)

### Claude Code Prompt
```
Implement Phase 6 – Stats and Dashboard.

StatsScreen using fl_chart:
1. Bar chart: daily practice minutes for last 14 days
   X-axis: dates, Y-axis: minutes
   Highlight today's bar in amber

2. Rudiment BPM progress: LineChart showing bestBpm over time
   for a selected rudiment (dropdown to pick rudiment)

3. Streak counter: consecutive days with at least 1 session
   Display as a number + label, e.g. "🔥 7 day streak"

4. Session history list (last 10 sessions):
   rudiment name, achieved BPM, rating emoji, date

DashboardScreen:
1. Greeting with streak ("Good morning – 🔥 5 day streak")
2. Today's routine card: "X rudiments · ~Y min" → taps to /routine
3. Last practiced card: shows rudiment name + current BPM + mastery level chip
4. Quick-start metronome button → /metronome

All data from StatsProvider reading Isar PracticeSession and RudimentProgress collections.
```

### Definition of Done
- Charts rendern korrekt mit echten Session-Daten
- Streak berechnet sich korrekt über Mitternacht hinweg
- Dashboard zeigt relevante Infos auf einen Blick
- Keine Performance-Probleme bei 100+ Sessions

---

## Phase 7 – Polish & UX
**Ziel:** App fühlt sich fertig und angenehm an.

### Was wird gebaut
- [ ] Onboarding (erster App-Start: Übungszeit-Ziel setzen)
- [ ] Empty States (noch keine Sessions, noch keine Routine)
- [ ] Haptic Feedback auf Metronom-Beats (optional, konfigurierbar)
- [ ] Tägliche Übungserinnerung (lokale Notification)
- [ ] Animationen: Screen-Transitions, Routine-Item abschließen
- [ ] App Icon + Splash Screen
- [ ] Fehlerbehandlung & Edge Cases absichern

### Claude Code Prompt
```
Implement Phase 7 – Polish and UX.

1. Onboarding flow (shown only on first launch, flag in SharedPreferences):
   Single screen: "How long do you want to practice daily?"
   Options: 15 min / 20 min / 30 min / 45 min
   Saves to local settings, used by RoutineProvider for time budgeting

2. Empty states:
   - No sessions yet → encouraging message + "Start your first session" button
   - Routine screen with no due items → "You're all caught up! 🎉" + free practice suggestion

3. Haptic feedback:
   - On each metronome accent beat: HapticFeedback.lightImpact()
   - Toggle in settings (default: on)

4. Local notification: daily practice reminder
   Use flutter_local_notifications
   Default: 18:00, user can change time in settings
   Message: "Time to practice! Your routine is ready 🥁"

5. Smooth page transitions via go_router custom transitions

6. Error handling:
   - Isar write failures: show snackbar, do not crash
   - Audio init failure: show banner with retry option
```

### Definition of Done
- Onboarding erscheint nur beim ersten Start
- Notification kommt zur eingestellten Zeit
- Keine unbehandelten Exceptions in normaler Nutzung
- App fühlt sich polished an (subjektiv testen)

---

## Übersicht

| Phase | Inhalt | Aufwand |
|---|---|---|
| 1 | Foundation, Navigation, Theme | ~1–2h |
| 2 | Metronom (Audio, Tap Tempo, Subdivisions) | ~3–4h |
| 3 | Rudiment Library, Sticking Display | ~3–4h |
| 4 | Practice Session (live Sticking + Rating) | ~2–3h |
| 5 | Learning System (SR + BPM + Routine) | ~4–5h |
| 6 | Stats & Dashboard | ~2–3h |
| 7 | Polish, Notifications, Onboarding | ~2–3h |
| 8 | *(Optional)* KI-Coaching + Mikrofon-Analyse | ~5–8h |

**Gesamt Phase 1–7: ~17–24h · Phase 8 optional on top**

---

---

## Phase 8 (Optional) – KI-Coaching via API
**Voraussetzung:** Mikrofon-Analyse muss zuerst implementiert sein (Phase 8a).
**Ziel:** Echtes Feedback das regelbasierte Systeme nicht leisten können.

> ⚠️ Diese Phase macht nur Sinn wenn die App Mikrofon-Input verarbeitet.
> Ohne Audio-Analyse hat die KI keinen Input und bringt keinen Mehrwert.

### Was wird gebaut
- [ ] **Mikrofon-Analyse (Phase 8a – Voraussetzung)**
  - Tap-Detection: erkennt Schläge via Mikrofon
  - Misst Timing-Abweichung pro Schlag (ms zu früh/spät)
  - Misst Dynamik (laut/leise) pro Hand
  - Speichert rohe Analyse-Daten pro Session

- [ ] **KI-Feedback Engine (Phase 8b)**
  - Sendet Session-Daten (Timing, Dynamik, Rudiment, BPM) an Claude API
  - Empfängt strukturiertes Coaching-Feedback
  - Zeigt Feedback nach der Session als Coach-Card an

- [ ] **Custom Exercise Generator (Phase 8c – optional)**
  - User beschreibt gewünschtes Pattern in Freitext
  - KI generiert neues `List<StrokeBeat>` Sticking-Pattern
  - Pattern wird als temporäre Übung gespeichert

### Welche KI-Inputs sinnvoll sind
```
{
  rudiment: "Single Paradiddle",
  targetBpm: 120,
  achievedBpm: 95,
  timingDeviationMs: { right: +12ms, left: -8ms },  // zu spät / zu früh
  dynamicsBalance: { right: 0.82, left: 0.61 },      // 0–1 Lautstärke
  sessionDurationSec: 360,
  rating: 2  // user's self-assessment
}
```

### Beispiel KI-Output
```
Deine rechte Hand kommt konstant ~12ms zu spät – 
versuch bewusst früher anzusetzen.
Linke Hand ist deutlich leiser (61% vs 82%) – 
übe 5 min nur Links bei 70 BPM.
Für dein Ziel-BPM (120) brauchst du ~3 weitere Sessions.
```

### Monetarisierung
- Phasen 1–7: komplett kostenlos
- Phase 8 (KI-Coaching): Premium-Feature, z.B. 3,99€/Monat
- Passt zum softbrewstudio.com Modell mit Stripe

### Claude Code Prompt
```
Implement Phase 8 – AI Coaching.

Prerequisites: Microphone tap detection must already work and produce
TimingAnalysis and DynamicsAnalysis data per session.

1. Create AICoachingService (features/coaching/ai_coaching_service.dart)
   Sends session data to Claude API (claude-sonnet-4-20250514)
   System prompt: you are an expert drum coach giving concise, 
   actionable feedback based on session performance data.
   Input: JSON with rudiment, bpm stats, timing deviation, dynamics balance
   Output: 2–3 sentences of specific coaching feedback

2. CoachFeedbackCard widget: shown after session rating
   Displays AI feedback with a coach avatar icon
   "Powered by AI" label
   Loading state while API call is in flight

3. Custom Exercise Generator (features/coaching/exercise_generator_screen.dart)
   Text input: "Create a 8-beat pattern combining flams and paradiddles"
   API call returns List<StrokeBeat> as JSON
   Preview with StickingPatternWidget before saving

4. Gate both features behind isPremium flag (Stripe integration follows)
```

### Definition of Done
- KI-Feedback erscheint nach jeder Session mit Mikrofon-Daten
- Feedback ist spezifisch (nicht generisch) basierend auf echten Messwerten
- Custom Patterns werden korrekt als StrokeBeat-Liste geparst
- Graceful fallback wenn API nicht erreichbar (offline)

---

## Workflow-Tipp

Starte jede Phase so:
```
We are working on DrumCoach. Read CLAUDE.md for full context.
We have completed phases 1–X. Now implement Phase X+1 as described
in PHASES.md. Follow all conventions from CLAUDE.md exactly.
```
