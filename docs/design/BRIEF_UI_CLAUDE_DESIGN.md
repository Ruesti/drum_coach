# BRIEF: UI-Redesign DrumCoach — für Claude Design

> **An Claude Design:** Du hast **keinen Repo-Zugriff** und **keinen Kontext**
> außer diesem Text. Alles unten ist aus dem echten Code der App extrahiert
> (Flutter/Dart, Material 3), Stand des Feature-Branchs zum Zeitpunkt der
> Erstellung dieses Briefs. Abschnitt „OFFENE PUNKTE" am Ende listet, was
> **nicht** aus dem Code ableitbar war — bitte dort nichts annehmen, sondern
> als Design-Entscheidung selbst treffen oder markieren.

---

## 1 · Produkt in 5 Sätzen + Kernloop

DrumCoach ist eine Android-App, mit der man Drum-Rudiments (Schlagzeug-
Stocktechnik-Übungen wie Single Stroke Roll, Paradiddle, Flam) auf einem
**Practice Pad** übt — ohne Schlagzeug, mit Stöcken auf einer Gummifläche.
Jede Übung wird als Sticking-Notenzeile dargestellt (R/L-Buchstaben, Akzente,
Ghost Notes), dazu läuft ein Metronom mit passender Unterteilung. Ein
Spaced-Repetition-System schlägt täglich eine kurze Routine aus fälligen
Wiederholungen + Fortschritts-Übungen + einer neuen Übung vor; alternativ
gibt es ein festes 12-Wochen-Curriculum („Stick Control"). Optional analysiert
das Mikrofon Timing/Dynamik der Session und ein Claude-API-Coach gibt
Text-Feedback dazu.

**Kernloop:** App öffnen → Dashboard zeigt Streak + heutigen Vorschlag →
Übung antippen → Practice-Session (Metronom + Notenzeile + Timer laufen
parallel) → „Finish Session" → 3-stufiges Selbst-Rating (😓/😐/💪) → optional
Mic-Feedback-Sheet → zurück zum Dashboard, Streak/Stats aktualisiert.

---

## 2 · Plattform, Breakpoints, Dark/Light

- **Nur Android, nur Hochformat-Phone.** `pubspec.yaml` beschreibt die App
  explizit als „Android app for training drum rudiments on a practice pad."
  iOS/macOS/Linux/Windows/Web-Ordner existieren nur als Flutter-Standard-
  Scaffolding, sind nicht aktiv anvisiert.
- **Keine Breakpoints/adaptives Layout im Code.** Alle Screens nutzen feste
  Paddings; einzige Ausnahme ist das Sticking-Notenwidget, das seine eigene
  verfügbare Breite per `LayoutBuilder` misst und Notenzeilen umbricht.
  Tablet/Desktop-Layout ist **nicht** vorbereitet.
- **Keine Orientation-Lock im Code** — Landscape ist technisch nicht
  gesperrt, aber kein Screen ist dafür layoutet. Design für Portrait-only
  auslegen; Landscape ignorieren.
- **Nur Dark Mode.** Es existiert keine Light-Theme-Definition. Farbe/Kontrast
  ausschließlich für ein dunkles UI entwerfen.

### Der entscheidende Nutzungskontext (wichtiger als übliche Mobile-UX-Regeln)

Das Handy liegt beim Üben ca. **60 cm neben dem Practice Pad**, der Nutzer
schaut nur mit dem **Augenwinkel** hin, während er auf das Pad schlägt.
**Lesbarkeit auf Distanz schlägt Ästhetik.** Das heißt konkret:
- BPM-Zahl, Beat-Indikator und aktuelle Notenposition müssen aus der
  Halbdistanz-Peripherie erfassbar sein (großer Kontrast, große Flächen,
  keine feinen Details, die nur aus der Nähe lesbar sind).
- Wichtige Zustandswechsel (Beat, aktive Note, Timer-Ende) brauchen starke,
  peripher wahrnehmbare visuelle Signale (Größe/Helligkeit/Farbe), nicht nur
  feine Textänderungen.

---

## 3 · Ästhetik: 3 Adjektive + Anti-Goals

**Adjektive (IST-Charakter der aktuellen App, als Ausgangspunkt für die
Neugestaltung):** *dunkel-fokussiert*, *funktional-roh*, *werkzeughaft*.
Aktuell: durchgängig dunkles Flat-Design (Elevation 0 auf Cards/AppBar),
ein Akzentton (Deep Orange) für alles Interaktive, keine Illustrationen,
keine Markenidentität außer dem 🥁-Emoji im Onboarding.

**Anti-Goals (was die App bewusst NICHT sein soll):**
- **Keine verspielte Konsumenten-App-Optik.** Kein Gradient-Overload, keine
  Illustrationen/Mascots, keine Gamification-Konfetti-Ästhetik — das Publikum
  übt ernsthaft Technik, nicht „Duolingo für Trommeln".
- **Kein Studio-/DAW-Look mit dichten Reglern und Fachjargon-Overkill.** Die
  App bleibt für Fortgeschrittene-Anfänger lesbar, nicht für Percussion-Nerds
  mit 20 Parametern pro Screen.
- **Keine feinen/dünnen UI-Elemente, die auf Distanz verschwinden** (siehe
  60-cm-Kontext oben) — kein typisches „elegantes" Minimal-UI mit 1px-Linien
  und kleiner Typo als Stilmittel.
- **Keine hellen/grellen Flächen** — die App läuft oft in dunklen Übungsräumen
  abends; das App-weite Dark-only-Konzept ist bewusst, nicht nur unfertig.

---

## 4 · Tokens IST (aus Code, nichts erfunden)

### Farben

| Verwendung | Wert | Bemerkung |
|---|---|---|
| App-Hintergrund | `#121212` | `scaffoldBackgroundColor` |
| AppBar / BottomNav-Hintergrund | `#1A1A1A` | identisch für beide |
| Card-Hintergrund (Standard) | `#1E1E1E` | zentrales `CardTheme`, aber die meisten Screens setzen ihn erneut inline als `Container`-Farbe statt `Card`-Widget zu nutzen |
| Sekundärer dunkler Container (z. B. Notenzeilen-Hintergrund) | `#1A1A1A` | in Practice-Session um das Notenwidget |
| Input-Feld-Füllung (Settings API-Key) | `#151515` | dunkler als Standard-Card |
| Chip-Hintergrund (Theme-Default) | `#2A2A2A` | `ChipTheme`, wird aber in Praxis kaum benutzt — die meisten Chips sind eigene Container mit `deepOrange`/`white`-Alpha-Varianten |
| „Coach Feedback"-Card (AI-Box) | `#1A1A2E` | einziger bläulich-violetter Ausreißer im sonst orangen/neutralen Palette-Set |
| Primär-/Akzentfarbe | `Colors.deepOrange` (Flutter-Named-Color, SDK-Wert `#FF5722`) | durchgängig für: Buttons, aktive Icons, Streak-Flamme, aktive Chips/Badges, Slider, Play-Button, aktive Notation-Elemente teils |
| Notenkopf-Standardfarbe (Notation) | `#EDEDED` | „Tinte" auf dem Notensystem |
| Notenlinien (Notation) | Weiß bei 20 % Alpha | dünne Linien |
| Akzent-Note (Notation) | `#FF7043` | helleres Orange als das App-Akzentorange — eigener Ton, nicht `deepOrange` |
| Aktive Note / Cursor (Notation) | `#FFC107` (Amber) | **wichtig:** die Abspiel-Hervorhebung ist Amber/Gelb, nicht Orange — bewusster Farbwechsel zum Akzentorange, um „gerade aktiv" von „ist ein Akzentschlag" zu unterscheiden |
| Ghost Note / Vorschlagnote (Notation) | Weiß bei 40 % Alpha | |
| R/L-Buchstaben unter Noten | Weiß bei 60 % Alpha | |
| Erfolg / „Solid"-Rating / gemeistert | `Colors.green` (Shade 400 an mehreren Stellen) | |
| Warnung / „OK"-Rating / Light-Tag-Badge | `Colors.amber` | |
| Fehler / „Struggled"-Rating | `Colors.red` (Shade 400/700 je Kontext) | Shade 700 auch als „Stop"-Zustand von Metronom-Buttons |
| Info/Fortschritt-Badge | `Colors.blue` (Shade 300) | „Progress"/„Technik"-Badges |
| Textfarben (Hierarchie) | `Colors.white`, `white70`, `white60/white54`, `white38`, `white24` | De-facto-Textstufen: Primärtext = weiß/`white70`, Sekundär = `white54`, Tertiär/disabled = `white38`, Rahmen/inaktive Borders = `white24` |
| Difficulty-Badges | Beginner `#4CAF50`, Intermediate `#FFC107`, Advanced `#FF9800`, Professional `#F44336` | vier feste Stufen, Teil des Domain-Modells (nicht des App-Themes) |

Es gibt **keine zentrale Farb-Token-Datei** — Farben sind entweder im einen
`ThemeData`-Objekt (App-weites Theme) oder als Hex-Literale/`Colors.*`-Alpha-
Varianten direkt in den einzelnen Screen-Dateien verstreut. Für das Redesign
ist ein sauberes, zentrales Farbsystem ausdrücklich erwünscht (siehe
Deliverables).

### Typografie

**Keine definierte Typo-Skala/Font-Familie.** Kein `TextTheme` im Theme
gesetzt, keine Custom-Fonts in `pubspec.yaml` — Standard-Material-3-Font
(System-Default/Roboto auf Android). Schriftgrößen werden **pro Screen ad
hoc** inline gesetzt. Beobachtete Größen quer durchs Repo (deskriptiv, nicht
präskriptiv — bitte im Redesign zu einer echten Skala konsolidieren):

`96` (BPM-Großanzeige Metronom) · `56` (Empty-State-Emoji) · `32` (Streak-
Flamme) · `30` (kompakte Metronom-BPM in Practice-Session) · `28` (Dashboard-
Icons/Emoji) · `22` (Empty-State-Überschriften) · `20`/`18`/`17` (Sheet-Titel,
Timer, Primär-Button-Text) · `16`/`15` (Card-/Section-Titel) · `14`/`13`
(Fließtext, Badges) · `12`/`11`/`10` (Meta-Text, Mikro-Badges).

Gewichtung: `FontWeight.bold` für Zahlen/Titel, `w600` für Chip-Labels,
sonst Normalgewicht. Zeilenhöhe wird punktuell manuell erhöht
(`height: 1.5`–`1.6`) für Fließtext (Technik-Beschreibungen).

### Spacing

Kein Spacing-Token-System — durchgängig manuelle `SizedBox`/`EdgeInsets`-
Werte. De-facto-Skala (die tatsächlich vorkommenden Werte, kein 8-Punkt-Raster
konsequent eingehalten): `4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48`.
Screen-Außenpadding fast immer `16` (`EdgeInsets.all(16)`), Card-Innenpadding
meist `16`, teils `12`–`20`. Bottom-Sheets: `24` horizontal, `40` unten.

### Radien

`12` ist der dominante Wert (Cards, die meisten Buttons, Standard-Container).
Daneben: `8` (kleine Chips/Inputfelder), `10` (kleine Buttons, Auswahl-
Kacheln), `14` (große CTA-Buttons, AI-Feedback-Card, Bottom-Sheet-Ecken oben),
`20` (Bottom-Sheet-Top-Ecken, Filter-Pill-Chips), `6`/`4` (Mikro-Badges),
`2` (Bottom-Sheet-Griff-Balken).

### Elevation / Schatten

Cards und AppBar haben **Elevation 0** — bewusst flaches Design, keine
Schlagschatten als Stilmittel. Die **einzige** Schatten-Verwendung im ganzen
Code: ein orangener Glow (`BoxShadow`, Blur 20, Spread 4, Deep-Orange bei
40 % Alpha) um den Metronom-Beat-Indikator bei akzentuierten Beats — ein
bewusster Ausreißer als Bewegungs-/Aufmerksamkeitssignal, kein generelles
Schatten-System.

---

## 5 · Screens + Navigation als Baum

```
App-Start
└─ Onboarding (nur beim allerersten Start, kein Zurück-Weg im UI)
   └─ Bottom-Nav-Shell (4 Tabs, State bleibt pro Tab erhalten)
      ├─ [Tab 1] Dashboard  (Startseite, "/")
      ├─ [Tab 2] Routine    ("/routine")
      │    └─ Practice-Session ("/routine/:rudimentId")
      ├─ [Tab 3] Lessons    ("/lessons")
      │    ├─ Lesson-Detail ("/lessons/:id")
      │    │    └─ Practice-Session ("/practice/:rudimentId")
      │    └─ Practice-Session ("/practice/:rudimentId?bpm=")  [auch von
      │         Program-Screen aus erreichbar, technisch im Lessons-Zweig]
      └─ [Tab 4] Stats      ("/stats")

Außerhalb der Bottom-Nav (als eigener Screen "obendrauf" geöffnet):
├─ Programm         ("/program")       ← von Dashboard-Karte
├─ Metronom         ("/metronome")     ← von Dashboard-Button
├─ Einstellungen    ("/settings")      ← von Dashboard-Zahnrad
└─ Exercise-Generator ("/coaching/exercise-generator") ← von Einstellungen
```

Bottom-Nav-Tabs (4, fixed): Dashboard (Icon: dashboard), Routine (Icon:
today/Kalender), Lessons (Icon: Bücherstapel), Stats (Icon: Balkendiagramm —
**kein eigener „Metronom"- oder „Programm"-Tab**, beide sind nur über
Dashboard-Einstiege erreichbar).

Praxis-Hinweis für den Screen-Katalog: **11 eigenständige Screens** —
Onboarding, Dashboard, Routine, Lessons, Lesson-Detail, Practice-Session,
Programm, Metronom, Stats, Einstellungen, Exercise-Generator.

---

## 6 · Komponenten mit allen Zuständen

### 6.1 Sticking-Notenwidget (Kernstück der App — braucht eine Bewegungs-Spec)

Ein handgezeichnetes 5-Linien-Perkussionssystem: Notenkopf pro Schlag auf der
Mittellinie, Notenfahnen/Balken je nach Notenwert, `>`-Akzentzeichen, Ghost
Notes in Klammern (kleinerer, hohler Kopf), Vorschlagnoten (Flam/Drag, kleine
Köpfe links vom Hauptschlag mit Schrägstrich), Pausen, R/L-Buchstabe unter
jeder Note. Mehrzeilig, wenn die Übung nicht in eine Zeile passt.

**Statischer Teil (ändert sich nur bei Übungswechsel, nicht während des
Spielens):** Liniensystem, Schlüssel, Taktart (nur erste Zeile), Taktstriche,
alle Notenköpfe/Fahnen/Akzente/Ghosts/Vorschläge/Pausen/Buchstaben in ihrer
Ruhefarbe.

**Bewegter Teil während der Wiedergabe — genaue Spec:**
- Bei jedem Metronom-Tick springt die „aktive Position" **diskret** zur
  nächsten Note weiter — es ist **kein** gleitender/animierter Übergang
  zwischen zwei Positionen, sondern ein harter Wechsel im Takt des Klicks.
- An der aktiven Position erscheinen **gleichzeitig drei visuelle Signale**:
  1. Ein leicht transparentes, abgerundetes Rechteck als Hintergrund-Band
     über die volle Zeilenhöhe an dieser Notenposition (Amber, sehr blass).
  2. Eine vertikale Linie mittig durch diese Position (Amber, kräftiger als
     das Band).
  3. Der Notenkopf selbst UND der R/L-Buchstabe darunter wechseln von ihrer
     Ruhefarbe auf **Amber** (bewusst nicht das App-Akzentorange — Amber ist
     reserviert für „gerade jetzt aktiv", Orange bleibt „ist ein Akzentschlag
     in der Notation") und der Notenkopf bekommt einen zusätzlichen dünnen
     Außenring.
- **Nichts blinkt/pulsiert am Notensystem selbst.** Es ist ein einzelnes,
  sich weiterbewegendes Highlight, kein Fade-in/Fade-out.
- Bei Stillstand (kein Playback) ist keine Position hervorgehoben — reiner
  Ruhezustand des Notensystems.

*Für das Redesign zu entscheiden:* Ob dieses „harte Springen" beibehalten
oder (siehe 60-cm-Distanz-Kontext in Abschnitt 2) durch ein stärkeres,
schneller peripher wahrnehmbares Signal ergänzt/ersetzt werden soll — das
aktuelle Amber-Band ist bei Halbdistanz-Sicht vermutlich zu subtil.

### 6.2 Metronom-Beat-Indikator (eigener, stärkerer Bewegungs-Mechanismus)

Ein großer Kreis, der bei jedem Beat pulsiert — bewusst als separates,
kräftigeres Bewegungssignal als das Notenwidget-Highlight konzipiert:
- Dauer 220 ms pro Puls, in zwei Phasen: **30 % der Zeit** Skalierung von
  100 % auf 145 % (beschleunigt auslaufend), **70 % der Zeit** zurück von
  145 % auf 100 % (beschleunigt einlaufend). Deckkraft läuft parallel von
  50 % → 100 % → 50 % im selben Zwei-Phasen-Timing.
- Ruhefarbe (kein Playback): sehr blasses Neutral. Spielend, unbetonter Beat:
  kräftigeres Neutral (70 % Deckkraft). Spielend, akzentuierter Beat (erster
  Schlag im Takt): App-Akzentorange **plus** weicher Orange-Glow (siehe
  Elevation/Schatten oben) — der einzige Schatten-Einsatz im ganzen UI.
- Kreisgröße im Ruhezustand ca. 80×80 (px-Basis, für Distanz-Lesbarkeit im
  Redesign eher zu klein — siehe 60-cm-Hinweis).

### 6.3 Cards / Container (durchgängiges Baumuster)

Zustände: **Standard** (dunkler Container, Radius 12, kein Rand) ·
**Betont/aktiv** (zusätzlich Farbrand + leicht getönter Hintergrund in
Akzentfarbe bei 12–30 % Alpha — z. B. Tages-Header im Programm-Screen, aktive
Routine-Kachel) · **Tappable** (per `InkWell`/`Material`, kein sichtbarer
Hover-/Pressed-Style über den Ripple-Default hinaus definiert) ·
**Loading** (feste Platzhalterhöhe mit zentriertem Spinner) ·
**Empty** (Emoji + Titel + Erklärtext, zentriert, oft mit CTA-Button darunter)
· **Error** (im Dashboard: Fehler werden meist komplett unsichtbar gemacht —
Karte kollabiert zu nichts statt eine Fehlermeldung zu zeigen; in
Vollbild-Screens dagegen: einfacher Text „Error: …“/„Fehler: …“ zentriert,
keine Retry-Aktion).

### 6.4 Badges / Chips

Drei wiederkehrende Familien, alle nach demselben Muster (Farbe bei 15 %
Alpha als Fläche + Farbe bei 40 % Alpha als 1px-Rand + Farbtext, Radius 4–6):
**Typ-Badge** (Review/Progress/New in Routine; Warmup/Technik/Tempo-
Leiter/Ausdauer im Programm), **Schwierigkeits-Badge** (Beginner…
Professional, feste Farben s. o.), **Filter-Chip** (Pill-Form, Radius 20,
zwei Zustände: unselektiert = neutral/dünner Rand, selektiert = Akzentfarbe
gefüllt bei 18 % + dickerer Akzentrand + Akzent-Textfarbe; animierter
Übergang 150 ms).

### 6.5 Buttons

**Primär** (voll gefüllt Akzentorange, weißer Text, Radius 12–14, meist volle
Breite, Mindesthöhe 50–56) — Zustand „Loading" existiert (Icon wird durch
kleinen weißen Spinner ersetzt, z. B. Exercise-Generator) und „Disabled"
(`onPressed: null` während Ladevorgang). **Sekundär/Outlined** (transparent,
heller Rand bei 24 % Alpha, heller Text) — für weniger wichtige Aktionen wie
„Tap Tempo", „Browse Lessons", „Neu starten". **Play/Stop-Kreisbutton**
(Metronom + kompaktes Metronom in der Practice-Session): 48–56 Durchmesser,
Kreisform, Farbwechsel Orange (Play) ↔ dunkles Rot (Stop), Icon wechselt mit.
**Icon-Only** (AppBar-Aktionen: Zahnrad, Mikro-Status-Icon — kein
Hintergrund, reine Icon-Farbe als Zustandsträger, z. B. Mikro an = Orange,
aus = sehr blasses Weiß).

### 6.6 Eingaben

**Slider** (BPM 40–240, 200 Schritte; Track Akzentorange aktiv, inaktiv
24 % Weiß) — Standardstil, keine Custom-Optik. **Segmented Selector**
(Subdivision-Auswahl Metronom, Sound-Type-Auswahl, Timer-Ziel-Auswahl,
Übungsziel-Minuten): horizontale Reihe gleich großer Pills/Kacheln,
selektiert = Akzentfüllung/-rand, 120–180 ms Animation beim Wechsel.
**Switch** (Settings-Toggles: Haptik, Erinnerungen, Mikrofon-Analyse) —
Standard-Material-Switch, aktiv = Akzentorange. **Textfeld** (API-Key-Eingabe,
Exercise-Generator-Beschreibung): dunkel gefüllt (`#151515`/`#1E1E1E`),
kein sichtbarer Rand im Ruhezustand, Akzentrand bei Fokus, optional
Sichtbarkeits-Toggle-Icon (API-Key ist standardmäßig maskiert).

### 6.7 Bottom Sheets & Dialoge

**Rating-Sheet** (nach Session-Ende): 3 große, gleich gebaute Auswahlkarten
(Emoji + Label + Konsequenz-Subtext „Keep the same BPM"/„+2 BPM next
time"/„+5 BPM next time"), je in einer eigenen Statusfarbe (Rot/Amber/Grün)
getönt. **Feedback-Sheet:** Session-Zusammenfassung, optional Mic-Analyse-
Block (Zeilen: Overall Timing, R-Hand, L-Hand, Konsistenz/Jitter, Dynamik
R/L, erkannte Schläge — reine Text-Zeilen, kein Chart), darunter die
Coach-Feedback-Card (s. u.), Abschluss-Button. **Bestätigungs-Dialog**
(„Sauber & locker?" im Programm-Screen): Standard-Alert mit Ja/Nein.

### 6.8 Coach-Feedback-Card (AI)

Eigener Container-Typ (einziger Ort mit der `#1A1A2E`-Farbe), vier Zustände:
**Loading** (kleiner zentrierter Orange-Spinner) · **Feedback vorhanden**
(Fließtext) · **Keine Mikrofon-Daten** (gedämpfter Hinweistext, erklärt dass
Mic-Analyse für nächstes Mal aktiviert werden kann) · **API-Fehler/kein
Feedback trotz Mic-Daten** (anderer gedämpfter Hinweistext, verweist auf
API-Key in Settings).

### 6.9 Stats-Visualisierungen (fl_chart) — siehe Abschnitt 7 für echte Daten

**Kalender-Heatmap:** Wochenspalten (Mo–So), quadratische Zellen (~13px),
5 Intensitätsstufen als Alpha-Abstufung der Akzentfarbe (0 Min = fast
unsichtbares Grau, dann 4 steigende Orange-Alpha-Stufen bis Volltonorange).
**Balkendiagramm** (letzte 14 Tage): schlichte Balken, heutiger Tag
hervorgehoben in Akzentorange, alle anderen neutral-hell, keine Achsenlinien/
Gitternetz, nur Datumsbeschriftung unten alle 7 Tage. **Liniendiagramm**
(BPM-Verlauf pro Übung, per Dropdown wählbar): gekurvte Linie, Punkte
sichtbar, Fläche unter der Linie leicht gefüllt (8 % Alpha), Y-Achse links
mit Zahlen, sonst achsenlos. **Empty-State** der Liniendiagramm-Karte, wenn
für die gewählte Übung noch keine Session existiert: reiner Hinweistext in
fester Kartenhöhe (kein leerer Graph).

---

## 7 · Realistische Beispieldaten (für Mockups, keine Lorem-Dummies)

### Übungskatalog (Auszug aus 41 echten Rudiments)

Single Stroke Roll (Beginner, 60–200 BPM) · Double Stroke Roll (Beginner,
60–180 BPM) · Multiple Bounce Roll (Intermediate, 40–100 BPM) · Single
Paradiddle (60–180 BPM) · Double Paradiddle · Flam · Flam Accent · Flamacue ·
Six Stroke Roll · „Akzent auf 2 und 4" · „Wandernder Akzent" · Moeller-
Bewegung · Eight on a Hand · Ghostnote-Training.

### Das feste 12-Wochen-Programm „Stick Control – 12 Wochen" (real, aus dem
Code, nutze das statt erfundener Phasen)

| Phase | Wochen | Übung | Start-BPM | Fokus (Ein-Satz-Text wie im echten UI) |
|---|---|---|---|---|
| 1 · Fundament | 1–3 | Single Stroke Roll | 70 | „Beide Hände exakt gleich hoch, exakt gleich laut. Locker greifen — der Stock soll federn, nicht gewürgt werden." |
| 2 · Fingerkontrolle | 4–6 | Double Stroke Roll | 60 | „Erster Schlag aus dem Handgelenk, zweiter aus dem Absprung." |
| 3 · Kontrolle | 7–9 | Single Paradiddle | 70 | „Akzent klar und voll, Taps klein und leise." |
| 4 · Tempo & Ausdauer | 10–12 | rotierend (Woche 10/11/12 = Singles/Doubles/Paradiddle) | 100 (oder gespeicherter Bestwert) | „Jetzt neue saubere Bestwerte holen." |

7 Tage/Woche-Rhythmus: Tag 1–5 = voller Übungstag (~15 Min: Warmup 3 Min +
Technik 8 Min + Tempo-Leiter 4 Min), Tag 6 = „light" (~8 Min, nur Warmup +
Technik, tieferes Tempo, keine Leiter), Tag 7 = Ruhetag (0 Min, kein Block).
→ Über 84 Tage: 60 Praxistage, 12 leichte Tage, 12 Ruhetage.

### Beispiel-Session-Log für Charts (Muster, an echte Werte angelehnt)

Nutzer übt „Single Stroke Roll", startet Phase 1 bei 70 BPM. Rating-Logik
im echten Code: 😓 „Struggled" → Tempo bleibt gleich, 😐 „OK" → +2 BPM nächstes
Mal, 💪 „Solid" → +5 BPM nächstes Mal. Realistischer 12-Wochen-Verlauf für
die BPM-Liniengrafik: Woche 1 ~70→78 BPM, Woche 2 ~80→90, Woche 3 ~90→98
(Phase-1-Ende), Phase-2-Sprung zurück auf 60 BPM (neue Übung: Double Stroke
Roll), dann erneuter Anstieg. Sessiondauer typischerweise 8–15 Minuten
(`durationSeconds`), Tagesminuten für die 14-Tage-Bar meist 15–25 Min an
Praxistagen, 0 an jedem 7. Tag (Ruhetag) — **das erzeugt bewusst Lücken im
Balkendiagramm/Heatmap, das ist korrektes Verhalten, keine fehlenden
Daten.** Streak-Beispiel: „14 day streak" mit „Best: 21 days", Ruhetage
brechen den Streak nicht (werden übersprungen, nicht als Lücke gezählt).

### Beispieltexte für Empty States (bereits im echten UI vorhanden, wörtlich)

„All caught up! – No reviews due today" (Dashboard) · „You're all caught up!
– No reviews due today. Great work!" (Routine, mit 🎉) · „No sessions yet –
Complete your first practice session to see stats here." (Stats, mit 🥁) ·
„Keine Übungen für diese Filterkombination." (Lessons-Filter) · „Ruhetag –
Frei. Kein Block heute — der Ruhetag zählt nicht gegen deinen Streak."
(Programm, mit 😴).

---

## 8 · Deliverable-Liste

1. **Style-Tile / Token-Vorschlag:** konsolidierte Farb-, Typo-, Spacing-,
   Radius-Skala als benanntes System (nicht mehr Ad-hoc-Literale wie im
   IST) — ausgehend von den Werten in Abschnitt 4, nicht komplett neu erfunden.
2. **High-Fidelity-Screens für alle 11 Screens**, je mit den in Abschnitt 6
   gelisteten relevanten Zuständen (mindestens: Ladezustand, Leerzustand,
   Normalzustand; wo vorhanden auch Fehlerzustand).
3. **Komponenten-Sheet:** Cards, Badges/Chips, Buttons, Eingaben, Sheets/
   Dialoge als isolierte, benannte Bausteine mit allen Zuständen nebeneinander.
4. **Bewegungs-Spec** für Sticking-Notenwidget und Metronom-Beat-Indikator,
   konkret genug zum Implementieren (Timing, Easing, Farben je Phase) —
   Abschnitt 6.1/6.2 als Ausgangsbasis, gerne verbessert im Hinblick auf den
   60-cm-Distanz-Kontext aus Abschnitt 2.
5. **fl_chart-Screens mit den echten 12-Wochen-Beispieldaten** aus
   Abschnitt 7 (Kalender-Heatmap, 14-Tage-Balken, BPM-Liniendiagramm je
   Übung) inklusive ihrer Leerzustände.
6. **Kurzbegründung** (kein langes Dokument, ein paar Sätze) je größere
   Design-Entscheidung, die von Abschnitt 3 (Ästhetik/Anti-Goals) oder
   Abschnitt 2 (60-cm-Lesbarkeit) abweicht oder sie besonders adressiert.

---

## OFFENE PUNKTE (nicht aus dem Code ableitbar — bitte entscheiden/rückfragen)

- **App-Icon/Branding fehlt komplett.** Kein Assets-/Fonts-Verzeichnis im
  Repo, Android-App-Label ist noch der Rohname „drum_coach", der
  MaterialApp-Titel ist „DrumCoach" — keine visuelle Markenidentität
  vorhanden außer dem 🥁-Emoji im Onboarding-Screen.
- **Landscape/Tablet:** technisch nicht gesperrt, aber nirgends layoutet.
  Ob das Redesign dafür vorsorgen soll, ist offen.
- **Fehlerzustände sind inkonsistent:** Auf dem Dashboard verschwinden
  fehlerhafte Karten komplett (keine Fehlermeldung sichtbar), auf
  Vollbild-Screens erscheint ein nackter Fehlertext ohne Retry-Möglichkeit.
  Ob das Redesign hier einen einheitlichen Fehlerzustand mit Retry vorsehen
  soll, ist eine offene Design-Entscheidung, keine Code-Vorgabe.
- **Zukunftsvision „Notation/Generator/Song-Sync"** (Mehrplattform,
  Kit-Modus, Song-Import, YouTube-Sync) existiert nur als separates
  Konzept-Dokument, ist **nicht** implementiert und nicht Teil des
  aktuellen UI. Falls das Redesign dafür schon Raum lassen soll, bitte
  explizit rückfragen — aus dem heutigen Code ist dazu nichts ableitbar.
- **Kein definiertes Verhalten für sehr lange Übungsnamen/Texte** auf
  kleinen Elementen (Badges, Dropdown) — im Code keine Overflow-Strategie
  über Standard-Flutter-Verhalten hinaus erkennbar.
- **Onboarding ist einmalig und hat keinen sichtbaren Wiederholungs-Weg**
  im UI (kein „Onboarding erneut zeigen" in Settings) — ob das gewollt
  bleibt, ist eine Produktentscheidung, keine reine Design-Frage.
