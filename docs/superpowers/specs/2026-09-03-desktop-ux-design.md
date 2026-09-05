# P4 — Desktop-UX für große Bildschirme

**Datum:** 2026-09-03
**Teil von:** [Desktop-Ausbau-Roadmap](2026-08-31-desktop-expansion-roadmap.md)
**Baut auf:** P1 (Desktop-Plattform-Bootstrap, `lib/app/platform_support.dart`)
**Status:** Design, bereit zur Umsetzung

## Kontext

P1 hat DrumCoach auf Windows/macOS/Linux lauffähig gemacht, aber bewusst
**kein** Desktop-Layout gebaut — nur die Inhaltsbreite auf 560px gedeckelt.
Ergebnis: die App sieht auf dem Desktop aus wie die Handy-App, nur größer
(zentrierte schmale Spalte). Der Nutzer möchte eine Oberfläche, die den
großen Bildschirm wirklich nutzt.

Diese Phase (P4 der Roadmap) liefert das Desktop-Layout für die **bestehenden**
Inhalte (Pad-Rudiments/Étüden). Sie ist unabhängig von der späteren
Kit-/MIDI-Anbindung (P2/P3) und macht keine Annahmen über Mehrspur-Content.

## Locked Decisions (mit dem Nutzer abgestimmt)

- **Schwerpunkt:** (1) desktop-typische Navigation, (2) flächennutzender
  Übungs-Screen, (3) Tastatur/Maus-Bedienung. **Nicht** in Scope: mehrspaltige
  Übersichts-Screens (Dashboard/Lektionen/Stats bleiben einspaltig, nur
  ohne 560px-Deckel).
- **Umschalt-Logik: fest plattform-gekoppelt.** Desktop-Layout immer auf
  Windows/macOS/Linux, Handy-Layout immer mobil — unabhängig von der
  Fenstergröße. Gate = `isDesktopPlatform` aus P1. **Keine** breiten-adaptive
  Umschaltung.
- **Navigation:** feste `NavigationRail` links statt Bottom-Nav; Einträge
  Dashboard · Routine · Lektionen · Stats, Einstellungen unten.
- **Übungs-Screen: Drei-Zonen** — Info (links ~22%) | Notation (Mitte ~53%) |
  Steuerung (rechts ~25%). Bewertung inline im rechten Steuerpult (kein
  Bottom-Sheet auf Desktop).
- **Alle Tastenkürzel:** Leertaste (Start/Stop), Pfeil hoch-runter bzw. +/−
  (BPM ±1, mit Umschalt ±5), 1/2/3 (Bewerten), Pfeil links/rechts
  (vorige/nächste Übung), Esc (Session verlassen).
- **Mindest-Fenstergröße** setzen, damit Seitenleiste + Inhalt nie quetschen.
- Mobil bleibt **komplett unverändert**; nur die Präsentationsschicht bekommt
  einen Desktop-Zweig. Keine Änderung an Metronom-Timing, Providern oder
  Datenmodell.

## Architektur

### 1. Adaptiver Shell-Wrapper

Der bestehende `_ScaffoldWithNavBar` in `lib/app/router.dart` (StatefulShell mit
`BottomNavigationBar`) wird um einen Desktop-Zweig ergänzt: bei
`isDesktopPlatform` rendert er die vier Branches im `navigationShell` mit einer
`NavigationRail` links statt der Bottom-Nav; sonst wie bisher. Die
Breiten-Deckelung (`AppLayout.maxContentWidth` / `ConstrainedBox` aus P1) wird
auf Desktop **nicht** angewandt — der Content füllt die Fläche rechts der Rail.

- Rail: Icons + Labels (Dashboard/Routine/Lektionen/Stats), aktiver Eintrag im
  Akzent-Orange (`AppColors.accent`), Einstellungen als unterer Eintrag
  (`trailing`) → `context.push('/settings')`.
- Mobil: unverändert `BottomNavigationBar` + 560px-Cap.
- Der Wrapper wird in zwei fokussierte Widgets aufgeteilt
  (`_MobileShell`, `_DesktopShell`) mit gemeinsamem `navigationShell`-Input,
  damit jede Datei eine klare Verantwortung hat.

### 2. Mindest-Fenstergröße

Paket `window_manager` (etabliert, Desktop-only) in `main()` **nur wenn
`isDesktopPlatform`**: nach `ensureInitialized` eine Mindestgröße von
**900×600** setzen (`setMinimumSize`). Auf Mobil wird `window_manager` nie
aufgerufen (Guard über `isDesktopPlatform`), sodass die Handy-App unberührt
bleibt.

### 3. Drei-Zonen-Übungs-Screen

`practice_session_screen.dart` (aktuell vertikaler Stapel: `Expanded`
NotationStaff → `_CompactMetronome` → `_TimerGoalRow` → Rating-Sheet) bekommt
eine Layout-Weiche im `build`:

- **Mobil (`!isDesktopPlatform`):** exakt der heutige vertikale Aufbau
  (unverändert, inkl. `_RatingSheet` als Bottom-Sheet).
- **Desktop:** ein `Row` mit drei Zonen:
  - **Info (`_PracticeInfoPanel`, flex 22):** Übungsname, Schwierigkeit,
    Ziel-Tempoband (min→target), Skill-/Limb-Tags, Sticking-Legende
    (R=rechts, L=links, ● = Akzent, gedimmt = Ghost). Reine Anzeige aus dem
    bereits geladenen `Rudiment`.
  - **Notation (flex 53):** die bestehende `NotationStaffWidget` (`Expanded`)
    + Sticking-Pattern darunter, maximiert, mit Live-Cursor.
  - **Steuerung (`_PracticeControlPanel`, flex 25):** wiederverwendet die
    Bausteine von `_CompactMetronome` (BPM-Zahl + Slider + ±, Start/Stop,
    Subdivision) und `_TimerGoalRow` (Session- + Übungs-Timer, Ziel),
    vertikal gestapelt. Nach Stop erscheint hier **inline** die 1/2/3-Bewertung
    (gleiche `onRating`-Logik wie das Sheet, nur anderer Container).

Die gemeinsamen Sub-Widgets (BPM-Control, Transport, Subdivision-Selector,
Timer, Rating-Buttons) werden — soweit sie heute privat in
`practice_session_screen.dart` liegen — in kleine, wiederverwendbare Widgets
extrahiert, die beide Layouts nutzen. Kein Verhalten ändert sich; nur die
Anordnung.

Kopfbereich Desktop: schlanke Zeile mit Zurück-Pfeil + Übungstitel (statt
voller AppBar-Row). Keine Seitenleiste im Übe-Screen (fokussiert).

### 4. Tastatur & Maus

Ein `Shortcuts` + `Actions` (bzw. `CallbackShortcuts`) um den Desktop-Übungs-
Screen, aktiv nur bei `isDesktopPlatform`:

| Taste | Aktion |
|---|---|
| `Space` | Metronom/Session Start ⇄ Stop (`_metronomeNotifier` toggle) |
| `↑` / `+` | BPM +1 (mit `Shift`: +5), max 240 |
| `↓` / `−` | BPM −1 (mit `Shift`: −5), min 40 |
| `1` / `2` / `3` | Bewertung Schwer / Ok / Sicher (wenn Bewertung ansteht) |
| `→` / `←` | nächste / vorige Übung (nur im Sammlungs-/Programm-Kontext; sonst No-Op) |
| `Esc` | Session verlassen (`context.pop()` / zurück) |

- BPM-Grenzen und Toggle-Logik rufen dieselben Notifier-Methoden wie die
  Buttons — keine Sonderpfade.
- „Vorige/nächste Übung" nutzt die im Aufruf-Kontext vorhandene Übungsliste;
  ohne solche Liste sind die Pfeiltasten inaktiv (kein Fehler).
- Maus: Hover-Zustände auf Nav-Einträgen, Karten und Buttons
  (`MouseRegion`/`InkWell`-Hover, Cursor `SystemMouseCursors.click`).
- Auffindbarkeit: kleine ein-/ausklappbare **Kürzel-Legende** (Icon „?" im
  Übe-Screen-Kopf), die die Belegung listet.

## Betroffene/neue Dateien

- `lib/app/router.dart` — `_ScaffoldWithNavBar` in `_MobileShell` +
  `_DesktopShell` (NavigationRail) aufteilen, Desktop lässt den 560px-Cap weg.
- `lib/app/window_setup.dart` — NEU: `applyDesktopWindowSetup()`
  (Mindestgröße 900×600 via `window_manager`, no-op wenn `!isDesktopPlatform`).
- `lib/main.dart` — `applyDesktopWindowSetup()` in `main()` aufrufen.
- `pubspec.yaml` — Dependency `window_manager`.
- `lib/features/practice/practice_session_screen.dart` — Layout-Weiche
  mobil/Desktop; Desktop-Drei-Zonen-Zusammenbau; Shortcuts/Actions;
  Inline-Rating auf Desktop.
- `lib/features/practice/widgets/` — NEU: extrahierte, von beiden Layouts
  genutzte Bausteine (`bpm_control.dart`, `practice_info_panel.dart`,
  `practice_control_panel.dart`, `rating_selector.dart`,
  `shortcut_legend.dart`) — je eine klare Verantwortung.
- Desktop-Rendering der übrigen Screens (Dashboard/Lektionen/Stats/Routine):
  keine Struktur-Änderung nötig; sie erben nur die entfallende Breiten-Deckelung
  über den `_DesktopShell`. (Einspaltig, wie festgelegt.)
- Tests: `test/app/desktop_shell_test.dart`,
  `test/features/practice/practice_desktop_layout_test.dart`,
  `test/features/practice/practice_shortcuts_test.dart`.

## Teststrategie

Alle Widget-Tests laufen headless auf dem NUC via `debugIsDesktopOverride`
(aus P1):

- **Shell-Weiche:** bei `debugIsDesktopOverride=true` rendert die Shell eine
  `NavigationRail` und **keine** `BottomNavigationBar`; bei false umgekehrt.
- **Drei-Zonen-Übungs-Screen:** bei Desktop rendern Info-Panel, NotationStaff
  und Control-Panel gleichzeitig (alle drei `find`-bar); bei Mobil der bisherige
  Stapel.
- **Shortcuts:** simulierte Tastendrücke lösen die richtigen Aktionen aus —
  `Space` togglet den Metronom-Zustand, `↑`/`↓` (und mit `Shift`) ändern die
  BPM in den korrekten Schritten und respektieren 40–240, `1/2/3` lösen die
  Bewertung aus. Getestet gegen den echten/gefälschten Notifier, nicht nur
  gegen Mocks.
- **Mobil-Regression:** bestehende Tests bleiben grün; keine Änderung an
  Timing/Providern/Modell.
- **Gerät:** lokaler Build auf dem Linux-Laptop (Setup aus P1 vorhanden) +
  CI-Grün auf allen drei OS; danach Screenshot des Desktop-Layouts.

## Nicht-Ziele (P4)

- Keine breiten-adaptive Umschaltung (bewusst plattform-gekoppelt).
- Keine mehrspaltigen Dashboard-/Lektionen-/Stats-Layouts (nur Deckel entfällt).
- Keine Änderung an Metronom-Timing, Audio, Providern oder Datenmodell.
- Keine MIDI-/Kit-Anbindung (P2) und kein Mehrspur-Content (P3).
- Kein AI-Coaching auf Desktop (bleibt aus P1 ausgeblendet).
- Keine frei konfigurierbaren/umbelegbaren Tastenkürzel (feste Belegung).
