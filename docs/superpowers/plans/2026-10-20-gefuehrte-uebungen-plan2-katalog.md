# Geführte Übungen — Plan 2 „Katalog + Runde 1" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein Katalog-Werkzeug, das geführte Übungen aus einer kleinen Python-Notation als Dart (`guidedCatalog`) und als englische Sprach-Clips erzeugt, eine Kurationsseite für Uli, und Runde 1 mit 8 Übungen (Set + Pad, je eine pro Schwierigkeit), hörbar auf der Hörprobe-Seite.

**Architecture:** Wie Katalog 3a/3b: die Inhalte stehen einmal in `tool/katalog/gefuehrt.py` (Tokens aus `sheetlang.py`), `gen_gefuehrt.py` schreibt daraus `lib/features/guided/data/guided_catalog.dart` und `tool/stimme/saetze_gefuehrt.py`; `render_clips.py` rendert die Clips; `build_gefuehrt_page.py` baut die Kurationsseite (abcjs wie `build_page.py`). Die Hörprobe-Seite bekommt eine Auswahl aus Demos + Katalog.

**Tech Stack:** Python 3 (unittest wie `tool/katalog/test_kit.py`), Piper über `tool/stimme`, Dart/Flutter (Tests unter `test/guided/`).

**Spec:** `docs/superpowers/specs/2026-10-17-gefuehrte-uebungen-design.md` (§3.1, §3.2, §3.9, §4 Punkt 6). Plan 1: `docs/superpowers/plans/2026-10-18-gefuehrte-uebungen-plan1-klang.md` (gebaut). Bildschirme/Messung = Plan 3.

## Global Constraints

- Ablauf je Übung (Spec §3.1): Intro (0 Takte) · Groove · V1 · Groove · V2 · … · Groove · Outro (1 Takt); jede Variation steht zwischen zwei Grooves; 3–5 Variationen.
- Länge 5 min ± 1 bei Standardtempo (Test: 4–6 min, wie `demo_exercise_test`).
- Nur 4/4, ganze Takte; Set-Zeilen bestehen `check_hands` (`sheetlang.py`).
- Texte Englisch, ein Text je Erklärung = angezeigt und gesprochen; kurz, konkret, freundlich, Erklärung ≤ 4 s gesprochen (Test ≤ 4500 ms).
- Inhalte komponiert, nicht kopiert; gegen Langeweile: musikalische Stile, je Übung ein roter Faden (Spec §3.9).
- Generierte Dateien nie von Hand ändern; nach dem Erzeugen `dart format` (tool/katalog/README.md).
- Clip-IDs der Katalog-Erklärungen: `g_<exercise_id>_v<n>` (n ab 1); Übergangssätze nutzen die vorhandenen `after_good`.
- Stimme bleibt `en_GB-cori-high` (Ruling R14 Plan 1).
- `Difficulty`-Werte: `beginner | intermediate | advanced | professional`; Paket `kit | pad`.

## Review Focus

1. **Übung beim Höchsttempo**: Erklärung bei `max_bpm` länger als die Relax-Phase → `buildRun` verlängert; Gesamtdauer bei `max_bpm` und `min_bpm` bleibt spielbar (≤ 9 min bei `min_bpm`). → Test in Task 2 (`catalog plays at min and max bpm`).
2. **Erklärung zu lang** (zu viele Wörter): Clip > 4500 ms → Test schlägt mit Übungs-ID fehl. → Task 3.
3. **Verwaiste Clips**: Übung umbenannt/entfernt → alte `g_*`-WAVs bleiben im Asset-Ordner. → Task 3 `render_clips.py --prune-prefix g_` + Test.
4. **Doppelte IDs / Kollision mit Demos** (`demo_*`, Clip-IDs). → Test in Task 1 (`check_catalog rejects duplicate ids`).
5. **Generator nicht idempotent** (zweiter Lauf ändert Dateien). → Test in Task 2 (`second run writes identical files`).

---

### Task 1: Notation `GuidedSheet` + Prüfung

**Files:**
- Create: `tool/katalog/gefuehrt_blatt.py`
- Test: `tool/katalog/test_gefuehrt.py` (unittest, Lauf: `cd tool/katalog && python3 -m unittest test_gefuehrt -v`)

**Interfaces:**
- Consumes: `sheetlang.parse_line(text, beats_per_bar=4, repeat=False)`, `sheetlang.parse_kit_line(text, ...)`, `sheetlang.check_hands(kl)`.
- Produces:
  ```python
  @dataclass(frozen=True)
  class Variation:
      line: str          # pad tokens or kit track text ("HH: …\nSN: …\nBD: …")
      text: str          # English explanation, shown and spoken
      after: str | None = 'after_good'   # clip after this variation; None for the last
  @dataclass(frozen=True)
  class GuidedSheet:
      id: str; name: str; description: str
      package: str       # 'kit' | 'pad'
      difficulty: str    # beginner|intermediate|advanced|professional
      default_bpm: int; min_bpm: int; max_bpm: int
      grid: str          # NoteGrid name as in blatt.Sheet.grid ('eighth', 'sixteenth', 'triplet' …)
      groove: str
      variations: tuple[Variation, ...]
      groove_bars: int = 12; variation_bars: int = 24
      def parsed(self) -> tuple[object, list[object]]   # (groove line, variation lines), raises ValueError
      def clip_id(self, n: int) -> str                  # 'g_<id>_v<n>'
  def check_catalog(sheets: list[GuidedSheet]) -> None  # raises ValueError
  ```
  Rules in `parsed()`/`check_catalog`: package/difficulty in the allowed sets; `40 ≤ min_bpm ≤ default_bpm ≤ max_bpm ≤ 240`; 3–5 variations; every line parses as whole 4/4 bars (1 or 2 bars) on the sheet's grid; kit lines pass `check_hands`; last variation has `after=None`, others not None; text non-empty, ≤ 16 words, ASCII punctuation only (no emojis); ids unique, `[a-z0-9_]`, must start with `guided_`; no id starts with `demo_` (demo ids: `demo_kit_rock8`, `demo_pad_eighths`).
- [ ] **Step 1: Failing tests** `test_gefuehrt.py`: `test_valid_kit_and_pad_sheet_parse` (one small kit + one pad fixture → `parsed()` returns 1 groove + 3 variations); `test_rejects_two_variations_rule` (4 variations with last `after` set → ValueError mentioning `after`); `test_rejects_non_whole_bar_line` (`'R8 L8 R8'`); `test_rejects_hand_conflict_kit` (R on HH and SN same tick); `test_rejects_long_text` (17 words); `test_check_catalog_rejects_duplicate_ids`; `test_clip_id` (`guided_x`, 2 → `g_guided_x_v2`).
- [ ] **Step 2: Run** → FAIL (module missing).
- [ ] **Step 3: Implement** `gefuehrt_blatt.py`.
- [ ] **Step 4: Run** → PASS; also `python3 -m unittest -v` in tool/katalog (all old tests still green).
- [ ] **Step 5: Commit** `feat(katalog): Notation für geführte Übungen + Prüfung`

---

### Task 2: Generator `gen_gefuehrt.py` → `guided_catalog.dart` + Satzliste

**Files:**
- Create: `tool/katalog/gen_gefuehrt.py`, `tool/katalog/gefuehrt.py` (data module, Runde-1-Inhalte kommen in Task 5; hier zwei Fixture-Übungen aus `demo_exercise.dart` nachgebaut: `guided_kit_rock8` und `guided_pad_eighths`, gleiche Noten und Texte wie die Demos, damit Task 2 ohne neue Inhalte testbar ist)
- Create (generated): `lib/features/guided/data/guided_catalog.dart`, `tool/stimme/saetze_gefuehrt.py`
- Modify: `tool/stimme/saetze.py` (am Ende `from saetze_gefuehrt import GEFUEHRT; SAETZE.update(GEFUEHRT)` — Import robust gegen fehlende Datei), `tool/katalog/README.md` (Abschnitt „Geführte Übungen")
- Test: `tool/katalog/test_gefuehrt.py` (erweitert), `test/guided/guided_catalog_test.dart`

**Interfaces:**
- Consumes: Task 1; `sheetlang.line_to_dart`, `sheetlang.kit_line_to_dart`; Dart `GuidedExercise`, `GuidedSection`, `SectionKind`, `GuidedPackage`, `Difficulty`, `NoteGrid`, DSL `line`/`kitLine`/`voice`/`note`/`foot`/`rest` (`lib/features/lessons/data/etude_dsl.dart`).
- Produces:
  - CLI `python3 tool/katalog/gen_gefuehrt.py <repo_root>` writes both generated files, then the user runs `dart format lib/features/guided/data/guided_catalog.dart`.
  - Dart: `final List<GuidedExercise> guidedCatalog = [...]` in `guided_catalog.dart`, header `// GENERATED by tool/katalog/gen_gefuehrt.py from tool/katalog/gefuehrt.py — do not edit.` Sections spelled out (no private helpers): intro `ExerciseLine([])` 0 bars; per variation n: groove (`groove_bars`), variation (`variation_bars`, `textEn`, `speechClipId: clip_id(n)`, `afterClipId: after`); final groove; outro (groove line, 1 bar).
  - Python: `GEFUEHRT: dict[str, str]` in `saetze_gefuehrt.py` (clip id → text), header comment as above.
- [ ] **Step 1: Failing tests:** Python `test_generate_writes_catalog_and_sentences` (tmp dir: both files exist, Dart contains `guidedCatalog`, `g_guided_kit_rock8_v1`; sentences dict has one entry per variation); `test_second_run_writes_identical_files` (Review Focus 5). Dart `guided_catalog_test.dart`: `every catalog exercise validates`; `ids are unique and not demo ids`; `about five minutes at default bpm` (4–6 min via `buildRun` + bar lengths, as in `demo_exercise_test.dart`); `catalog plays at min and max bpm` (Review Focus 1: total at `minBpm` ≤ 9 min, at `maxBpm` ≥ 2.5 min, `buildRun` does not throw); `fixture equals demo notes` (guided_kit_rock8 sections' lines == demoKitExercise's, same for pad — proves the generator emits the same Dart).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** generator + data module with the two fixtures; run it; `dart format`.
- [ ] **Step 4: Run** Python tests and `flutter test test/guided/guided_catalog_test.dart` → PASS.
- [ ] **Step 5: Commit** `feat(katalog): Generator für geführte Übungen (guided_catalog.dart + Sätze)`

---

### Task 3: Clips für den Katalog + Aufräumen

**Files:**
- Modify: `tool/stimme/render_clips.py` (`--prune-prefix PREFIX`: entfernt Manifest-Einträge und WAVs mit diesem Präfix, deren ID nicht mehr in `SAETZE` steht), `tool/stimme/test_render_clips.py`, `tool/stimme/README.md`
- Create (generated): `assets/voice/g_*.wav`, Manifest aktualisiert
- Test: `test/guided/guided_catalog_test.dart` (erweitert)

**Interfaces:**
- Consumes: `render(out_dir, voice, only, synth, saetze, force) -> list[str]` (Plan 1 Task 6), `GEFUEHRT` (Task 2).
- Produces: `render(..., prune_prefix: str | None = None)`; CLI `--prune-prefix g_`.
- [ ] **Step 1: Failing tests:** pytest `test_prune_prefix_removes_stale_clips` (manifest with `g_old_v1` + wav, SAETZE without it → both gone; `demo_*` untouched); Dart `every catalog clip exists in the manifest`, `catalog textEn equals manifest text` (manifest `text` field), `explanations are at most 4500 ms` (Review Focus 2; failure message names the exercise id; at default bpm the planner's auto-extension must not add more than 2 bars per groove).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** `--prune-prefix`; run `tool/stimme/.venv/bin/python tool/stimme/render_clips.py --prune-prefix g_`.
- [ ] **Step 4: Run** pytest + `flutter test test/guided/` → PASS.
- [ ] **Step 5: Commit** `feat(stimme): Katalog-Clips + --prune-prefix`

---

### Task 4: Kurationsseite + Auswahl auf der Hörprobe-Seite

**Files:**
- Create: `tool/katalog/build_gefuehrt_page.py`
- Modify: `lib/features/guided/debug_guided_screen.dart` (Auswahl: statt `SegmentedButton` Kit/Pad ein Dropdown „Exercise" mit den zwei Demos und allen `guidedCatalog`-Einträgen, gruppiert Set/Pad, Anzeige `Name · Difficulty · ~m:ss`), `test/guided/debug_guided_screen_test.dart`
- Test: `tool/katalog/test_gefuehrt.py` (erweitert)

**Interfaces:**
- Consumes: Task 1/2, `build_page.py` (`KIT_LEGEND`, abcjs-Einbindung, CSS), `sheetlang.line_to_abc`, `sheetlang.kit_line_to_abc`, `assets/voice/manifest.json`.
- Produces: CLI `python3 tool/katalog/build_gefuehrt_page.py <out.html>`. Eine selbsttragende HTML-Datei: je Übung Kopf (Name, Set/Pad, Schwierigkeit, Tempo-Bereich, Dauer bei Standardtempo), Ablauf als Liste (Groove 12 · V1 24 · …), Noten von Groove und jeder Variation (abcjs 6.4.4, wie `build_page.py`), darunter `textEn` und ein `<audio>`-Element mit dem Clip als `data:audio/wav;base64` eingebettet; Notizfeld je Übung entfällt (Uli antwortet im Chat).
- [ ] **Step 1: Failing tests:** Python `test_page_contains_every_exercise_and_audio` (HTML enthält jede ID, je Variation ein `data:audio/wav;base64,`, abcjs-Script-Tag); Dart widget `exercise dropdown lists demos and catalog` (Fake-Player; Auswahl eines Katalog-Eintrags → `start` erhält diese Übung).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** Python + `flutter test test/guided/` → PASS; `flutter analyze` ohne neue Befunde.
- [ ] **Step 5: Commit** `feat(gefuehrt): Kurationsseite + Katalog-Auswahl auf der Hörprobe-Seite`

---

### Task 5: Runde 1 — 8 Übungen komponieren

**Files:**
- Modify: `tool/katalog/gefuehrt.py` (die zwei Fixtures aus Task 2 bleiben als `guided_kit_rock8`/`guided_pad_eighths` nur, wenn sie zur Runde passen; sonst ersetzen — dann den Dart-Test `fixture equals demo notes` auf „Demos unverändert" umstellen)
- Regenerate: `guided_catalog.dart`, `saetze_gefuehrt.py`, Clips (`--prune-prefix g_`)
- Create: `docs/BERICHT_GEFUEHRT_RUNDE1.md` (deutsch, einfach: was jede Übung übt, roter Faden, offene Fragen an Uli)

**Inhalt (Vorgabe, Feinheiten = Komponist):**

| Paket | Schwierigkeit | Stil / roter Faden | Tempo (min–std–max) |
|---|---|---|---|
| Set | beginner | Rock-Achtel; Bassdrum wandert (1·3 → +„3 und" → +„1 und") , letzte V: Crash auf 1 statt HH | 60–90–120 |
| Set | intermediate | Funk-Sechzehntel-Hi-Hat; Ghost Notes kommen dazu (2e, 4a), dann offene HH | 70–95–120 |
| Set | advanced | Half-Time-Shuffle (Triolen); Ghosts in den Triolen, Kick-Varianten | 60–80–100 |
| Set | professional | Linear-Groove (Sechzehntel, keine zwei Gliedmaßen gleichzeitig); Verschiebungen + Tom-Akzente | 70–90–110 |
| Pad | beginner | Achtel R L; Akzent auf 1 → auf 1 und 3 → wandernder Akzent | 60–90–130 |
| Pad | intermediate | Sechzehntel Singles; Doubles-Einschübe → Paradiddle → Paradiddle mit Akzenten | 60–85–120 |
| Pad | advanced | Triolen; Akzent-Verschiebung → Flams auf Akzenten → Drag-Einschübe | 60–80–110 |
| Pad | professional | Sechzehntel; Fünfer-/Sechser-Gruppierungen über den Takt (Akzente), dann Flam-Taps | 60–80–110 |

Regeln: 3–4 Variationen je Übung, steigernd; jede Erklärung sagt konkret, was sich ändert und wo („add the bass drum on the and of three"); Grooves 1 Takt, Variationen 1–2 Takte; Gruppen-/Abschnittslängen so, dass Standardtempo 4–6 min ergibt (ggf. `groove_bars`/`variation_bars` je Übung anpassen).

- [ ] **Step 1:** Inhalte in `gefuehrt.py` schreiben; `python3 tool/katalog/gefuehrt.py` druckt eine Tabelle (ID, Paket, Schwierigkeit, Variationen, Dauer) und ruft `check_catalog`.
- [ ] **Step 2:** Generieren, `dart format`, Clips rendern mit `--prune-prefix g_`.
- [ ] **Step 3: Run** `cd tool/katalog && python3 -m unittest -v`, `tool/stimme/.venv/bin/python -m pytest tool/stimme`, `flutter test` → alle PASS; `flutter analyze` ohne neue Befunde.
- [ ] **Step 4:** Kurationsseite bauen nach `~/gefuehrt-runde1.html`; Bericht schreiben; APK (NUC, versionCode 1) nach `~/gefuehrt-plan2.apk`; Emulator-Smoke: Hörprobe-Seite, eine Katalog-Übung 20 s, logcat ohne Fehler.
- [ ] **Step 5: Commit** `feat(katalog): geführte Übungen Runde 1 (8)`
- [ ] **Step 6: Gate (Controller):** Kurationsseite als Artifact veröffentlichen, APK aufs S23 (wenn verbunden) und Linux-Bundle auf dem Laptop; Uli kuratiert (streicht/ändert). Änderungen sind eine neue Runde, nicht Teil dieses Plans.

---

## Danach

Plan 3 (nach PR #35-Gerätetest): Liste „Guided" in der Bibliothek (Set | Pad), Vorschau, Übungs-Bildschirm (Noten, Banner, kommende Variation gedimmt), Kopfhörer-Regel, Pad-Messung + Auswertung je Abschnitt, Log. Danach Runden 2+ bis ~40 Übungen, Set-Messung (Etappe 2 Teil 2), Hintergrundband (eigene Spec), echte Schlagzeug-Samples statt synthetischem Kick/Hi-Hat (Befund 20.10. „klingt computergeneriert").
