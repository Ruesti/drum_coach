# SP3 (+SP2) — Übungs-Sammlung: Rudiment-Étüden + Technik-Studien

**Datum:** 2026-08-10
**Branch:** `feature/drum-etudes` (baut auf SP1)
**Teil von:** [Roadmap](2026-08-09-drum-etudes-roadmap.md)
**Status:** Design, bereit zur Umsetzung

## Kontext

SP1 hat die Engine für gemischte Notenwerte geliefert. SP3 füllt sie mit den
eigentlichen Inhalten — den komplexen, mehrtaktigen Übungen, die der Nutzer sich
gewünscht hat — und bündelt die kleine **Sammlung (SP2)** mit, damit die neuen
Übungen als benannte, browsebare Gruppe erscheinen.

Alle Inhalte sind **original** (kein Kopieren des Drumeo-PDFs). Aufbau nach dem
Vorbild: pro Rudiment mehrere Étüden mit steigender Schwierigkeit.

## Locked Decisions (mit dem Nutzer abgestimmt)

- **10 Rudiments** als Basis (Auswahl unten).
- **5 Étüden pro Rudiment** — Schwierigkeit steigt **über die Übung selbst**
  (Komplexität) **und über das Tempo** (min→target BPM).
- **Ergänzende Studien:** je ~2 pro Typ — **Akzent-/Dynamik**,
  **Kombinations-/Koordinations**, **Roll-/Endurance** (~6 gesamt).
- Erscheinen als **benannte Sammlung** mit Untergruppen (pro Rudiment / pro
  Studien-Typ).
- Gerätetest (Optik/Audio) für SP1-Rendering **und** SP3-Inhalte erfolgt
  gebündelt (diese Maschine ist headless; hier nur strukturelle Validierung).

## Umfang

**10 Rudiments** (je 5 Étüden = ~50):
Single Stroke Roll · Double Stroke Roll · Single Paradiddle · Double Paradiddle ·
Paradiddle-diddle · Flam · Drag · Flam Accent · Five Stroke Roll ·
Swiss Army Triplet.

**~6 Technik-Studien:**
- Akzent/Dynamik ×2 (wandernde Akzente; Ghost-Note-Kontrolle)
- Kombination/Koordination ×2 (2–3 Rudiments zu einer Phrase verbunden)
- Roll/Endurance ×2 (lange Rolle mit Crescendo/Decrescendo; Ausdauer)

## Architektur

### 1. Sammlung (SP2) — Modell + Browse

`Rudiment` bekommt zwei optionale, rückwärtskompatible Felder:

```dart
final ExerciseCollection? collection;  // Default null (= Basis-Katalog)
final String? collectionGroup;          // Untergruppen-Überschrift, z.B. "Single Paradiddle"
```

```dart
enum ExerciseCollection {
  rudimentEtudes(label: 'Rudiment-Étüden'),
  techniqueStudies(label: 'Technik-Studien');
  final String label;
  const ExerciseCollection({required this.label});
}
```

- **Browse-Screen** (`collection_screen.dart`): zeigt die Einträge einer
  `ExerciseCollection`, gruppiert nach `collectionGroup` (Reihenfolge = Seed-
  Reihenfolge), jeder Eintrag navigiert zum bestehenden Practice-Screen
  (`/practice/:id`).
- **Routing:** `/collection/:name` in `router.dart`; **Dashboard-Eintrag**
  („Übungs-Sammlung") analog zum Programm-Eintrag.
- Dient zugleich als Pool-Grundlage für SP4 (`ProgramPool.newExercises`).

### 2. Authoring-DSL

Neue Datei `lib/features/lessons/data/etude_dsl.dart` mit reinen Helfern, die
`List<StrokeBeat>` liefern — sonst wird das Setzen von ~56 Übungen unwartbar:

```dart
const R = Hand.right, L = Hand.left;
StrokeBeat note(Hand h, NoteValue v, {bool accent, bool ghost, bool dotted, Tuplet tuplet, List<Hand> graces});
StrokeBeat rest(NoteValue v, {bool dotted, Tuplet tuplet});
List<StrokeBeat> run(List<Hand> hands, NoteValue v, {Tuplet tuplet, Set<int> accents}); // gleichwertige Noten
List<StrokeBeat> eighths(List<Hand> h, {Set<int> accents});
List<StrokeBeat> sixteenths(List<Hand> h, {Set<int> accents});
List<StrokeBeat> triplet8(List<Hand> h, {Set<int> accents});   // 1 Beat 8tel-Triole
List<StrokeBeat> sextuplet16(List<Hand> h, {Set<int> accents});
StrokeBeat flam(Hand h, NoteValue v, {bool accent});           // graces:[andere Hand]
StrokeBeat drag(Hand h, NoteValue v, {bool accent});           // graces:[andere Hand ×2]
```

Plus eine reine Validierungsfunktion `int barCountOrThrow(List<StrokeBeat> beats, {int beatsPerBar, NoteGrid grid})`, die sicherstellt, dass **neue** Étüden ganze Takte füllen (Summe der Dauern = n × beatsPerBar) — im Test über alle Étüden angewandt.

### 3. Inhalte — je eine Datei pro Rudiment/Gruppe

`lib/features/lessons/data/etudes/<slug>_etudes.dart`, jede exportiert
`final List<Rudiment> <slug>Etudes = [...]` (nicht `const`, da DSL zur Laufzeit
baut). Aggregator `lib/features/lessons/data/etudes.dart`:

```dart
final List<Rudiment> allEtudes = [
  ...singleStrokeRollEtudes, ...doubleStrokeRollEtudes, /* … */ ...techniqueStudies,
];
```

`lessons_provider.dart`: `rudimentsProvider` liefert
`[...rudimentsSeedData, ...allEtudes]`. Fortschritt/SR/Programm greifen
automatisch per `id`.

**Étüden-Progression (Template, pro Rudiment):** Die 5 Étüden steigern
Komplexität *und* Tempo:
1. Reines Rudiment, 2–4 Takte, langsames Tempo — Sauberkeit.
2. Mit Akzenten auf Zählzeiten.
3. Phrasiert (Pausen, Orchestrierung um den Grundschlag).
4. Gemischt mit einer zweiten Subdivision / Feel.
5. „Challenge" — länger (4–8 Takte), synkopiert, höheres Ziel-Tempo.

`difficulty` und `minBpm`/`targetBpm` steigen über die 5. Jede Étude:
eindeutige `id` (`etude_<slug>_<n>`), `collection: rudimentEtudes`,
`collectionGroup: '<Rudiment-Name>'`, passende `skills`/`limbs`.

## Betroffene/neue Dateien

- `lib/features/lessons/models/rudiment.dart` — `ExerciseCollection` + 2 Felder.
- `lib/features/lessons/data/etude_dsl.dart` — NEU (DSL + Validierung).
- `lib/features/lessons/data/etudes/*.dart` — NEU (10 Rudiment-Dateien + `technique_studies.dart`).
- `lib/features/lessons/data/etudes.dart` — NEU (Aggregator).
- `lib/features/lessons/lessons_provider.dart` — Provider hängt `allEtudes` an.
- `lib/features/lessons/collection_screen.dart` — NEU (Browse).
- `lib/app/router.dart` — Route `/collection/:name`.
- `lib/features/dashboard/dashboard_screen.dart` — Sammlungs-Eintrag.
- Tests: `etude_dsl_test.dart`, `etudes_integrity_test.dart` (eindeutige ids
  über den **kombinierten** Katalog; jede Étude füllt ganze Takte; 24-Tick-
  Invariante), `collection_screen_test.dart` (rendert/gruppiert).

## Teststrategie

- DSL rein/unit-getestet (Dauer, Akzente, Flam/Drag-graces, Tuolen,
  `barCountOrThrow`).
- **Étüden-Integrität** über `allEtudes`: eindeutige ids (auch vs. Seed), jede
  Étude füllt ganze Takte, jede Note auf Integer-24-Tick.
- Browse-Screen: Widget-Test (rendert, gruppiert nach `collectionGroup`).
- `renders every seeded pattern without throwing` deckt jetzt auch `allEtudes`
  ab (Provider-Katalog erweitern lassen bzw. separater Render-Smoke-Test über
  `allEtudes`).
- **Gerät (gebündelt mit SP1):** Optik der Étüden + Audio-Sync auf PC/Handy.

## Nicht-Ziele (SP3)

- Kein adaptives Programm (SP4).
- Keine ausführliche Technik-Prosa pro Übung (optional; ggf. eine Kurz-Notiz
  pro Gruppe statt pro Étude — YAGNI).
- Keine Backing-Tracks / Audio-Playalongs.
