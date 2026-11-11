# SP4 — Konfigurierbares, adaptives Trainingsprogramm

**Datum:** 2026-08-10
**Branch:** `feature/drum-etudes` (baut auf SP1–SP3)
**Teil von:** [Roadmap](2026-08-09-drum-etudes-roadmap.md)
**Status:** Design, bereit zur Nutzer-Durchsicht

## Kontext

Das heutige Programm ist ein **fest verdrahtetes 84-Tage-Programm**: `program_provider.dart`
liefert immer die const `stickControlProgram` (4 Phasen, Übungs-Keys
`single/double/paradiddle` hartcodiert), und der aktuelle Tag wird aus einem
Startdatum abgeleitet (`dayNumberOn`, Tag 1..84). Es gibt keine Wahl von
Zeitraum, Startschwierigkeit oder Inhalt und keine echte Anpassung.

SP4 ersetzt das durch ein **konfigurierbares, adaptives** Programm — die vier
Nutzer-Anforderungen:
1. **Zeitraum wählen** (= **Pacing-Ziel**, echt adaptiv)
2. **Startschwierigkeit festlegen**
3. **Inhalts-Pool wählen** (neue Übungen / klassische Schlagübungen / gemischt)
4. **Adaptive Steigerung** — Stufe hoch, wenn der User bereit ist

## Kernidee: Inhalt an Reife koppeln, Zeitraum als Richtwert

- Der Inhalt wird **nicht** vom Kalender bestimmt, sondern von **Stufen**
  (Schwierigkeits-Tiers ab der Startschwierigkeit aufwärts). Der User steht auf
  einer **aktuellen Stufe**; er steigt auf, wenn er **bereit** ist.
- Der gewählte **Zeitraum** verteilt die Stufen als **Richtwert** über die
  Wochen und liefert eine Fortschritts-Referenz („Woche 3/8 · Stufe: Intermediate
  · voraus/im Plan/hinterher"). Er erzwingt **keinen** Aufstieg — der User kann
  schneller oder langsamer sein.

## Datenmodell & Generierung

### ProgramConfig (neu, persistiert)
```dart
enum ProgramPool { basicStrokes, newExercises, mixed }

class ProgramConfig {
  final int durationWeeks;          // Pacing-Ziel, z.B. 4 / 8 / 12
  final Difficulty startDifficulty; // beginner / intermediate / advanced
  final ProgramPool pool;
  const ProgramConfig({required this.durationWeeks, required this.startDifficulty, required this.pool});
}
```
Persistenz in `SettingsService` (wie `programStartDate`): Keys
`program_duration_weeks` (int), `program_start_difficulty` (enum-name),
`program_pool` (enum-name), plus der vorhandene `program_start_date` und ein
neuer `program_stage_index` (int, aktuelle adaptive Stufe). Config fehlt/kein
Startdatum ⇒ nicht gestartet.

### Pool-Auswahl (reine Funktion)
```dart
List<Rudiment> programPoolExercises(List<Rudiment> all, ProgramPool pool);
```
- **basicStrokes:** die klassischen Basis-Rudiments — `collection == null`
  (der vorhandene Katalog, z.B. Single/Double Stroke Roll, Paradiddle, …).
- **newExercises:** die neuen Inhalte — `collection != null` (die 56 SP3-Übungen).
- **mixed:** beide.

### Stufen (Schwierigkeits-Tiers)
Ab `startDifficulty` aufwärts bis `professional`:
z.B. Start `beginner` ⇒ `[beginner, intermediate, advanced, professional]`
(4 Stufen); Start `intermediate` ⇒ `[intermediate, advanced, professional]`.
Jede Stufe zieht ihre Übungen aus `programPoolExercises(pool)` gefiltert auf
`difficulty == stufe` (fällt eine Stufe leer aus, wird sie übersprungen).

### Generierter Programm-Tag
`buildAdaptiveProgramDay(config, poolByStage, stageIndex, dayNumber, cleanBpmFor)`
ersetzt `buildProgramDay`. Struktur bleibt (Warmup-Singles + Technik-Fokus +
Tempo-Leiter mit `cleanPassRequired`), aber die **Fokus-Übung** kommt aus der
**aktuellen Stufe** (rotierend nach Tag, damit Abwechslung entsteht), nicht aus
einer festen Phase. `programTotalDays` wird aus `durationWeeks × 7` abgeleitet.

### Reife-Gate (reine Funktion — der adaptive Kern)
```dart
bool isStageComplete(List<Rudiment> stageExercises, {
  required int? Function(String id) cleanBpmFor,
  required MasteryLevel? Function(String id) masteryFor,
});
```
Eine Stufe gilt als abgeschlossen, wenn ihre Fokus-Übung(en) das Zieltempo
sauber erreicht haben (`cleanBpmFor(id) >= targetBpm`) **oder** die Mastery
`proficient` erreicht hat (`bestBpm/targetBpm ≥ 0.85`, s. `bpm_progression_service.dart`).
Ist die Stufe abgeschlossen ⇒ `program_stage_index++` („Level up"). Der Check
läuft nach jedem Clean-Pass / Session-Save.

## Persistenz-Reuse
- Tempo-Fortschritt: vorhandene `CleanTempo` (sauberes Tempo je id) + die
  `recordCleanPass +4`-Leiter.
- Mastery/Bestwerte: vorhandene `RudimentProgress` (bestBpm/targetBpm →
  `mastery`), gespeist aus dem Practice-Feedback.
- Kein neues Isar-Schema nötig; nur die 4 neuen Prefs-Keys.

## UI

- **Setup-Screen** (`/program/setup`): drei Auswahlen — Zeitraum (4/8/12 Wochen),
  Startschwierigkeit (Beginner/Intermediate/Advanced), Pool (Klassische
  Schlagübungen / Neue Übungen / Gemischt) → `ProgramController.startWithConfig(config)`
  (schreibt Config + Startdatum + Stufe 0). Ersetzt den „Programm starten"-Knopf
  im `_NotStarted`-Zustand.
- **`_DayView`:** nutzt die Blöcke der aktuellen Stufe; Kopf zeigt Stufe/
  Schwierigkeit + Pacing („Woche X/N · Stufe: <difficulty> · voraus/im Plan/hinterher").
- **`_BlockCard` + Clean-Pass** bleiben; der Clean-Pass löst zusätzlich den
  Reife-Check aus → möglicher Stufen-Aufstieg mit sichtbarem „Level up"-Moment
  (Snackbar/Dialog).
- Das alte fixe Stick-Control-Programm entfällt als Pflicht-Weg; seine Phasen-
  Fokus-Texte können als generische Stufen-Hinweise wiederverwendet werden.
- Routing: `/program/setup` neben `/program`; Dashboard-Eintrag bleibt.

## Betroffene/neue Dateien

- `lib/features/program/models/program_config.dart` — NEU (`ProgramConfig`, `ProgramPool`).
- `lib/features/program/program_generator.dart` (oder erweitertes `program_provider.dart`)
  — `programPoolExercises`, Stufen-Ableitung, `buildAdaptiveProgramDay`, `isStageComplete`.
- `lib/data/local/settings_service.dart` — 4 neue Prefs-Keys + Config-Getter/Setter.
- `lib/features/program/program_provider.dart` — Provider auf Config/Stufe umstellen
  (`trainingProgram`/`currentProgramDay`/`ProgramController`), Reife-Aufstieg.
- `lib/features/program/program_setup_screen.dart` — NEU (Setup-UI).
- `lib/features/program/program_screen.dart` — `_NotStarted` → Setup; `_DayView`-Kopf
  (Stufe + Pacing); Level-up-Moment.
- `lib/app/router.dart` — Route `/program/setup`.
- `lib/features/lessons/rudiment_filter.dart` — ggf. Difficulty als Filterachse
  ergänzen (oder Pool-Filter separat halten).
- Tests: `program_config_test.dart`, `program_generator_test.dart` (Pool-Auswahl,
  Stufen, `buildAdaptiveProgramDay`, `isStageComplete` inkl. „bereit/nicht bereit"),
  `program_setup_screen_test.dart`. Bestehenden `program_generator_test.dart`
  anpassen/ersetzen.

## Teststrategie

- Reine Logik (Unit): `programPoolExercises` je Pool; Stufen-Ableitung ab jeder
  Startschwierigkeit (inkl. Überspringen leerer Stufen); `buildAdaptiveProgramDay`
  (Blöcke, Fokus-Rotation, Tempo aus Clean-Tempo); **`isStageComplete`** —
  bereit bei Tempo-Ziel/Mastery, nicht bereit sonst; Pacing-Berechnung
  (Woche X/N, voraus/hinterher).
- Widget: Setup-Screen (drei Auswahlen → Config gesetzt, Start ruft Controller);
  `_DayView` zeigt Stufe + Pacing.
- **Gerät (gebündelt):** Setup durchspielen, eine Stufe „mastern" → Aufstieg
  sichtbar; Pool-Wechsel prüfen.

## Nicht-Ziele (SP4)

- Kein neuer Übungs-Inhalt (nutzt SP3-Übungen + Basis-Katalog).
- Keine Mic-basierte Reife (Clean-Pass bleibt selbst-bewertet; Feld
  `cleanPassRequired` bleibt der Hebel für späteren Mic-Gate).
- Kein Multi-Programm-Management (eine aktive Config; Reset überschreibt).

## Migration / Rückwärtskompatibilität

- Ein bereits gestartetes Alt-Programm (nur `program_start_date`, keine Config)
  gilt als „nicht konfiguriert": beim Öffnen bekommt der User den Setup-Screen
  (Reset des Alt-Anlaufs). Da noch nichts ausgeliefert ist, kein Daten-Risiko.
- Der bestehende `program_generator_test.dart` wird auf das neue Modell
  umgeschrieben.
