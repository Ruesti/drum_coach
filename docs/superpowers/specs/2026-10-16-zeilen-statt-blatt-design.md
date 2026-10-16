# Zeilen statt Blatt — Übungs-Screen als Zeilenliste, Zeilenfolge, Desktop-Lieferung

Stand: Entwurf 16.10.2026 abends, nach Ulis erstem Gerätetest der Set-Übungen
(Build drum-coach-set-b1c, „Double Bass Eighths"). **Von Uli freigegeben 16.10. 18:26:
„ja, 2×, Linux" (Antworten auf §6).**

## 0. Ulis Befund (Wortlaut sinngemäß)

- „Die Unterteilung Line vs. Sheet finde ich generell nicht gut. Fände es gut, wenn man
  alle Übungen/Lines untereinander separat sehen könnte und auf dem Screen scrollen.
  Antippen öffnet die Line. Sheet generell in allen Übungen ganz weg. Man könnte
  einbauen, dass man eine Line durch direktes Antippen öffnet oder mehrere Lines
  markieren und dann als Sheet spielen kann."
- „Die Challenge ist nicht anders als die Lines, nur dass es halt 2 Lines sind."
- „Will jetzt auch Desktop-App machen, damit ich, wenn ich zuhause bin, damit üben kann."

Die vier kleinen Punkte aus demselben Test (Zählsilben weg, Buchstaben nur bei
Hand-/Fußwechsel, Zeilen müssen sich unterscheiden, Backing bei Set-Übungen tot) sind
NICHT Teil dieser Spec; sie werden direkt auf dem Branch gefixt.

## 1. Ist-Zustand (was der Code heute macht)

- Der Übungs-Screen (`practice_session_screen.dart`) übt schon zeilenweise: Zeilen-Modus
  (eine Zeile in Schleife, Standard) oder Blatt-Modus (alle Zeilen einmal hintereinander
  als eine Schleife, `SheetPlan.wholeSheet`). Umschalter und Vor/Zurück in `_LineBar`.
- Die Anzeige ist ein **Blattfenster** (`SheetWindow`): 2–4 Reihen sichtbar, aktive Zeile
  oben, die nächsten gedimmt darunter; Antippen einer Reihe wählt die Zeile (nur im
  Zeilen-Modus). Das ist genau die Mischform, die Uli stört.
- Einstieg: `/practice/:id?line=N&mode=line|sheet`; Bibliothek und Sammlung öffnen ohne
  `line`; die Info-Seite (`lesson_detail_screen.dart`) hat PATTERN, THE SHEET (Zeilen dort
  antippbar → `?line=N`), Legende, LESSON, „Start Practice".
- Heute/Routine planen ganze Übungen (`DailyRoutineItem(rudimentId, …)`), Fortschritt
  liegt pro Übung (`RudimentProgress`), nicht pro Zeile. Das Sitzungs-Log kennt die
  Zeilennummer (`sheetLine`).
- Modell: `ExerciseLine` hat `beats`/`kitVoices`, `repeat` (nur Notation:
  Wiederholungszeichen), `title`, `counts`. Die Challenge ist nur „`title == 'Challenge'`
  und `repeat == false`". Eine Zeile hat keine eigene Kennung außer dem Index.
- Desktop: Linux-Client aus Phase A.7 vorhanden (`platform_support.dart`, Tastenkürzel
  Leertaste/±/Esc, Inhaltsbreite 900 px, Fenster 1280×720, Minimum 720×640). Windows
  nur Runner-Gerüst. **Falle:** Der NUC baut mit glibc 2.41 (Debian 13), der Laptop hat
  2.35 (Ubuntu 22.04) → das Linux-Bundle muss auf dem Laptop selbst gebaut werden
  (Toolchain dort vorhanden, Checkout `~/agent-test-checkouts/drum_coach-etappe2-phase-b`).

## 2. Ziel

Üben heißt: **eine Zeile** oder **eine Folge von Zeilen**. Es gibt kein Blatt mehr —
weder als Anzeige (Blattfenster) noch als Modus noch als Inhalt (Challenge-Zeile).

## 3. Entwurf

### 3.1 Übungs-Screen = Zeilenliste (neu, ersetzt den Direktsprung in den Übungs-Screen)

- Antippen einer Übung in Bibliothek, Sammlung, Programm oder Heute öffnet die
  **Zeilenliste** der Übung: Kopf (Titel, Tempo-Bereich, Chips, ⓘ für die Lektion), dann
  **alle Zeilen untereinander**, jede als Karte: Nummer, optionaler Titel, die Notation der
  Zeile (2 Takte bei Grooves/Rudimenten, 4 bei Fills; auf schmalen Handys wie heute in
  zwei Reihen umgebrochen), Buchstaben nach der neuen Regel, keine Zählsilben. Die Liste
  scrollt; die zuletzt geübte Zeile ist markiert.
- **Antippen** einer Zeile → Übungs-Screen mit genau dieser Zeile (Schleife bis Stopp).
- **Mehrere markieren:** langes Drücken (oder Knopf „Auswählen") schaltet Kästchen ein;
  „N Zeilen spielen" startet die **Zeilenfolge** in Listenreihenfolge; „Alle spielen" gibt
  es als Abkürzung oben.
- Die Info-Seite bleibt als Lektion (Beschreibung, PATTERN, LESSON-Karten); ihr Block
  THE SHEET entfällt, weil die Zeilenliste das übernimmt.

### 3.2 Übungs-Screen = eine Zeile groß (umgebaut)

- Zeigt **nur die aktuelle Zeile** als eine Reihe mit Cursor (bei 4-Takt-Fills zwei Reihen),
  darüber „Zeile 3 von 8" bzw. „Folge: 3 von 4 Zeilen", darunter wie heute Tempo, Klick,
  Backing, Start/Stopp, Messung.
- **Einzelne Zeile:** Schleife bis Stopp (wie heute im Zeilen-Modus).
- **Zeilenfolge:** jede Zeile der Folge `n`-mal (Standard 2, in den Einstellungen
  änderbar), dann die nächste ohne Unterbrechung des Klicks; nach der letzten beginnt die
  Folge von vorn, bis Stopp. Vor/Zurück springt in der Folge; eine kleine Vorschau der
  nächsten Zeile unter der aktuellen (eine Reihe, gedimmt) ist optional und darf in
  Phase 1 entfallen.
- Weg: `SheetWindow`, Blatt-Modus, Modus-Umschalter, Blatt-Position; `?mode=` wird nicht
  mehr gelesen. Route neu: `/practice/:id?lines=3` oder `?lines=1,3,5,8` (1-basiert);
  `?line=N` bleibt als Alias für eine Zeile.

### 3.3 Inhalt: Challenge-Zeile weg

- Alle Blätter (Pad und Set) verlieren die Challenge-Zeile; jedes Blatt hat 8 Zeilen. Die
  Zeilenfolge („Alle spielen" oder eine Auswahl) ersetzt sie. Katalog-Werkzeug: `challenge`
  entfällt in `Sheet`, Generator und Kurationsseite; Goldens und Takt-Zählungen (24 → 16,
  40 → 32) ziehen nach. Lektionstexte, die „the Challenge" nennen, werden angepasst.

### 3.4 Heute / Routine / Programm

- Planen weiter ganze Übungen; der Einstieg aus Heute/Routine öffnet den Übungs-Screen
  direkt mit der Folge **aller Zeilen** (Tempo wie geplant). Fortschritt bleibt pro Übung.
  Fortschritt pro Zeile ist ein späterer Schritt (braucht eine Zeilen-Kennung
  `"<übung>#<index>"`, hier noch nicht).

### 3.5 Desktop-App (Lieferung, kein Umbau)

- Phase A.7 hat den Linux-Client gebaut; er wird jetzt **geliefert**: Release-Bundle auf
  dem Laptop bauen (glibc-Falle), Startskript `~/drum-coach/drum_coach`, in `docs/CLAUDE.md`
  dokumentiert. Zuhause läuft er auf dem Laptop (Linux) oder auf dem pc; Schlagquelle MIDI
  vom Millenium-Modul per USB (Phase A), Klick/Backing über die Soundkarte ins Modul.
- Die Zeilenliste und der Ein-Zeilen-Screen nutzen die Breite (Inhalt bis 900 px); das
  große Drei-Zonen-Layout P4 bleibt Etappe 3.
- **Windows** (für die Superior-Drummer-Maschine) ist ein eigener Schritt: Flutter +
  Visual-Studio-Build-Tools auf laptop-win, MIDI-Port-Teilen prüfen. Nicht in dieser Spec.

## 4. Nicht in dieser Spec

Fortschritt pro Zeile; Desktop-Layout P4; Messung je Stimme am Set (Teil 2, B.3);
App-eigene Set-Klänge; Windows-Build.

## 5. Abnahme

- Emulator/S23: Bibliothek → Übung → Zeilenliste mit 8 Zeilen, scrollt; Antippen öffnet
  die Zeile groß, Cursor läuft, Stopp; lange drücken → 3 Zeilen markieren → „3 Zeilen
  spielen" → Folge läuft 2× je Zeile und beginnt von vorn.
- Pad-Übung (z. B. Single Stroke Roll) genauso; keine Challenge mehr sichtbar.
- Heute → Übung → Folge aller Zeilen.
- Linux: `~/drum-coach/drum_coach` startet auf dem Laptop, Zeilenliste und Üben mit
  Tastenkürzeln; MIDI-Quelle erscheint, wenn ein Gerät hängt.
- Tests: Zeilenfolge-Plan (Reihenfolge, n-fach, Rundlauf), Route-Parameter `lines`,
  Goldens Zeilenliste (Pad + Set), alles Vorherige grün.

## 6. Fragen an Uli — beantwortet 16.10. 18:26

1. Challenge-Zeile überall raus (auch Pad-Übungen)? Vorschlag: ja.
2. Zeilenfolge: jede markierte Zeile 2× und dann die nächste, Folge wiederholt bis Stopp?
   Vorschlag: ja, Anzahl einstellbar. **Uli: 2×.**
3. Desktop: reicht Linux (Laptop/pc) fürs Üben zuhause, Windows erst mit Superior Drummer?
   Welche Maschine steht am Set? **Uli: Linux.**
