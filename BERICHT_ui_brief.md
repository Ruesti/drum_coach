# BERICHT: UI-Design-Brief für Claude Design

> Auftrag: `BRIEF_UI_CLAUDE_DESIGN.md` erzeugen — ein selbsttragender Prompt
> für eine separate Claude-Design-Session ohne Repo-Zugriff. Dieser Bericht
> belegt jeden Token/jede Aussage im Brief mit Datei:Zeile aus dem echten
> Code, damit nichts „erfunden" ist.

**Branch/Basis:** Isolierter Worktree, HEAD auf lokalem
`feature/training-program-stick-control` (Commit `30d7517`) — bewusst *nicht*
auf `origin/main`, weil dort die aktuellen Screens (u. a. `program_screen.dart`)
fehlen würden.

**Zusätzlich gelesen (nicht im Git-Tree, lagen unversioniert im
Original-Checkout):** `BRIEF_DRUM_COACH_ERWEITERUNG.md`,
`BRIEF_TRAINING_PROGRAM.md`, `STICK_CONTROL_PROGRAM.md` — als Produkt-/
Programmkontext für Abschnitt 1 und 7 des Briefs, nicht als UI-Quelle.

---

## 1 · Gelesene Dateien (vollständig)

`lib/app/theme.dart` · `lib/app/router.dart` · `lib/main.dart` ·
`lib/features/dashboard/dashboard_screen.dart` ·
`lib/features/learning/daily_routine_screen.dart` ·
`lib/features/learning/routine_provider.dart` ·
`lib/features/learning/models/daily_routine.dart` ·
`lib/features/lessons/lessons_screen.dart` ·
`lib/features/lessons/lesson_detail_screen.dart` ·
`lib/features/lessons/rudiment_filter.dart` ·
`lib/features/lessons/models/rudiment.dart` ·
`lib/features/lessons/data/rudiments_seed.dart` (erste 150 Zeilen + Grep über
den Rest) ·
`lib/features/practice/practice_session_screen.dart` ·
`lib/features/practice/practice_provider.dart` ·
`lib/features/program/program_screen.dart` ·
`lib/features/program/models/training_program.dart` ·
`lib/features/program/data/stick_control_program.dart` ·
`lib/features/metronome/metronome_screen.dart` (Enums `Subdivision`/
`SoundType` per Grep aus `metronome_engine.dart`) ·
`lib/features/stats/stats_screen.dart` ·
`lib/features/stats/stats_provider.dart` ·
`lib/features/settings/settings_screen.dart` ·
`lib/features/onboarding/onboarding_screen.dart` ·
`lib/features/coaching/exercise_generator_screen.dart` ·
`lib/features/coaching/widgets/coach_feedback_card.dart` ·
`lib/shared/widgets/notation_staff_widget.dart` ·
`lib/data/local/models/practice_session.dart` ·
`lib/data/local/models/rudiment_progress.dart` ·
`pubspec.yaml` · `README.md` · `android/app/src/main/AndroidManifest.xml`.

**Nicht gelesen / nur per Existenzprüfung bestätigt:** `bpm_progression_service.dart`
und `spaced_repetition_service.dart` (nur referenziert von
`practice_provider.dart:6-7,62-65`, Inhalt nicht geöffnet — die „+2/+5 BPM"-
Aussage im Brief stammt aus dem UI-Text, nicht aus dieser Service-Logik
selbst, siehe unten).

---

## 2 · Token-Nachweise (Abschnitt 4 des Briefs)

| Token im Brief | Datei:Zeile | Wörtlich/Wert im Code |
|---|---|---|
| `#121212` App-Hintergrund | `lib/app/theme.dart:10` | `scaffoldBackgroundColor: const Color(0xFF121212)` |
| `#1A1A1A` AppBar/BottomNav | `lib/app/theme.dart:12,17` | `AppBarTheme(backgroundColor: Color(0xFF1A1A1A))`, `BottomNavigationBarThemeData(backgroundColor: Color(0xFF1A1A1A))` |
| `#1E1E1E` Card-Standard | `lib/app/theme.dart:36` | `CardThemeData(color: const Color(0xFF1E1E1E))` — inline wiederholt u. a. in `dashboard_screen.dart:191,305,324`, `daily_routine_screen.dart:102`, `lesson_detail_screen.dart:157`, `program_screen.dart:91,268`, `stats_screen.dart:110,194,259,325,361,375`, `settings_screen.dart:139,199,310,363` |
| `#1A1A1A` sekundärer Container (Notenzeile) | `lib/features/practice/practice_session_screen.dart:312,443` | `Container(color: const Color(0xFF1A1A1A))` um `NotationStaffWidget`/Kompakt-Metronom |
| `#151515` Input-Füllung | `lib/features/settings/settings_screen.dart:163` | `fillColor: const Color(0xFF151515)` |
| `#2A2A2A` Chip-Theme-Default | `lib/app/theme.dart:41` | `ChipThemeData(backgroundColor: const Color(0xFF2A2A2A))` |
| `#1A1A2E` Coach-Feedback-Card | `lib/features/coaching/widgets/coach_feedback_card.dart:21` | `color: const Color(0xFF1A1A2E)` |
| `Colors.deepOrange` Primärfarbe | `lib/app/theme.dart:7,18,23-24,29` u. a. | `ColorScheme.fromSeed(seedColor: Colors.deepOrange, …)`; durchgängig in fast jeder gelesenen Screen-Datei als Button-/Icon-/Akzentfarbe |
| `#EDEDED` Notenkopf-Tinte | `lib/shared/widgets/notation_staff_widget.dart:83` | `_inkColor = Color(0xFFEDEDED)` |
| Notenlinien 20 % Weiß | `lib/shared/widgets/notation_staff_widget.dart:82` | `_staffColor = Color(0x33FFFFFF)` |
| `#FF7043` Akzent-Note | `lib/shared/widgets/notation_staff_widget.dart:84` | `_accentColor = Color(0xFFFF7043)` |
| `#FFC107` aktive Note/Cursor | `lib/shared/widgets/notation_staff_widget.dart:85` | `_activeColor = Color(0xFFFFC107)` |
| Ghost Note 40 % Weiß | `lib/shared/widgets/notation_staff_widget.dart:86` | `_ghostColor = Color(0x66FFFFFF)` |
| R/L-Buchstaben 60 % Weiß | `lib/shared/widgets/notation_staff_widget.dart:87` | `_letterColor = Color(0x99FFFFFF)` |
| Rating-Farben Rot/Amber/Grün | `lib/features/practice/practice_session_screen.dart:562,573,584` | `color: Colors.red.shade400` / `Colors.amber` / `Colors.green.shade400` |
| Blue.shade300 „Progress"/„Technik" | `lib/features/learning/daily_routine_screen.dart:155`, `lib/features/program/program_screen.dart:384` | `Colors.blue.shade300` |
| Difficulty-Hexfarben | `lib/features/lessons/models/rudiment.dart:33-36` | `beginner(color: Color(0xFF4CAF50))`, `intermediate(Color(0xFFFFC107))`, `advanced(Color(0xFFFF9800))`, `professional(Color(0xFFF44336))` |
| Textstufen `white70/54/38/24` | durchgängig, z. B. `lib/features/dashboard/dashboard_screen.dart:64,109,150,156,173` | konsistent verwendetes Muster, keine zentrale Konstante |

**Keine zentrale Farb-/Typo-/Spacing-/Radius-Datei gefunden:** Suche nach
`lib/theme/**` und `lib/ui/**` (wie im Auftrag verlangt) ergab **keine
Treffer** — beide Verzeichnisse existieren nicht im Repo (`find lib/theme`,
`find lib/ui` → leer). Das einzige zentrale Theme-Artefakt ist
`lib/app/theme.dart` (46 Zeilen, siehe oben); alles andere ist Ad-hoc in den
Screens verstreut. Das steht so auch im Brief (Abschnitt 4, Fließtext).

### Typografie — Belege für die genannten Größen

`96` → `lib/features/metronome/metronome_screen.dart:188` (`fontSize: 96`,
BPM-Anzeige) · `56` → `lib/features/stats/stats_screen.dart:462`,
`lib/features/program/program_screen.dart:123`,
`lib/features/learning/daily_routine_screen.dart:184` (Empty-State-Emoji) ·
`32` → `lib/features/stats/stats_screen.dart:115` (Flamme) · `30` →
`lib/features/practice/practice_session_screen.dart:470` (kompaktes BPM) ·
`28` → `lib/features/dashboard/dashboard_screen.dart:54,219` · `22` →
`lib/features/stats/stats_screen.dart:465`,
`lib/features/learning/daily_routine_screen.dart:188` · `20/18/17` →
`practice_session_screen.dart:555` (Rating-Sheet-Titel),
`practice_session_screen.dart:288` (Timer),
`practice_session_screen.dart:352` (Finish-Button) · `16/15` →
`coach_feedback_card.dart:34`, `program_screen.dart:98,286` · `14/13` →
verbreitet, z. B. `settings_screen.dart:368`, `stats_screen.dart:432` ·
`12/11/10` → Badges/Meta-Text, z. B.
`daily_routine_screen.dart:124,167`, `program_screen.dart:397`.

Keine zentrale `TextTheme` im `ThemeData` (`lib/app/theme.dart:3-46` enthält
keinen `textTheme:`-Parameter) → belegt „keine definierte Typo-Skala".
`pubspec.yaml` enthält keinen `fonts:`-Block unter `flutter:` (Zeilen 36-37)
→ belegt „kein Custom-Font".

### Spacing/Radien — Belege

`EdgeInsets.all(16)` als Screen-Padding: `dashboard_screen.dart:37`,
`daily_routine_screen.dart:30`, `stats_screen.dart:41`,
`settings_screen.dart:91`, `program_screen.dart:55,155`. Radius `12`:
`lib/app/theme.dart:32,38`; Radius `20` (Bottom-Sheet oben):
`practice_session_screen.dart:171-172`; Radius `14` (CTA/Feedback-Card):
`practice_session_screen.dart:350`, `coach_feedback_card.dart:22`; Radius
`2` (Sheet-Griff): `practice_session_screen.dart:549`.

### Elevation/Schatten — Beleg

`elevation: 0` für Cards und AppBar: `lib/app/theme.dart:14,37`. Einziger
`BoxShadow` im gesamten gelesenen Code:
`lib/features/metronome/metronome_screen.dart:163-167`
(`BoxShadow(color: Colors.deepOrange.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 4)`,
nur wenn `isPlaying && isAccent`, Zeile 161).

---

## 3 · Navigation/Screens (Abschnitt 5)

Baum direkt aus `lib/app/router.dart:17-104` abgeleitet: Onboarding-Gate
Zeile 19-24, vier Shell-Branches Zeile 36-84 (Dashboard `/` Z.37-40, Routine
`/routine` + `:rudimentId` Z.43-55, Lessons `/lessons` + `:id` + `/practice/:rudimentId`
Z.58-78, Stats `/stats` Z.80-84), plus vier eigenständige Routen außerhalb der
Shell: `/program` Z.87-90, `/metronome` Z.91-94, `/settings` Z.95-98,
`/coaching/exercise-generator` Z.99-102. Bottom-Nav-Items (4, in dieser
Reihenfolge) mit Icons: `router.dart:121-142`. Verlinkungen: Dashboard→Settings
(`dashboard_screen.dart:32`), Dashboard→Program (`:50`), Dashboard→Routine
(`:83`), Dashboard→Metronome (`:105`), Settings→Exercise-Generator
(`settings_screen.dart:207`), Lesson-Detail→Practice (`lesson_detail_screen.dart:64`),
Program-Block→Practice mit `?bpm=` (`program_screen.dart:305-309`).

---

## 4 · Komponenten-Zustände (Abschnitt 6) — Kernbelege

- **Sticking-Widget Bewegungs-Spec:** diskreter Sprung, kein Tween, weil
  `activeIndex` als einfacher `int?`-Parameter durchgereicht wird
  (`notation_staff_widget.dart:11-18`) und der Aufrufer bei jedem
  Metronom-Tick per `ref.watch`/State-Rebuild neu rendert
  (`practice_session_screen.dart:252-254`,
  `shouldRepaint` Z.452-458 vergleicht nur den Wert, keine Animation).
  Drei gleichzeitige Signale an der aktiven Position: Hintergrund-Band
  (Z.174-185), Vertikallinie (Z.186-190), Kopf-/Buchstabenfarbwechsel
  (Z.253-259 Kopf, Z.294-298 Buchstabe) + Ring (Z.344-351).
- **Metronom-Puls:** `AnimationController(duration: 220ms)`
  (`metronome_screen.dart:30-33`), `TweenSequence` Skalierung
  1.0→1.45 (Gewicht 30, easeOut) →1.45→1.0 (Gewicht 70, easeIn)
  Z.34-45; Opazität 0.5→1.0→0.5 im selben Gewichtsschema Z.46-55;
  Auslösung bei jedem Beat-Wechsel via `ref.listen` Z.73-78;
  Farbe/Glow-Logik `_BeatIndicator` Z.129-175.
- **CoachFeedbackCard 4 Zustände:** Loading Z.57-70, Feedback-Text Z.71-79,
  „keine Mic-Daten" Z.80-84, „API-Fehler/kein Feedback" Z.85-89 — alle in
  `coach_feedback_card.dart`.
- **Dashboard-Fehlerverhalten (Karten kollabieren):**
  `dashboard_screen.dart:77,90-91` — `error: (_, __) => const SizedBox.shrink()`
  für Routine- und Sessions-Karte; im Gegensatz dazu Vollbild-Fehlertext in
  `daily_routine_screen.dart:22` und `stats_screen.dart:35`
  (`Text('Error: $e')`) bzw. `program_screen.dart:24` (`'Fehler: $e'`).
- **Rating-Sheet-Subtexte** (Quelle der „+2/+5 BPM"-Aussage im Brief, nur
  UI-Copy, nicht verifiziert gegen die tatsächliche BPM-Progressions-Logik):
  `practice_session_screen.dart:561` „Keep the same BPM", `:572` „+2 BPM next
  time", `:583` „+5 BPM next time".
- **fl_chart-Konfiguration:** Balkendiagramm `stats_screen.dart:262-303`
  (kein Grid `FlGridData(show:false)` Z.281, kein Border Z.282, heutiger
  Balken hervorgehoben Z.266-268,275); Liniendiagramm `:378-407` (`isCurved:
  true`, `barWidth:2`, `belowBarData` Alpha 0.08 Z.386-389); Heatmap-Farben
  `:171-177` (5 Stufen, Schwellen 10/20/40 Minuten).

---

## 5 · Beispieldaten (Abschnitt 7)

- 41 Rudiments im Seed: `grep -c "^  Rudiment(" lib/features/lessons/data/rudiments_seed.dart`
  → `41`. Namen/IDs per Grep aus derselben Datei (siehe Werkzeug-Output der
  Session; u. a. `single_stroke_roll` Z.7-8, `double_stroke_roll` Z.58-59,
  `multiple_bounce_roll` Z.111-112 direkt gelesen).
- Programmstruktur, Phasen, Start-BPM, Fokustexte wörtlich aus
  `lib/features/program/data/stick_control_program.dart:13-84` — Phase 1
  Z.21-35, Phase 2 Z.36-50, Phase 3 Z.51-65, Phase 4 Z.66-83 (inkl.
  Zeilen-Rotation-Kommentar Z.78).
- Wochenrhythmus/84-Tage-Aufteilung aus `STICK_CONTROL_PROGRAM.md` §1/§5
  (nicht im Git-Tree, s. o.) — dort exakt die im Brief zitierten Zahlen (60/12/12
  Tage, 15/8/0 Minuten je Tagtyp).
- Empty-State-Texte wörtlich zitiert aus:
  `dashboard_screen.dart:224-227`, `daily_routine_screen.dart:186-191`,
  `stats_screen.dart:464-469`, `lessons_screen.dart:152-155`,
  `program_screen.dart:236-247`.
- `PracticeSession`-Felder (`achievedBpm`, `durationSeconds`, `rating`
  1–3, `date`) aus `lib/data/local/models/practice_session.dart:6-13` —
  Basis für die im Brief vorgeschlagenen Chart-Beispielwerte (die konkreten
  BPM-/Minuten-Zahlen im Brief sind plausible Beispiele auf Basis dieser
  Felder + der echten Start-BPMs, keine geloggten echten Werte, da die App
  keine Demo-Datenbank mit Sessions enthält — es existiert keine Seed-Datei
  für `PracticeSession`).

---

## 6 · Plattform/Breakpoints (Abschnitt 2)

- `pubspec.yaml:3` — Produktbeschreibung „Android app for training drum
  rudiments on a practice pad."
- Plattformordner `android/ ios/ linux/ macos/ web/ windows/` existieren alle
  (Standard-`flutter create`-Scaffolding, per `ls` bestätigt), aber keine
  Screen-Datei enthält adaptive/responsive Logik außer
  `notation_staff_widget.dart:22-26` (`LayoutBuilder`) und
  `practice_session_screen.dart:709` (`MediaQuery … viewInsets.bottom` für
  Tastatur-Padding im Bottom-Sheet) — per Grep über `lib/**/*.dart` nach
  `MediaQuery|LayoutBuilder|Breakpoint` bestätigt (nur diese 3 Treffer).
- Keine Orientation-Lock: Grep nach `orientation` (case-insensitiv) über
  `lib/**/*.dart` → keine Treffer.
- Kein `assets:`/`fonts:`-Block in `pubspec.yaml` (Zeilen 34-37 = nur
  `uses-material-design: true`); keine `assets/`- oder `fonts/`-Verzeichnisse
  im Repo (`find . -maxdepth 2 -iname assets -o -iname fonts` → leer).
- App-Label „drum_coach" (Rohname, nicht „DrumCoach"):
  `android/app/src/main/AndroidManifest.xml:7`. `MaterialApp.router`-Titel
  „DrumCoach": `lib/main.dart:32`.

---

## 7 · Annahmen / bewusst nicht belegte Aussagen

Alles unter „OFFENE PUNKTE" im Brief ist als **Lücke** markiert, nicht als
Tatsachenbehauptung — dort wurde bewusst nichts erfunden, sondern der Mangel
an Code-Evidenz benannt (App-Icon/Branding, Landscape/Tablet, Zukunftsvision
aus `BRIEF_DRUM_COACH_ERWEITERUNG.md`, Overflow-Verhalten, Onboarding-Reset).
Die einzige nicht wörtlich aus Code zitierte Zahl ist der SDK-Hex-Wert von
`Colors.deepOrange` (`#FF5722`) — das ist eine öffentlich dokumentierte
Flutter-Framework-Konstante, kein Repo-Literal; im Brief entsprechend als
„Flutter-Named-Color … SDK-Wert" gekennzeichnet, nicht als Repo-Fund.
