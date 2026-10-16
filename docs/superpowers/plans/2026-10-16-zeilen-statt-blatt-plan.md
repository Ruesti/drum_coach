# Zeilen statt Blatt — Zeilenliste, Zeilenfolge, Challenge weg, Linux-Lieferung

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Üben heißt eine Zeile oder eine Folge von Zeilen: Die Challenge-Zeile verschwindet aus allen Blättern, der Übungs-Screen zeigt nur noch die aktuelle Zeile groß und spielt Folgen (jede Zeile n-mal, dann die nächste, Rundlauf bis Stopp), eine neue Zeilenliste je Übung ersetzt das Blatt auf der Info-Seite, und der Linux-Client wird auf dem Laptop gebaut und geliefert.

**Architecture:** Eine Folge ist **eine** Schleife wie bisher das ganze Blatt: `SheetPlan.sequence` hängt jede gewählte Zeile `repeats`-mal hintereinander, die Engine spielt das als einen Loop (kein Umbau, kein Klick-Aussetzer an Zeilengrenzen); `locate`/`locateTick` liefern dazu den Slot, aus dem Kopfzeile und Ein-Zeilen-Ansicht die aktuelle Zeile und den Durchgang ablesen. Vor/Zurück in einer Folge dreht den Startpunkt (`start`) und lädt die Einheit neu (bestehende `_applyUnitChange`-Mechanik, Neustart auf der „1"). Die Zeilenliste rendert jede Zeile mit dem vorhandenen `SheetStaffWidget` (neuer Parameter `onlyLine`).

**Tech Stack:** Flutter 3.44 / Dart 3, Riverpod, go_router, shared_preferences, Bravura; Python 3.13 (Katalog-Werkzeug).

**Spec:** `docs/superpowers/specs/2026-10-16-zeilen-statt-blatt-design.md` (der Controller legt sie dort ab; Quelle: `$CLAUDE_JOB_DIR/tmp/2026-10-16-zeilen-statt-blatt-design.md`), freigegeben 16.10. 18:26. Ulis Antworten auf §6: Challenge überall raus (Pad und Set); Folge = jede gewählte Zeile 2×, dann die nächste, die ganze Folge wiederholt bis Stopp, Anzahl in den Einstellungen änderbar; Desktop = nur Linux.

**Branch:** `worktree-etappe2-phase-b` (Worktree `/home/uli/projects/drum_coach/.claude/worktrees/etappe2-phase-b`).

**Voraussetzung:** Die Abend-Fixes vom 16.10. (Zählsilben weg bei Set, Buchstaben nur bei Hand-/Fußwechsel, Zeilen unterscheiden sich, Backing bei Set-Übungen — derzeit uncommittete Änderungen in `practice_session_screen.dart`, `kit_layout.dart`, `kit_staff_painting.dart`, `loop_voices.dart`, `metronome_*`, `kit_backing.dart`, `tool/katalog/{blatt,feet,grooves,set_more}.py`) sind committet, der Baum ist sauber. Die Zeilenangaben unten stammen von `HEAD` = `5575e9a`; nach diesen Fixes können sie wandern — im Zweifel nach dem genannten Symbol suchen.

**Baseline:** `flutter test` 643 + 1 skipped (vor den Abend-Fixes; der Controller nennt die Zahl nach den Fixes), `flutter analyze` 13 bestehende Meldungen, `cd tool/katalog && python3 -m unittest -q` grün.

## Ist-Zustand (HEAD 5575e9a)

- **Katalog:** `tool/katalog/blatt.py:25` Feld `Sheet.challenge`, `:50` `parsed()` hängt sie an (`repeat=False, title='Challenge'`), `:57-58` Prüfung 8 Takte; Hilfsfunktionen `fills.py:36` `challenge()`, `set_fills.py:191` `challenge()`, `set_more.py:15` Import davon, `:156-170` `feet_fill(challenge_lines=…)`, `:270-293` `_check_linear` mit `i < 8`/`{3, 7}`; `challenge=`-Argumente in `rudimente.py` (12 mehrzeilige Blöcke ab `:29`), `fills.py` (8, ab `:165`), `grooves.py` (7, ab `:210`), `feet.py` (7, ab `:185`), `set_fills.py:218,358`, `set_more.py:236,246,264`; Texte `katalog.py:35`, `gen_dart.py:58`, Modul-Docstrings, `README.md` (Zeile `blatt.py`); `test_kit.py:261`. `build_page.py` hat keine Challenge-Sonderlogik (rendert `parsed()`), Lektionstexte nennen „the Challenge" nirgends (grep: nur Code/Docstrings).
- **Dart-Inhalt:** 48 generierte `lib/features/lessons/data/sheets/*_sheet.dart` (alle aus dem Katalog, je 9 Zeilen), `rudiments_seed.dart` (48 × `lines:`). Integritätstests: `test/lessons/etudes_integrity_test.dart:64-160` (9 Zeilen, `last.title == 'Challenge'`, 24/40 Takte), `test/lessons/kit_seed_integrity_test.dart:63,67-84,121-122,141-142,168-172,207-228` (dito, `SheetPlan.wholeSheet`), `test/lessons/lessons_screen_meta_test.dart:13,22,24` („9 lines · 24 bars"), `test/features/practice/practice_session_screen_test.dart:279-347` („Line n / 9", „Sheet · 24 bars", `24 * 96`). Goldens mit Challenge-Reihe: `test/goldens/kit_sheet_groove_rock8.png`, `kit_sheet_feet_double_bass_eighths.png` (`test/notation_kit_goldens_test.dart:48-80`). `sheet_staff_three_lines.png` und `kit_staff_sheet.png` kommen aus Test-Fixtures (Titel „Challenge" dort ist nur ein Titel-Beispiel) → bleiben.
- **Alte Étüden** (`lib/features/lessons/data/etudes/`, `etudes.dart`, `etude_dsl.dart`): `Rudiment`s **ohne** `lines` (Einzeilen-Blätter aus `sticking`); „Challenge:" steht nur im Beschreibungstext der fünften Étüde je Gruppe. **Nichts zu tun** — keine Challenge-Zeile, kein Blatt. Sie laufen weiter als Ein-Zeilen-Übungen direkt in den Übungs-Screen.
- **Plan-Modell:** `lib/features/lessons/models/sheet_plan.dart:37-50` `SheetPlan.line`, `:53-105` `SheetPlan.wholeSheet` (Stimmen je Instrument verkettet, fehlende mit Pausen), `:120-136` `locate`/`locateTick`, `:166` `sheetBars`. Nutzer von `wholeSheet`: Übungs-Screen `:273-275`, `kit_seed_integrity_test.dart:63,172`, `sheet_plan_test.dart`.
- **Übungs-Screen** `lib/features/practice/practice_session_screen.dart`: Parameter `line`/`mode` `:85-89`, `initialSheetPosition` `:110-127`, Zustand `_lineIndex/_sheetMode/_plan` `:260-262`, `_buildUnit` `:271-281`, `_applyUnitChange` `:286-303` (merkt `setSheetPosition(line:, sheet:)`), `_selectLine`/`_setSheetMode` `:331-344`, `initState` `:360-389` (Snapshot mit `line`/`sheet`), `didChangeAppLifecycleState` `:435-447`, Optionen „About" → `LessonDetailScreen(onLineTap:)` `:760-778`, Sitzungs-Log `sheetLine/sheetMode` `:987-988`, Cursor `loc`/`tickLoc` `:1124-1136`, `SheetWindow` `:1250-1266`, `_LineBar` `:1268-1281` und Klasse `:1388-1460`. `SheetWindow`: `lib/features/practice/widgets/sheet_window.dart` (ganzes File), Test `test/features/practice/sheet_window_test.dart`.
- **Einstellungen:** `lib/data/local/settings_service.dart:196-206` `sheetPositionFor`/`setSheetPosition` (Schlüssel `sheet_line_<id>`, `sheet_mode_<id>`), `:212-260` Snapshot (`practice_snap_line`, `practice_snap_sheet`); Test `test/data/settings_sheet_test.dart`. Einstellungs-Screen `lib/features/settings/settings_screen.dart:100-140` (Abschnitte, `_TargetRow`-Chips `:388-409`).
- **Routen** `lib/app/router.dart:91-100` (`/routine/:rudimentId`, `line`/`mode`), `:139-152` (`/practice/:rudimentId`, bpm/min/ladder/ctx/phase/line/mode), `/library/:id` = Info-Seite `:66-72`.
- **Einstiege:** Bibliothek `lib/features/lessons/lessons_screen.dart:228-275` (`_RudimentTile`, ⓘ → `/library/:id`, Tap → `/practice/:id?bpm=`), Sammlung `collection_screen.dart:85-106` (`_EtudeTile`, nur Étüden → Einzeiler), Info-Seite `lesson_detail_screen.dart:13-95` (PATTERN nur bei `lines.isNotEmpty` `:51-56`, THE SHEET `:57-66`, Legende `:68`, LESSON, „Start Practice" `:80-90`; `_MetaRow` `:109-143`), Heute `features/today/next_step.dart:51` (Routine) und `:104` (`practiceRouteFor`), `features/program/practice_route.dart:8-16`, Programm `program_screen.dart:451`, Routine `features/learning/daily_routine_screen.dart:48`.
- **Desktop:** `lib/app/platform_support.dart` (`capContentWidth` 900 px global über `main.dart:50`), `practice_shortcuts.dart` (Leertaste/±/Esc). Linux-Bundle muss auf dem **Laptop** gebaut werden (glibc 2.35 dort vs. 2.41 auf dem NUC), Checkout `~/agent-test-checkouts/drum_coach-etappe2-phase-b`, Flutter unter `~/development/flutter/bin`.
- **Engine-Grenze:** Der Loop wird als ganzes WAV gerendert (`metronome_engine.dart:222` `buildLoopWav`), Backing fällt über `maxBackingCycleBars = 64` weg (`loop_voices.dart:7`). Eine Folge darf deshalb höchstens 64 Takte lang sein (8 Fill-Zeilen × 4 Takte × 2 = genau 64 → der Standard passt immer).

## Global Constraints

- Tests zuerst (jede Aufgabe: roter Test → Code → grün).
- `flutter analyze`: keine neuen Meldungen (13 bestehende).
- `flutter test` vollständig grün nach jeder Aufgabe; `cd tool/katalog && python3 -m unittest -q` grün.
- Generierte Dart-Dateien (`lib/features/lessons/data/sheets/*`, `rudiments_seed.dart`-Einträge, `*.g.dart`) nie von Hand ändern — Python-Quelle ändern und neu generieren. Keine Isar-Schemaänderung (kein `build_runner`).
- `dart format` nur auf berührte und generierte Dateien (der Repo-Baum passt nicht überall zum installierten Formatter).
- Pad-Goldens ändern sich nur, wo die Challenge-Reihe verschwindet; neue Goldens nur für Zeilenliste und Ein-Zeilen-Ansicht. Nach jedem `--update-goldens` mit `git status` prüfen, dass kein anderes PNG geändert ist.
- UI-Texte Englisch (exakte Strings in den Aufgaben), Commit-Nachrichten und Doku Deutsch wie im Repo; Commit-Abschluss mit den Attributionszeilen aus der Sitzung.
- Jedes Blatt: 8 Zeilen; Rudiment/Groove/Fuß 2 Takte je Zeile = 16 Takte, Fill 4 Takte = 32 Takte.
- Folge: Standard 2 Wiederholungen je Zeile, einstellbar 1–4; Folge ≤ 64 Takte (`maxSequenceBars`), sonst werden die Wiederholungen bis zur Grenze verringert (mindestens 1).
- Heute/Routine/Programm planen weiter ganze Übungen; Fortschritt bleibt pro Übung (`RudimentProgress`); kein Fortschritt pro Zeile.
- Tastenkürzel unverändert (Leertaste, ↑/↓/±, Esc).

## Review Focus

1. **Lange Folge über 64 Takte** (8 Fill-Zeilen bei Einstellung 3× oder 4×): Wiederholungen sinken auf 2, die Kopfzeile zeigt die echte Zahl („· 1/2"), Backing bleibt an. Tests: Task 2 (`sequence caps repeats at 64 bars`), Task 3 (Kopfzeile).
2. **Vor/Zurück während eine Folge läuft:** Neustart auf der gewählten Zeile an ihrer „1", keine alten Ticks (der bestehende Stale-Tick-Mechanismus), › auf dem letzten Schritt springt auf den ersten. Test: Task 3 (`› in a running sequence wraps and reloads`).
3. **Ein-Zeilen-Übung mit `lines=all`** (Étüde/Legacy aus Heute oder Routine): spielt als Einzelzeile, keine Navigationsleiste, kein „Sequence". Test: Task 3.
4. **Unterbrochene Sitzung (Anruf) mitten in einer Folge:** Wiederaufnahme mit derselben Auswahl und demselben Startpunkt; ein Snapshot im alten Format (`practice_snap_line`) nimmt die Zeile wieder auf. Test: Task 3 (`settings_sheet_test`).
5. **Kaputte Routenparameter** (`?lines=0,abc,99`, `?lines=3,3`, `?lines=`, `?line=40`, `?mode=sheet`): nie ein Fehler, Rückfall wie beschrieben, `mode` wird ignoriert. Test: Task 3 (`initialLineSelection`).

---

## Dateistruktur

**Neu:**
- `lib/features/practice/line_selection.dart` — reine Funktionen: Routenparameter → Auswahl, Auswahl → Query, Kopfzeilen-Text, Log-Felder.
- `lib/features/practice/widgets/line_view.dart` — Ein-Zeilen-Ansicht (ersetzt `SheetWindow`), Geometrie-Cache.
- `lib/features/lessons/line_list_screen.dart` — Zeilenliste je Übung (Route `/exercise/:rudimentId`), Auswahlmodus.
- `lib/features/lessons/exercise_entry.dart` — `opensLineList(Rudiment)` + `openExercise(context, ref, rudiment)` für die Kacheln.
- `lib/features/settings/sequence_repeats_row.dart` — Chips „1× … 4×".
- Tests: `test/features/practice/line_selection_test.dart`, `test/features/practice/line_view_test.dart`, `test/lessons/line_list_screen_test.dart`, `test/features/settings/sequence_repeats_row_test.dart`; Goldens `test/goldens/line_view_fill_sixteenth_singles.png`, `test/goldens/line_list_single_stroke_roll.png`, `test/goldens/line_list_groove_rock8.png`.

**Gelöscht:** `lib/features/practice/widgets/sheet_window.dart`, `test/features/practice/sheet_window_test.dart`.

**Geändert:** Katalog (`tool/katalog/*.py`, `README.md`), alle generierten Blätter + Seed, `sheet_plan.dart`, `practice_session_screen.dart`, `settings_service.dart`, `settings_screen.dart`, `router.dart`, `practice_route.dart`, `next_step.dart`, `daily_routine_screen.dart`, `lessons_screen.dart`, `collection_screen.dart`, `lesson_detail_screen.dart`, `notation_staff_widget.dart` (`onlyLine`), Tests wie in den Aufgaben, `docs/CLAUDE.md`.

---

### Task 1: Challenge raus aus Katalog und Inhalt

**Files:**
- Modify: `tool/katalog/blatt.py` (Docstring, Feld `challenge` weg, `parsed()` `:49-59`), `tool/katalog/rudimente.py`, `fills.py`, `grooves.py`, `feet.py`, `set_fills.py`, `set_more.py` (alle `challenge=`-Argumente, Hilfsfunktionen `challenge()`, `feet_fill(challenge_lines=)`, `_check_linear`, Modul-Docstrings), `tool/katalog/katalog.py:35`, `tool/katalog/gen_dart.py:58`, `tool/katalog/README.md` (Zeile `blatt.py`), `tool/katalog/test_kit.py`
- Regenerate: `lib/features/lessons/data/sheets/*_sheet.dart` (alle 48), `lib/features/lessons/data/rudiments_seed.dart`
- Test: `tool/katalog/test_kit.py`, `test/lessons/seed_integrity_test.dart`, `test/lessons/etudes_integrity_test.dart`, `test/lessons/kit_seed_integrity_test.dart`, `test/lessons/lessons_screen_meta_test.dart`, `test/features/practice/practice_session_screen_test.dart`, `test/notation_kit_goldens_test.dart` (nur Goldens neu)

**Interfaces:**
- Produces: `Sheet` ohne Feld `challenge`; `Sheet.parsed()` liefert genau 8 Zeilen (alle `repeat=True`, ohne Titel). Jedes `Rudiment` mit `lines` im Seed hat 8 Zeilen. Kein Dart-API-Wechsel.

- [ ] **Step 1: Python-Tests schreiben** (in `test_kit.py`, neue Klasse `NoChallengeTest`)

```python
class NoChallengeTest(unittest.TestCase):
    def test_sheet_has_no_challenge_field(self):
        self.assertNotIn('challenge', {f.name for f in dataclasses.fields(Sheet)})

    def test_every_sheet_parses_to_eight_repeating_lines(self):
        for st in katalog.SETS:
            for s in st.sheets:
                lines = s.parsed()
                self.assertEqual(len(lines), 8, s.id)
                self.assertTrue(all(ln.repeat and ln.title is None for ln in lines), s.id)
                self.assertEqual(sum(ln.bars for ln in lines), 8 * s.line_bars, s.id)
```

Außerdem in `test_sheets_check_their_lines` (`:257-262`) das Argument `challenge=bad` streichen.

- [ ] **Step 2: Rot prüfen** — `cd tool/katalog && python3 -m unittest -q` → FAIL (`challenge` ist noch ein Feld; 9 Zeilen).

- [ ] **Step 3: Katalog ändern**
  - `blatt.py`: Feld `challenge` und Docstring-Hinweis weg; `parsed()` = 8 Zeilen parsen, `check_sheet`, Prüfung „8 Zeilen" und „jede Zeile `line_bars` Takte" bleiben, Challenge-Anhang und 8-Takt-Prüfung weg. Die `count_lines`-Kit-Prüfung der Abend-Fixes bleibt.
  - Datenmodule: jedes `challenge=`-Argument löschen; Hilfsfunktionen `fills.challenge`, `set_fills.challenge` löschen; `set_more.py`: `challenge` aus dem Import, Parameter `challenge_lines` aus `feet_fill` und den beiden Aufrufen, `_check_linear` prüft nur noch `{3}` je Zeile (Schleifen ohne `i < 8`-Zweig, Meldungen `f'line {i + 1}'`).
  - Danach jede Konstante, die nur noch in einem gelöschten Challenge-Ausdruck vorkam (z. B. `KC_8`, `DB8_8A`, `_around_bars` — prüfen mit `grep -n '<Name>' tool/katalog/*.py`), ebenfalls löschen; Konstanten mit weiterer Verwendung bleiben.
  - Texte: `katalog.py:35` „… mit Wiederholung." (ohne Challenge-Halbsatz), `gen_dart.py:58` `/// {sheet.name}: {form}, composed`, Modul-Docstrings „8 Zeilen à n Takte mit Wiederholung", README `blatt.py   Sheet: ein Blatt (8 Zeilen à line_bars Takte), Formprüfung, Übersichtstabelle`.

- [ ] **Step 4: Grün prüfen und Blätter prüfen**

```bash
cd tool/katalog && python3 -m unittest -q && for m in rudimente fills grooves set_fills feet set_more; do python3 $m.py | tail -1; done
```
Expected: OK; jede Übersicht `… Blätter ok`, Zeilen „8 Zeilen  16 Takte" bzw. „32 Takte"; `set_more.py` zusätzlich `linear ok`.

- [ ] **Step 5: Dart-Tests auf 8 Zeilen umstellen (rot)**
  - `seed_integrity_test.dart`, neuer Test `'every authored sheet has eight lines and no Challenge'`: für jedes `r in rudimentsSeedData` mit `r.lines.isNotEmpty`: `expect(r.lines.length, 8, reason: r.id)`; `expect(r.lines.any((l) => l.title == 'Challenge'), isFalse, reason: r.id)`; `expect(r.lines.every((l) => l.repeat), isTrue, reason: r.id)`.
  - `etudes_integrity_test.dart:64-160`: Testnamen ohne „+ Challenge"; `r.sheet.length` 8; `r.sheet.every((l) => l.repeat)`; die `last`-Erwartungen (repeat false, Titel, 8 Takte) streichen; `sheetBars` 24 → 16, 40 → 32.
  - `kit_seed_integrity_test.dart`: 9 → 8, 24 → 16, 40 → 32, `last.title`/`last.repeat`-Erwartungen weg, Kommentar `:211` und `fillBars = {3}` für jede Zeile (`:214`). `SheetPlan.wholeSheet` bleibt hier bis Task 2.
  - `lessons_screen_meta_test.dart`: „9 lines · 24 bars" → „8 lines · 16 bars" (alle drei Stellen).
  - `practice_session_screen_test.dart`: „Line n / 9" → „Line n / 8", „Sheet · 24 bars" → „Sheet · 16 bars", `24 * 96` → `16 * 96`.

  Run: `flutter test test/lessons test/features/practice/practice_session_screen_test.dart` → FAIL (Seed hat noch 9 Zeilen).

- [ ] **Step 6: Neu generieren**

```bash
python3 tool/katalog/gen_dart.py lib/features/lessons/data/sheets
python3 tool/katalog/patch_seed.py lib/features/lessons/data/rudiments_seed.dart
dart format lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart
grep -rl "title: 'Challenge'" lib/features/lessons/data/sheets | wc -l   # Expected: 0
```

- [ ] **Step 7: Goldens nachziehen** — `flutter test --update-goldens test/notation_kit_goldens_test.dart`; `git status test/goldens` zeigt **nur** `kit_sheet_groove_rock8.png` und `kit_sheet_feet_double_bass_eighths.png` geändert (die PATTERN-Goldens bleiben byte-gleich). PNGs mit Read ansehen: 8 Zeilen, keine Challenge-Reihe.

- [ ] **Step 8: Volle Prüfung** — `flutter analyze` (13), `flutter test` grün, `cd tool/katalog && python3 -m unittest -q` grün. Kurationsseite einmal bauen: `python3 tool/katalog/build_page.py /tmp/rudimente.html rudimente` (läuft ohne Fehler, Eyebrow „8 Zeilen · 16 Takte").

- [ ] **Step 9: Commit**

```bash
git add tool/katalog lib/features/lessons/data test/lessons test/features/practice/practice_session_screen_test.dart test/goldens/kit_sheet_groove_rock8.png test/goldens/kit_sheet_feet_double_bass_eighths.png
git commit -m "feat(Katalog): Challenge-Zeile aus allen Blättern entfernt — 8 Zeilen je Blatt (16/32 Takte), neu generiert"
```

---

### Task 2: `SheetPlan.sequence` ersetzt `wholeSheet`

**Files:**
- Modify: `lib/features/lessons/models/sheet_plan.dart`
- Modify (mechanisch): `lib/features/practice/practice_session_screen.dart:273-275` (Blatt-Modus → `SheetPlan.sequence(rudiment, alle, repeats: 1)` bis Task 3), `test/lessons/kit_seed_integrity_test.dart:63,172`
- Test: `test/lessons/sheet_plan_test.dart`

**Interfaces:**
- Produces (in `sheet_plan.dart`):
  - `const int maxSequenceBars = 64;` (gleich `maxBackingCycleBars`), `const int maxSequenceRepeats = 4;`
  - `factory SheetPlan.sequence(Rudiment r, List<int> selection, {int repeats = 2, int start = 0})`
  - `factory SheetPlan.line(Rudiment r, int lineIndex)` — klemmt `lineIndex` in das Blatt, dann `sequence(r, [i])`.
  - Felder: `beats`, `voices`, `totalTicks` wie bisher; `lines` (Blattzeile **je Slot**, Spielreihenfolge), `lineStarts`, `lineTickStarts` (je Slot); neu `selection` (bereinigte Auswahl in Originalreihenfolge), `start` (Index in `selection`, an dem der Loop beginnt), `repeats` (tatsächlich verwendet). Feld `wholeSheet` entfällt.
  - `bool get isSequence => selection.length > 1;` `int get lineIndex => lines.first;`
  - `({int step, int pass}) stepOf(int slot)` — `step` = Index in `selection` (`(start + slot ~/ repeats) % selection.length`), `pass` = `slot % repeats`.
  - `({int line, int index, int slot}) locate(int noteIndex)`, `({int line, int tick, int slot}) locateTick(int tick)`.
  - `sheetBars`, `barsOf` unverändert.

- [ ] **Step 1: Tests schreiben** (in `sheet_plan_test.dart`; die bestehenden `wholeSheet`-Tests umschreiben, Fixture-Helfer der Datei weiterverwenden: ein Pad-Blatt mit drei 2-Takt-Zeilen A, B, C — `t` = Ticks einer Zeile = 192)

```dart
test('sequence plays every line `repeats` times in order', () {
  final p = SheetPlan.sequence(r, [0, 2], repeats: 2);
  expect(p.lines, [0, 0, 2, 2]);
  expect(p.beats, [...a, ...a, ...c, ...c]);
  expect(p.totalTicks, 4 * 192);
  expect(p.isSequence, isTrue);
  expect(p.repeats, 2);
});
test('locateTick maps to line, tick in line and slot; stepOf gives step and pass', () {
  final p = SheetPlan.sequence(r, [0, 2], repeats: 2);
  expect(p.locateTick(0), (line: 0, tick: 0, slot: 0));
  expect(p.locateTick(192 + 30), (line: 0, tick: 30, slot: 1));
  expect(p.locateTick(2 * 192), (line: 2, tick: 0, slot: 2));
  expect(p.stepOf(1), (step: 0, pass: 1));
  expect(p.stepOf(2), (step: 1, pass: 0));
});
test('start rotates the loop; steps keep the selection order (Rundlauf)', () {
  final p = SheetPlan.sequence(r, [0, 1, 2], repeats: 1, start: 1);
  expect(p.lines, [1, 2, 0]);
  expect(p.stepOf(0).step, 1);
  expect(p.stepOf(2).step, 0);
  expect(SheetPlan.sequence(r, [0, 1, 2], start: 4).start, 1); // modulo
});
test('one line loops alone: repeats 1, no sequence', () {
  final p = SheetPlan.sequence(r, [1], repeats: 3);
  expect((p.lines, p.repeats, p.isSequence), ([1], 1, false));
  expect(SheetPlan.line(r, 7).lineIndex, 2);
  expect(SheetPlan.line(r, -1).lineIndex, 0);
});
test('selection is cleaned: out of range and duplicates dropped, empty = line 1', () {
  expect(SheetPlan.sequence(r, [5, -1, 1, 1, 0]).selection, [1, 0]);
  expect(SheetPlan.sequence(r, []).selection, [0]);
});
test('sequence caps repeats at 64 bars', () {
  // eight four-bar lines (fill sheet shape)
  expect(SheetPlan.sequence(fill8, [0, 1, 2, 3, 4, 5, 6, 7], repeats: 4).repeats, 2);
  expect(SheetPlan.sequence(fill8, [0, 1], repeats: 4).repeats, 4);
  expect(SheetPlan.sequence(r, [0, 1, 2], repeats: 9).repeats, maxSequenceRepeats);
  expect(maxSequenceBars, maxBackingCycleBars);
});
test('kit sequence: a voice missing in a line is filled with rests per slot', () {
  // port of the old wholeSheet kit test: line 1 has no kick
  final p = SheetPlan.sequence(kit, [0, 1], repeats: 2);
  final kick = p.voices.firstWhere((v) => v.instrument == KitInstrument.kick);
  expect(ticksOf(kick.beats), p.totalTicks);
  expect(p.playsKick, isTrue);
});
```
`fill8` = Test-Rudiment mit acht 4-Takt-Pad-Zeilen (im Test bauen). Legacy-Test (`:57-58`): `SheetPlan.line(legacy, 0).beats` bleibt `same(legacy.sticking)` (Einzelzeile übernimmt die Liste der Zeile unverändert); `SheetPlan.sequence(legacy, [0]).beats.length == 4`.

- [ ] **Step 2: Rot prüfen** — `flutter test test/lessons/sheet_plan_test.dart` → FAIL (`sequence` undefiniert).

- [ ] **Step 3: Implementieren.** Auswahl bereinigen (Reihenfolge behalten, ungültige/doppelte raus, leer → `[0]`); eine Zeile → `repeats = 1`; sonst `repeats.clamp(1, maxSequenceRepeats)`, dann verringern, solange `repeats * Σ barsOf(Zeile) > maxSequenceBars` und `repeats > 1`; `start %= selection.length`; Slots = rotierte Auswahl, jede Zeile `repeats`-mal. Stimmen-Verkettung aus `wholeSheet` übernehmen, aber über die Slots statt über das Blatt. `wholeSheet` löschen. `maxBackingCycleBars` wird nur im Test importiert (`features/metronome/loop_voices.dart`), nicht im Modell.

- [ ] **Step 4: Aufrufer umstellen** — Übungs-Screen `_buildUnit`: `SheetPlan.sequence(rudiment, [for (var i = 0; i < rudiment.sheet.length; i++) i], repeats: 1)` statt `wholeSheet` (Übergang bis Task 3); `kit_seed_integrity_test.dart:63,172`: `SheetPlan.sequence(r, alle Zeilen)` → `returnsNormally`. Aufrufer von `locate`/`locateTick` lesen nur `.line`/`.index`/`.tick` und bleiben gültig.

- [ ] **Step 5: Grün prüfen** — `flutter test test/lessons test/features/practice` grün; `flutter analyze` (13).

- [ ] **Step 6: Commit**

```bash
git add lib/features/lessons/models/sheet_plan.dart lib/features/practice/practice_session_screen.dart test/lessons/sheet_plan_test.dart test/lessons/kit_seed_integrity_test.dart
git commit -m "feat(Plan): SheetPlan.sequence — Zeilenfolge n-fach mit Startpunkt und Slot-Ortung, ersetzt wholeSheet"
```

---

### Task 3: Auswahl, Routen und Folge im Übungs-Screen (Logik)

**Files:**
- Create: `lib/features/practice/line_selection.dart`, `test/features/practice/line_selection_test.dart`
- Modify: `lib/data/local/settings_service.dart:196-260`, `lib/app/router.dart:91-100,139-152`, `lib/features/program/practice_route.dart:8-16`, `lib/features/today/next_step.dart:51`, `lib/features/learning/daily_routine_screen.dart:48`, `lib/features/practice/practice_session_screen.dart` (Parameter, `initialSheetPosition` weg, Zustand, `_LineBar`, Snapshot, Log)
- Test: `test/data/settings_sheet_test.dart`, `test/features/program/practice_route_test.dart`, `test/features/today/next_step_test.dart:116`, `test/features/practice/practice_session_screen_test.dart` (Gruppe `initialSheetPosition` → `line_selection_test`, Gruppe „sheet (Blattform)" umschreiben)

**Interfaces:**
- Consumes: `SheetPlan.sequence/line`, `stepOf`, `locate`/`locateTick` mit `slot` (Task 2).
- Produces:
  - `line_selection.dart`:
    - `List<int> initialLineSelection({required int lineCount, String? linesParam, int? lineParam, int? rememberedLine})` — 0-basiert.
    - `String linesQuery(List<int> zeroBased)` — `[0, 2, 4]` → `'1,3,5'`.
    - `String lineNavLabel({required int line, required int lineCount, required int step, required int steps, required int pass, required int repeats})`
    - `({int? line, String mode}) sessionLogSheetFields(SheetPlan plan)`
  - `SettingsService`: `static int? lastLineFor(String id)` (Schlüssel `sheet_line_<id>`, null = nie geübt), `static Future<void> setLastLine(String id, int line)`, `static int get sequenceRepeats` (Schlüssel `sequence_repeats`, Standard 2, gelesen geklemmt 1–4), `static Future<void> setSequenceRepeats(int n)` (klemmt 1–4). `sheetPositionFor`/`setSheetPosition` entfallen. Snapshot: `savePracticeSnapshot({…, List<int> lines = const [0], int start = 0})`, `practiceSnapshotFor` liefert `({int elapsedSeconds, int? goalSeconds, int sessionSeconds, List<int> lines, int start})`; Schlüssel `practice_snap_lines` (`'0,2,4'`), `practice_snap_start`; `practice_snap_sheet` wird nicht mehr geschrieben.
  - `PracticeSessionScreen`: Parameter `final String? lines;` (roh aus `?lines=`) und `final int? line;` (Alias, 1-basiert); `mode` entfällt.
  - `practiceRouteFor(...)` setzt immer `lines=all` als ersten Parameter.

- [ ] **Step 1: Tests für die reinen Funktionen** (`line_selection_test.dart`)

```dart
test('lines=all selects every line', () =>
    expect(initialLineSelection(lineCount: 8, linesParam: 'all'), [0, 1, 2, 3, 4, 5, 6, 7]));
test('lines=1,3,5 is 1-based, order kept', () =>
    expect(initialLineSelection(lineCount: 8, linesParam: '1,3,5'), [0, 2, 4]));
test('garbage is dropped, never an error', () {
  expect(initialLineSelection(lineCount: 8, linesParam: '0,abc,99,3,3'), [2]);
  expect(initialLineSelection(lineCount: 8, linesParam: '', rememberedLine: 4), [4]);
  expect(initialLineSelection(lineCount: 8, linesParam: 'x', lineParam: 2), [1]);
});
test('line=N is an alias; out of range opens line 1', () {
  expect(initialLineSelection(lineCount: 8, lineParam: 3), [2]);
  expect(initialLineSelection(lineCount: 8, lineParam: 40), [0]);
});
test('no params: the remembered line, clamped; never practised = line 1', () {
  expect(initialLineSelection(lineCount: 8, rememberedLine: 4), [4]);
  expect(initialLineSelection(lineCount: 3, rememberedLine: 7), [0]);
  expect(initialLineSelection(lineCount: 8), [0]);
});
test('lines=all on a one-line exercise is that line', () =>
    expect(initialLineSelection(lineCount: 1, linesParam: 'all'), [0]));
test('linesQuery is 1-based and comma separated', () =>
    expect(linesQuery([0, 2, 4]), '1,3,5'));
test('lineNavLabel: single line and sequence', () {
  expect(lineNavLabel(line: 2, lineCount: 8, step: 0, steps: 1, pass: 0, repeats: 1), 'Line 3 of 8');
  expect(lineNavLabel(line: 4, lineCount: 8, step: 1, steps: 4, pass: 0, repeats: 2),
      'Sequence 2 of 4 · Line 5 · 1/2');
});
test('sessionLogSheetFields: line number for one line, null for a sequence', () {
  expect(sessionLogSheetFields(SheetPlan.line(r, 2)), (line: 3, mode: 'line'));
  expect(sessionLogSheetFields(SheetPlan.sequence(r, [0, 2])), (line: null, mode: 'sequence'));
});
```
(`r` = `rudimentsSeedData.firstWhere((r) => r.id == 'single_paradiddle')`.)

- [ ] **Step 2: Tests für Einstellungen und Routen**
  - `settings_sheet_test.dart`: `lastLineFor('x')` null; nach `setLastLine('x', 3)` → 3. `sequenceRepeats` 2; `setSequenceRepeats(9)` → 4; `setSequenceRepeats(0)` → 1. Snapshot: `savePracticeSnapshot(rudimentId: 'x', elapsedSeconds: 30, lines: [0, 2, 4], start: 1)` → `practiceSnapshotFor('x')!.lines == [0, 2, 4]`, `.start == 1`. Altes Format: `SharedPreferences.setMockInitialValues({'practice_snap_id': 'x', 'practice_snap_elapsed': 30, 'practice_snap_time': <jetzt ISO>, 'practice_snap_line': 5})` → `lines == [5]`, `start == 0`.
  - `practice_route_test.dart`: `'/practice/single_paradiddle?lines=all&bpm=84&min=8&ladder=1'`; „omits empty parameters" → `'/practice/single_stroke_roll?lines=all'`.
  - `next_step_test.dart:116`: `'/routine/single_paradiddle?bpm=90&lines=all'`.

- [ ] **Step 3: Screen-Tests umschreiben** (`practice_session_screen_test.dart`, Gruppe „sheet (Blattform)" → „lines and sequences"; `_screen(...)` bekommt `String? lines` statt `mode`)
  - `'a sheet opens on the remembered line, › moves to line 2 and reloads'`: Text `'Line 1 of 8'`, Tap `line-next` → `'Line 2 of 8'`, `rec.volumes.last` = Ticks von Zeile 2, `SettingsService.lastLineFor(sheetId) == 1`.
  - `'?lines=1,3 plays a sequence: each line twice'`: `rec.volumes.last == 2 * 2 * 2 * 96` (zwei 2-Takt-Zeilen × 2), Text `'Sequence 1 of 2 · Line 1 · 1/2'`, keine Keys `mode-line`/`mode-sheet`.
  - `'the sequence advances with the cursor'` (`_TickingMetronomeNotifier`, `?lines=1,3`): `tickTo(2 * 192)` → `'Sequence 2 of 2 · Line 3 · 1/2'`; `tickTo(3 * 192)` → `'… · 2/2'`.
  - `'› in a running sequence wraps and reloads'` (`_RecordingPlayingMetronomeNotifier`, `?lines=1,3`): Tap `line-next` → `'Sequence 2 of 2 · Line 3 · 1/2'`, `rec.volumes.length` +1; nochmals → `'Sequence 1 of 2 · Line 1 · 1/2'` (Rundlauf); `'Stop'` sichtbar.
  - `'the repeats setting is used and capped'`: `setSequenceRepeats(3)`, `?lines=all` auf `fill_sixteenth_singles` (8 × 4 Takte) → `rec.volumes.last == 64 * 96`, Text endet auf `'· 1/2'`.
  - `'lines=all on a one-line exercise plays it alone'` (`multiple_bounce_roll`): kein `line-bar`, kein Text mit `'Sequence'`.
  - `'?line=3 opens line 3; ?mode=sheet is ignored'`: `_screen(line: 3)` → `'Line 3 of 8'`; mit `PracticeSessionScreen(… lines: null, line: null)` und gesetzter `lastLine` 4 → `'Line 5 of 8'`.
  - Tests „Sheet mode …" und „tapping a line in the window selects it" löschen.

  Run: `flutter test test/features/practice test/data test/features/program test/features/today` → FAIL.

- [ ] **Step 4: Implementieren**
  - `line_selection.dart` nach den Tests (`'all'` → alle; Komma-Liste mit `int.tryParse`, 1-basiert, Bereich, Duplikate raus; leer → `lineParam` (ungültig → `[0]`) → `rememberedLine` geklemmt → `[0]`).
  - `SettingsService` wie im Interface; Alt-Snapshot: fehlt `practice_snap_lines`, gilt `[practice_snap_line ?? 0]`.
  - Router: beide Practice-Routen übergeben `lines: state.uri.queryParameters['lines']` und `line: int.tryParse(…['line'] ?? '')`; `mode` nicht mehr lesen. `practiceRouteFor`: `'lines=all'` als erstes Element der Parameterliste. `next_step.dart:51` und `daily_routine_screen.dart:48`: `…?bpm=${item.suggestedBpm}&lines=all`. Programm-Screen bleibt bei `practiceRouteFor` (→ alle Zeilen, siehe Task 5 Begründung).
  - Übungs-Screen:
    - Zustand `late List<int> _selection; late int _start;` statt `_lineIndex/_sheetMode`; `_buildUnit`: `_plan = SheetPlan.sequence(rudiment, _selection, repeats: SettingsService.sequenceRepeats, start: _start)`.
    - `initState`: `_selection = initialLineSelection(lineCount: rudiment.sheet.length, linesParam: widget.lines, lineParam: widget.line, rememberedLine: SettingsService.lastLineFor(widget.rudimentId))`, `_start = 0`; Snapshot stellt `_selection`/`_start` wieder her (Zeilen außerhalb des Blatts verwirft `sequence` selbst).
    - `_applyUnitChange`: `SettingsService.setLastLine(widget.rudimentId, _plan.lineIndex)` statt `setSheetPosition`.
    - Navigation: Feld `int _shownStep = 0` (im `build` aus `tickLoc?.slot ?? loc?.slot` über `_plan.stepOf` gesetzt, ohne `setState`). `_step(int delta)`: Einzelzeile → `_selection = [i + delta]` innerhalb `0..sheet.length-1` (an den Rändern nichts); Folge → `_start = (_shownStep + delta) % _selection.length`. Danach `_applyUnitChange()`. `_selectLine`/`_setSheetMode` entfallen.
    - `_LineBar` → nur noch `‹ label ›` (Keys `line-bar`, `line-prev`, `line-next` bleiben; Chips `mode-line`/`mode-sheet` weg); Label `lineNavLabel(...)` mit Zeile/Step/Pass des Cursors (vor dem Start: Slot 0); Pfeile in der Einzelzeile an den Rändern deaktiviert, in der Folge immer aktiv. Sichtbar wie bisher nur bei `rudiment.sheet.length > 1`.
    - `SheetWindow` bleibt bis Task 4: `activeLine` aus `tickLoc?.line ?? loc?.line ?? _plan.lineIndex`, `sheetMode: false`, `onLineTap: null`.
    - Optionen „About" (`:760-778`): `onLineTap`-Handler entfernen (Info-Seite verliert ihn in Task 5; bis dahin `onLineTap` einfach nicht übergeben).
    - Snapshot schreiben mit `lines: _selection, start: _start`; Sitzungs-Log mit `sessionLogSheetFields(_plan)` (`sheetLine:`/`sheetMode:`).
    - `initialSheetPosition` und seine Testgruppe löschen; Kommentar `:657` „a triplet challenge" → „a triplet line".

- [ ] **Step 5: Grün prüfen** — gezielte Tests grün, dann `flutter analyze` (13) und `flutter test` voll.

- [ ] **Step 6: Commit**

```bash
git add lib/features/practice/line_selection.dart lib/data/local/settings_service.dart lib/app/router.dart lib/features/program/practice_route.dart lib/features/today/next_step.dart lib/features/learning/daily_routine_screen.dart lib/features/practice/practice_session_screen.dart test/features/practice test/data/settings_sheet_test.dart test/features/program/practice_route_test.dart test/features/today/next_step_test.dart
git commit -m "feat(Üben): Zeilenauswahl ?lines=, Zeilenfolge n-fach mit Rundlauf und Vor/Zurück, Blatt-Modus entfernt, Heute/Routine spielen alle Zeilen"
```

---

### Task 4: Ein-Zeilen-Ansicht und Einstellung „Repeats per line"

**Files:**
- Create: `lib/features/practice/widgets/line_view.dart`, `lib/features/settings/sequence_repeats_row.dart`, `test/features/practice/line_view_test.dart`, `test/features/settings/sequence_repeats_row_test.dart`, Golden `test/goldens/line_view_fill_sixteenth_singles.png`
- Modify: `lib/shared/widgets/notation_staff_widget.dart:103-196` (`onlyLine`), `lib/features/practice/practice_session_screen.dart` (`SheetWindow` → `LineView`), `lib/features/settings/settings_screen.dart` (Abschnitt nach DAILY PRACTICE GOAL)
- Delete: `lib/features/practice/widgets/sheet_window.dart`, `test/features/practice/sheet_window_test.dart`
- Test: `test/notation_staff_test.dart` (onlyLine), `test/features/practice/practice_session_screen_test.dart` (alle `SheetWindow`-Finder)

**Interfaces:**
- Consumes: `SettingsService.sequenceRepeats/setSequenceRepeats` (Task 3).
- Produces:
  - `SheetStaffWidget({…, int? onlyLine})` — zeichnet nur diese Zeile: Nummernkasten `onlyLine + 1`, Titel, Wiederholungszeichen, Schlüssel und Taktart, Schlussstrich; nie gedimmt; `onLineTap` meldet `onlyLine`. `onlyLine == null` zeichnet wie bisher (alle Goldens unverändert).
  - `class LineView extends StatefulWidget { const LineView({super.key, required Rudiment rudiment, required int line, int? activeIndex, int? activeTick, bool showSticking = true, bool showCounts = true}); }` — Papierkarte genau so hoch wie die Zeile (`rowCount × rowPitch + 2 × SheetStaffWidget.vPad`), Geometrie gecacht wie in `SheetWindow._geometryFor` (Rudiment-Identität, Breite, Zählsilben).
  - `class SequenceRepeatsRow extends StatelessWidget { const SequenceRepeatsRow({super.key, required int value, required ValueChanged<int> onChanged}); }` — Chips `1×`…`4×` (Keys `repeats-1` … `repeats-4`, `AppSelectableChip`).

- [ ] **Step 1: Tests schreiben**
  - `notation_staff_test.dart` (Gruppe SheetStaffWidget): `'onlyLine draws one line, numbered as in the sheet'` — `SheetStaffWidget(rudiment: sheet, onlyLine: 1)` → genau ein `CustomPaint` unter dem Widget, Höhe = `sheetRowPitch`-Vielfaches der Zeile; mit `onLineTap: taps.add` und Tap auf die Karte → `taps == [1]`.
  - `line_view_test.dart`: `'shows only the given line, height fits its rows'` — `fill_sixteenth_singles` Zeile 0 bei 360 px Breite: ein `CustomPaint`; Höhe des `LineView` = `geo.layouts[0].rowCount * geo.rowPitch + 2 * SheetStaffWidget.vPad` mit `rowCount == 2`. `'golden: a four-bar fill line in two rows'` → `matchesGoldenFile('../../goldens/line_view_fill_sixteenth_singles.png')` (Bravura laden wie in `notation_kit_goldens_test.dart:12-19`).
  - `sequence_repeats_row_test.dart`: Chip `repeats-2` ausgewählt bei `value: 2`; Tap `repeats-3` → `onChanged(3)`.
  - `practice_session_screen_test.dart`: alle `find.byType(SheetWindow)` → `find.byType(LineView)`; Kit-Cursor-Test liest `(view().line, view().activeTick)`; der Rand-Test (`rect.left == 6`) und der Zentrier-Test (`:970-990`, jetzt ohne `ClipRect`-Suche: Rechteck des `LineView`) bleiben inhaltlich; neu `'one-line view: only the current line is drawn'` — `?lines=1,3`, genau ein `CustomPaint` unter `LineView`, nach `tickTo(2 * 192)` zeigt `view().line == 2`.

  Run: `flutter test test/notation_staff_test.dart test/features/practice test/features/settings` → FAIL.

- [ ] **Step 2: Implementieren** — `onlyLine` in `SheetStaffWidget.build` (Schleife über `[onlyLine]` statt über alle; `showTimeSig`/`showClef`/`finalBar` true, `dimmed` false); `LineView` (Struktur aus `SheetWindow` ohne Fenster/Slide/Bänder); im Übungs-Screen `SheetWindow(...)` durch `LineView(rudiment:, line: tickLoc?.line ?? loc?.line ?? _plan.lineIndex, activeIndex: loc?.index, activeTick: tickLoc?.tick, showSticking:, showCounts:)` ersetzen, Opazität/Zentrierung/Ränder wie bisher, veraltete Kommentare zum Blattfenster anpassen. `sheet_window.dart` + Test löschen. Einstellungen: neuer Abschnitt nach DAILY PRACTICE GOAL —

```dart
_SectionLabel('LINE SEQUENCES'),
const SizedBox(height: 10),
SequenceRepeatsRow(value: _repeats, onChanged: _setRepeats),
const SizedBox(height: 6),
Text('Each selected line plays this many times before the next one.',
    style: AppTypography.label.copyWith(color: AppColors.textMuted)),
const SizedBox(height: 28),
```
(`_repeats` im State aus `SettingsService.sequenceRepeats`, `_setRepeats` speichert und `setState`.) Eine Vorschau der nächsten Zeile entfällt (Spec §3.2 erlaubt das für Phase 1).

- [ ] **Step 3: Goldens erzeugen** — `flutter test --update-goldens test/features/practice/line_view_test.dart`; `git status test/goldens` → nur `line_view_fill_sixteenth_singles.png` neu. Ansehen: 4 Takte in zwei Reihen, Nummer 1, Wiederholungszeichen, keine Zählsilben-Überlappung.

- [ ] **Step 4: Grün prüfen** — `flutter analyze` (13), `flutter test` voll (alle alten Goldens unverändert).

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/notation_staff_widget.dart lib/features/practice lib/features/settings test/notation_staff_test.dart test/features/practice test/features/settings test/goldens/line_view_fill_sixteenth_singles.png
git rm lib/features/practice/widgets/sheet_window.dart test/features/practice/sheet_window_test.dart
git commit -m "feat(Üben): Ein-Zeilen-Ansicht statt Blattfenster, Einstellung Wiederholungen je Zeile"
```

---

### Task 5: Zeilenliste je Übung, Einstiege, Info-Seite ohne THE SHEET

**Files:**
- Create: `lib/features/lessons/line_list_screen.dart`, `lib/features/lessons/exercise_entry.dart`, `test/lessons/line_list_screen_test.dart`, Goldens `test/goldens/line_list_single_stroke_roll.png`, `test/goldens/line_list_groove_rock8.png`
- Modify: `lib/app/router.dart` (Route `/exercise/:rudimentId`), `lib/features/lessons/lessons_screen.dart:263-273`, `lib/features/lessons/collection_screen.dart:100-104`, `lib/features/lessons/lesson_detail_screen.dart` (THE SHEET + `onLineTap` weg, PATTERN immer, `showStart`, `_MetaRow` → `ExerciseMetaRow`), `lib/features/practice/practice_session_screen.dart` (About → `showStart: false`)
- Test: `test/lessons/lessons_screen_navigation_test.dart`, `test/lessons/lesson_detail_sheet_test.dart`, `test/app/router_test.dart`

**Interfaces:**
- Consumes: `linesQuery` (Task 3), `SettingsService.lastLineFor` (Task 3), `SheetStaffWidget(onlyLine:, geometry:)` (Task 4), `computeSheetGeometry`, `suggestedBpmProvider`, `rudimentByIdProvider`.
- Produces:
  - `class LineListScreen extends ConsumerStatefulWidget { const LineListScreen({super.key, required String rudimentId}); }`
  - `bool opensLineList(Rudiment r) => r.sheet.length > 1;`
  - `Future<void> openExercise(BuildContext context, WidgetRef ref, Rudiment r)` — Mehrzeiler: `context.push('/exercise/${r.id}')`; Einzeiler: Tempo holen, `context.push('/practice/${r.id}?bpm=$bpm')` (wie heute).
  - `LessonDetailScreen({required String rudimentId, bool showStart = true})`; `class ExerciseMetaRow` (öffentlich, gleiche Optik wie `_MetaRow`).

**Entscheidungen (mit Begründung):**
- **Programm-Screen** (`program_screen.dart:451`) bleibt bei `practiceRouteFor` → Übungs-Screen mit allen Zeilen, **nicht** Zeilenliste: Der Block trägt Tempo-Leiter, Dauer und Kontext; Spec §3.4 behandelt geplante Blöcke wie Heute. (Abweichung von Spec §3.1 „Programm öffnet die Zeilenliste" — siehe offene Frage.)
- **Sammlung** (`collection_screen.dart`) und Einzeiler allgemein: `openExercise` → Einzeiler direkt in den Übungs-Screen; eine Liste mit einer Karte wäre ein leerer Zwischenschritt. Die Sammlung enthält heute nur Étüden (Einzeiler), ändert sich also im Verhalten nicht.
- **Info-Seite „Start Practice"** → `/practice/:id?lines=all&bpm=` (alle Zeilen als Folge): Die Info-Seite wird von der Zeilenliste (ⓘ) und der Bibliothek (ⓘ) erreicht; ein Sprung in die Zeilenliste würde von der Liste aus eine zweite Liste stapeln, „alle spielen" ist eindeutig und die Liste ist einen Zurück-Tipp entfernt. Aus dem Übungs-Screen (Optionen → About) wird die Seite mit `showStart: false` geöffnet (bisher stapelte der Knopf einen zweiten Übungs-Screen).
- **PATTERN** erscheint jetzt für jede Übung (bei Legacy/Étüden ist das die ganze Übung — sonst hätten sie nach dem Wegfall von THE SHEET keine Noten mehr); Legende bleibt.
- **ⓘ in der Zeilenliste** öffnet die Info-Seite per `Navigator.of(context).push(MaterialPageRoute(...))`, nicht `context.push('/library/:id')` — dieselbe Doppel-Page-Key-Falle wie im Übungs-Screen (`practice_session_screen.dart:762-766`), weil `/exercise` außerhalb der Shell liegt.

**Zeilenliste — Aufbau (exakte Keys und Texte):**
- `AppBar`: Titel `rudiment.name`; Aktionen `TextButton(key: ValueKey('select-mode'), child: Text('Select'))` und `IconButton(key: ValueKey('lesson-info'), icon: Icon(Icons.info_outline), tooltip: 'About this exercise')`. Im Auswahlmodus: `leading` `IconButton(key: ValueKey('selection-close'), icon: Icon(Icons.close))`, Titel `'$n selected'`, keine Aktionen; System-Zurück verlässt zuerst den Auswahlmodus (`PopScope(canPop: !_selecting)`).
- Kopf: `ExerciseMetaRow(rudiment)`, darunter `FilledButton.icon(key: ValueKey('play-all'), icon: Icon(Icons.play_arrow_rounded), label: Text('Play all'))` → `lines=all`.
- Liste (`ListView`, scrollt): je Zeile `i` eine Karte `Key('line-card-${i + 1}')` = `SheetStaffWidget(rudiment:, geometry: geo, onlyLine: i, showCounts: false, showSticking: true)`; Geometrie **einmal** je Breite per `LayoutBuilder` + `computeSheetGeometry(rudiment, width - 2 * SheetStaffWidget.hPad, showCounts: false)`. Zuletzt geübte Zeile (`lastLineFor`): 2 px Rahmen `AppColors.accent`, Radius `AppRadius.card`, Key `line-card-last` am Rahmen. Im Auswahlmodus links `Checkbox(key: ValueKey('line-check-${i + 1}'))`.
- Tap: normal → Tempo holen, `await context.push('/practice/$id?lines=${linesQuery([i])}&bpm=$bpm')`, danach `setState` (Markierung neu lesen). Im Auswahlmodus → Häkchen umschalten. Langes Drücken → Auswahlmodus mit dieser Zeile.
- Auswahlmodus unten: `FilledButton(key: ValueKey('play-selected'))` mit `'Play $n lines'` bzw. `'Play 1 line'`, deaktiviert bei 0; startet `lines=${linesQuery(sorted)}` — **immer aufsteigend** (Listenreihenfolge), egal in welcher Reihenfolge angetippt.
- Desktop: keine eigene Behandlung, `capContentWidth` (900 px) greift global.

- [ ] **Step 1: Tests schreiben** (`line_list_screen_test.dart`; `ProviderScope` mit `suggestedBpmProvider(id).overrideWith((ref) async => 80)`, Mini-`GoRouter` mit `/exercise/:id` → `LineListScreen` und `/practice/:id` → `Text('practice:${state.uri}')`; `SettingsService` mit Mock-Prefs)
  - `'lists all eight lines and scrolls'`: `single_stroke_roll` → `line-card-1` sichtbar; `scrollUntilVisible(find.byKey(Key('line-card-8')), 300)` findet sie; kein Text `'Challenge'`.
  - `'tap opens that line'`: Tap `line-card-3` → `practice:/practice/single_stroke_roll?lines=3&bpm=80`.
  - `'long-press selects; Play 3 lines starts the sequence in list order'`: Long-press `line-card-5`, Tap `line-card-2`, Tap `line-card-7` → Text `'3 selected'`, Tap `play-selected` (Text `'Play 3 lines'`) → `…?lines=2,5,7&bpm=80`.
  - `'Play all'`: Tap `play-all` → `…?lines=all&bpm=80`.
  - `'Select button, close and back leave selection mode'`: Tap `select-mode` → Checkboxen sichtbar, `play-selected` deaktiviert; Tap `selection-close` → keine Checkbox.
  - `'the last practised line is marked'`: `setLastLine('single_stroke_roll', 3)` → `line-card-last` ist Vorfahr von `line-card-4`; ohne gespeicherte Zeile → kein `line-card-last`.
  - `'ⓘ opens the lesson'`: Tap `lesson-info` → `LessonDetailScreen` gefunden.
  - Goldens: `'golden: line list pad'` (`single_stroke_roll`) und `'golden: line list kit'` (`groove_rock8`), Fläche 360 × 1400, dpr 1, Bravura geladen → `matchesGoldenFile('../goldens/line_list_<id>.png')`.
  - `lessons_screen_navigation_test.dart`: erster Test → `'tapping a sheet tile opens its line list'` (Router um `/exercise/:id` → `Text('lines:<id>')` ergänzen; Tap „Single Stroke Roll" → `lines:single_stroke_roll`). Neuer reiner Test `opensLineList`: `single_stroke_roll` true, eine Étüde (`allEtudes.first`) false.
  - `lesson_detail_sheet_test.dart`: `find.text('THE SHEET')` → `findsNothing`; PATTERN vorhanden, auch für eine Étüde (`allEtudes.first.id`); `LessonDetailScreen(rudimentId: …, showStart: false)` → kein `'Start Practice'`.
  - `router_test.dart`: `router.go('/exercise/single_paradiddle')` → `find.byType(LineListScreen)` findet eins.

  Run: `flutter test test/lessons test/app/router_test.dart` → FAIL.

- [ ] **Step 2: Implementieren** — Route (oberste Ebene, `parentNavigatorKey: _rootNavigatorKey`, wie `/practice`), `exercise_entry.dart`, `LineListScreen` nach dem Aufbau oben, Kacheln in Bibliothek/Sammlung rufen `openExercise(context, ref, rudiment)` (Kommentar über `onTap` in `lessons_screen.dart:267-269` anpassen: „Sheets open their line list; one-line exercises go straight to practice"), Info-Seite nach den Entscheidungen oben (`onLineTap`-Parameter und THE-SHEET-Block löschen, Kommentar `:47-50` anpassen), Übungs-Screen About → `LessonDetailScreen(rudimentId: widget.rudimentId, showStart: false)`.

- [ ] **Step 3: Goldens erzeugen** — `flutter test --update-goldens test/lessons/line_list_screen_test.dart`; `git status test/goldens` → nur die zwei neuen PNGs. Ansehen: Karten untereinander, Nummernkästen 1…, keine Zählsilben, Kit-Karten zweistimmig, Buchstaben nach der neuen Regel (nur bei Wechsel).

- [ ] **Step 4: Grün prüfen** — `flutter analyze` (13), `flutter test` voll.

- [ ] **Step 5: Commit**

```bash
git add lib/features/lessons lib/app/router.dart lib/features/practice/practice_session_screen.dart test/lessons test/app/router_test.dart test/goldens/line_list_single_stroke_roll.png test/goldens/line_list_groove_rock8.png
git commit -m "feat(Bibliothek): Zeilenliste je Übung mit Auswahl und Play all, Kacheln öffnen sie, Info-Seite ohne THE SHEET"
```

---

### Task 6: Doku, Builds, Linux-Lieferung, Emulator-Abnahme

**Files:**
- Modify: `docs/CLAUDE.md` (Abschnitte „Desktop (Linux)", „Sheets (Blattform …)", „Navigation (K2, 2026-09)", Ordnerbaum `features/lessons`, `features/practice`), `tool/katalog/README.md` (nur falls in Task 1 nicht schon alles stimmt)

- [ ] **Step 1: `docs/CLAUDE.md` aktualisieren**
  - „Sheets": ein Blatt = 8 nummerierte Zeilen (keine Challenge mehr; Rudiment/Groove/Fuß 16 Takte, Fill 32). `SheetPlan.sequence(r, selection, {repeats, start})` — eine Zeile in Schleife oder eine Folge (jede Zeile `repeats`-mal, Rundlauf), als **ein** Loop gespielt, ≤ 64 Takte (`maxSequenceBars`, Wiederholungen werden sonst verringert); `locate/locateTick` mit Slot, `stepOf`. Übungs-Screen: `LineView` (nur die aktuelle Zeile), Leiste `‹ Line 3 of 8 ›` bzw. `Sequence 2 of 4 · Line 5 · 1/2`, Vor/Zurück in der Folge dreht den Startpunkt; Routen `?lines=all|1,3,5` (1-basiert), `?line=N` als Alias, `?mode=` wird ignoriert; zuletzt geübte Zeile `SettingsService.lastLineFor`, Wiederholungen `SettingsService.sequenceRepeats` (Einstellungen → LINE SEQUENCES, 1–4, Standard 2); Log `sheetMode` = `line`/`sequence`. Neuer Absatz „Line list" (`/exercise/:rudimentId`, `LineListScreen`): Karten mit `SheetStaffWidget(onlyLine:)`, Tap = eine Zeile, langes Drücken/Select = Auswahl, „Play N lines" aufsteigend, „Play all", ⓘ = Info-Seite; Bibliothek öffnet sie für Mehrzeiler, Einzeiler/Sammlung direkt üben; Heute, Routine und Programm spielen alle Zeilen. Info-Seite: PATTERN · Legende · LESSON · „Start Practice" (= alle Zeilen).
  - „Navigation": `/exercise/:rudimentId → LineListScreen` ergänzen.
  - „Desktop (Linux)" ergänzen um **Lieferung**: Bundle auf dem **Laptop** bauen (NUC hat glibc 2.41, Laptop 2.35 — ein NUC-Bundle startet dort nicht):

```bash
ssh laptop
cd ~/agent-test-checkouts/drum_coach-etappe2-phase-b && git fetch && git checkout worktree-etappe2-phase-b && git pull --ff-only
~/development/flutter/bin/flutter build linux --release
rsync -a --delete build/linux/x64/release/bundle/ ~/drum-coach/
~/drum-coach/drum_coach        # Start; MIDI-Quelle erscheint, wenn das Modul per USB hängt
```
  Klick/Backing über die Soundkarte, Tastenkürzel Leertaste/↑↓/±/Esc; Windows ist ein eigener späterer Schritt.

- [ ] **Step 2: Volle Prüfung** — `flutter analyze` (13), `flutter test` grün (Zahl notieren), `cd tool/katalog && python3 -m unittest -q` grün.

- [ ] **Step 3: APK bauen** — `flutter build apk --debug && cp build/app/outputs/flutter-apk/app-debug.apk ~/drum-coach-zeilen.apk`.

- [ ] **Step 4: Emulator-Abnahme (Spec §5)** — NUC-Emulator `~/bin/emu-nuc.sh` (Gedächtnis „Android-Build + Emulator auf dem NUC"), APK installieren (`adb install -r`, auf `Success` prüfen), Screenshots nach `$CLAUDE_JOB_DIR/tmp/emu-zeilen/` und mit Read ansehen:
  1. Bibliothek → „Double Bass Eighths" → Zeilenliste mit 8 Karten, bis Karte 8 scrollen (`01_list_kit.png`, `02_list_kit_bottom.png`).
  2. Karte 3 antippen → Übungs-Screen zeigt nur Zeile 3, „Line 3 of 8", Start → Cursor läuft (`03_line3_running.png`), Stop.
  3. Zurück, lange drücken auf Karte 1, Karten 4 und 6 antippen → „3 selected", „Play 3 lines" → „Sequence 1 of 3 · Line 1 · 1/2"; laufen lassen bis „Sequence 2 of 3 · Line 4" und nach der letzten wieder „Sequence 1 of 3" (`04_seq_start.png`, `05_seq_step2.png`, `06_seq_wrap.png`).
  4. Pad: „Single Stroke Roll" → Zeilenliste, keine Challenge, 8 Karten (`07_list_pad.png`).
  5. Heute → „Continue the path" Start → Übungs-Screen mit „Sequence 1 of 8 · …" (`08_today_all.png`; ohne Programm: Routine-Schritt).
  6. Einstellungen → LINE SEQUENCES (`09_settings.png`).

- [ ] **Step 5: Commit**

```bash
git add docs/CLAUDE.md tool/katalog/README.md
git commit -m "docs(Zeilen): CLAUDE.md Zeilenliste, Zeilenfolge, Routen, Linux-Lieferung vom Laptop"
```

- [ ] **Step 6: Übergabe an den Controller** — Linux-Release-Build und Kopie nach `~/drum-coach/` auf dem Laptop führt der Controller aus (Befehle aus Step 1), danach Sichtprüfung dort: Start, Zeilenliste, Üben mit Leertaste/Esc.

---

## Self-Review (erledigt)

- **Spec-Abdeckung:** §3.1 Zeilenliste → Task 5 (Kopf, Karten, Tap, Auswahl, Play all, Markierung, Info ohne THE SHEET); §3.2 Ein-Zeilen-Screen → Task 4 (Ansicht), Task 3 (Kopfzeile, Einzelzeile/Folge, n-fach, Rundlauf, Vor/Zurück, `?lines=`, `?line=`-Alias, `mode`/Blatt-Position weg); Vorschau der nächsten Zeile bewusst weggelassen (Spec erlaubt es); §3.3 Challenge weg → Task 1; §3.4 Heute/Routine/Programm → Task 3 (`lines=all`), Fortschritt unverändert; §3.5 Desktop-Lieferung → Task 6 (Doku + Controller-Build), Breite über `capContentWidth`; §5 Abnahme → Task 6 Step 4 + Tests in Task 2/3/5; §6 Antworten → Global Constraints.
- **Typen:** `SheetPlan.sequence(r, selection, {repeats, start})`, `stepOf`, `locate*` mit `slot` (Task 2) werden in Task 3/4 so benutzt; `initialLineSelection`, `linesQuery`, `lineNavLabel`, `sessionLogSheetFields` (Task 3) in Task 3/5; `lastLineFor/setLastLine/sequenceRepeats` (Task 3) in Task 4/5; `onlyLine` (Task 4) in Task 5.
- **Grenze 64 Takte** begründet (WAV-Loop, Backing-Grenze) und getestet.
