# Trainingsraum Etappe 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Das Gerüst des Trainingsraums (Bereich + Stufe je Übung, Tempo-Leiter pro Runde, „sitzt“, Einheit aus Aufwärmen + Vertiefen, Erklärung auf Wunsch) ersetzt Programm und Tagesplan; alle vorhandenen Übungen werden eingeordnet; der erste neue Inhalt ist der Bereich **Hände-Technik** in Beginner + Intermediate.

**Architecture:** Neue Felder `area` (`TrainingArea`) und `songHint` am `Rudiment`; Katalog-Werkzeug schreibt sie. Reine Logik für Runden-Urteil, Tempo-Leiter, „sitzt“, Bereichs-Stufe und Einheitsplanung in `lib/features/room/`; der Übungsbildschirm bekommt einen Trainingsraum-Modus (`?room=1`), der Runden erkennt und das Tempo nach jeder Runde stellt. `features/program` und der Tagesplan werden entfernt; Fortschritt (`RudimentProgress`), Wiederholung (`SpacedRepetitionService`) und Messung (`analyzeStrokes`) werden weiterverwendet.

**Tech Stack:** Flutter (Linux-Desktop), Dart 3, Riverpod, Isar, go_router; Python 3 (tool/katalog, tool/stimme/Piper).

**Spec:** `docs/superpowers/specs/2026-10-31-trainingsraum-design.md` (Etappe 1 = Gerüst + Einordnung + Hände-Technik Beginner/Intermediate). Folge-Etappen: je ein Bereich Inhalt (Rudiments, Füße, Koordination, Groove, Metal, Fills) mit Kuration.

## Global Constraints

- Branch: neuer Branch `trainingsraum-etappe1` von `spec-trainingsraum` (gestapelt), eigener Draft-PR auf #37.
- Nur Linux-Desktop bauen und abnehmen; Handy-Layout darf nicht brechen. UI-Texte Englisch; Kurationsseiten Deutsch.
- „Das bisher Gebaute nicht komplett verwerfen“: Übungs-IDs bleiben, `RudimentProgress`-Zeilen bleiben gültig, Blätter/Lehrtexte/Messung/Wiederholung werden weiterverwendet.
- Tempo 40–240 BPM. Tempo-Leiter **+4 / 0 / −4 BPM** pro Runde; nie unter `minBpm` der Übung.
- „Sitzt“ = **zwei saubere Runden hintereinander im Ziel-Tempo** (`bpm >= targetBpm`).
- Stufe eines Bereichs geschafft ab **80 %** sitzender Übungen der Zelle.
- Erklärung (Text + Stimme) **nur auf Knopfdruck**, nie automatisch.
- Songnamen nur als Text („Like in: …“), keine Transkription, keine Logos.
- Generierte Dateien nie von Hand bearbeiten (Katalog-Werkzeug + `dart format` nur auf generierte Dateien). Isar-Codegen mit `dart run build_runner build`.
- Normale Übung ohne `?room=1` verhält sich wie heute (außer entfernten Programm-Hooks).

## Review Focus

1. **Übung ohne Messung** (Set-Übungen vor Etappe 2 B.3, Fuß-Stimmen am Pad): kein Absturz, Tempo-Leiter über die drei Knöpfe am Ende. → Task 4.
2. **Runde mit zu schwachem Signal / zu wenigen Schlägen**: Urteil „close“ (Tempo bleibt), nie „off“. → Task 3.
3. **Bestehende Nutzerdaten**: gespeicherte Programm-Einstellungen in SharedPreferences und `CleanTempo`-Zeilen in Isar führen nach dem Update nicht zum Absturz; alter Fortschritt erscheint im Trainingsraum. → Task 6.
4. **Bereich ohne Inhalt in der eigenen Stufe** (z. B. Advanced, noch nicht gebaut) und **leerer Bereich**: Rückfall auf die höchste vorhandene Stufe; leere Bereiche werden nicht vorgeschlagen. → Task 5.
5. **Tempo von Hand ändern mitten in der Runde**: die laufende Runde zählt nicht für „sitzt“, die Leiter rechnet ab dem neuen Tempo weiter. → Task 4.

---

### Task 1: Bereich und Songhinweis im Modell und im Katalog-Werkzeug

**Files:**
- Modify: `lib/features/lessons/models/rudiment.dart` (Feld + Konstruktor + `withSticking`)
- Create: `lib/features/room/training_area.dart`
- Modify: `tool/katalog/blatt.py` (`Sheet.area`, `Sheet.song`), `tool/katalog/patch_seed.py` (`_entry` schreibt `area:`/`songHint:`; vorhandene IDs: `area:`/`songHint:` ergänzen bzw. ersetzen), `tool/katalog/gefuehrt_blatt.py` nur falls nötig
- Modify: `lib/features/lessons/rudiment_filter.dart` + `lessons_screen.dart` (neue Filterachse „Area“)
- Test: `test/lessons/rudiment_model_test.dart`, `test/lessons/rudiment_filter_test.dart`, `tool/katalog/test_kit.py` (oder neue `test_area.py`)

**Interfaces:**
- Produces: `enum TrainingArea { handTechnique('Hand technique'), rudiments('Rudiments'), feet('Feet'), coordination('Coordination'), groove('Grooves'), metal('Metal'), fills('Fills') }` mit `final String label`.
- Produces: `Rudiment.area` (`TrainingArea?`, Standard `null`), `Rudiment.songHint` (`String?`); beide in `withSticking` übernommen.
- Produces (Python): `Sheet.area: str | None = None` (Werte = Dart-Enum-Namen), `Sheet.song: str | None = None`; Prüfung: unbekannter Bereich → ValueError.
- Produces: `RudimentFilters.areas` (`Set<TrainingArea>`), gleiche Logik (ODER innerhalb, UND zwischen Achsen).

- [ ] **Step 1: Failing tests:** `withSticking keeps area and songHint`, `filter by area`, Python `test_unknown_area_rejected`, `test_patch_seed_writes_area`.
- [ ] **Step 2:** → FAIL. **Step 3:** umsetzen. **Step 4:** `flutter test test/lessons` + `python3 -m pytest tool/katalog -q` (venv-Python aus `spec-gefuehrte-uebungen/tool/stimme/.venv`, falls System-Python kein pytest hat) → PASS.
- [ ] **Step 5: Commit** `feat(raum): Bereich und Songhinweis je Übung, Filter in der Bibliothek`

### Task 2: Alle vorhandenen Übungen einordnen

**Files:**
- Modify: `tool/katalog/rudimente.py`, `fills.py`, `grooves.py`, `set_fills.py`, `feet.py`, `set_more.py` (je Blatt `area=`), dann `gen_dart.py` + `patch_seed.py` laufen lassen
- Modify: `lib/features/lessons/data/rudiments_seed.dart` (die 32 handgeschriebenen Einträge bekommen `area:` von Hand — sie sind nicht generiert), `lib/features/lessons/data/etudes.dart` bzw. Étüden-Liste (Bereich je Sammlung)
- Test: `test/lessons/seed_integrity_test.dart`

**Interfaces:**
- Consumes: Task 1.
- Produces: jede Übung in `rudimentsProvider` hat `area != null`. Zuordnung: Rudiment-Blätter → `rudiments`; Pad-/Set-Fills → `fills` (`set_fill_double_bass` → `fills`); `feet_*` → `feet` außer `feet_ostinatos` → `coordination`; `groove_*` → `groove`, außer `groove_linear`, `groove_kick_sixteenths` → `coordination`; handgeschriebene Technik-Einträge (Akzente, Ghost Notes, Dynamik, Möller, Doppelschlag, Speed, Ausdauer, Gleichmäßigkeit, Timing, eight_on_a_hand) → `handTechnique`; handgeschriebene Rudiments (Flam-/Drag-/Roll-Varianten, cheese, flamacue, lesson_25 …) → `rudiments`; Linear-Beats und ghost_note_groove → `coordination`; Étüden → Bereich ihrer Sammlung (`rudimentEtudes` → `rudiments`, `techniqueStudies`/`padWorkouts` → `handTechnique`). Schwierigkeiten bleiben unverändert.
- Produces: Kuration der Zuordnung: `python3 tool/katalog/build_page.py` ist dafür nicht nötig — stattdessen eine kurze Tabelle im Bericht (Task 9).

- [ ] **Step 1: Failing test:** `every exercise has an area` (über `rudimentsSeedData` + `allEtudes`), `area counts per cell are reported` (druckt nichts, prüft nur, dass `handTechnique`, `rudiments`, `feet`, `coordination`, `groove`, `fills` je mindestens eine Beginner- oder Intermediate-Übung haben).
- [ ] **Step 2:** → FAIL. **Step 3:** einordnen, generieren. **Step 4:** `flutter test test/lessons` → PASS.
- [ ] **Step 5: Commit** `feat(raum): alle vorhandenen Übungen einem Bereich zugeordnet`

### Task 3: Runden-Urteil, Tempo-Leiter, „sitzt“ (rein)

**Files:**
- Create: `lib/features/room/round_verdict.dart`, `lib/features/room/tempo_ladder.dart`
- Test: `test/room/round_verdict_test.dart`, `test/room/tempo_ladder_test.dart`

**Interfaces:**
- Consumes: `SessionAnalysis` (`coaching/models/session_analysis.dart`: `alignment.hitRate`, `alignment.extraRate`, `unassigned.timingMedianMs`, `unassigned.timingSpreadMs`, `signalTooWeak`, `notMeasurable`, `hasData`).
- Produces: `enum RoundVerdict { clean, close, off }`.
- Produces: `RoundVerdict? verdictOf(SessionAnalysis? a)` — `null` wenn nicht messbar (`a == null || a.notMeasurable`); `close` wenn `signalTooWeak || !a.hasData`; sonst `clean` bei `hitRate >= 0.95 && extraRate <= 0.05 && |timingMedianMs| <= 15 && timingSpreadMs <= 20`; `off` bei `hitRate < 0.80 || timingSpreadMs > 40`; sonst `close`. (Schwellen angelehnt an `core_values.dart`; als `const` oben in der Datei.)
- Produces: `RoundVerdict verdictOfRating(int rating)` — 3 → clean, 2 → close, 1 → off.
- Produces: `int nextLadderBpm(int bpm, RoundVerdict v, {required int minBpm})` — clean +4, close 0, off −4; Ergebnis `clamp(max(minBpm, 40), 240)`.
- Produces: `class LadderRound { final int bpm; final RoundVerdict verdict; }` und `bool sitsAt(List<LadderRound> rounds, int targetBpm)` — wahr, wenn die letzten zwei Runden beide `clean` und beide `bpm >= targetBpm`.

- [ ] **Step 1: Failing tests** (alle Schwellenränder): `clean at 0.95 hit rate and 15 ms`, `close when signal too weak`, `null when not measurable`, `off below 0.80 hit rate`, `ladder +4/0/-4`, `ladder never below minBpm nor 40`, `ladder never above 240`, `sits after two clean rounds at target`, `does not sit when one of the two is below target`, `does not sit after clean-close-clean`.
- [ ] **Step 2:** → FAIL. **Step 3:** umsetzen. **Step 4:** → PASS.
- [ ] **Step 5: Commit** `feat(raum): Runden-Urteil, Tempo-Leiter und „sitzt“`

### Task 4: Trainingsraum-Modus im Übungsbildschirm

**Files:**
- Create: `lib/features/room/round_tracker.dart` (rein: Runden-Grenzen aus dem Takt-Strom)
- Create: `lib/features/room/room_progress_service.dart`
- Modify: `lib/features/practice/practice_session_screen.dart` (Modus `room`), `lib/app/router.dart` (`/practice/:id?room=1`), `lib/features/practice/practice_provider.dart` (Speichern über den neuen Dienst im Raum-Modus)
- Modify: `lib/features/practice/widgets/result_sheet.dart` nur falls nötig (drei Knöpfe bleiben)
- Test: `test/room/round_tracker_test.dart`, `test/room/room_progress_service_test.dart`, `test/features/practice/practice_session_screen_test.dart` (neue Raum-Fälle)

**Interfaces:**
- Consumes: Task 3; `SheetPlan` (`totalTicks`, `beats`), `BeatEvent(beatIndex, plannedAt)` aus `beatStream`, `analyzeStrokes(...)`, `RudimentProgress`, `SpacedRepetitionService.updateAfterSession`.
- Produces: `class RoundTracker { RoundTracker({required int beatsPerRound}); int? onBeat(int beatIndex); void reset(); }` — liefert die Nummer der gerade beendeten Runde, wenn `beatIndex` die Grenze überschreitet; `reset()` bei Tempowechsel von Hand (Review Focus 5: die angebrochene Runde zählt nicht).
- Produces: `class RoomProgressService { const RoomProgressService(); RudimentProgress applyRounds(RudimentProgress p, List<LadderRound> rounds, {required int targetBpm, required int minBpm}); }` — `currentBpm` = Tempo nach der letzten Runde (über `nextLadderBpm`), `bestBpm` = höchstes Tempo einer `clean`-Runde, `mastery = mastered` wenn `sitsAt(rounds, targetBpm)` (sonst wie bisher aus `bestBpm/targetBpm`), Wiederholung über `SpacedRepetitionService.updateAfterSession(p, rating)` mit `rating = 3` bei „sitzt“, `2` sonst, `1` wenn die letzte Runde `off`.
- Produces: Raum-Modus im Bildschirm (`room: true` aus `?room=1`): Runde = einmal durch alle gewählten Zeilen (`beatsPerRound` aus `_plan`); am Rundenende Urteil aus `analyzeStrokes` über das Fenster dieser Runde (Ereignisse + Beat-Log seit Rundenbeginn), dann `setBpm(nextLadderBpm(...))` und ein kurzer Hinweis-Chip (`Key('room-round-chip')`, Texte `Clean · +4`, `Hold`, `Slower · −4`). Ohne Messung: kein Urteil pro Runde; am Ende fragt das Ergebnisblatt wie heute 1/2/3, daraus `verdictOfRating` für eine Runde. „Sitzt“ erreicht → Chip `Nailed it` und Ergebnisblatt zeigt es. Knopf „How to play“ (`Key('room-how-to')`) öffnet ein Blatt mit den `technique`-Abschnitten und, wenn ein Clip `h_<id>` im Manifest steht, einem Abspielknopf (Wiedergabe über `loadVoiceClip` + vorhandene SoLoud-Wiedergabe). Nie automatisch.
- Entfernt hier: `_askCleanPass`, `cleanTempoNotifierProvider`, `programControllerProvider.advanceStageIfReady`, `isLadder`/Zeit-Leiter-Pfad (`ladder_plan.dart` bleibt nur, wenn noch genutzt; sonst löschen mit Test).

- [ ] **Step 1: Failing tests:** `tracker reports round end at beatsPerRound`, `tracker reset drops the started round`, `applyRounds sets mastered after two clean rounds at target`, `applyRounds keeps old rows valid` (vorhandene Zeile mit +5-Historie), Bildschirm: `room mode raises tempo by 4 after a clean measured round` (Fake-Messquelle), `room mode keeps tempo when signal too weak`, `room mode without measurement asks rating at the end and stores one round`, `manual tempo change mid-round does not count the round`, `how to play never opens by itself`, `normal mode has no round chip`.
- [ ] **Step 2:** → FAIL. **Step 3:** umsetzen. **Step 4:** `flutter test test/room test/features/practice` → PASS; Goldens des Übungsbildschirms nur neu, wenn sich der Normalmodus nicht ändert (sonst begründen).
- [ ] **Step 5: Commit** `feat(raum): Tempo-Leiter pro Runde im Übungsbildschirm, Erklärung auf Wunsch`

### Task 5: Stufe je Bereich und Einheitsplanung (rein)

**Files:**
- Create: `lib/features/room/area_level.dart`, `lib/features/room/session_planner.dart`
- Test: `test/room/area_level_test.dart`, `test/room/session_planner_test.dart`

**Interfaces:**
- Consumes: `Rudiment` (`area`, `difficulty`), `RudimentProgress` (`mastery`, `nextReviewDate`, `lastPracticed`).
- Produces: `Difficulty areaLevel(TrainingArea area, List<Rudiment> catalog, Map<String, RudimentProgress> progress)` — niedrigste Stufe des Bereichs, in der < 80 % der Übungen `mastered` sind; gibt es in einer Stufe keine Übungen, wird sie übersprungen; sind alle geschafft, die höchste vorhandene.
- Produces: `class RoomSession { final List<String> warmup; final TrainingArea area; final List<String> deepen; }` und `RoomSession planSession({required List<Rudiment> catalog, required Map<String, RudimentProgress> progress, required DateTime now, TrainingArea? chosen})`:
  - **Aufwärmen:** je eine Übung aus `handTechnique`, `rudiments`, `feet`, jeweils aus `areaLevel` des Bereichs (fällt ein Bereich leer aus: weglassen); bevorzugt schon gespielte, nicht fällige Übungen; höchstens 3.
  - **Bereich:** `chosen`, sonst der Bereich mit fälligen Wiederholungen (`nextReviewDate <= now`), sonst der am längsten nicht gespielte (`max lastPracticed` je Bereich, nie gespielt = am längsten); leere Bereiche nie.
  - **Vertiefen:** fällige Wiederholungen des Bereichs zuerst, dann die nächste nicht `mastered` Übung der Bereichsstufe (nach `difficulty`, dann Katalog-Reihenfolge), insgesamt höchstens 5.
- [ ] **Step 1: Failing tests:** `level is beginner while less than 80 % mastered`, `level skips empty levels`, `warmup takes one from hands, rudiments, feet`, `warmup omits an empty area`, `area with due reviews wins`, `never-played area counts as longest`, `chosen area overrides`, `empty area is never suggested`, `deepen lists due reviews first, max 5`, `advanced player falls back to highest available level` (Review Focus 4).
- [ ] **Step 2:** → FAIL. **Step 3:** umsetzen. **Step 4:** → PASS.
- [ ] **Step 5: Commit** `feat(raum): Stufe je Bereich und Planung der Einheit`

### Task 6: Programm und Tagesplan ersetzen

**Files:**
- Create: `lib/features/room/room_screen.dart`, `lib/features/room/room_provider.dart`
- Modify: `lib/features/today/next_step.dart`, `next_step_provider.dart`, `today_screen.dart`; `lib/app/router.dart`; `lib/features/stats/stats_provider.dart`; `lib/data/local/settings_service.dart`; `lib/data/local/isar_service.dart`
- Delete: `lib/features/program/` (ganz), `lib/features/learning/routine_provider.dart`(+`.g.dart`), `daily_routine_screen.dart`, `models/daily_routine.dart`, zugehörige Tests (`test/features/program/*`, `test/data/settings_program_config_test.dart`, `test/learning/new_rudiment_pick_test.dart`); `test/features/stats/streak_rest_test.dart` auf die neue Streak-Signatur umschreiben
- Test: `test/room/room_screen_test.dart`, `test/features/today/next_step_test.dart`, `test/features/today/today_screen_test.dart`, `test/app/router_test.dart`

**Interfaces:**
- Consumes: Task 4 (`/practice/:id?room=1`), Task 5 (`planSession`).
- Produces: Route `/room` (`RoomScreen`, `parentNavigatorKey: _rootNavigatorKey`): oben „Warm-up“ (Liste, je Eintrag Start), darunter „Today's focus: <Area>“ mit Bereichswahl (Chips aller nicht leeren Bereiche, Vorschlag markiert) und die Vertiefen-Liste; Start öffnet `/practice/<id>?lines=all&bpm=<currentBpm oder minBpm>&room=1`; Aufwärm-Übungen ohne `room=1` (keine Leiter, Spec 4.2).
- Produces: `PathStep` „Continue“ auf Heute = `route: '/room'`, Titel `Today's session`, Detail „Warm-up + <Area>“, Minuten `30`. `PathStepKind.setup/restDay/dayDone/programComplete` entfallen.
- Produces: `computeStreak`/`computeLongestStreak` ohne Ruhetags-Parameter.
- Altdaten: Programm-Schlüssel in SharedPreferences werden ignoriert und beim Start einmal gelöscht (`SettingsService.clearLegacyProgramKeys()`); `CleanTempoSchema` bleibt in `Isar.open` registriert (Daten bleiben, ungenutzt) — kein Löschen der Isar-Collection.
- [ ] **Step 1: Failing tests:** `today continue opens /room`, `room screen shows warm-up and focus`, `choosing an area replans deepen`, `start opens practice in room mode`, `warm-up start opens practice without room mode`, `legacy program prefs do not crash and are cleared` (Review Focus 3), `streak without rest days`, Router: `/program` und `/routine` gibt es nicht mehr.
- [ ] **Step 2:** → FAIL. **Step 3:** umsetzen, Altes löschen. **Step 4:** volles `flutter test` + `flutter analyze` → grün, keine toten Importe.
- [ ] **Step 5: Commit** `feat(raum): Trainingsraum ersetzt Programm und Tagesplan`

### Task 7: Inhalt Hände-Technik Beginner + Intermediate

**Files:**
- Create: `tool/katalog/technik.py` (neuer Satz, in `katalog.py` registrieren, `area='handTechnique'`)
- Regenerate: `lib/features/lessons/data/sheets/*_sheet.dart`, `rudiments_seed.dart` (über `patch_seed.py`)
- Test: `tool/katalog/test_technik.py`, `test/lessons/seed_integrity_test.dart`

**Interfaces:**
- Consumes: Task 1/2 (Felder, Generatoren).
- Produces: **10 neue Pad-Blätter**, je 8 Zeilen à 4 Takte (Teil-1-Form: Zeilen ausgeschrieben, Steigerung in der Zeile), mit Lehrtext (Why / How / Tips / Song examples, englisch), `minBpm`/`targetBpm`:
  - Beginner (5): Grip & Rebound (Viertel/Achtel, lockerer Rückprall), Full Stroke & Tap (laut/leise im Wechsel), Even Singles (gleichmäßige Achtel/16tel), Accent Basics (Akzente auf den Zählzeiten), Single-Hand Control (eine Hand allein, dann wechseln).
  - Intermediate (5): Down & Up Strokes (Akzent-Vorbereitung), Moving Accents (wandernde Akzente in 16teln), Doubles Control (Doppelschläge gleichmäßig, offen → geschlossen), Ghost & Accent Contrast (Ghost Notes gegen Akzente), Speed Bursts (kurze schnelle Gruppen, dann Pause).
  - Vorhandene handgeschriebene Technik-Einträge mit gleichem Inhalt werden **nicht** gelöscht; doppelte Themen sind erlaubt, die neuen Blätter sind die Trainingsraum-Hauptübungen der Zelle.
- Produces: Kurationsseite `~/raum-kuration-haende-technik.html` (`build_page.py` mit Satz `technik`).
- [ ] **Step 1: Failing tests:** `technik set has 5 beginner and 5 intermediate sheets`, `every technik sheet has area handTechnique, 8 lines of 4 bars, a lesson with Why/How/Tips`, Dart `seed contains the 10 technik sheets with area handTechnique`.
- [ ] **Step 2:** → FAIL. **Step 3:** schreiben, generieren. **Step 4:** Python + Flutter-Tests → PASS.
- [ ] **Step 5:** Kurationsseite bauen; dem Controller melden (er veröffentlicht sie für Uli).
- [ ] **Step 6: Commit** `feat(raum): Hände-Technik Beginner und Intermediate – zehn neue Übungen`

### Task 8: Erklärung als Stimme für die Hände-Technik

**Files:**
- Create: `tool/stimme/saetze_raum.py` (generiert: `h_<id>` → How-Abschnitt), Generator-Schritt in `tool/katalog/gen_dart.py` oder eigenes `gen_raum_voice.py`
- Modify: `tool/stimme/saetze.py` (`SAETZE.update(RAUM)`)
- Regenerate: `assets/voice/h_*.wav`, `manifest.json`
- Test: `tool/stimme/test_render_clips.py` (Satz vorhanden), `test/room/how_to_voice_test.dart` (Manifest enthält `h_<id>` für die 10 Technik-Blätter)

**Interfaces:**
- Consumes: Task 4 (Abspielknopf sucht `h_<id>`), Task 7 (Blätter).
- Produces: je Technik-Blatt ein Clip `h_<id>` mit dem „How“-Text (≤ 40 Wörter; längere Texte für die Stimme kürzen, der Text auf dem Bildschirm bleibt voll). Rendern mit der vorhandenen Stimme `en_GB-cori-high` (`render_clips.py --only h_…`).
- [ ] **Step 1–4:** Tests rot → Generator + Render → grün.
- [ ] **Step 5: Commit** `feat(raum): Erklärung als Stimme für die Hände-Technik`

### Task 9: Lieferung

- [ ] **Step 1:** volles `flutter test` + `flutter analyze` auf dem NUC; Push; Draft-PR `trainingsraum-etappe1` auf `spec-trainingsraum`.
- [ ] **Step 2:** PC: Worktree `~/drum-coach-trainingsraum` auf den neuen Branch umstellen, `flutter build linux --release`, laufende App mit `pkill -x drum_coach` beenden, starten (DISPLAY=:0); `~/.no-idle-suspend` vor dem Bauen setzen, danach löschen.
- [ ] **Step 3:** Bericht `docs/BERICHT_RAUM_ETAPPE1.md`: was gebaut, Tabelle der Bereichs-Zuordnung (Anzahl je Bereich × Stufe), Kurationsseite, offene Punkte (Messung am Set erst mit B.3, Zellen ohne Inhalt bis zu den Folge-Etappen). Commit, Push.
