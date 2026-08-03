# Design: Kategorie → Tag-Achsen (Migrationsschritt 2)

> Für `BRIEF_DRUM_COACH_ERWEITERUNG.md`, Migrationsschritt 2 aus `docs/AUDIT.md` §6.
> Baut auf Migrationsschritt 1 auf (`ExerciseSource`/`ExerciseVoicing`-Felder, FK-Rename
> `rudimentId` → `exerciseId`, bereits gemergt in `feature/training-program-stick-control`).

## Kontext

`docs/AUDIT.md` §6 Schritt 2 verlangt, den heutigen flachen `category: String` (ein
Rudiment gehört zu genau einer von 13 Kategorien) durch die im Brief geforderten
Mehrachsen-Tags zu ersetzen: "Ein Linear-Fill trainiert gleichzeitig Fill, Koordination
und Weak Hand — in einem Baum läge er immer falsch." Phase 0.5 (`docs/AUDIT.md`,
Abschnitt "Phase 0.5") hat zusätzlich bereits entschieden: die kuratierte,
`level`-basierte `practicePlanProvider`-Spur entfällt zugunsten der adaptiven
`dailyRoutineProvider`-Planung — es soll danach kein zweites Organisationssystem mehr
geben.

Zwei Scope-Entscheidungen wurden vor diesem Design per Rückfrage geklärt:
1. Von den sechs im Brief genannten Achsen werden nur vier als echte, statische Tags
   implementiert: **Skill, Genre, Subdivision, Gliedmaßen**. *Tempo-Zone* (Kontrolle/
   Arbeitstempo/Chops) ist laut Brief selbst kein Tag, sondern eine Laufzeit-Ableitung
   aus aktuellem BPM vs. `targetBpm` (Brief-Abschnitt "Modi statt Kategorien") — sie
   gehört in einen späteren "Modi"-Schritt, nicht in dieses Datenmodell. *Modus-Eignung*
   (pad-tauglich/set-erforderlich) ist inhaltlich deckungsgleich mit dem in Schritt 1
   bereits eingeführten `voicing`-Feld (`pad`/`kit`) — ein zweites Feld dafür wäre
   Redundanz.
2. Die Lessons-Screen-UI bekommt in diesem Schritt eine vollwertige
   Multi-Achsen-Filter-UI (nicht nur eine minimale Ersatzgruppierung).

## Datenmodell (`lib/features/lessons/models/rudiment.dart`)

Drei neue Enums:

```dart
enum Skill { control, coordination, endurance, groove, fill, independence }
enum Genre { rock, funk, jazz, latin, metal, drumCorps }
enum Limb { hands, feet, doubleBass, allFour }
```

`Rudiment` bekommt drei neue Felder:

```dart
final Set<Skill> skills;   // required, mind. 1 Wert
final Set<Genre> genres;   // default {}
final Set<Limb> limbs;     // default {Limb.hands}
```

**Subdivision wird kein eigenes Feld.** Sie deckt sich inhaltlich mit dem bereits
existierenden `gridUnit` (`NoteGrid`), das die Notenwerte des Patterns steuert — ein
paralleles Tag-Feld wäre dieselbe Art Redundanz, die wir bei Tempo-Zone/`voicing`
bewusst vermieden haben. Stattdessen wird `NoteGrid` um die zwei im Brief genannten,
heute fehlenden Werte ergänzt:

```dart
enum NoteGrid {
  quarter(cellsPerQuarter: 1),
  eighth(cellsPerQuarter: 2),
  triplet(cellsPerQuarter: 3),
  sixteenth(cellsPerQuarter: 4),
  sixteenthTriplet(cellsPerQuarter: 6),
  thirtySecond(cellsPerQuarter: 8);
  ...
}
```

Die Filter-UI liest die Subdivision-Achse direkt aus `rudiment.gridUnit`.

**Entfernt:**
- `Rudiment.category` (`String`) — vollständig ersetzt durch die Tag-Achsen.
- `Rudiment.level` (`int?`) — Phase-0.5-Beschluss: die kuratierte Plan-Spur entfällt.
- `rudimentCategories`, `exerciseCategories` (`rudiments_seed.dart`) — keine
  Kategorielisten mehr.
- `practicePlanProvider` (`lessons_provider.dart`).
- `_PracticePlanList`, `_LevelBadge`, der "Plan"-Tab in `lessons_screen.dart`.

`dailyRoutineProvider` (`features/learning/routine_provider.dart`) ist danach die
einzige Planungsspur — unverändert, da er nie von `category`/`level` abhing.

## Retagging der 41 Seed-Einträge

Mechanisches Mapping von der alten `category` auf die neuen Achsen (kein
Einzelfall-Tagging pro Übung — 41 Einträge sind reine Pad-Technik ohne
Grooves/Fills/Independence-Inhalt, daher ist eine ehrliche, grobe Zuordnung
angemessener als erzwungene Vielfalt):

| alte `category` | `skills` | `genres` |
|---|---|---|
| Rolls | `{control}` | — |
| Paradiddles | `{control, coordination}` | — |
| Flams | `{control}` | — |
| Ruffs | `{control}` | — |
| Ghost Notes | `{control}` | — |
| Linear Patterns | `{coordination, fill}` | — |
| Marching Snare | `{control}` | `{drumCorps}` |
| Geschwindigkeit | `{control}` | — |
| Stockkontrolle | `{control}` | — |
| Ausdauer | `{endurance}` | — |
| Akzente | `{control}` | — |
| Dynamik & Ghost Notes | `{control}` | — |
| Timing & Gleichmäßigkeit | `{control}` | — |

`limbs` bleibt für alle 41 Einträge beim Default `{Limb.hands}` (keine
Fuß-/Doublebass-Inhalte im heutigen Katalog) — kein expliziter Override nötig.

Die 7 Marching-Snare-Einträge (`eight_on_a_hand`, `flam_accent` [Duplikat-ID,
siehe unten], `flam_tap`, `flamacue`, `flam_paradiddle` [Duplikat-ID], `cheese`,
`inverted_flam_tap`) sind die einzigen mit einem `Genre`-Tag — echte Drum-Corps-Stücke.

*Anmerkung (kein Scope dieses Schritts, aber beim Retagging per Skript-Check
aufgefallen):* `rudiments_seed.dart` enthält drei ID-Kollisionen — `flam_accent`,
`flam_paradiddle` und `paradiddle_diddle` existieren je zweimal mit
unterschiedlichem Inhalt (einmal als "echtes" Rudiment, einmal als Übung mit
`level` in einer der `exerciseCategories`). `rudimentById` (`firstWhere`) liefert
dadurch nur den ersten Treffer, der zweite ist über die Detail-Route nie
erreichbar. Das bleibt für diesen Schritt unangetastet und wird nicht
stillschweigend "repariert" — wird nur hier dokumentiert, damit es nicht als neuer
Bug missverstanden wird.

## Provider (`lib/features/lessons/lessons_provider.dart`)

`groupedRudiments` entfällt ersatzlos. Kein neuer Riverpod-Provider fürs Filtern —
41 Einträge werden clientseitig in der Screen-State gefiltert, wie der heutige
`_filter`-State es bereits tut. `rudimentsProvider` und `rudimentByIdProvider`
bleiben unverändert.

## UI (`lib/features/lessons/lessons_screen.dart`, `lesson_detail_screen.dart`)

Die 5 Tabs (Alle/Rudiments/Marching/Übungen/Plan) werden durch Filterchip-Reihen
pro Achse ersetzt:
- **Skill**-Chips (6 Werte)
- **Genre**-Chips (nur die Werte, die tatsächlich in `rudimentsSeedData` vorkommen —
  aktuell nur `drumCorps` — damit die Zeile nicht mit leeren Optionen vollläuft)
- **Gliedmaßen**-Chips (4 Werte)
- **Subdivision**-Chips (aus `gridUnit`, nur vorkommende Werte)

Mehrfachauswahl **innerhalb** einer Achse = ODER, **zwischen** Achsen = UND
(Standard-Facettenfilter-UX). Ergebnis ist eine flache, gefilterte Liste
(`_RudimentTile`, wie heute) ohne Kategorie-Gruppenüberschriften — bei keiner
Auswahl zeigt die Liste alle 41 Einträge.

`_RudimentTile` verliert die `_LevelBadge` (Feld entfällt), bleibt sonst
unverändert (Name, BPM-Range, Difficulty-Chip).

`lesson_detail_screen.dart`s `_MetaRow` ersetzt den einzelnen
`Icons.folder_outlined`-Kategorie-Chip durch je einen `_InfoChip` pro
`Skill`-Tag (und, falls vorhanden, pro `Genre`-Tag) der Übung.

`lib/features/coaching/exercise_generator_screen.dart` (`buildGeneratedRudiment`)
verliert das `category: ''`-Argument; setzt `skills: {}` nicht explizit
(Default reicht, da KI-generierte Übungen bisher keine Skill-Klassifikation haben —
das ist eine bekannte Lücke, kein Bug: der Freitext-Generator klassifiziert heute
nicht nach Skill, das ist außerhalb dieses Schritts).

## Tests

- `test/lessons/rudiment_model_test.dart` — `category:`-Argumente aus den
  Test-Fixtures entfernen, `skills: {Skill.control}` ergänzen (Pflichtfeld).
- `test/coaching/exercise_generator_rudiment_test.dart` — unverändert in der
  Aussage, nur Fixture-Anpassung falls `buildGeneratedRudiment` intern
  `Rudiment(...)` mit `category:` konstruiert (wird entfernt).
- `test/notation_staff_test.dart` — die Gruppe `practice plan` (testet
  `practicePlanProvider`/`exerciseCategories`) wird ersetzt durch eine neue Gruppe,
  die die Tag-Konsistenz aller 41 Seed-Einträge prüft: jeder Eintrag hat mindestens
  einen `Skill`-Tag; jeder in der obigen Mapping-Tabelle erwartete `Genre`-Tag ist
  tatsächlich vorhanden (Regressionsschutz fürs Retagging).
- Neuer Test für die Filterlogik in `lessons_screen.dart` (falls die
  ODER/UND-Kombinatorik als eigene pure Funktion extrahiert wird, s.
  Implementierungsplan) — Achsen-intern ODER, achsen-übergreifend UND, leere
  Auswahl = alle.

## Nicht im Scope dieses Schritts

- Die drei ID-Kollisionen in `rudiments_seed.dart` (siehe Anmerkung oben).
- Skill-Klassifikation für KI-generierte Übungen.
- Genre-Vielfalt jenseits `drumCorps` — kommt erst mit Groove-Generator-Content.
- Tempo-Zone- und Modus-Eignung-UI (Speed-Modus, Weak-Hand-Modus) — eigener
  späterer Schritt laut `docs/AUDIT.md` §6.
