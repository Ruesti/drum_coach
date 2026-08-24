# Trainingsprogramm: "Stick Control – 12 Wochen" (DrumCoach)

> Ziel: Fortgeschrittener Anfänger → saubere, lockere Hände. Kein Set nötig, nur
> Pad + Stöcke. Gedacht für 3 Monate unterwegs, tägliche kurze Sessions.
> Tempo ist **Nebenprodukt** von Evenness + Lockerheit, nicht das Trainingsziel.

---

## 0. Leitprinzip (warum das Programm so gebaut ist)

Der klassische Fehler beim "schneller werden": fester greifen, aus dem Arm
spielen. Genau das bremst. Deshalb ist das Programm **gegated** – das Tempo steigt
nur nach einem *sauberen* Durchlauf, nie nach Zeit oder Wille. Die eigentliche
Metrik ist nicht bpm, sondern **L/R-Gleichheit** (Höhe + Lautstärke beider Hände).

Konsequenz fürs Datenmodell: jeder Block trägt ein `gate`, und der Fortschritt
wird pro Übung als *erreichtes sauberes Tempo* gespeichert – nicht als Maximaltempo.

---

## 1. Wochenrhythmus (freie Tage eingebaut)

Ein Wochenzyklus = 7 Tage, wiederholt über 12 Wochen:

| Wochentag | Typ        | Inhalt                                            |
|-----------|------------|---------------------------------------------------|
| Tag 1–5   | `practice` | Voller Block (Warmup + Technik + Tempo-Leiter)    |
| Tag 6     | `light`    | Nur Technik-Review, tiefes Tempo, **keine** Leiter |
| Tag 7     | `rest`     | Frei. Kein Block, zählt nicht gegen Streak.       |

Über 12 Wochen: 60 Practice-Tage, 12 Light-Tage, 12 Ruhetage. Nachhaltig auch
auf Reisen. `rest` und `light` sind **erste-Klasse-Tag-Typen**, damit der
Streak-Kalender frei geplante Pausen nicht als Abbruch wertet.

---

## 2. Die vier Phasen

| Phase | Wochen | Fokus (das *Warum*)                         | Kernübung                                   | Tempo-Start → Ziel (16tel) | Gate-Kriterium                          |
|-------|--------|---------------------------------------------|---------------------------------------------|----------------------------|-----------------------------------------|
| 1 · Fundament     | 1–3   | Evenness & Lockerheit. Beide Hände exakt gleich. | Stick Control, Single Beat Combinations (erste Seite), Zeilen 1–6 | 70 → offen | L/R-Höhe & -Lautstärke gleich, locker    |
| 2 · Fingerkontrolle | 4–6 | Übergang Handgelenk → Finger. Rebound nutzen.    | Fingerstroke-Isolation + Double-Stroke-Übungen (Rebound-Doubles) | 60 → offen | 2. Schlag kommt aus Absprung, nicht aktiv |
| 3 · Kontrolle     | 7–9   | Akzent/Tap-Trennung, Dynamik über die Zeile.     | Accent-&-Tap-Muster auf denselben Zeilen     | 70 → offen | Akzent klar, Taps gleich leise, kein Death Grip |
| 4 · Tempo & Ausdauer | 10–12 | Neue persönliche Bestwerte + längere saubere Läufe. | Alles kombiniert, Leiter-Push + Endurance-Runs | Bestwert → +X | 1 Min ununterbrochen sauber am neuen Tempo |

Regel: **Eine Zeile pro Session.** Tiefe schlägt Breite. Die Zeile wird in
mehreren Varianten geübt (siehe Blocktypen), nicht durch viele Zeilen gehetzt.

---

## 3. Aufbau eines Practice-Tags (15 Min)

| Block        | Dauer | Inhalt                                                        |
|--------------|-------|---------------------------------------------------------------|
| `warmup`     | 3 min | Lockere Single Strokes, tiefes Tempo, bewusst weicher Griff   |
| `technique`  | 8 min | *Eine* Zeile in 4 Varianten: even → pp → ff → crescendo        |
| `tempoLadder`| 4 min | Dieselbe Zeile, +4 bpm nur nach sauberem Durchlauf; bei Verkrampfung −4 |

`light`-Tag: nur `warmup` + `technique` bei tiefem Tempo. `rest`-Tag: leer.

---

## 4. Datenmodell (Isar-kompatibel)

Ergänzt die bestehenden Modelle (Rudiment, PracticeSession). Neue Collections:

```dart
@collection
class TrainingProgram {
  Id id = Isar.autoIncrement;
  late String name;            // "Stick Control – 12 Wochen"
  late String description;
  late int totalWeeks;         // 12
  final phases = IsarLinks<ProgramPhase>();
}

@collection
class ProgramPhase {
  Id id = Isar.autoIncrement;
  late int index;              // 1..4
  late String name;            // "Fundament"
  late String focus;           // das Warum (UI-Text)
  late int weekStart;          // 1
  late int weekEnd;            // 3
  late int startBpm;           // 70
  late String exerciseKey;     // Referenz auf Rudiment/Line
}

enum DayType { practice, light, rest }

@collection
class ProgramDay {
  Id id = Isar.autoIncrement;
  late int dayNumber;          // 1..84 (global)
  late int week;               // 1..12
  @enumerated late DayType type;
  late int estimatedMinutes;   // 15 / 8 / 0
  final blocks = IsarLinks<ExerciseBlock>();  // leer bei rest
}

enum BlockType { warmup, technique, tempoLadder, endurance }
enum Variant { even, pp, ff, crescendo, fingers, rebound, accentTap }

@embedded
class ExerciseBlock {
  @enumerated late BlockType type;
  late String exerciseKey;     // welche Zeile
  List<Variant> variants = []; // z.B. [even, pp, ff, crescendo]
  int? startBpm;
  int durationMinutes = 0;
  bool cleanPassRequired = false;  // Gate an/aus
}
```

Fortschritt hängt sich an die bestehende `PracticeSession` (dort `achievedBpm`);
zusätzlich pro `exerciseKey` ein "letztes sauberes Tempo" persistieren – das ist
der Startwert der nächsten Tempo-Leiter.

---

## 5. Daily-Routine-Generator: Regeln

Der Generator (existiert bereits) erzeugt die 84 `ProgramDay`-Objekte aus den
Phasen + Wochenrhythmus, statt sie hart zu speichern:

```
für tag in 1..84:
  week   = ceil(tag / 7)
  dow    = ((tag - 1) mod 7) + 1        // 1..7
  phase  = phase, deren [weekStart..weekEnd] die week enthält

  wenn dow in 1..5:  type = practice, blocks = [warmup, technique(phase), tempoLadder(phase)]
  wenn dow == 6:     type = light,    blocks = [warmup, technique(phase, tempo=phase.startBpm)]
  wenn dow == 7:     type = rest,     blocks = []

  technique(phase).variants =
     Phase 1 → [even, pp, ff, crescendo]
     Phase 2 → [fingers, rebound]
     Phase 3 → [accentTap, even]
     Phase 4 → [even, endurance]
  tempoLadder.startBpm = last_clean_bpm(phase.exerciseKey) ?? phase.startBpm
  tempoLadder.cleanPassRequired = true
```

So bleibt das Programm datengetrieben: eine neue Phase = ein Datensatz, kein Code.

---

## 6. Gate-Logik (heute manuell, später Mikro)

**Jetzt (ohne Mikro):** Nach der Tempo-Leiter fragt die UI knapp:
"Sauber & locker durchgelaufen?" → Ja hebt das gespeicherte saubere Tempo um
+4 bpm, Nein lässt es stehen. Bewusst self-rated, ehrlich mit sich selbst.

**Später (Phase 8, Mikro-Input):** Das Gate wird messbar. Interessante Metrik
ist **nicht** bpm, sondern die **L/R-Lautstärkedifferenz** pro Schlagpaar. Ein
"clean pass" = Tempo gehalten UND L/R-Abweichung unter Schwelle x %. Das Modell
`ExerciseBlock.cleanPassRequired` bleibt gleich – nur die Auswertung wird vom
Menschen zur Analyse verschoben.

---

## 7. Claude-Code-Integrationsprompt

```
Add a "Training Program" feature to DrumCoach that plays a fixed multi-week
curriculum with rest days, on top of the existing Daily Routine Generator.

New Isar collections: TrainingProgram, ProgramPhase, ProgramDay (with a
DayType enum: practice | light | rest), and an embedded ExerciseBlock
(BlockType: warmup | technique | tempoLadder | endurance; Variant enum).
See data model in STICK_CONTROL_PROGRAM.md §4 — match it exactly.

Requirements:
1. Seed one program: "Stick Control – 12 Wochen", 12 weeks, 4 phases as in §2.
2. Extend the Daily Routine Generator to expand ProgramDays from phases +
   the weekly rhythm in §5 (do NOT hard-store 84 days). rest days produce
   an empty block list and must NOT break the streak calendar.
3. Persist a "last clean bpm" per exerciseKey; it seeds the next tempo ladder.
4. Program screen: current day, phase focus text, blocks with target tempo,
   and a start button. rest days show a distinct "Ruhetag" state.
5. After a tempoLadder block, ask "Sauber & locker?" (yes → +4 bpm to the
   stored clean tempo, no → keep). Keep this behind ExerciseBlock.cleanPassRequired
   so a later mic-based gate can replace the self-rating without model changes.

Riverpod (@riverpod codegen), go_router, Material 3 dark theme. Follow the
conventions already in CLAUDE.md. Do not touch the metronome engine.
```

---

## 8. Definition of Done

- [ ] Programm "Stick Control – 12 Wochen" ist geseedet, 4 Phasen korrekt.
- [ ] Generator erzeugt 84 Tage; dow 6 = `light`, dow 7 = `rest`.
- [ ] `rest`-Tage brechen den Streak **nicht**.
- [ ] Tempo-Leiter startet beim gespeicherten sauberen Tempo, nicht bei 0.
- [ ] "Sauber & locker?"-Abfrage hebt/erhält das saubere Tempo korrekt.
- [ ] Ein voller Durchlauf Tag 1 → Tag 8 (inkl. Ruhetag) manuell getestet.
- [ ] Gate-Feld bleibt mic-ready (kein self-rating hartcodiert im Modell).

---

## 9. Phaseninhalt & Übungs-Seed

### 9.1 Kern-Übungen (nur drei — mappt auf das bestehende `Rudiment`-Modell)

Das ganze Programm läuft über drei Zeilen. Der Fortschritt entsteht aus den
*Varianten*, nicht aus mehr Material.

| exerciseKey     | Name           | Sticking (16tel)      | category      | minBpm | maxBpm | difficulty |
|-----------------|----------------|-----------------------|---------------|--------|--------|------------|
| `sc_singles`    | Single Strokes | `R L R L R L R L`     | single_stroke | 60     | 200    | 1          |
| `sc_doubles`    | Double Strokes | `R R L L R R L L`     | double_stroke | 50     | 180    | 2          |
| `sc_paradiddle` | Single Paradiddle | `R L R R  L R L L`  | paradiddle    | 60     | 180    | 3          |

Seed (Dart, an bestehende `Rudiment`-Seedliste anhängen):

```dart
final stickControlRudiments = [
  Rudiment(
    key: 'sc_singles',
    name: 'Single Strokes',
    sticking: 'RLRL RLRL',
    category: RudimentCategory.singleStroke,
    minBpm: 60, maxBpm: 200, difficulty: 1,
    description: 'Grundlage für alles. Beide Hände exakt gleich.',
  ),
  Rudiment(
    key: 'sc_doubles',
    name: 'Double Strokes',
    sticking: 'RRLL RRLL',
    category: RudimentCategory.doubleStroke,
    minBpm: 50, maxBpm: 180, difficulty: 2,
    description: 'Zweiter Schlag aus dem Rebound, nicht aktiv geschlagen.',
  ),
  Rudiment(
    key: 'sc_paradiddle',
    name: 'Single Paradiddle',
    sticking: 'RLRR LRLL',
    category: RudimentCategory.paradiddle,
    minBpm: 60, maxBpm: 180, difficulty: 3,
    description: 'Akzent auf dem ersten Schlag jeder Vierergruppe.',
  ),
];
```

### 9.2 Pro Phase: `focus`-Text (App-Screen) + `exerciseKey` + Varianten

Die `focus`-Strings sind so gebaut, dass sie 1:1 im Programm-Screen stehen können —
kurz, ein Gedanke, kein Fachchinesisch.

**Phase 1 · Fundament (W1–3)** — `exerciseKey: sc_singles` · startBpm 70
`variants: [even, pp, ff, crescendo]`
> **focus:** „Beide Hände exakt gleich hoch, exakt gleich laut. Locker greifen —
> der Stock soll federn, nicht gewürgt werden. Kein Tempo suchen; Gleichheit ist
> das Ziel."
> **cue (kleiner Zweitzeiler / Tooltip):** „Von vorne filmen. Die schwache Hand
> schlägt fast immer tiefer — genau das angleichen."

**Phase 2 · Fingerkontrolle (W4–6)** — `exerciseKey: sc_doubles` · startBpm 60
`variants: [fingers, rebound]`
> **focus:** „Erster Schlag aus dem Handgelenk, zweiter aus dem Absprung. Die
> Finger fangen den zweiten nur — du schlägst ihn nicht aktiv. Handgelenk ruhiger,
> Finger arbeiten."
> **cue:** „Fühlt sich anfangs schwach an. Dieser Muskel ist genau der, der dir
> zum Tempo gefehlt hat."

**Phase 3 · Kontrolle (W7–9)** — `exerciseKey: sc_paradiddle` (+ `sc_singles`) · startBpm 70
`variants: [accentTap, even]`
> **focus:** „Akzent klar und voll, Taps klein und leise — der Unterschied kommt
> aus der Stockhöhe, nicht aus mehr Kraft. Zwischen Akzent und Tap darf der Griff
> nicht verkrampfen."
> **cue:** „Beim Paradiddle liegt der Akzent auf dem ersten Schlag jeder Gruppe.
> Die restlichen drei bleiben klein und gleich."

**Phase 4 · Tempo & Ausdauer (W10–12)** — rotiert wöchentlich · startBpm = Bestwert
`variants: [even, endurance]`
- W10 → `sc_singles` · W11 → `sc_doubles` · W12 → `sc_paradiddle`
> **focus:** „Jetzt neue saubere Bestwerte holen. Die Regel bleibt: Tempo nur nach
> lockerem, gleichmäßigem Durchlauf. Endurance-Läufe: zwei Minuten am Stück, ohne
> dass die Gleichheit zerfällt."
> **cue:** „Wenn es verkrampft, ist das Tempo zu hoch — vier zurück, sauber
> festigen, dann erneut."

### 9.3 Was das für den Generator (§5) bedeutet

- `phase.exerciseKey` und `phase.focus` sind jetzt gefüllt (Werte oben).
- Phase 4 ist der einzige Sonderfall: `exerciseKey` hängt von der Woche ab.
  Im Generator: `if phase.index == 4: exerciseKey = {10: sc_singles, 11: sc_doubles, 12: sc_paradiddle}[week]`.
- `cue` ist ein optionales zweites Textfeld auf `ProgramPhase` (z.B. `focusCue`),
  falls du Haupttext + Tooltip trennen willst. Sonst in `focus` mit reinnehmen.
