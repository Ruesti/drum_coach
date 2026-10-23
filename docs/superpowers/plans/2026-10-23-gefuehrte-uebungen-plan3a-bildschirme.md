# Geführte Übungen — Plan 3a „Bildschirme (Desktop zuerst)" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die geführten Übungen bekommen echte Bildschirme — Eintrag „Guided" in der Bibliothek, Vorschau, Übungs-Bildschirm mit Noten, Ansage-Banner, Countdown und Abschluss — zuerst für den Linux-Desktop (breites Fenster, Tastatur), in der Optik der Handy-Übung, und so gebaut, dass dieselben Widgets auf Handy und Tablet tragen.

**Architecture:** Neue Screens unter `lib/features/guided/screens/`, wiederverwendete Bausteine aus `practice/` (Backdrop + Scrim, `TempoRow`, `_PrimaryButton`-Stil, `practiceShortcuts`) und `lessons/` (`SheetStaffWidget`/`LineView`, `AppBadge`). Ein Breakpoint-Helfer entscheidet zwischen **breit** (zwei Spalten: Noten links groß, Steuerung rechts) und **schmal** (eine Spalte wie die Handy-Übung). Der Spieler kommt unverändert aus `guidedRigProvider` (Plan 1). Keine Messung (Plan 3b, zweite Priorität — Uli 23.10.).

**Tech Stack:** Flutter/Dart, Riverpod, go_router, Widget-/Golden-Tests (`flutter test`, Fonts gebündelt).

**Spec:** `docs/superpowers/specs/2026-10-17-gefuehrte-uebungen-design.md` §3.6 (Liste/Auswahl), §3.7 (Übungs-Screen), §3.2 (Lehrer an/aus → Banner + Countdown), §4 (Abnahme). Ulis Vorgaben 23.10.: **nur Desktop bauen/testen**, **Optik vom Handy beibehalten**, **immer handy-/pad-tauglich**, **Messung zweitrangig**; „an was Schönes herantasten" → Optik-Runden mit Uli (Task 6).

## Global Constraints

- Optik = Handy-Übung: dunkles Übungs-Thema `drumCoachPracticeTheme`/`PracticeColors`, Backdrop-Foto (`nextBackdrop()`) mit Scrim (Werte aus `practice_session_screen.dart`: konfigurierend `0x26101010/0x66101010/0xD9101010`, spielend `0x4D101010/0x99101010/0xE0101010`), Akzent `#FF6A2B`, Space Grotesk / IBM Plex Mono, `AppSpacing`/`AppRadius` aus `design_tokens.dart`. Bibliothek bleibt hell (`AppColors`).
- Breakpoint: `guidedWide(width) = width >= 1000` (logische Pixel). Breit = zwei Spalten; schmal = eine Spalte. Jeder Screen muss bei 412×915 (Handy), 820×1180 (Tablet hoch) und 1280×800 (Desktop) ohne Überlauf rendern (Test).
- Content-Cap: Bibliothek und Vorschau bleiben im globalen Cap (`desktopContentMaxWidth` 900); der Übungs-Bildschirm nutzt die volle Fensterbreite bis 1440 (Opt-out vom Cap, Task 1).
- Desktop-Tasten auf Vorschau und Übung: Leertaste Start/Pause, ↑/↓ und +/− Tempo (±4, Shift ±8), T Teacher, P Play along, Esc zurück/stopp — über `practiceShortcuts`-Muster, Weiche nur `isDesktopPlatform` (`platform_support.dart`).
- Alle UI-Strings Englisch. Tempo im Bereich der Übung (`minBpm..maxBpm`).
- Spieler-API unverändert (`GuidedPlayer`, `RunPosition`, `RunOptions`); die versteckte Hörprobe-Seite `/debug/guided` bleibt.
- Neuer Code unter `lib/features/guided/screens/` bzw. `lib/features/guided/widgets/`, Tests unter `test/guided/screens/`.
- Gebaut/abgenommen wird nur der Linux-Desktop (Bundle auf dem Laptop, Checkout `~/agent-test-checkouts/drum_coach-guided`). Keine APK.

## Review Focus

1. **Fenster schmaler/breiter ziehen während die Übung läuft** (Desktop): Layout springt zwischen ein- und zweispaltig, Spieler läuft weiter, Cursor bleibt richtig. → Task 5 (`resizing while playing keeps the run`).
2. **Sehr lange Erklärung + schmales Handy**: Banner-Text bricht um, nichts läuft über. → Task 5 (`long variation text wraps at 412 wide`).
3. **Esc / Zurück während die Übung läuft**: Spieler stoppt, kein Ton läuft nach dem Verlassen weiter. → Task 5 (`leaving the screen stops the player`).
4. **Übung zu Ende**: Abschluss-Ansicht erscheint, Leertaste startet nicht ungewollt neu. → Task 5 (`finished shows the end view; space does not restart`).
5. **Katalog leer oder Übung-ID unbekannt** (Deep-Link `/guided/xyz`): freundliche Meldung statt Absturz. → Task 4 (`unknown id shows not found`).

---

### Task 1: Layout-Grundlage — Breakpoint, Cap-Opt-out, Backdrop-Gerüst

**Files:**
- Create: `lib/features/guided/widgets/guided_layout.dart`, `lib/features/guided/widgets/guided_backdrop.dart`
- Modify: `lib/main.dart` bzw. die Datei mit `capContentWidth` (Opt-out-Mechanismus), `lib/app/…` wo `desktopContentMaxWidth` liegt
- Test: `test/guided/screens/guided_layout_test.dart`

**Interfaces:**
- Produces:
  ```dart
  bool guidedWide(double width);                 // width >= 1000
  const double guidedMaxWidth = 1440;
  class UncappedContent extends StatelessWidget { const UncappedContent({required this.child}); }
  // capContentWidth leaves descendants of UncappedContent un-capped (route-level opt-out)
  class GuidedBackdrop extends StatelessWidget {
    const GuidedBackdrop({required this.playing, required this.child, this.photo});
    // Stack: practice backdrop photo (nextBackdrop() once per screen open), scrim with the
    // practice screen's configuring/playing values (AnimatedContainer), SafeArea child.
  }
  ```
- [ ] **Step 1: Failing tests:** `guidedWide boundary` (999 → false, 1000 → true); `uncapped content uses full width on desktop` (debugDesktopOverride, surface 1280×800: a `SizedBox.expand` inside `UncappedContent` reports width 1280, outside it 900 — mirror `test/app/content_width_cap_test.dart`); `backdrop scrim switches with playing` (finds `ValueKey('guided-scrim')`, gradient colors equal the practice values).
- [ ] **Step 2: Run** `flutter test test/guided/screens/guided_layout_test.dart` → FAIL.
- [ ] **Step 3: Implement.** The opt-out must not change capping anywhere else (existing `content_width_cap_test.dart` stays green).
- [ ] **Step 4: Run** test + `flutter test test/app/` → PASS.
- [ ] **Step 5: Commit** `feat(gefuehrt): Layout-Grundlage (Breakpoint, Cap-Opt-out, Backdrop)`

---

### Task 2: Noten einer geführten Zeile

**Files:**
- Create: `lib/features/guided/widgets/guided_line_view.dart`
- Test: `test/guided/screens/guided_line_view_test.dart`, Goldens `test/goldens/guided_line_*.png`

**Interfaces:**
- Consumes: `GuidedExercise`, `ExerciseLine`, `SheetStaffWidget`/`LineView` (take a `Rudiment`), `computeSheetGeometry`.
- Produces:
  ```dart
  Rudiment rudimentForGuidedLine(GuidedExercise ex, ExerciseLine line); // adapter: one-line sheet, kit/pad voicing, gridUnit
  class GuidedLineView extends StatelessWidget {
    const GuidedLineView({required this.exercise, required this.line,
      this.activeTick, this.dimmed = false, this.maxStaffHeight});
    // draws the line with the existing notation (kit: five lines; pad: sticking letters),
    // cursor at activeTick (null = no cursor), dimmed = 45 % opacity for "coming up";
    // fills the given width; on wide layouts the staff scales up to maxStaffHeight.
  }
  ```
  Adapter rule: reuse whatever the practice screen does to build a `Rudiment` for one line (`Rudiment.withSticking`, kit voices) — no second notation path.
- [ ] **Step 1: Failing tests:** `adapter keeps voices and grid` (kit line from `guidedCatalog` → rudiment `isKit`, one line, same tick length); goldens `guided_line_kit_wide.png` (width 760) and `guided_line_pad_narrow.png` (width 380) for the first catalog kit/pad exercise's V1 with cursor at tick 24; `dimmed renders at 45 %`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement**, `--update-goldens` once, look at the PNGs (report them). **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(gefuehrt): Notenansicht für geführte Zeilen`

---

### Task 3: Bibliothek — Umschalter „Exercises | Guided" und Guided-Liste

**Files:**
- Modify: `lib/features/lessons/lessons_screen.dart`
- Create: `lib/features/guided/widgets/guided_tile.dart`, `lib/features/guided/screens/guided_list.dart`
- Test: `test/guided/screens/guided_list_test.dart`, bestehende `test/…/lessons_screen*` grün halten

**Interfaces:**
- Consumes: `guidedCatalog`, `guidedExerciseLabel`-Formel (Dauer), `AppBadge`, `AppSelectableChip`, `Difficulty.label/.color`.
- Produces: unter dem Bibliotheks-Foto ein `SegmentedButton` **Exercises | Guided** (Zustand gemerkt in `SettingsService` o. ä., Standard Exercises). Guided zeigt: Filter-Chips **Set | Pad** (beide an = alle) und **Difficulty**; Liste gruppiert nach Schwierigkeit; `GuidedTile`: Name (subtitle-Stil), eine Zeile Beschreibung (muted), rechts `AppBadge('SET'|'PAD')`, Schwierigkeits-Badge, `~m:ss · 90 BPM` (label-Stil). Tap → `context.push('/guided/<id>')`. Breit (≥1000): Kacheln in zwei Spalten (Grid), schmal: Liste.
- [ ] **Step 1: Failing tests:** `toggle shows guided list`; `set/pad filter`; `tile shows name, badges, duration`; `tap pushes preview route`; `two columns when wide` (1280×800 desktop: two tiles share a row) / `one column at 412`.
- [ ] **Step 2–4:** RED → implement → GREEN (+ existing lessons tests).
- [ ] **Step 5: Commit** `feat(gefuehrt): Guided in der Bibliothek`

---

### Task 4: Vorschau `/guided/:id`

**Files:**
- Create: `lib/features/guided/screens/guided_preview_screen.dart`
- Modify: `lib/app/router.dart` (top-level `GoRoute('/guided/:id')` und `'/guided/:id/play'` mit `parentNavigatorKey: _rootNavigatorKey`, wie `/exercise`)
- Test: `test/guided/screens/guided_preview_test.dart`

**Interfaces:**
- Consumes: Task 1 (`GuidedBackdrop(playing: false)`, `guidedWide`), Task 2 (`GuidedLineView` für die Groove-Vorschau), `TempoRow`, Settings für Teacher/Play-along (gemerkt, Standard an/an).
- Produces: dunkler Screen mit Backdrop. Kopf: Zurück, Name (title), Beschreibung, Badges (SET/PAD, Schwierigkeit), `~m:ss`. **Ablauf** als vertikale Zeitleiste: Groove · V1 „textEn" · Groove · V2 … · Schluss, je mit Taktzahl. **Groove-Noten** (`GuidedLineView`). Einstellungen: `TempoRow` (min–max der Übung), Schalter **Teacher** und **Play along**. Großer Akzent-Knopf **Start** (Handy-Stil, Höhe 56) → `context.push('/guided/<id>/play?bpm=&teacher=&along=')`. Breit: links Zeitleiste + Groove-Noten, rechts Einstellungen + Start. Schmal: alles untereinander, Start unten fest. Desktop-Tasten (Leertaste = Start, ↑/↓ Tempo, T, P, Esc = zurück). Unbekannte ID → „Exercise not found" + Zurück.
- [ ] **Step 1: Failing tests:** `shows timeline with every variation text`; `start pushes play with bpm and options`; `keys change tempo and toggles` (desktop override); `unknown id shows not found` (Review Focus 5); `renders at phone, tablet and desktop sizes without overflow`.
- [ ] **Step 2–4:** RED → implement → GREEN.
- [ ] **Step 5: Commit** `feat(gefuehrt): Vorschau einer geführten Übung`

---

### Task 5: Übungs-Bildschirm `/guided/:id/play` + Abschluss

**Files:**
- Create: `lib/features/guided/screens/guided_play_screen.dart`, `lib/features/guided/widgets/guided_banner.dart`, `lib/features/guided/widgets/guided_timeline_bar.dart`
- Test: `test/guided/screens/guided_play_test.dart`, Goldens `test/goldens/guided_play_{desktop,phone}.png`

**Interfaces:**
- Consumes: `guidedRigProvider` (Spieler), `RunPosition`, `RunOptions`, `guidedStatusLine`, Task 1/2, `TempoRow`, Desktop-Tasten; `FakeGuidedPlayer`-Muster aus `test/guided/debug_guided_screen_test.dart`.
- Produces (`UncappedContent`, `GuidedBackdrop(playing: running)`):
  - **Kopf:** Zurück, Name, Statuszeile „Variation 2 of 4 · bar 5" (aus `guidedStatusLine`), Zeit `1:42 / ~5:04`.
  - **Zeitleiste** (`GuidedTimelineBar`): ganzer Ablauf als Balken, Groove-Segmente ruhig, Variationen akzentfarben, Fortschritt gefüllt, Marker an der aktuellen Stelle.
  - **NOW:** `GuidedLineView` der laufenden Zeile groß mit Cursor (`activeTick` aus `RunPosition`).
  - **Banner** (`GuidedBanner`): während der Erklärung „COMING UP" + `textEn` und darunter die kommende Variation gedimmt (`GuidedLineView(dimmed: true)`); im Countdown-Takt große Zahl **3 · 2 · 1 · GO** (auch bei Teacher aus — Spec §3.2); während der Variation bleibt `textEn` klein über den Noten.
  - **Steuerung:** Play/Pause (Akzent-Knopf), Stop, `TempoRow`, Schalter Teacher / Play along (wirken live über `setOptions`).
  - **Layout:** breit = links NOW + Banner (≈ 2/3), rechts Zeitleiste vertikal + Steuerung (≈ 1/3); schmal = Kopf, Zeitleiste horizontal, NOW, Banner, Steuerung unten (wie Handy-Übung).
  - **Abschluss** (`finished`): ruhige Ansicht auf dem Backdrop: „Done", Name, gespielte Zeit, Tempo, Knöpfe **Again** und **Back to library**. Keine Messwerte (Plan 3b).
  - Verlassen (Zurück/Esc) stoppt den Spieler.
- [ ] **Step 1: Failing tests** (FakeGuidedPlayer): `starts with bpm and options from the route`; `banner shows coming-up text before a variation`; `countdown numbers appear in the countdown bar, also with teacher off`; `cursor follows run position`; `timeline marker advances`; `resizing while playing keeps the run` (Review Focus 1); `long variation text wraps at 412 wide` (2); `leaving the screen stops the player` (3); `finished shows the end view; space does not restart` (4); goldens desktop 1280×800 and phone 412×915 mid-run with banner.
- [ ] **Step 2–4:** RED → implement → GREEN; `flutter test` (gesamt) + `flutter analyze` (keine neuen Befunde).
- [ ] **Step 5: Commit** `feat(gefuehrt): Übungs-Bildschirm mit Banner, Countdown und Abschluss`

---

### Task 6: Desktop-Lieferung + erste Optik-Runde mit Uli

**Files:**
- Create: `docs/BERICHT_GEFUEHRT_PLAN3A.md` (deutsch, einfach)

- [ ] **Step 1:** Screenshots der Goldens + echte Linux-Screenshots: Linux-Bundle auf dem Laptop bauen (docs/CLAUDE.md „Delivery", Checkout `~/agent-test-checkouts/drum_coach-guided`, Ziel `~/drum-coach-guided/`), App starten, Bibliothek → Guided → Vorschau → Übung (je ein Screenshot per `import`/`gnome-screenshot` o. ä. auf dem Laptop, nur wenn Ulis Bildschirm frei ist — sonst die Goldens).
- [ ] **Step 2:** Bericht: was neu ist, wo man es findet, Tastenkürzel, offene Optik-Fragen (Spaltenverhältnis, Größe der Noten, Banner-Stil, Zeitleiste horizontal/vertikal, Foto ja/nein im Spielmodus).
- [ ] **Step 3: Gate (Controller):** Screenshot-Galerie als Artifact veröffentlichen, Uli probiert am Laptop; seine Optik-Wünsche sind die nächste Runde (neuer kleiner Plan), nicht Teil dieses Plans.
- [ ] **Step 4: Commit** `docs(gefuehrt): Bericht Plan 3a`

## Danach

Optik-Runden nach Ulis Rückmeldung; Plan 3b Messung + Auswertung je Abschnitt (zweite Priorität); Runde 2 der Inhalte nach Ulis Kuration; Hintergrundband; echte Schlagzeug-Samples.
