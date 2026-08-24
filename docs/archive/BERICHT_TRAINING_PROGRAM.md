# BERICHT: Training Program „Stick Control – 12 Wochen"

> Status: **Implementiert.** Modelle + Seed + Generator + Streak-Integration +
> Screen gebaut, alle headless-DoD-Punkte grün. Offen: UI-Durchlauf am Gerät.
> Datum: 2026-07-07 · Branch: `feature/training-program-stick-control`
> (im Worktree als `worktree-training-program-stick-control`).

---

## 1 · §0-Antworten (was vorgefunden, welche Abweichungen abgebildet)

### §0.1 Repo & Toolchain → ✅ Blocker #1 aufgelöst
Flutter **3.44.4** / Dart **3.12.2** sind auf dem Host verfügbar
(`/home/uli/.local/bin`). `flutter pub get`, `dart run build_runner build` und
`flutter analyze` laufen im sauberen Worktree grün.

### §0.2 Modell-Abgleich → Spec-Werte abgebildet
Wie im vorigen Bericht dokumentiert weicht die reale Codebase von Spec §4/§9.1
ab. Getroffene, mit Uli bestätigte Abbildung:

- **Modellform (idiomatisch statt Spec §4-Isar-Links):** Die Codebase nutzt
  nirgends `IsarLinks`/`@embedded`/Init-Seeding — statische Katalogdaten liegen
  als In-Memory-`const` (`rudimentsSeedData`). Deshalb sind
  `TrainingProgram`/`ProgramPhase`/`ProgramDay`/`ExerciseBlock` **plain Value-
  Objekte** (`lib/features/program/models/training_program.dart`); das Programm
  ist ein `const` (`lib/features/program/data/stick_control_program.dart`); die
  84 Tage werden zur Laufzeit **generiert**, nicht gespeichert (Spec §5).
- **Persistenz:** Nur veränderlicher State ist in Isar — die neue kleine
  Collection **`CleanTempo { exerciseKey (unique), bpm }`** (das „letzte saubere
  Tempo") + das **Programm-Startdatum** als Scalar in `SettingsService`.
- **exerciseKey → bestehende IDs** (keine `sc_*`-Duplikate, Entscheidung Uli):
  `single_stroke_roll` / `double_stroke_roll` / `single_paradiddle`.
- **`Variant`-Enum:** Spec §5 nutzt `endurance` als Variante, §4 listet es
  nicht — ergänzt, damit Phase-4 `[even, endurance]` valide ist.

### §0.3 Generator → dedizierter Neu-Provider
`routine_provider.dart` (Spaced-Repetition-Tagesauswahl) bleibt **unangetastet**.
Der Programm-Generator ist neu: `lib/features/program/program_provider.dart`,
reine testbare Funktion `buildProgramDay(...)` + Provider `programDay`,
`currentProgramDay`, `trainingProgram`, `CleanTempoNotifier`, `ProgramController`.

### §0.4 Branch
`feature/training-program-stick-control` angelegt; Arbeit isoliert im Worktree.

---

## 2 · Erledigte DoD-Punkte (mit Proof)

| DoD (BRIEF §4) | Status | Proof |
|---|---|---|
| `flutter analyze` grün | ✅ | Nur 7 vorbestehende `buildQuery experimental`-Warnungen (repo-weit, auch in routine/practice/stats), **0 Fehler**. |
| Modelle + Isar-Codegen bauen | ✅ | `dart run build_runner build --delete-conflicting-outputs` → „Succeeded … with 48 outputs" (Runde 1) / „243 outputs" (Runde 2); `clean_tempo.g.dart` + `program_provider.g.dart` erzeugt. |
| Seed: die drei Rudiments + das Programm existieren | ✅ | `stickControlProgram` (4 Phasen) referenziert die 3 bestehenden IDs; Test „phases 1–3 use their fixed line" + „phase 4 rotates line". |
| Generator erzeugt **84** `ProgramDay`; dow 6 = `light`, dow 7 = `rest` | ✅ | Tests „expands exactly 84 days", „60 practice / 12 light / 12 rest", „dow 6 = light, dow 7 = rest for every week". |
| `rest`-Tage: leere Blockliste, zählen nicht gegen Streak | ✅ | Test „rest days have empty block list and 0 minutes"; Streak-Tests „a scheduled rest day does not consume the freeze …" (7 statt 3) + „a lone rest day today does not break the streak". |
| Tempo-Leiter-Start = gespeichertes sauberes Tempo (nicht 0) | ✅ | Test „ladder starts at stored clean tempo, not 0/default" (96) + „ladder starts at phase.startBpm when no clean tempo stored" (70). |
| Gate-Feld `cleanPassRequired` vorhanden, self-rating nicht hartcodiert | ✅ | Feld auf `ExerciseBlock`; Gate-Auswertung liegt im Screen (`_askCleanPass` → `recordCleanPass`), nicht im Modell → mic-ready. Test „every practice tempo ladder requires a clean pass". |

**Testlauf gesamt:** `flutter test` → **39 passed** (20 neu: 15 Generator + 5 Streak;
19 vorbestehend, nichts regressiert).

---

## 3 · Offene Punkte (Mensch)

1. **UI-Durchlauf am Gerät (nicht headless, BRIEF §4):** „Tag 1 → Tag 8 inkl.
   Ruhetag" in der laufenden App. Der Screen ist gebaut, aber **nicht am Gerät
   verifiziert** — auf diesem Host gibt es **kein Android SDK** und die App ist
   **nicht web-baubar** (Isar nutzt `dart:ffi`, nativ-only — betrifft auch die
   bestehenden Collections). Check bitte am Handel / über Cockpit.
2. **Optional:** Der „Sauber & locker?"-Gate ist als expliziter Button auf der
   Tempo-Leiter-Karte umgesetzt (nicht automatisch nach Session-Ende), weil kein
   Hook in den Practice-Abschluss existiert. Falls gewünscht, kann der Gate
   später an das Session-Ende gekoppelt werden.

---

## 4 · Commit-Range dieses Laufs

```
f1f4afe Add program screen, route, dashboard entry + target-BPM handoff
e20722a Make streak rest-day-aware so program rest days don't break it
c5d23c1 Add program generator provider + headless tests
33c34f2 Add training-program models, const curriculum, CleanTempo collection
```

## 5 · Geänderte / neue Dateien
- **Neu:** `lib/features/program/models/training_program.dart`,
  `lib/features/program/data/stick_control_program.dart`,
  `lib/features/program/program_provider.dart` (+ `.g.dart`),
  `lib/features/program/program_screen.dart`,
  `lib/data/local/models/clean_tempo.dart` (+ `.g.dart`),
  `test/features/program/program_generator_test.dart`,
  `test/features/stats/streak_rest_test.dart`.
- **Geändert:** `lib/data/local/isar_service.dart` (Schema),
  `lib/data/local/settings_service.dart` (programStartDate),
  `lib/features/stats/stats_provider.dart` (ruhetag-bewusster Streak),
  `lib/app/router.dart` (`/program`, `?bpm=`),
  `lib/features/practice/practice_session_screen.dart` (optionales `targetBpm`),
  `lib/features/dashboard/dashboard_screen.dart` (Programm-Karte).

Metronom-**Engine** wurde nicht angefasst (BRIEF §1 OUT OF SCOPE).
