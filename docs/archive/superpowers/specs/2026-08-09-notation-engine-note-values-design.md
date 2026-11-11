# SP1 — Notations-Engine mit echten Notenwerten

**Datum:** 2026-08-09
**Branch:** `feature/drum-etudes`
**Teil von:** [Roadmap](2026-08-09-drum-etudes-roadmap.md)
**Status:** Design, bereit zur Nutzer-Durchsicht

## Kontext

Das heutige Übungs-Modell bildet **einen `StrokeBeat` auf einen Metronom-Tick** ab
und kennt nur **eine** Subdivision pro Übung (`gridUnit`). Damit lassen sich keine
Übungen mit gemischten Notenwerten (z. B. Viertel + zwei Achtel + eine
Sechzehntel-Gruppe, oder Triolen neben geraden Werten) darstellen — genau das
brauchen „musikalische Lese-Étuden". SP1 schafft dieses Fundament, ohne das
erprobte Timing-Isolate umzuschreiben und ohne die 41 vorhandenen Übungen zu
brechen.

## Ziele

- Jede Note trägt einen **eigenen Notenwert** (Ganze … Zweiunddreißigstel,
  punktiert, Triolen/Sextolen).
- Renderer zeichnet **dauer-proportional** mit korrekten Fähnchen/Balken, Pausen,
  Tuolen-Klammern und Balken-Gruppierung pro Zählzeit.
- Playback spielt gemischte Rhythmen korrekt ab und bewegt den Cursor synchron —
  **ohne** Änderung am Timing-Isolate.
- Die 41 bestehenden Übungen laufen unverändert (automatische Migration).

## Nicht-Ziele (v1)

- **Mic-Analyse** wird nicht angepasst (bleibt auf dem alten „ein Tick"-Modell;
  in SP1 ausgeschaltet lassen bzw. separat behandeln).
- **Quintolen / beliebige Tuolen** außer Triole/Sextole — nicht Teil von v1
  (kommen im PDF-Material nicht vor; würden ein feineres Feinraster erzwingen).
- Voller **Kit-Voicing**-Modus (`ExerciseVoicing.kit`) — unberührt.
- Ein separater **hörbarer Metronom-Puls** parallel zur Referenz-Wiedergabe —
  v1 spielt die Noten als Referenz; optionaler Klick-Track ist späterer Schritt.

## Betroffene Dateien

- `lib/features/lessons/models/rudiment.dart` — Modell (`NoteValue`, `StrokeBeat`).
- `lib/shared/widgets/notation_staff_widget.dart` — Renderer (größter Neuteil).
- `lib/features/metronome/metronome_engine.dart` /
  `metronome_provider.dart` — beliebiger Tick-Faktor für Pattern-Playback.
- `lib/features/practice/practice_session_screen.dart` — Onset-Map + Cursor.
- `lib/features/coaching/exercise_generator_screen.dart` — nutzt den Renderer
  (nur prüfen/anpassen, dass es weiter kompiliert).
- Tests unter `test/…` — neue Unit-Tests für Dauer-/Onset-/Tuolen-Mathematik.

## Design

### 1. Datenmodell (`rudiment.dart`)

Neues Enum für Notenwerte, Dauer in Viertel-Einheiten:

```dart
enum NoteValue {
  whole(quarters: 4.0),
  half(quarters: 2.0),
  quarter(quarters: 1.0),
  eighth(quarters: 0.5),
  sixteenth(quarters: 0.25),
  thirtySecond(quarters: 0.125);
  final double quarters;
  const NoteValue({required this.quarters});
}

/// Tuolen-Markierung. `triplet` = 3 im Raum von 2 (Faktor 2/3),
/// `sextuplet` = 6 im Raum von 4 (Faktor 2/3 auf Sechzehntel).
enum Tuplet { none, triplet, sextuplet }
```

`StrokeBeat` bekommt drei neue Felder (rückwärtskompatibel per Default):

```dart
class StrokeBeat {
  final Hand hand;
  final bool isAccent;
  final bool isGhost;
  final bool isRest;
  final List<Hand> graces;
  final NoteValue? value;   // null ⇒ aus gridUnit ableiten (Altdaten)
  final bool dotted;        // Default false
  final Tuplet tuplet;      // Default Tuplet.none
  // … const-Konstruktoren erweitert, Defaults erhalten
}
```

Effektive Dauer (rein, testbar):

```dart
double effectiveQuarters(NoteValue value, {bool dotted = false, Tuplet tuplet = Tuplet.none}) {
  var q = value.quarters * (dotted ? 1.5 : 1.0);
  if (tuplet == Tuplet.triplet || tuplet == Tuplet.sextuplet) q *= 2 / 3;
  return q;
}
```

Beispiele (alle liegen sauber auf dem 24er-Feinraster, s. u.):
Viertel = 24 Ticks · Achtel = 12 · Sechzehntel = 6 · 32tel = 3 ·
Achtel-Triole = 8 · Sechzehntel-Sextole = 4 · punktierte Achtel = 18.

**Migration der Altdaten:** Ist `value == null`, wird der Notenwert aus `gridUnit`
abgeleitet (`eighth`→`NoteValue.eighth`, `triplet`→`eighth`+`Tuplet.triplet`,
`sixteenthTriplet`→`sixteenth`+`Tuplet.sextuplet`, usw.). Damit sind die 41
gleichmäßigen Alt-Patterns exakt dasselbe wie zuvor — **keine** Handarbeit pro
Eintrag nötig.

**Authoring-Helfer (DSL, optional in SP1, spätestens SP3):** freie Funktionen, die
`List<StrokeBeat>` liefern, damit die vielen Étuden lesbar bleiben:

```dart
eighths([R, L, R, L])        // ein Beat gerade Achtel
triplet8([R, L, R])          // ein Beat Achtel-Triole
sixteenths([R, L, R, L])     // ein Beat Sechzehntel
note(R, NoteValue.quarter, accent: true)
rest(NoteValue.eighth)
```

### 2. Renderer (`notation_staff_widget.dart`)

Umstellung von zell-uniform auf **dauer-proportionales Layout**:

- **X-Position** einer Note = kumulierte Dauer (in Vierteln) × `pxPerQuarter`,
  plus Bar-Offsets. `pxPerQuarter` wird so gewählt, dass ein Takt in die
  verfügbare Breite passt; Zeilenumbruch weiterhin an Taktgrenzen.
- **Notenwert-Glyphen:** Fähnchen-/Balkenanzahl aus `NoteValue`
  (Achtel = 1, Sechzehntel = 2, 32tel = 3; Viertel/größer = 0), punktierte
  Noten mit Punkt, halbe/ganze Noten mit offenem Kopf.
- **Balken-Gruppierung:** innerhalb einer Zählzeit über aufeinanderfolgende
  Noten gleicher/kompatibler Balkenzahl; Pausen und Beat-Grenzen brechen Gruppen
  (Logik analog zum vorhandenen `_paintBeamsAndNotes`, aber dauer-basiert).
- **Tuolen:** aufeinanderfolgende Noten mit gleicher `Tuplet`-Markierung in einer
  Zählzeit erhalten Klammer + Zahl („3" bzw. „6").
- **Pausen** korrekt je Notenwert (Viertel-/Achtel-/Sechzehntel-Pause).
- Vorhandene Glyph-Helfer (`_drawHead`, `_drawAccent`, `_drawGraces`, `_drawFlags`,
  `_drawRest`, R/L-Buchstaben, Cursor-Band) werden weiterverwendet/erweitert.
- **Cursor:** Position weiterhin über `activeIndex` (Noten-Index), aber die X-Lage
  kommt jetzt aus dem Dauer-Layout.

Die Layout-Berechnung (Note → X, Balken-Gruppen, Tuolen-Gruppen, Zeilenumbruch)
wird in eine **reine, testbare** Funktion/Struktur gezogen (getrennt vom Canvas-
Zeichnen), damit sie ohne Rendering geprüft werden kann.

### 3. Playback / Timing — Feinraster-Ansatz

**Kernidee:** Das Pattern wird intern auf ein festes Feinraster von
**24 Ticks/Viertel** abgebildet (kgV, deckt Achtel, Sechzehntel, 32tel,
Achtel-Triolen und Sechzehntel-Sextolen ganzzahlig ab). Jede Note belegt N Ticks
und **klingt nur auf ihrem Onset-Tick**.

Ableitung pro Übung (rein, testbar):

```dart
class PatternPlayback {
  final int ticksPerQuarter;      // = 24
  final int totalTicks;           // = gesamte Dauer in Ticks
  final List<double> tickVolumes; // Länge totalTicks; Onset-Tick = Notenlautstärke, sonst 0
  final List<int> onsetTicks;     // Onset-Tick je Noten-Index
  // tickToNoteIndex: für Cursor — letzter Onset ≤ aktuellem Tick
}
```

- `tickVolumes` wird in das **bereits vorhandene** `setPatternVolumes` gefüttert
  (heute zyklisch über `beatIndex % length`). Statt „ein Schlag/Tick" ist die
  Länge jetzt `totalTicks`; Nicht-Onset-Ticks haben Volume 0 → still.
- Der Metronom-Faktor wird auf `ticksPerQuarter` (24) gesetzt. Dazu bekommt der
  `MetronomeEngine`/`MetronomeNotifier` einen Pfad für einen **beliebigen
  Integer-Faktor** (z. B. `setPatternClock(int ticksPerQuarter)`), der intern
  `_cmdFactor` mit dem Wert sendet. Das Isolate rechnet `factor` bereits generisch
  (`60e6/bpm/factor`) — **keine** Isolate-Änderung.
- **Cursor:** `activeBeat` (Noten-Index) = `tickToNoteIndex[currentTick % totalTicks]`.
- Die Lautstärke-Zuordnung (Akzent/Ghost/Normal/Rest → Volume) bleibt wie in
  `_volumesFor`, nur auf Onset-Ticks angewandt.

**BPM bleibt Viertel-Puls** (Isolate: `idx % factor == 0` = Viertel). Tempo-Live-
Änderung funktioniert über die vorhandene Re-Anchoring-Logik unverändert.

### 4. Migration & Aufräumen

- Alt-Einträge: `value == null` → aus `gridUnit` abgeleitet; Rendering und
  Playback identisch zu heute (verifiziert per Golden/Sichttest an je einem
  Vertreter pro `gridUnit`).
- **Doppelte ids** im Seed (`paradiddle_diddle`, `flam_accent`,
  `flam_paradiddle`) werden im Zuge der Migration bereinigt (eindeutige ids),
  damit `rudimentById` deterministisch bleibt.

## Wichtigste Weichen (Empfehlung)

- **Timing:** Feinraster-Quantisierung statt Event-Scheduler → minimales Risiko,
  Isolate unangetastet.
- **Modell:** `NoteValue` + `Tuplet` statt roher Tick-Dauern → lesbares Authoring.
- **Feinraster 24/Viertel** genügt für alles im PDF-Material; Quintolen bewusst
  ausgeschlossen.

## Teststrategie

Rein/logisch (Unit-Tests auf dieser Maschine):

- `effectiveQuarters` für alle Werte/Punktierung/Tuolen.
- `PatternPlayback`: Onset-Ticks, `totalTicks`, `tickVolumes`-Länge und
  Onset-Positionen; `tickToNoteIndex`-Mapping (inkl. Wrap am Pattern-Ende).
- **Takt-Validierung:** Summe der Notendauern je Takt == `beatsPerBar` (schlägt
  fehlerhafte Étuden früh; auch als Test über alle Seed-Einträge).
- Layout-Funktion: X-Positionen, Balken-/Tuolen-Gruppen für Beispielpatterns.
- **Regressionstest Altdaten:** je ein Vertreter pro `gridUnit` erzeugt dieselben
  Onset-Ticks wie das bisherige uniforme Modell.

Rendering/Gerät (über `cross-machine-test-deploy`, PC/Laptop bzw. S23 Ultra):

- Sichtprüfung gemischter Étuden (gerade + Triolen in einer Zeile, punktierte
  Werte, Pausen, Tuolen-Klammern, mehrtaktig mit Umbruch).
- Playback-Sync: Cursor sitzt auf der klingenden Note; Timing-Jitter wie in PR #7
  gemessen.
- Bestehende Übungen unverändert (Regressions-Sichtprüfung).

## Verifikation (end-to-end)

1. `flutter test` (neue + bestehende Unit-Tests) auf dem NUC.
2. `flutter analyze` sauber.
3. Deploy auf PC/Laptop bzw. Android-Gerät via `cross-machine-test-deploy`:
   eine gemischt-notierte Test-Étude öffnen, abspielen, Notation + Cursor-Sync
   prüfen; einen bestehenden Eintrag (z. B. `single_paradiddle`) gegenprüfen.

## Risiken / offene Punkte

- Renderer-Layout für gemischte Balken/Tuolen ist die anspruchsvollste Stelle —
  reine Layout-Funktion + Golden-Tests halten das beherrschbar.
- `setPatternVolumes` mit langem `tickVolumes`-Array (bis ~24 × Viertel × Takte)
  und Faktor 24: bei 240 BPM ~96 Ticks/s — unkritisch, aber im Gerätetest zu
  bestätigen.
- Mic-Analyse ist danach temporär „falsch indexiert" — deshalb in v1 deaktiviert
  lassen, bis der Onset-Umbau dort nachgezogen ist.
