# Übungsansicht im Drumeo-Look (Teil 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vorschau und Spielbildschirm der geführten Übungen im Look von Entwurf A (Bühne mit ganzem Foto oben, weißes Notenblatt mit zwei Seiten à vier ausgeschriebenen Takten, Steuerleiste unten) und die 8 Übungen mit ausgeschriebenen Vier-Takt-Zeilen.

**Architecture:** Der Katalog bekommt Vier-Takt-Zeilen, Vier-Takt-Abschnitte und Kurznamen (Python-Werkzeug → generiertes Dart). Eine reine Seiten-Logik (`guided_pages.dart`) schneidet aus Abschnitt und Laufposition die aktuelle und die nächste Seite. Zwei neue Widgets — `GuidedStage` (Foto-Bühne) und `GuidedPageView` (eine Seite, immer eine Zeile, auf Weiß) — ersetzen in beiden Bildschirmen die bisherige Anordnung; Ablaufplan, Player und Klang bleiben bis auf die Verlängerung in ganzen Phrasen unverändert.

**Tech Stack:** Flutter (Linux-Desktop), Dart 3, flutter_test + Goldens; Python 3 (tool/katalog, tool/stimme/Piper).

**Spec:** `docs/superpowers/specs/2026-10-29-uebungsansicht-trainingsraum-design.md` (nur Teil 1). Entwürfe: https://claude.ai/artifact/QpGrbCgaEnnW8S8z7RCrYA (Entwurf A).

## Global Constraints

- Branch `spec-trainingsraum` (gestapelt auf `spec-gefuehrte-uebungen`, PR #36). Draft-PR #37.
- Nur Linux-Desktop bauen und abnehmen (PC 2560×1440, Laptop wenn erreichbar); Handy-Layout darf nicht brechen (412×915-Tests laufen weiter). Keine APK.
- UI-Texte Englisch. Akzentfarbe der App bleibt `#FF6A2B`; Laufstrich auf dem Notenblatt **blau, halbtransparent** (`Color(0xBF3A8DDE)`).
- Notenblatt: Weiß `#FFFFFF`, schwarze Noten, keine Karten/Rahmen/Schatten je Takt.
- Bühnen-Foto: Ausschnitt **4:3**, volle Bühnenhöhe, mittig; links/rechts dieselbe Datei weichgezeichnet und abgedunkelt; kein Schleier über dem 4:3-Foto.
- Seitengröße: **4 Takte** (breit), **2 Takte** (schmal, < 1000 px). Seiten zählen ab Abschnittsbeginn.
- Katalog: Groove- und Variationsabschnitte Vielfache von 4 Takten; Outro 1 Takt; Verlängerung für die Ansage nur in ganzen 4-Takt-Phrasen; Gesamtdauer je Übung bei Standardtempo höchstens ±10 % gegenüber heute.
- Generierte Dateien (`guided_catalog.dart`, `tool/stimme/saetze_gefuehrt.py`) nie von Hand bearbeiten; `gen_gefuehrt.py` + `dart format`.
- Normale Übungen (`PracticeSessionScreen`, `LineView`-Standardverhalten) bleiben unverändert; neue Parameter sind opt-in mit bisherigem Standard.
- Flutter-Tests und `flutter analyze` laufen auf dem NUC; Linux-Bundle auf der Zielmaschine selbst bauen (PC: laufende App mit `pkill -x drum_coach` beenden, nie `pkill -f` mit Pfad).

## Review Focus

1. **Tempowechsel mitten im Abschnitt** (Pfeiltasten während des Spielens): Seite und Laufstrich bleiben an derselben Stelle, kein Sprung auf eine andere Seite. → Test in Task 6.
2. **Teacher aus** (keine Verlängerung) und **Teacher an bei langsamstem Tempo** (Verlängerung): jede Seite ist eine ganze Phrase, die letzte Seite eines Abschnitts endet mit dem Abschnitt. → Test in Task 2 + Task 3.
3. **Pad-Übungen mit Triolen und Vorschlägen** (Triplet Flams and Drags, Fives and Sixes): Seitenschnitt an Taktgrenzen verliert keine Note und keinen Vorschlag; Sticking-Buchstaben bleiben. → Test in Task 3.
4. **Vor dem Start, im Einzähltakt, pausiert**: obere Zeile zeigt die erste Groove-Seite ohne laufenden Strich; nichts wirft. → Test in Task 3 + Task 6.
5. **Fenstergröße ändern während des Spielens** (breit ↔ schmal, 4 ↔ 2 Takte pro Seite): kein Absturz, Laufstrich auf der richtigen Seite. → Test in Task 6.

---

### Task 1: Katalog-Form — Vier-Takt-Abschnitte, mehrtaktige Zeilen, Kurznamen

**Files:**
- Modify: `tool/katalog/gefuehrt_blatt.py`, `tool/katalog/gen_gefuehrt.py`, `tool/katalog/gefuehrt.py` (nur Längen + Titel, Noten unverändert), `tool/katalog/test_gefuehrt.py`
- Modify: `lib/features/guided/models/guided_exercise.dart`
- Regenerate: `lib/features/guided/data/guided_catalog.dart`, `tool/stimme/saetze_gefuehrt.py`
- Test: `test/guided/guided_exercise_test.dart`, `test/guided/guided_catalog_test.dart`

**Interfaces:**
- Produces (Python): `Variation(line, text, after='after_good', title=...)` — neues Pflichtfeld `title: str` (2–5 Wörter, ASCII). `GuidedSheet`: Zeilen von **1, 2 oder 4** Takten; `groove_bars % 4 == 0`, `variation_bars % 4 == 0`.
- Produces (Dart): `GuidedSection.titleEn` (`String?`); `GuidedExercise.validate()` prüft zusätzlich: Groove/Variation `bars % 4 == 0`; Zeilenlänge in Takten ∈ {1, 2, 4}; Variation braucht nicht-leeres `titleEn`.
- Produces: `const int guidedPhraseBars = 4;` in `guided_exercise.dart`.

- [ ] **Step 1: Failing Python tests** in `test_gefuehrt.py`: `test_variation_needs_title` (leerer/fehlender Titel → ValueError mit „title“), `test_title_word_limit` (6 Wörter → ValueError), `test_section_bars_multiple_of_four` (`variation_bars=18` → ValueError „multiple of 4“), `test_four_bar_line_accepted` (Groove als 4-Takt-Zeile wird geparst), `test_three_bar_line_rejected`, `test_catalog_durations_within_ten_percent` (für jede der 8 Übungen: `bars(s) * 240 / default_bpm` liegt innerhalb ±10 % des heutigen Werts — die heutigen Sekunden als Tabelle im Test festhalten, vor dem Ändern von `gefuehrt.py` aus `print_table` abgelesen).
- [ ] **Step 2:** `python3 -m pytest tool/katalog/test_gefuehrt.py -q` → FAIL.
- [ ] **Step 3:** `gefuehrt_blatt.py`: Feld `title` + Prüfungen; `_parse` erlaubt `ln.bars in (1, 2, 4)`; die Groove-Regel „exactly 1 bar“ wird zu „1, 2 or 4 bars“ (das Outro spielt Takt 1 der Zeile); 2-/4-Takt-Variationen brauchen `variation_bars % ln.bars == 0`. `gen_gefuehrt.py` schreibt `titleEn:`. `gefuehrt.py`: Längen auf das nächste Vielfache von 4 runden (18→20, 10→12 usw.), jede Variation bekommt einen `title` (z. B. „Kick on the and of three“).
- [ ] **Step 4:** Python-Tests → PASS. `python3 tool/katalog/gen_gefuehrt.py .` und `dart format lib/features/guided/data/guided_catalog.dart`.
- [ ] **Step 5: Failing Dart tests** in `guided_exercise_test.dart`: `validate rejects groove bars not multiple of 4`, `validate rejects variation without titleEn`, `validate rejects a 3-bar line`, `validate accepts a 4-bar line`. In `guided_catalog_test.dart`: `every catalog section is a whole phrase` (Groove/Variation `bars % guidedPhraseBars == 0`), `every variation has a short title of 2-5 words`.
- [ ] **Step 6:** Modell + `validate()` anpassen; `demo_exercise.dart` ggf. mitziehen (eigene Längen auf Vielfache von 4, Titel ergänzen), damit `demo_exercise_test` grün bleibt.
- [ ] **Step 7:** `flutter test test/guided` → PASS; `flutter analyze` sauber.
- [ ] **Step 8: Commit** `feat(gefuehrt): Vier-Takt-Abschnitte, mehrtaktige Zeilen, Kurznamen je Variation`

### Task 2: Ablaufplan — Verlängerung in ganzen Phrasen

**Files:**
- Modify: `lib/features/guided/run_plan.dart` (`buildRun`, Abschnitt `bars = math.max(bars, lead + afterBars + 1)`)
- Test: `test/guided/run_plan_test.dart`

**Interfaces:**
- Consumes: `guidedPhraseBars` (Task 1).
- Produces: unverändertes `buildRun`-API; ein verlängerter Groove hat `bars` = nächstes Vielfaches von `guidedPhraseBars` ≥ benötigte Takte; `explanationBar` bleibt relativ zum Abschnittsende (`bars - 1 - lead`).

- [ ] **Step 1: Failing tests:** `extension rounds up to whole phrases` (Testübung mit Groove 4 Takte, Clip-Manifest so, dass `lead + afterBars + 1 == 5` → Abschnitt hat 8 Takte, Erklärung in Takt `8 - 1 - lead`, Countdown im letzten Takt); `catalog runs keep whole phrases` (für alle 8 Übungen, bei `minBpm`, `defaultBpm`, `maxBpm`, Teacher an und aus, mit dem echten `assets/voice/manifest.json`: jede Groove-/Variations-Abschnittslänge im Plan ist `% 4 == 0`, Outro 1).
- [ ] **Step 2:** `flutter test test/guided/run_plan_test.dart` → FAIL.
- [ ] **Step 3:** Rundung auf `guidedPhraseBars` einbauen.
- [ ] **Step 4:** → PASS; `flutter test test/guided` komplett grün.
- [ ] **Step 5: Commit** `feat(gefuehrt): Ansage-Verlängerung nur in ganzen Vier-Takt-Phrasen`

### Task 3: Seiten-Logik (rein)

**Files:**
- Create: `lib/features/guided/guided_pages.dart`
- Test: `test/guided/guided_pages_test.dart`

**Interfaces:**
- Consumes: `GuidedExercise`, `ExerciseLine`, `NoteGrid`, `RunPosition` (`run_clock.dart`), `GuidedSectionTime` (`guided_run_controller.dart`: `({int sectionIndex, int bars, double ms})`), `runTicksPerBar`.
- Produces:
  - `ExerciseLine pageLine(ExerciseLine line, NoteGrid grid, {required int firstBar, required int bars})` — die Takte `firstBar .. firstBar+bars-1` der zyklisch wiederholten Zeile als neue Zeile mit `repeat: false`; Kit-Zeilen je Stimme geschnitten; wirft `ArgumentError`, wenn eine Note (inkl. Tuplet-Gruppe) über eine Taktgrenze reicht. Vorschläge (Flam/Drag) bleiben an ihrer Hauptnote.
  - `class GuidedPage { final int sectionIndex; final int firstBar; final int bars; final ExerciseLine line; }` (const, `==`/`hashCode` über die drei Zahlen).
  - `({GuidedPage now, GuidedPage? next}) guidedPagesAt(GuidedExercise ex, List<GuidedSectionTime> plan, RunPosition? pos, {required int pageBars})` — `now` = Seite mit `barInSection` in `[firstBar, firstBar+bars)` des laufenden Abschnitts; Seitenlänge `min(pageBars, sectionBars - firstBar)` (Outro: 1 Takt); `next` = folgende Seite im selben Abschnitt oder Seite 0 des nächsten Abschnitts mit Noten; `null` nach dem Outro. Ohne Position, im Einzähltakt (`sectionIndex < 0`) oder in einem leeren Intro: `now` = Seite 0 des ersten Grooves. Abschnittslängen kommen aus `plan` (verlängerte Grooves!), fehlt ein Eintrag, aus `section.bars`.
  - `int? guidedPageTick(GuidedPage page, RunPosition? pos)` — `(barInSection - firstBar) * runTicksPerBar + tick`, wenn `pos` in dieser Seite liegt, sonst `null`.
  - `List<GuidedPage> guidedPreviewPages(GuidedExercise ex, {required int pageBars})` — erster Groove, dann jede Variation in Reihenfolge, je Seite 0.

- [ ] **Step 1: Failing tests:** `pageLine repeats a 1-bar line to 4 bars`, `pageLine takes bars 2-3 of a 4-bar kit line per voice`, `pageLine keeps triplets and flams of Triplet Flams and Drags` (Notenzahl und Vorschläge = Summe der Takte), `pageLine rejects a note crossing a bar line`, `pages at count-in show the first groove without tick`, `page turns at bar 4 of a 8-bar section`, `last page of an extended groove ends with the section` (plan sagt 12 Takte bei `section.bars == 8` → Seiten 0/4/8, Seite 8 hat 4 Takte), `next of a groove's last page is the variation's first page`, `outro page has 1 bar and no next`, `pageBars 2 halves the pages` (Review Focus 5), `preview pages are groove plus each variation`.
- [ ] **Step 2:** `flutter test test/guided/guided_pages_test.dart` → FAIL.
- [ ] **Step 3:** Implementieren. Taktgrenzen über die kumulierten Ticks (`ticksOf` je Note, Tuplets als Gruppe).
- [ ] **Step 4:** → PASS.
- [ ] **Step 5: Commit** `feat(gefuehrt): Seiten-Logik für ausgeschriebene Vier-Takt-Seiten`

### Task 4: `GuidedPageView` — eine Seite, eine Zeile, auf Weiß

**Files:**
- Create: `lib/features/guided/widgets/guided_page_view.dart`
- Modify: `lib/shared/widgets/notation_staff_widget.dart` (Laufstrich-Farbe als Parameter `playheadColor`, Standard `AppColors.accent`), `lib/features/practice/widgets/line_view.dart` (durchreichen)
- Test: `test/guided/screens/guided_page_view_test.dart`, Golden `test/goldens/guided_page_kit_wide.png`, `guided_page_pad_wide.png`

**Interfaces:**
- Consumes: `GuidedPage`, `guidedPageTick` (Task 3), `rudimentForGuidedLine`, `LineView`, `computeSheetGeometry`.
- Produces: `GuidedPageView({required GuidedExercise exercise, required GuidedPage page, int? activeTick, bool dimmed = false, double? maxStaffHeight})`. Zeichnet die Seite **immer in genau einer Reihe** über die volle Breite (`fillWidth: true`): Layout-Breite so groß wählen, dass `rowCount == 1`, dann per `FittedBox` auf die verfügbare Breite und höchstens `maxStaffHeight` skalieren. Eine kürzere Seite (Outro, 1 Takt) bekommt die Taktbreite einer vollen Seite, links bündig. Hell gezeichnet (`Theme(data: drumCoachTheme)` um die Notation → schwarze Noten), Laufstrich `CursorStyle.line` in `Color(0xBF3A8DDE)`, keine Notenfärbung, `dimmed` = Deckkraft 0,38. Kein Wiederholungszeichen, keine Zeilennummer.
- Produces: `const guidedPlayheadBlue = Color(0xBF3A8DDE);`

- [ ] **Step 1: Failing tests:** `four-bar kit page is one row at 2560 and 1920` (über `GuidedLineView.naturalHeightAt`-ähnliche Geometrie oder Finder auf die eine `SheetStaffWidget`-Reihe), `page staff is not drawn below natural size at 1920 wide`, `outro page bar has the width of a full page bar`, `playhead is blue and moves with activeTick`, `no note is coloured`, `dimmed page has opacity 0.38`, `practice LineView playhead stays accent` (Standard unverändert). Goldens `guided_page_kit_wide` (Funk Sixteenths V2, 1920 breit) und `guided_page_pad_wide` (Triplet Flams V2).
- [ ] **Step 2:** → FAIL.
- [ ] **Step 3:** Implementieren.
- [ ] **Step 4:** → PASS; Goldens erzeugen (`--update-goldens`) und ansehen (Read der PNGs): eine Reihe, vier Takte, schwarz auf weiß, keine Wiederholungszeichen.
- [ ] **Step 5: Commit** `feat(gefuehrt): Seitenansicht – vier Takte in einer Zeile, schwarz auf weiß, blauer Laufstrich`

### Task 5: `GuidedStage` — Foto-Bühne mit 4:3-Ausschnitt

**Files:**
- Create: `lib/features/guided/widgets/guided_stage.dart`
- Modify: `lib/features/practice/backdrop.dart` (Ausrichtungstabelle)
- Create: `tool/backdrop_focus_sheet.py` (Kontaktbogen der 36 Fotos im 4:3-Ausschnitt mit den Tabellenwerten)
- Test: `test/guided/screens/guided_stage_test.dart`

**Interfaces:**
- Produces: `double backdropFocusY(String asset)` in `backdrop.dart` — vertikale Ausrichtung −1..1 aus `const Map<String, double> backdropFocus` (Schlüssel = Asset-Pfad), Standard `-0.2`.
- Produces: `GuidedStage({required String photo, required Widget child})` — `Stack`: (1) Foto `BoxFit.cover`, `ImageFiltered` Blur σ 24, darüber `Color(0x8C000000)`; (2) mittig das Foto in `AspectRatio(4/3)` über die volle Höhe (bei zu schmaler Bühne volle Breite, dann höher als 4:3 beschnitten), `BoxFit.cover`, `Alignment(0, backdropFocusY(photo))`, `errorBuilder` → leer; (3) Verlauf nur oben (`0x99000000` → transparent auf 30 % Höhe); (4) `child` (Overlays). Kein Schleier über (2).
- Produces: `GuidedBackdrop` bleibt für andere Nutzer erhalten.

- [ ] **Step 1: Failing tests:** `stage photo is 4:3 at full height when wide` (Bühne 2560×790 → Foto 1053×790), `stage photo takes full width when the stage is narrow`, `blurred copy fills the stage`, `missing photo still renders the stage` (Review Focus), `focus table default is -0.2`, `every practiceBackdrops entry has a focus value in -1..1` (Tabelle vollständig).
- [ ] **Step 2:** → FAIL.
- [ ] **Step 3:** Widget + Tabelle. Werte so wählen: `python3 tool/backdrop_focus_sheet.py <out.png>` erzeugt den Kontaktbogen; ansehen (Read), Werte je Foto setzen, bis Kopf und Trommeln in jedem Ausschnitt ganz drin sind; Kontaktbogen nach `~/drum-coach-fotos-4zu3.png` auf dem NUC legen (für Ulis Abnahme).
- [ ] **Step 4:** → PASS.
- [ ] **Step 5: Commit** `feat(gefuehrt): Foto-Bühne mit 4:3-Ausschnitt und Ausrichtung je Foto`

### Task 6: Spielbildschirm im neuen Look

**Files:**
- Modify: `lib/features/guided/screens/guided_play_screen.dart` (`_wide`, `_narrow`, `_now`, `_banner`, `_header`, `_wideControls`)
- Modify: `lib/features/guided/widgets/guided_banner.dart` (Parameter `showLine`, Standard `true`; auf der Bühne `false`, die Noten der kommenden Variation stehen ja in der unteren Zeile)
- Test: `test/guided/screens/guided_play_test.dart`, Goldens `guided_play_desktop_2560.png`, `guided_play_desktop.png` (1920×1080), `guided_play_desktop_variation.png`, `guided_play_phone.png`, `guided_play_phone_variation.png`

**Interfaces:**
- Consumes: `GuidedStage` (Task 5), `GuidedPageView` + `guidedPlayheadBlue` (Task 4), `guidedPagesAt` / `guidedPageTick` (Task 3), `_run.plan`, `GuidedTimelineBar`, `TempoRow`, `_ToggleChip`, `GuidedKeyHint`.
- Produces: Breites Layout (≥ 1000) als `Column`: **Bühne** (`Key('guided-stage')`, Rest-Höhe), **Notenblatt** (`Key('guided-sheet')`, weiß, volle Breite mit Gutter `AppSpacing.screenPadding`, Höhe so, dass zwei Seiten bei 1920×1080 in natürlicher Größe passen, Richtwert 38 %), **Steuerleiste** (`Key('guided-controls')`, dunkel, eine Zeile: Play/Pause + Stop, Zeit `m:ss`, `GuidedTimelineBar` als `Expanded`, `~m:ss`, Tempo, Teacher, Play along, Tastenhinweis).
  - Bühnen-Overlays: oben links Paket · Stufe (Akzentfarbe, Großbuchstaben), Name, Statuszeile (`guidedSectionLine`); oben rechts `Bar 3 / 8` (`Key('guided-bar-count')`, Takt im Abschnitt / Abschnittslänge aus dem Plan) und darunter `Coming up: <titleEn>` (`Key('guided-coming-up')`, nur wenn die nächste Variation bevorsteht); Zurück-Knopf oben links vor dem Titel; Lehrer-Banner (`showLine: false`) und Countdown unten mittig.
  - Notenblatt: Beschriftung über jeder Seite: oben `Now · Groove` / `Now · Variation 2 · <titleEn>` / `Now · Ending` / im Einzähltakt `Count-in`; unten `Next · …` gleich aufgebaut (`Key('guided-label-now')`, `Key('guided-label-next')`); obere Seite mit `activeTick`, untere `dimmed`. Seitenwechsel ohne Scrollen; höchstens `AnimatedSwitcher` ≤ 150 ms.
  - Ende-Ansicht (`_EndView`): Inhalt unverändert, Hintergrund jetzt `GuidedStage` mit demselben Foto statt `GuidedBackdrop`.
  - Schmales Layout: Bühne als Streifen (30 % Höhe) mit Titel, darunter dieselben zwei Seiten mit `pageBars: 2`, Steuerung wie heute unten; die bestehenden Keys (`guided-play-toggle`, `guided-play-stop`, `guided-teacher`, `guided-along`, `guided-timeline`, `guided-time`, `guided-status`, `guided-countdown`, `guided-banner`) bleiben erhalten.

- [ ] **Step 1: Failing tests:** `wide play shows stage, sheet and controls in that order`, `sheet spans the window width minus gutter at 2560` (≥ 2560 − 2·screenPadding − 1), `now and next pages show 4 bars each when wide`, `page turns when bar 5 of a section starts` (FakeGuidedPlayer-Position barInSection 3 → 4), `tempo change keeps the page and tick` (Review Focus 1: Position bleibt, `setBpm` → gleiche `GuidedPage`), `count-in shows the first groove page without playhead` (Review Focus 4), `paused keeps the page and freezes the playhead`, `resize from wide to narrow while playing shows 2-bar pages` (Review Focus 5), `coming up shows the variation title`, `bar count shows bar in section and section length from the plan`, `banner on the stage has no note line`, `photo is not covered by the sheet` (Bühnen-Rechteck und Notenblatt-Rechteck überlappen nicht). Phone-Tests 412×915 bleiben grün.
- [ ] **Step 2:** → FAIL.
- [ ] **Step 3:** Umbau.
- [ ] **Step 4:** → PASS; Goldens neu erzeugen und ansehen (2560, 1920, Variation mit Banner, Phone).
- [ ] **Step 5: Commit** `feat(gefuehrt): Spielbildschirm im Drumeo-Look – Bühne, Notenblatt mit zwei Seiten, Steuerleiste`

### Task 7: Vorschau im neuen Look

**Files:**
- Modify: `lib/features/guided/screens/guided_preview_screen.dart`
- Test: `test/guided/screens/guided_preview_test.dart`, Goldens `guided_preview_desktop.png`, `guided_preview_phone.png`

**Interfaces:**
- Consumes: `GuidedStage`, `GuidedPageView`, `guidedPreviewPages`.
- Produces: Breit: **Bühne** (Rest-Höhe, mindestens 45 %) mit Zurück, Paket · Stufe, Name, Beschreibung, `~m:ss`, und rechts unten in der Bühne die Einstellungen (Tempo, Teacher, Play along) und der Start-Knopf (`Key('guided-start')` wie heute); **Notenblatt** darunter (weiß, scrollt in sich, `Key('guided-preview-sheet')`): je Seite aus `guidedPreviewPages(pageBars: 4)` eine Beschriftung `Groove · 8 bars` bzw. `Variation 1 · <titleEn> · 20 bars` (Taktzahl = `section.bars`) und die `GuidedPageView` ohne Laufstrich. Schmal: wie heute, aber Noten als `GuidedPageView` mit `pageBars: 2`. Tastenkürzel unverändert.

- [ ] **Step 1: Failing tests:** `preview sheet lists groove and every variation once`, `variation label shows title and bars`, `sheet scrolls, stage stays` (bei 1366×768 mit 5 Variationen), `start keeps tempo and switches` (bestehender Test bleibt), Phone-Test bleibt.
- [ ] **Step 2:** → FAIL.
- [ ] **Step 3:** Umbau.
- [ ] **Step 4:** → PASS; Goldens neu und ansehen.
- [ ] **Step 5: Commit** `feat(gefuehrt): Vorschau im Drumeo-Look – Bühne mit Einstellungen, ganze Übung als Notenblatt`

### Task 8: Inhalte — die 8 Übungen ausgeschrieben + Kuration

**Files:**
- Modify: `tool/katalog/gefuehrt.py` (alle 8 Übungen), `tool/katalog/build_gefuehrt_page.py` (Titel je Variation anzeigen, 4-Takt-Zeilen in einer Reihe)
- Regenerate: `guided_catalog.dart`, `tool/stimme/saetze_gefuehrt.py`, `assets/voice/*.wav` + `manifest.json` (nur geänderte Sätze, `render_clips.py --only …`)
- Test: `tool/katalog/test_gefuehrt.py`, `test/guided/guided_catalog_test.dart`, `test/guided/voice_assets_test.dart`

**Interfaces:**
- Consumes: Katalog-Form aus Task 1.
- Produces: jede Groove- und Variationszeile ist eine **4-Takt-Zeile**: Takt 1–3 die Figur bzw. eine verwandte Abwandlung, Takt 4 eine kleine Steigerung (zusätzliche Bassdrum, Ghost Note, Akzentverschiebung, kurzer Fill-Ansatz). Stufe, Tempo-Spanne, Charakter und Variationsfolge jeder Übung bleiben. `text` nur ändern, wenn sich die Variation inhaltlich ändert (dann neuer Clip). Die Regeln aus `check_hands` gelten.

- [ ] **Step 1: Failing tests:** `test_every_line_is_four_bars` (alle Groove-/Variationszeilen `bars == 4`), `test_bar_four_differs` (Takt 4 jeder Zeile unterscheidet sich von Takt 1 in mindestens einer Note). Dart: `catalog lines are four bars`.
- [ ] **Step 2:** → FAIL.
- [ ] **Step 3:** Zeilen schreiben; `gen_gefuehrt.py`; geänderte Sätze rendern (`tool/stimme/.venv/bin/python tool/stimme/render_clips.py --only <ids>`); `dart format`.
- [ ] **Step 4:** Python- und Flutter-Tests → PASS (inkl. `catalog runs keep whole phrases` aus Task 2 und Dauer ±10 % aus Task 1).
- [ ] **Step 5:** Kurationsseite bauen: `python3 tool/katalog/build_gefuehrt_page.py ~/gefuehrt-kuration-4takte.html`; dem Controller melden (er veröffentlicht sie für Uli).
- [ ] **Step 6: Commit** `feat(gefuehrt): acht Übungen als Vier-Takt-Zeilen mit Steigerung in Takt 4`

### Task 9: Lieferung

- [ ] **Step 1:** `flutter test` (alles) und `flutter analyze` auf dem NUC → grün; Push.
- [ ] **Step 2:** PC: Checkout aktualisieren (`git fetch && git reset --hard origin/spec-trainingsraum`), `flutter build linux --release`, laufende App mit `pkill -x drum_coach` beenden, Bundle installieren, mit `DISPLAY=:0` starten; Bildschirmfoto von Vorschau und Spielbildschirm (ffmpeg x11grab, 5120×1440-Schirm → linke Hälfte) prüfen.
- [ ] **Step 3:** Laptop, falls erreichbar, ebenso (Bundle dort bauen).
- [ ] **Step 4:** Bericht `docs/BERICHT_GEFUEHRT_DRUMEO_LOOK.md` (was gebaut, Bildschirmfotos-Pfade, Kontaktbogen `~/drum-coach-fotos-4zu3.png`, Kurationsseite, offene Punkte); Commit `docs(gefuehrt): Bericht Drumeo-Look`; Push.
