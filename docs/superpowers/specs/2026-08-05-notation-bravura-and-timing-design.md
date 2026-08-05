# Design: Notation-Engraving, weicher Cursor & einheitliches Tempo-Modell

**Datum:** 2026-08-05
**Branch:** `feat/notation-bravura-timing` (Basis: `feature/training-program-stick-control` @ 30d7517)
**Status:** Entwurf zur Freigabe

## Kontext & Motivation

Ausgangspunkt war der Wunsch „die Notation von Drumr gefällt mir" — konkret zwei Aspekte:
**Engraving-Look** (echtes Notenschriftbild) und **Playback-Gefühl** (weich mitlaufender Cursor).
Beim Testen kamen zwei Timing-Fehler dazu, die dieselbe Notations-/Timing-Kette betreffen:

- **Bug 1 — inkonsistente Geschwindigkeit:** Dieselbe Übung (z. B. Single Stroke Roll) klingt
  bei 140 BPM mal langsam, mal schnell. Es gibt keine feste Bezugsgröße.
- **Bug 2 — hörbarer Jitter:** Die Schläge klingen „nicht regelmäßig genug"; deutliche
  Abstands­unterschiede zwischen einzelnen Schlägen.

Weil alles in derselben Kette (Metronom-Engine → Provider → Screens → Notation) sitzt, wird es
zusammen entworfen.

## Ziele (Scope)

**Enthalten:**
1. **Bravura-Engraving** für die einzeilige Snare/Pad-Notation (`NotationStaffWidget`).
2. **Weich gleitender Playback-Cursor.**
3. **Einheitliches Tempo-Modell** (Bug 1): BPM = Viertel-Puls überall; Notenrate rein aus
   `gridUnit`; 4/4-Takt sichtbar als Anker.
4. **Jitter-Untersuchung** (Bug 2): on-device Instrumentierung + Messung. Der eigentliche Fix
   wird erst nach der Messung festgelegt (bewusste Entscheidung „erst instrumentieren").

**Nicht enthalten:** Voll-Kit-Notation, Kit-Animation, fertige Notationsbibliothek,
Änderungen an der Mikrofon-Analyse. Der konkrete Jitter-Fix (z. B. Lookahead-Scheduler) ist
Gegenstand einer Folge-Spec, sobald Messdaten vorliegen.

---

## Teil A — Bravura-Engraving

**Idee:** Die bestehende Layout-Engine (`_StaffPainter`) bleibt; die von Hand gezeichneten
Formen werden gegen echte **Bravura**-Glyphen getauscht, gerendert per `TextPainter` mit
`fontFamily: 'Bravura'`. Bravura ist die Referenz-SMuFL-Schriftart (SIL Open Font License).

**Größen-Mapping:** SMuFL definiert 1 em = 4 Notenlinien-Abstände. Mit dem heutigen
`_lineGap = 6px` folgt `glyphFontSize = 4 × _lineGap = 24px`. Damit skalieren Notenkopf,
Schlüssel und Pausen automatisch aufs System. `_lineGap` bleibt ein Tuning-Knopf, falls das
System insgesamt größer wirken soll.

**Glyph-Map** (Bravura-Codepoints):

| Element | heute | künftig |
|---|---|---|
| Perkussions-Schlüssel | 2 handgezeichnete Balken | `unpitchedPercussionClef1` U+E069 |
| Taktangabe-Ziffern | Text | `timeSig0`–`timeSig9` U+E080–E089 |
| Notenkopf | `drawOval` | `noteheadBlack` U+E0A4 |
| Pause (je Raster) | Squiggle/Punkte | `restQuarter/8th/16th/32nd` U+E4E5–E4E8 |
| Einzel-Fähnchen | Bézier | `flag8th/16th/32ndUp` U+E240/E242/E244 |
| Akzent | Pfad | `articAccentAbove` U+E4A0 (in Akzent-Orange eingefärbt) |
| Ghost-Klammern | Text `( )` | `noteheadParenthesisLeft/Right` U+E0F5/E0F6 |
| Vorschlag (Flam/Drag) | kleine Ovale | verkleinerter `noteheadBlack` + gezeichneter Slash |

**Rest-Mapping (Raster → Pausen-Glyph):**
`quarter → restQuarter`, `eighth/triplet → rest8th`, `sixteenth/sixteenthTriplet → rest16th`,
`thirtySecond → rest32nd`.

**Bleibt handgezeichnet** (korrekt, da SMuFL dafür keine Glyphen kennt): Notenlinien,
Taktstriche, **Hälse**, **Balken**, das Cursor-Band und die **R/L-Buchstaben**. Hälse werden nur
am Notenkopf-Ankerpunkt der Bravura-Köpfe neu ausgerichtet (empirisch, kein Metadaten-Parsing).

**Font-Einbindung:** `assets/fonts/Bravura.otf` (+ `OFL.txt` als Lizenz), deklariert in
`pubspec.yaml` unter `fonts: - family: Bravura`. Der `assets/`-Ordner entsteht neu.

**Bekannter Aufwand (Kalibrierung):** Glyphen sitzen an der Text-Grundlinie, nicht an der
Notenkopf-Mitte. Eine kleine **Anker-Tabelle** (dy-Versatz pro Glyph, in Notenlinien-Abständen)
wird einmalig kalibriert und zentral im Painter hinterlegt.

---

## Teil B — Weicher Cursor

**Heute:** Der Cursor springt bei jedem `beatIndex`-Event hart auf die Zelle
(`activeIndex` → Highlight-Band + Linie snappt).

**Künftig:** `NotationStaffWidget` wird `StatefulWidget` mit `SingleTickerProviderStateMixin`
und `AnimationController` (Bild-für-Bild-Uhr). Zwischen den Beat-Events läuft der Cursor
**kontinuierlich** im Tempo weiter; jedes eingehende Event ist ein **Re-Sync-Anker**, der die
Position exakt setzt und Drift korrigiert. Der Painter zeichnet Band + Linie an der
**fraktionalen** x-Position; der gerade passierte Notenkopf leuchtet aktiv.

**API-Erweiterung** (rückwärtskompatibel, alles optional):

```dart
NotationStaffWidget({
  required Rudiment rudiment,
  int? activeIndex,            // bestehend: diskreter Re-Sync-Anker
  Duration? perCellDuration,   // neu: Dauer einer Zelle beim aktuellen Tempo
  bool isPlaying = false,      // neu: nur dann läuft der Ticker
})
```

`perCellDuration` ist **dieselbe Größe** wie das Audio-Onset-Intervall aus Teil C
(`60000ms / bpm / gridUnit.cellsPerQuarter`). Sind die neuen Felder null/false
(Lesson- & Generator-Screen), verhält sich alles exakt wie heute (diskretes Springen).

**Wichtig (Test-Stabilität):** Der Ticker läuft nur bei `isPlaying`. In den statischen
Widget-Tests (kein `isPlaying`) startet kein Controller → keine „pending timer"-Fehler.

**Verworfene Alternative:** echten Audio-Playhead pro Frame aus `flutter_soloud` ziehen —
genauer, aber die Engine sendet heute nur diskrete Events; das wäre ein Engine-Umbau.
Interpolieren + Re-Sync ist der Standard und lässt die Audio-Schicht unberührt.

---

## Teil C — Einheitliches Tempo-Modell (Bug 1)

### Ursache

Die reale Notengeschwindigkeit ist heute `bpm × subdivision.factor`. Dabei ist `subdivision`
eine **separate, veränderliche globale Zustandsvariable** (der `MetronomeNotifier` ist
`keepAlive`-Singleton). Die Notation dagegen zeichnet Takte aus `gridUnit` + `beatsPerBar`.
Solange beide übereinstimmen, klingt es richtig — sie laufen aber auseinander bei:

1. **Deckel-Bug** (`practice_session_screen.dart`, `_subdivisionFor`): `sixteenthTriplet`
   (6 Zellen/Viertel) und `thirtySecond` (8) werden beide auf `Subdivision.sixteenth`
   (Faktor 4) abgebildet, weil die Engine keinen Faktor 6/8 kennt. → falsche Dichte, und
   `_beatVolumes[index % length]` verrutscht.
2. **Freie Subdivision** auf dem Metronom-Screen (`onSelected: notifier.setSubdivision`), deren
   Wert der globale Singleton behält.

### Invariante (Zielzustand)

> **BPM = Viertelnoten-Puls, überall gleich. Die Onset-Rate einer Übung ist ausschließlich
> `bpm × gridUnit.cellsPerQuarter` — abgeleitet aus denselben Feldern, die die Notation nutzt.**

Der Viertel-Puls bleibt damit für jede Übung bei gleichem BPM identisch (140 BPM → 428 ms/Viertel),
egal ob Achtel-, Sechzehntel- oder Triolen-Übung. Die *Oberflächen-Dichte* unterscheidet sich
korrekt nach `gridUnit` — aber nicht mehr willkürlich nach globalem Zustand.

### Umbau

- **Engine-Onset-Faktor wird ein reiner `int`** (Onsets pro Viertel), nicht mehr an die
  4-stufige `Subdivision`-Enum gekoppelt. `computeNextBeatDelayUs` nutzt den Faktor bereits als
  freie Zahl (`ivUs = 60000000 / bpm / factor`) — es ist nur die *Quelle* des Faktors zu
  generalisieren. Neue Methode `MetronomeEngine.setGridFactor(int cellsPerQuarter)` /
  entsprechende Provider-Durchreichung.
- **Zwei Setzer, nie gemischt** (beseitigt das Split-Brain):
  - *Plain-Metronom-Screen:* setzt den Faktor aus der `Subdivision`-Enum (1/4…1/16) — das ist
    dort eine bewusste Nutzerwahl fürs Click-Üben.
  - *Übungs-Playback (Practice):* setzt den Faktor **immer beim Eintritt** direkt aus
    `rudiment.gridUnit.cellsPerQuarter` (inkl. 6 und 8). Kein Deckeln, keine Abhängigkeit von
    hinterlassenem globalem Zustand.
- **`_subdivisionFor` entfällt** zugunsten von `gridUnit.cellsPerQuarter`.
- **Accent-Erkennung:** Der Isolate-Zweig `idx % factor == 0` betrifft nur den Plain-Metronom;
  im Übungs-Playback kommen Akzente aus `_beatVolumes`/`StrokeBeat.isAccent` und überschreiben
  ihn. Faktor 6/8 ist damit für Übungen unproblematisch.
- **4/4 sichtbar:** Die Notation zeichnet Taktstriche bereits aus `beatsPerBar`+`gridUnit`.
  Zusätzlich wird der **Viertel-Puls** dezent sichtbar gemacht (leichte Beat-Hilfslinien oder
  Beat-Zähler unter dem System), damit die Bezugsgröße lesbar ist. Cursor, Audio und Takte
  leiten sich dann alle aus demselben `(bpm, gridUnit, beatsPerBar)` ab.

---

## Teil D — Jitter-Untersuchung (Bug 2, „erst instrumentieren")

### Hypothese (aus Code-Analyse, noch nicht gemessen)

Der Timing-Isolate plant sauber, aber `SoLoud.instance.play()` wird in `_onBeat` ausgelöst, und
`_onBeat` läuft im **Haupt-Isolate** (die `ReceivePort`-Schleife wurde dort erzeugt) — *nach*
einem Isolate-Sprung, **zur Aufrufzeit** (kein sample-genaues Vorplanen). Zusätzlich feuert jeder
Schlag `state = copyWith(...)` → Widget-Rebuild im selben Isolate. Der Isolate korrigiert damit
die **Drift** (Durchschnittstempo), nicht den **Abstand einzelner Schläge**.

### Schritte

1. **Instrumentierung (dieser Umfang):** Sollzeit jedes Schlags im Isolate stempeln
   (`sw.elapsedMicroseconds` beim `send`) und mitsenden; im `_onBeat` die Ist-Zeit beim
   `play()`-Aufruf stempeln; Delta loggen. Hinter einem Debug-Flag, kein Overhead im Release.
2. **Messung on-device** (via `cross-machine-test-deploy` auf PC/Handy, da dieser Host headless
   ist): N Schläge bei z. B. 140 BPM Achtel aufzeichnen, Jitter-Statistik (Stdabw., Max, Muster)
   berechnen.
3. **Fix (Folge-Spec):** Auf Basis der Daten die dominante Quelle bestätigen und gezielt fixen —
   voraussichtlich Lookahead-Scheduler und/oder Entkopplung des UI-Rebuilds (Teil B nimmt den
   Cursor-`setState` pro Schlag bereits raus). **Hier nicht entschieden.**

---

## Betroffene Dateien

- `lib/shared/widgets/notation_staff_widget.dart` — Stateless→Stateful, Bravura-Glyphen,
  fraktionaler Cursor.
- `lib/features/metronome/metronome_engine.dart` — Onset-Faktor als freier `int`;
  Timing-Instrumentierung.
- `lib/features/metronome/metronome_provider.dart` — `setGridFactor` durchreichen;
  Instrumentierungs-Verdrahtung.
- `lib/features/practice/practice_session_screen.dart` — Onset-Faktor + `perCellDuration` aus
  `gridUnit` ableiten und an das Widget geben; `_subdivisionFor` entfernen.
- `pubspec.yaml` + `assets/fonts/Bravura.otf` + `assets/fonts/OFL.txt` — neu.
- `lib/features/lessons/lesson_detail_screen.dart`,
  `lib/features/coaching/exercise_generator_screen.dart` — **keine** Änderung (statisch, weiter
  gültig über die abwärtskompatible API).

## Tests & Verifikation

**Headless (auf diesem Host):**
- Unit-Test `onsetIntervalMs(bpm, gridUnit)`: Single Stroke Roll (eighth) @ 140 = 214 ms/Zelle;
  Sechzehntel-Übung @ 140 = 107 ms/Zelle; **derselbe** Viertel-Puls 428 ms für beide.
- Unit-Test `computeNextBeatDelayUs` mit Faktor 6 und 8 (heute ungetestet).
- Unit-Test Cursor-Interpolation (Anker + verstrichene Zeit → fraktionale Position).
- Unit-Test Raster→Glyph-Zuordnung (Pausen/Fähnchen-Codepoints).
- Bestehender `notation_staff_test.dart` bleibt grün (prüft nur „kein Fehler + Höhe > 0";
  Font-Fallback wirft nicht).

**On-device (via cross-machine):**
- Visuelle Prüfung des Bravura-Schriftbilds + weicher Cursor.
- Jitter-Messung (Teil D, Schritt 2).

## Risiken / offene Punkte

- **Font-Beschaffung** auf dem headless NUC: Download von Bravura vs. der User legt die Datei ab.
  Zu klären beim Umsetzen.
- **Bravura-Anker-Kalibrierung** (dy-Versatz pro Glyph) ist Handarbeit.
- **Engine-Faktor > 4:** prüfen, dass keine andere Stelle einen Faktor ≤ 4 annimmt
  (Accent-per-Faktor betrifft nur den Plain-Metronom).
- **Jitter-Fix aufgeschoben** bis Messdaten vorliegen (bewusst).
