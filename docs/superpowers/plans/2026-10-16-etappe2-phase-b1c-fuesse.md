# Etappe 2 / Phase B Teil 1c — Füße, Double Bass, mehr Fills und Grooves

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elf bis zwölf weitere Set-Blätter — Kick-Kontrolle, Kick-Sechzehntel, Double Bass (Achtel, Sechzehntel, Triolen), Hi-Hat-Fuß, Fuß-Ostinati, linearer Fill, Double-Bass-Fill, linearer Groove, Sechzehntel-Kick-Groove, optional Half-time Shuffle — und die eine Notenbild-Erweiterung, die Double Bass braucht: Fußbuchstaben R/L.

**Architecture:** Fußnoten dürfen eine Seite tragen (`StrokeBeat.hand` auf einer Fußstimme = Fußseite; DSL `foot(v, side: R)`; Notenschrift `K16r`/`K16l`). Ein Blatt mit Fußseiten bekommt eine höhere Kit-Reihe (146) mit einer zweiten Buchstabenzeile unter den Fuß-Hälsen; alles andere bleibt. Inhalt wie Teil 1: zwei neue Python-Sätze (`feet.py`, `set_more.py`) in der Spuren-Notenschrift, generiert mit `gen_dart.py`/`patch_seed.py`, Integritätstests, Goldens, Emulator.

**Tech Stack:** wie Teil 1 (Flutter 3.44 / Dart 3, Bravura, Python 3.13, abcjs).

**Spec:** `docs/superpowers/specs/2026-10-16-set-inhalt-fuesse-design.md` (Nachtrag B.4c) auf Basis von `docs/BRIEF_ETAPPE2_SET.md` Phase B; Teil-1-Plan `docs/superpowers/plans/2026-10-15-etappe2-phase-b1-set-mehrstimmig.md` (Konventionen, Werkzeuge).

## Global Constraints

- 24-Tick-Raster; alle Spuren einer Zeile gleich lang; Blatt ≤ 64 Takte; Form wie Teil 1 (8 Zeilen + Challenge; Grooves/Übungen 2 Takte je Zeile = 24 Takte, Fills 4 Takte je Zeile = 40 Takte).
- Fußseite: `r`/`l` nur auf `K`/`P`-Tokens; genau eine Seite je Note; Dart `foot(v, side: Hand.right|left)`; Messung ignoriert die Seite. Pausen und Fußnoten ohne Flag bleiben `hand: null`.
- Notenbild: Blätter ohne Fußseiten zeichnen **byte-gleich** wie in Teil 1 (alle vorhandenen Goldens bleiben unverändert). Blätter mit Fußseiten: Reihe **146**, Titel 96, Fußbuchstaben 114, Handbuchstaben 130, Zählsilben 146 (+ Zählband 14); Fußbuchstaben folgen dem Schalter „Sticking letters".
- Set-Übungen: `kit=True`, `requiredSensor: midi`, `backing=None`, `new_seed=True`, Limbs laut Tabelle (`feet`, `doubleBass`, `allFour`); `Limb.doubleBass` ⇒ mindestens eine Fußnote mit Seite im Blatt.
- Linear = nie zwei Stimmen auf demselben Tick (Integritätstest für `groove_linear` und die Fill-Takte von `set_fill_linear`).
- Katalog-Inhalt lebt einmal in Python; generierte Dart-Dateien nie von Hand ändern; `dart format` nur auf berührte/generierte Dateien im Repo-Baum.
- Lektion vier Abschnitte (`Why it matters`, `How to play it`, `Practice tips`, `Where you hear it`), Englisch, konkret; Beschreibung ein Satz.
- Jede Aufgabe: Test zuerst, `flutter analyze` ohne neue Meldungen, `flutter test` grün (Stand bei Start: 627 + 1 skipped), Python `cd tool/katalog && python3 -m unittest` grün, Commit.

## Review Focus

1. **Double-Bass-Zeile unter Hi-Hat-Vierteln:** Kick-Sechzehntel R L unter Hat-Vierteln — jede Kick-Spalte zeigt ihren Fußbuchstaben, die Hat-Spalten ihren Handbuchstaben, nichts überlappt (Reihe 146). Golden in Task 2, Test in Task 1 (`hasFootSides`).
2. **Blatt ohne Fußseiten nach dieser Änderung:** Reihe bleibt 132, Goldens aus Teil 1 byte-gleich. Test in Task 2 (bestehende Goldens laufen mit).
3. **Fußseite auf einer Handspur** (`R8r`) oder beide Seiten (`K8rl`): Parser lehnt ab. Test in Task 1.
4. **Linearer Fill mit Kick-Tokens:** `orchestrate` legt `K`-Tokens auf die `BD`-Spur, die Hände auf die geplanten Trommeln; kein Tick doppelt belegt; der Fill-Takt bekommt dann **nicht** zusätzlich `BD13`. Test in Task 4.
5. **Kick Control im Ganz-Blatt-Modus:** Zeilen mit und ohne Pedal-Spur wechseln — `SheetPlan.wholeSheet` füllt fehlende Spuren mit Pausen (Teil 1) — der Cursor läuft durch. Bestehender Test (Teil 1, Task 4) + Integritätstest `SheetPlan.wholeSheet` für jedes neue Blatt (Task 3/4).

---

## Dateistruktur

**Neu:** `tool/katalog/feet.py` (7 Blätter), `tool/katalog/set_more.py` (4–5 Blätter), `test/lessons/foot_side_test.dart`, `test/goldens/kit_staff_feet.png`, `test/goldens/kit_pattern_feet_double_bass_sixteenths.png`, `test/goldens/kit_pattern_feet_kick_control.png`, `test/goldens/kit_sheet_feet_double_bass_eighths.png`, generierte `lib/features/lessons/data/sheets/feet_*_sheet.dart`, `set_fill_linear_sheet.dart`, `set_fill_double_bass_sheet.dart`, `groove_linear_sheet.dart`, `groove_kick_sixteenths_sheet.dart` (+ optional `groove_halftime_shuffle_sheet.dart`).

**Geändert:** `lib/features/lessons/data/etude_dsl.dart` (`foot(side:)`), `lib/features/lessons/models/rudiment.dart` (`hasFootSides`), `lib/shared/widgets/sheet_geometry.dart` (`kitRowPitchWithFeet`, Pitch-Wahl), `lib/shared/widgets/notation_staff_widget.dart` (`footLetters`, Getter), `lib/shared/widgets/kit_staff_painting.dart` (Fußbuchstabe), `tool/katalog/sheetlang.py` (`r`/`l`, `Note.side`, Dart-Ausgabe), `tool/katalog/set_fills.py` (`orchestrate` mit Fuß-Tokens) oder `set_more.py` importiert und erweitert, `tool/katalog/katalog.py`, `tool/katalog/build_page.py` (Legendenzeile), `tool/katalog/test_kit.py`, `test/helpers/kit_fixtures.dart`, `test/lessons/kit_seed_integrity_test.dart`, `test/notation_kit_goldens_test.dart`, `lib/features/lessons/data/rudiments_seed.dart` (generiert), `docs/CLAUDE.md`.

---

### Task 1: Fußseite — DSL `foot(side:)`, `hasFootSides`, Notenschrift `r`/`l`

**Files:**
- Modify: `lib/features/lessons/data/etude_dsl.dart` (`foot`), `lib/features/lessons/models/rudiment.dart` (`voicesHaveFootSides`, `Rudiment.hasFootSides`)
- Modify: `tool/katalog/sheetlang.py` (`_TOKEN`, `Note.side`, `_parse_token`, `note_to_dart`)
- Test: `test/lessons/foot_side_test.dart`, `tool/katalog/test_kit.py` (Klasse `FootSide`)

**Interfaces:**
- Produces: `StrokeBeat foot(NoteValue v, {bool accent = false, bool ghost = false, bool dotted = false, Tuplet tuplet = Tuplet.none, Hand? side})` → `StrokeBeat(hand: side, …)`; `bool voicesHaveFootSides(Iterable<Voice> voices)` (irgendeine Fußstimme hat eine Nicht-Pausen-Note mit `hand != null`); `Rudiment.hasFootSides` (über `sheet` und `patternVoices`); Python `Note.side: str | None` (`'R'`/`'L'`), Token-Flags `r`/`l` nur auf `K`/`P`, `note_to_dart` ⇒ `foot(NoteValue.x[, …], side: R)`.

- [ ] **Step 1: Failing tests**

`test/lessons/foot_side_test.dart`:

```dart
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foot() may carry a side; without one it stays null', () {
    expect(foot(NoteValue.sixteenth, side: R).hand, Hand.right);
    expect(foot(NoteValue.sixteenth, side: L).hand, Hand.left);
    expect(foot(NoteValue.sixteenth).hand, isNull);
    expect(foot(NoteValue.eighth, side: R, accent: true).isAccent, isTrue);
  });

  test('voicesHaveFootSides: true only when a foot voice note carries a side', () {
    final hh = voice(KitInstrument.hiHatClosed, eighths([R, R, R, R, R, R, R, R]));
    final kickPlain = voice(KitInstrument.kick, [
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
    ]);
    final kickSided = voice(KitInstrument.kick, [
      for (var i = 0; i < 4; i++) ...[
        foot(NoteValue.eighth, side: R),
        foot(NoteValue.eighth, side: L),
      ],
    ]);
    expect(voicesHaveFootSides([hh, kickPlain]), isFalse);
    expect(voicesHaveFootSides([hh, kickSided]), isTrue);
    // A hand voice with hands is not a foot side.
    expect(voicesHaveFootSides([hh]), isFalse);
  });

  test('Rudiment.hasFootSides looks at the sheet and the pattern voices', () {
    final hh = voice(KitInstrument.hiHatClosed, eighths([R, R, R, R, R, R, R, R]));
    final db = voice(KitInstrument.kick, [
      for (var i = 0; i < 4; i++) ...[
        foot(NoteValue.eighth, side: R),
        foot(NoteValue.eighth, side: L),
      ],
    ]);
    final plain = voice(KitInstrument.kick, [foot(NoteValue.whole)]);
    Rudiment make({required List<Voice> pattern, required List<Voice> line}) =>
        Rudiment(
            id: 'x',
            name: 'X',
            description: '',
            minBpm: 60,
            targetBpm: 120,
            difficulty: Difficulty.beginner,
            sticking: pattern.first.beats,
            voicing: ExerciseVoicing.kit,
            requiredSensor: SensorLevel.midi,
            patternVoices: pattern,
            lines: [kitLine(line)]);
    expect(make(pattern: [hh, plain], line: [hh, plain]).hasFootSides, isFalse);
    expect(make(pattern: [hh, plain], line: [hh, db]).hasFootSides, isTrue);
    expect(make(pattern: [hh, db], line: [hh, plain]).hasFootSides, isTrue);
  });
}
```

`tool/katalog/test_kit.py`, Klasse dazu (vor dem `__main__`-Guard):

```python
class FootSide(unittest.TestCase):
    def test_side_flags_on_feet(self):
        notes = parse_line('K16r K16l K8 -4 -2').notes
        self.assertEqual([n.side for n in notes], ['R', 'L', None, None, None])
        self.assertEqual(note_to_dart(notes[0]), 'foot(NoteValue.sixteenth, side: R)')
        self.assertEqual(note_to_dart(notes[1]), 'foot(NoteValue.sixteenth, side: L)')
        self.assertEqual(note_to_dart(notes[2]), 'foot(NoteValue.eighth)')
        self.assertEqual(note_to_dart(parse_line('K8>r -8 -2.').notes[0]),
                         'foot(NoteValue.eighth, accent: true, side: R)')

    def test_side_only_on_feet_and_only_one(self):
        with self.assertRaises(ValueError):
            parse_line('R8r L8 R4 L4 R4')
        with self.assertRaises(ValueError):
            parse_line('K8rl -8 -4 -2')
        kl = parse_kit_line('HH: R4 R4 R4 R4\nBD: K16r K16l K16r K16l K4 -2')
        self.assertEqual([n.side for n in kl.tracks[1].notes][:4], ['R', 'L', 'R', 'L'])
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/lessons/foot_side_test.dart` → Kompilierfehler (`side`, `hasFootSides`); `cd tool/katalog && python3 -m unittest -v test_kit.FootSide` → `bad token 'K16r'`.

- [ ] **Step 3: Implementation**

`etude_dsl.dart`:

```dart
/// A foot stroke (kick, hi-hat pedal): no hand — or, for double bass, the
/// foot that plays it ([side]; Nachtrag B.4c). Measurement ignores the side.
StrokeBeat foot(NoteValue v,
        {bool accent = false,
        bool ghost = false,
        bool dotted = false,
        Tuplet tuplet = Tuplet.none,
        Hand? side}) =>
    StrokeBeat(
        hand: side,
        value: v,
        isAccent: accent,
        isGhost: ghost,
        dotted: dotted,
        tuplet: tuplet);
```

`rudiment.dart`, nach `class Voice`:

```dart
/// True when a foot voice carries a sided stroke (double bass, Nachtrag
/// B.4c): the sheet then draws a second letter row under the feet stems.
bool voicesHaveFootSides(Iterable<Voice> voices) => voices.any((v) =>
    v.isFoot && v.beats.any((b) => !b.isRest && b.hand != null));
```

und in `Rudiment` (nach `isKit`): `/// A foot voice with sides (double bass): second letter row (B.4c).` `bool get hasFootSides => voicesHaveFootSides(patternVoices) || sheet.any((l) => voicesHaveFootSides(l.voices));`

`sheetlang.py`: `_TOKEN = re.compile(r'^([RLKP])(32|16|8|4|2|1)([.>gfdrl]*)$')`; `Note` bekommt `side: str | None = None`; in `_parse_token` nach den Flags:

```python
    sides = [s for s in 'rl' if s in flags]
    if sides:
        if not n.is_foot:
            raise ValueError(f'side flag on a hand note {tok!r} (r/l belong to K/P)')
        if len(sides) > 1:
            raise ValueError(f'both sides on {tok!r}')
        n.side = sides[0].upper()
```

`note_to_dart`, Fußzweig: nach `ghost` → `if n.side: args.append(f'side: {n.side}')` (vor `args += extras`; die Dart-Konstanten `R`/`L` sind `Hand`-Werte aus `etude_dsl`).

- [ ] **Step 4: Run tests, commit**

`flutter analyze && flutter test test/lessons`; `cd tool/katalog && python3 -m unittest -v && python3 grooves.py && python3 set_fills.py`.

```bash
git add lib/features/lessons/data/etude_dsl.dart lib/features/lessons/models/rudiment.dart tool/katalog/sheetlang.py test/lessons/foot_side_test.dart tool/katalog/test_kit.py
git commit -m "feat(model): Fußseite — foot(side:), hasFootSides, Notenschrift K16r/K16l"
```

---

### Task 2: Notenbild — zweite Buchstabenzeile für Fußseiten (Reihe 146)

**Files:**
- Modify: `lib/shared/widgets/sheet_geometry.dart` (`kitRowPitchWithFeet`, Pitch-Wahl in `computeSheetGeometry`), `lib/shared/widgets/notation_staff_widget.dart` (`footLetters` am Painter und an beiden Widgets, Getter), `lib/shared/widgets/kit_staff_painting.dart` (Fußbuchstabe)
- Modify: `test/helpers/kit_fixtures.dart` (`doubleBassShowcase()`), `tool/katalog/build_page.py` (Legendenzeile „Fußseiten R/L nur in der App")
- Test: `test/notation_kit_staff_test.dart` (Gruppe „foot letters"), Golden `test/goldens/kit_staff_feet.png`

**Interfaces:**
- Produces: `const double kitRowPitchWithFeet = 146;` `_StaffPainter({…, bool footLetters = false})`; `SheetStaffWidget`/`NotationStaffWidget` leiten `rudiment.hasFootSides` weiter; `computeSheetGeometry`: Pitch = `kitRowPitchWithFeet` wenn `kit && r.hasFootSides`, sonst wie bisher.

- [ ] **Step 1: Failing tests** — Fixture in `kit_fixtures.dart`:

```dart
/// Double bass: hat quarters, backbeat, kick sixteenths R L; line 2 adds
/// the pedal on 2 and 4 and a bar of plain (unsided) kick quarters.
Rudiment doubleBassShowcase() {
  List<StrokeBeat> hhQ() => [for (var i = 0; i < 4; i++) note(R, NoteValue.quarter)];
  List<StrokeBeat> backbeat() => [
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
      ];
  List<StrokeBeat> db16() => [
        for (var i = 0; i < 8; i++) ...[
          foot(NoteValue.sixteenth, side: R),
          foot(NoteValue.sixteenth, side: L),
        ],
      ];
  List<StrokeBeat> kickQ() => [for (var i = 0; i < 4; i++) foot(NoteValue.quarter)];
  final pattern = [
    voice(KitInstrument.hiHatClosed, hhQ()),
    voice(KitInstrument.snare, backbeat()),
    voice(KitInstrument.kick, db16()),
  ];
  return Rudiment(
    id: 'double_bass_showcase',
    name: 'Double bass showcase',
    description: '',
    minBpm: 60,
    targetBpm: 160,
    difficulty: Difficulty.advanced,
    sticking: pattern.first.beats,
    gridUnit: NoteGrid.sixteenth,
    voicing: ExerciseVoicing.kit,
    requiredSensor: SensorLevel.midi,
    limbs: {Limb.doubleBass},
    patternVoices: pattern,
    lines: [
      kitLine([
        voice(KitInstrument.hiHatClosed, [...hhQ(), ...hhQ()]),
        voice(KitInstrument.snare, [...backbeat(), ...backbeat()]),
        voice(KitInstrument.kick, [...db16(), ...db16()]),
      ], counts: true),
      kitLine([
        voice(KitInstrument.hiHatClosed, [...hhQ(), ...hhQ()]),
        voice(KitInstrument.snare, [...backbeat(), ...backbeat()]),
        voice(KitInstrument.kick, [...db16(), ...kickQ()]),
        voice(KitInstrument.hiHatPedal, [
          for (var i = 0; i < 2; i++) ...[
            rest(NoteValue.quarter),
            foot(NoteValue.quarter),
            rest(NoteValue.quarter),
            foot(NoteValue.quarter),
          ],
        ]),
      ], repeat: false, title: 'Pedal'),
    ],
  );
}
```

Tests in `test/notation_kit_staff_test.dart`, Gruppe `'foot letters (Nachtrag B.4c)'`:

```dart
    testWidgets('a sheet with foot sides uses the taller kit row', (tester) async {
      final r = doubleBassShowcase();
      expect(r.hasFootSides, isTrue);
      final g = computeSheetGeometry(r, 352, showCounts: true);
      expect(g.rowPitch, kitRowPitchWithFeet + sheetCountBand);
      expect(computeSheetGeometry(r, 352, showCounts: false).rowPitch,
          kitRowPitchWithFeet);
      // The showcase without foot sides keeps the Teil-1 pitch.
      expect(computeSheetGeometry(kitShowcase(), 352, showCounts: false).rowPitch,
          kitRowPitch);
    });

    testWidgets('golden: double bass sixteenths with foot letters and pedal',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360, child: SheetStaffWidget(rudiment: doubleBassShowcase())))));
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(SheetStaffWidget),
          matchesGoldenFile('goldens/kit_staff_feet.png'));
    });
```

- [ ] **Step 2: Run tests to verify they fail** — `kitRowPitchWithFeet` unbekannt.

- [ ] **Step 3: Implementation**

`sheet_geometry.dart`: nach `kitRowPitch`:

```dart
/// A kit row with foot letters (double bass, Nachtrag B.4c): a second
/// letter row under the feet stems needs more height.
const double kitRowPitchWithFeet = 146;
```

`computeSheetGeometry`: `final feet = kit && r.hasFootSides;` und `final base = feet ? kitRowPitchWithFeet : kit ? kitRowPitch : sheetRowPitch;`.

`notation_staff_widget.dart`, `_StaffPainter`: Feld `final bool footLetters;` (`/// Sheet draws a second letter row for foot sides (Nachtrag B.4c).`), Konstruktor `this.footLetters = false`; Getter:

```dart
  double get _staffBandH =>
      footLetters ? kitRowPitchWithFeet : isKit ? kitRowPitch : sheetRowPitch;
  double get _letterY => footLetters ? 130 : isKit ? 116 : 90;
  double get _countY => footLetters ? kitRowPitchWithFeet : isKit ? kitRowPitch : 104;
  double get _titleY => footLetters ? 96 : isKit ? 98 : 69;
  static const double _footLetterY = 114; // foot sides under the feet stems
```

`shouldRepaint`: `|| old.footLetters != footLetters`. `NotationStaffWidget`: `footLetters: rudiment.hasFootSides`, `rowPitch: rudiment.hasFootSides ? kitRowPitchWithFeet : kit ? kitRowPitch : sheetRowPitch`; `SheetStaffWidget`: `footLetters: rudiment.hasFootSides` an jedem Painter.

`kit_staff_painting.dart`, `_paintLayerColumn`, die Zeile `if (!up) return;` ersetzen durch:

```dart
    if (!up) {
      // Foot side (double bass): the one side of the column, under the stems.
      final side = switch (drawn.hand) {
        Hand.right => 'R',
        Hand.left => 'L',
        null => null,
      };
      if (footLetters && showSticking && side != null) {
        _drawText(canvas, side, Offset(x, y0 + _StaffPainter._footLetterY),
            _dim(_StaffPainter._letterColor), 11,
            bold: true);
      }
      return;
    }
```

(`drawn` ist der Fuß-Track-Beat der Spalte; `layerTrack` setzt seine `hand` nur, wenn alle Noten der Spalte dieselbe Seite tragen — Pedal ohne Seite + Kick R ⇒ R.)

`build_page.py`: `KIT_LEGEND` um „ · Fußseiten R/L nur in der App" ergänzen (Pad-Seiten bleiben byte-gleich, die Legende erscheint nur bei Kit-Sätzen).

- [ ] **Step 4: Goldens erzeugen, ansehen, Suite, Commit**

`flutter test --update-goldens test/notation_kit_staff_test.dart` → nur `kit_staff_feet.png` neu (`git status`: kein anderes Golden geändert!). Ansehen: Reihe höher, „R L R L …" unter den Kick-Sechzehnteln, „R" unter den Hat-Vierteln in der Handzeile, Zählsilben darunter; Zeile 2: Pedal-x unter der ersten Linie auf 2 und 4, Kick-Viertel ohne Buchstaben im zweiten Takt, Titel „Pedal" links ohne Überlappung. Dann `flutter analyze && flutter test`.

```bash
git add lib/shared/widgets/sheet_geometry.dart lib/shared/widgets/notation_staff_widget.dart lib/shared/widgets/kit_staff_painting.dart tool/katalog/build_page.py test/helpers/kit_fixtures.dart test/notation_kit_staff_test.dart test/goldens/kit_staff_feet.png
git commit -m "feat(notation): Fußbuchstaben R/L unter den Fuß-Hälsen (Double Bass), Kit-Reihe 146"
```

---

### Task 3: Inhalt — Satz `feet` (7 Blätter): Kick Control, Kick Sixteenths, Double Bass ×3, Hi-hat Foot, Foot Ostinatos

**Files:**
- Create: `tool/katalog/feet.py`
- Modify: `tool/katalog/katalog.py` (Satz `feet`, Schritt `B.4c`, `seed_marker='PHASE B.4c: feet'`)
- Generated: `lib/features/lessons/data/sheets/feet_*_sheet.dart` (7), `rudiments_seed.dart` (+7)
- Test: `test/lessons/kit_seed_integrity_test.dart` (Test dazu)

**Interfaces:**
- Consumes: `grooves.kit`, Vokabular aus `grooves.py` (`HH8`, `HH8_NO1`, `HH16`, `HH16A`, `SN24`, `SN3`, `SN24G`, `RIDE8`, `RIDE_SW`, `RIDE_SW_A`, `HP24`, `HP_ALL`, `BD13`, `BD1_3A`, `BD_DBL`, `BD_ALL`, `BD_SW`, `SN_SW4`, `SN_SW2`, `SR4`, `C1_1`, `SHUF`, `SHUF_NO1`), `Sheet(kit=True, limbs=…)`, Fußseiten `K8r`/`K8l` (Task 1).
- Produces: `feet.SHEETS` (7), `feet.groove(**kw)`-Helfer wie `grooves.groove` (Vorgaben `kit=True`, `line_bars=2`, `new_seed=True`, `count_lines=2`, `genres=[]`; `limbs` je Blatt).

- [ ] **Step 1: Failing test** — in `kit_seed_integrity_test.dart`:

```dart
  test('the seven feet sheets: form, limbs, foot sides where double bass, '
      'whole-sheet units build', () {
    const ids = {
      'feet_kick_control': Limb.feet,
      'feet_kick_sixteenths': Limb.feet,
      'feet_double_bass_eighths': Limb.doubleBass,
      'feet_double_bass_sixteenths': Limb.doubleBass,
      'feet_double_bass_triplets': Limb.doubleBass,
      'feet_hihat_foot': Limb.feet,
      'feet_ostinatos': Limb.allFour,
    };
    for (final e in ids.entries) {
      final r = rudimentsSeedData.firstWhere((r) => r.id == e.key);
      expect(r.sheet.length, 9, reason: e.key);
      expect(sheetBars(r), 24, reason: e.key);
      expect(r.limbs.contains(e.value), isTrue, reason: e.key);
      expect(r.hasFootSides, e.value == Limb.doubleBass, reason: e.key);
      expect(() => SheetPlan.wholeSheet(r), returnsNormally, reason: e.key);
      expect(r.technique.map((s) => s.title),
          ['Why it matters', 'How to play it', 'Practice tips', 'Where you hear it'],
          reason: e.key);
      // Every line has a foot voice (kick or pedal): these sheets train the feet.
      for (var i = 0; i < r.lines.length; i++) {
        expect(r.lines[i].kitVoices.any((v) => v.isFoot), isTrue,
            reason: '${e.key} line ${i + 1} has no foot voice');
      }
    }
    final db = rudimentsSeedData.firstWhere((r) => r.id == 'feet_double_bass_sixteenths');
    final kick = db.lines.first.kitVoices.firstWhere((v) => v.instrument == KitInstrument.kick);
    expect(kick.beats.take(4).map((b) => b.hand).toList(),
        [Hand.right, Hand.left, Hand.right, Hand.left]);
  });
```

Expected RED: `No element` (die Blätter fehlen).

- [ ] **Step 2: `feet.py`**

Kopf wie `grooves.py` (Docstring: Füße, Double Bass; Form; Regel). Vokabular (je ein Takt):

```python
# Hände
HHQ = 'R4 R4 R4 R4'
HHQ_NO1 = '-4 R4 R4 R4'  # die Eins gehört dem Crash
RDQ = 'R4 R4 R4 R4'  # Ride-Viertel (Spur RD)
RB_Q = 'R4 R4 R4 R4'  # Glocken-Viertel (Spur RB)
BON_SN = '3(R8 L8 -8) 3(R8 L8 -8) 3(R8 L8 -8) 3(R8 L8 -8)'  # Bonham-Dreier: Hände 1+2 der Triole
BOSSA_SR = 'L4 -8 L8 -4 L4'  # Cross-Stick auf 1, „2 +", 4 (Bossa-Clave)
SAMBA_SN = 'R16g L16g R16> L16g R16g L16> R16g L16g R16> L16g R16g L16> R16g L16g R16> L16g'  # Akzente auf „e"-Lagen 1e? → siehe Kommentar im Code: Akzente auf 1a, 2+, 3a, 4+ (partido-alto-nah)
# Kick Control (ohne Seite)
BD_AND = '-8 K8 -4 -8 K8 -4'  # nur „1 +" und „3 +"
BD_1E = 'K16 K16 -8 -4 K16 K16 -8 -4'  # Doppel auf 1 e, 3 e
BD_3A = 'K4 -4 -8. K16 -4'  # 1 und „3 a"
BD_GAPS = '-4 K4 -4 -8 K8'  # 2 und „4 +"
BD_MIX = 'K4 -8 K8 -8. K16 K4'  # 1, „2 +", „3 a", 4
# Kick Sixteenths — eine Kombination je Zählzeit auf 1 und 3, 2 und 4 Pause
BD_C_1E = 'K16 K16 -8 -4 K16 K16 -8 -4'
BD_C_1A = 'K8. K16 -4 K8. K16 -4'
BD_C_1PA = 'K8 K16 K16 -4 K8 K16 K16 -4'
BD_C_EP = '-16 K16 K8 -4 -16 K16 K8 -4'
BD_C_EA = '-16 K16 -16 K16 -4 -16 K16 -16 K16 -4'
BD_C_ALL = 'K16 K16 K16 K16 -4 K16 K16 K16 K16 -4'
BD_C_PA = '-8 K16 K16 -4 -8 K16 K16 -4'
BD_C_A1 = '-8. K16 K4 -8. K16 K4'  # „a" von 1 in die 2, „a" von 3 in die 4
# Double Bass (mit Seite)
BD_R8 = 'K8r K8l K8r K8l K8r K8l K8r K8l'
BD_R8_R4 = 'K8r K8l K8r K8l K8r K8l -4'  # Pause auf 4
BD_R8_H = 'K8r K8l K8r K8l K4r K4r'  # halber Takt Teppich, dann Viertel
BD_R8_BURST = 'K4r -4 K8r K8l K8r K8l'  # Ausbruch auf 3–4
BD_R16 = 'K16r K16l K16r K16l K16r K16l K16r K16l K16r K16l K16r K16l K16r K16l K16r K16l'
BD_R16_H = 'K16r K16l K16r K16l K16r K16l K16r K16l K4r K4r'
BD_R16_B3 = 'K4r K4r K16r K16l K16r K16l K4r'  # Burst auf 3
BD_R16_GAP = 'K16r K16l K16r -16 K16r K16l K16r -16 K16r K16l K16r -16 K16r K16l K16r -16'  # Lücke auf „a"
BD_R16_24 = 'K4r K16r K16l K16r K16l K4r K16r K16l K16r K16l'  # Teppich nur auf 2 und 4
BD_R3 = '3(K8r K8l K8r) 3(K8l K8r K8l) 3(K8r K8l K8r) 3(K8l K8r K8l)'
BD_R3_24 = 'K4r 3(K8l K8r K8l) K4r 3(K8l K8r K8l)'
BD_R6 = '6(K16r K16l K16r K16l K16r K16l) 6(K16r K16l K16r K16l K16r K16l) 6(K16r K16l K16r K16l K16r K16l) 6(K16r K16l K16r K16l K16r K16l)'
BD_R6_B = 'K4r K4r 6(K16r K16l K16r K16l K16r K16l) K4r'  # Sextolen-Burst auf 3
BD_FSHUF = '3(K8r -8 K8l) 3(K8r -8 K8l) 3(K8r -8 K8l) 3(K8r -8 K8l)'  # Fuß-Shuffle
BON_BD = '3(-8 -8 K8r) 3(-8 -8 K8r) 3(-8 -8 K8r) 3(-8 -8 K8r)'  # Bonham-Dreier: Kick auf der 3. Triole
# Hi-hat-Fuß / Ostinati
HP_OFF = '-8 P8 -8 P8 -8 P8 -8 P8'  # Chick auf jedem „+"
SAMBA_BD = 'K8. K16 K8. K16 K8. K16 K8. K16'  # Kick auf 1 und „a" jeder Zählzeit
BOSSA_BD = 'K4 -8 K8 K4 -8 K8'  # 1, „2 +", 3, „4 +"
```

Die sieben Blätter (Zeilen als Takt-Dicts; `two(x)` = Takt zweimal, `kit(a, b)` = zwei Takte; Challenge = die vier genannten Zeilen in einem `kit(...)` je zwei Takte; `pattern` = erster Takt der Zeile 1; Schreibweise wie in Teil 1: `{HH8, SN24, BD13}` = `{'HH': HH8, 'SN': SN24, 'BD': BD13}`, Spurkopf aus dem Konstantennamen, wo nicht ausdrücklich `KEY: wert`):

| Blatt / Felder | Zeilen 1–8 | Challenge |
|---|---|---|
| `feet_kick_control` „Kick Control", 60–130, beginner, `eighth`, limbs `feet`, skills `['coordination']` | Hände überall `{HH8, SN24}`: 1 `BD13` · 2 `BD1_3A` · 3 `BD_DBL` · 4 `BD_AND` · 5 `BD_1E` · 6 `BD_3A` · 7 `BD_ALL` · 8 `kit({…BD_GAPS}, {…BD_MIX})` | 1, 3, 5, 8 |
| `feet_kick_sixteenths` „Kick Sixteenths", 60–120, intermediate, `sixteenth`, `feet`, `['coordination', 'control']` | Hände Zeilen 1–4 `{HH8, SN24}`, Zeilen 5–8 `{HH16, SN24}`: 1 `BD_C_1E` · 2 `BD_C_1A` · 3 `BD_C_1PA` · 4 `BD_C_EP` · 5 `BD_C_EA` · 6 `BD_C_ALL` · 7 `BD_C_PA` · 8 `BD_C_A1` (je `two`) | 1, 3, 6, 8 |
| `feet_double_bass_eighths` „Double Bass Eighths", 60–160, intermediate, `eighth`, `doubleBass`, `['endurance', 'coordination']`, genres `['metal']` | 1 `two({HHQ, SN24, BD_R8})` · 2 `kit({HHQ, SN24, BD_R8}, {HHQ, SN24, BD_R8_R4})` · 3 `two({HHQ, SN24, BD_R8_H})` · 4 `two({RD: RDQ, SN24, BD_R8})` · 5 `two({HHQ, SN3, BD_R8})` · 6 `kit({HHQ, SN24, BD13}, {HHQ, SN24, BD_R8_BURST})` · 7 `two({HH8, SN24, BD_R8})` · 8 `two({C1~: C1_1, HH: HHQ_NO1, SN24, BD_R8})` | 1, 2, 5, 8 |
| `feet_double_bass_sixteenths` „Double Bass Sixteenths", 60–140, advanced, `sixteenth`, `doubleBass`, `['endurance', 'coordination']`, `['metal']` | 1 `two({HHQ, SN24, BD_R16})` · 2 `two({HHQ, SN24, BD_R16_H})` · 3 `two({HHQ, SN24, BD_R16_B3})` · 4 `two({HHQ, SN3, BD_R16})` · 5 `two({HH8, SN24, BD_R16})` · 6 `kit({C1~: C1_1, HH: HHQ_NO1, SN24, BD_R16}, {HHQ, SN24, BD_R16})` · 7 `two({HHQ, SN24, BD_R16_GAP})` · 8 `two({HHQ, SN24, BD_R16_24})` | 1, 3, 4, 8 |
| `feet_double_bass_triplets` „Double Bass Triplets", 60–140, advanced, `triplet`, `doubleBass`, `['endurance', 'coordination']`, `['rock']` | 1 `two({SHUF, SN24, BD_R3})` · 2 `two({SHUF, SN24, BD_R3_24})` · 3 `two({SHUF, SN24, BD_FSHUF})` · 4 `two({HHQ, SN: BON_SN, BD: BON_BD})` · 5 `two({SHUF, SN24, BD_R6_B})` · 6 `two({HHQ, SN24, BD_R6})` · 7 `kit({SHUF, SN24, BD13}, {SHUF, SN24, BD_R3})` · 8 `two({C1~: C1_1, HH: SHUF_NO1, SN24, BD_R3})` | 1, 3, 4, 8 |
| `feet_hihat_foot` „Hi-hat Foot", 60–140, intermediate, `eighth`, `feet`, `['independence', 'coordination']` | 1 `two({RD: RIDE8, SN24, BD13, HP: HP24})` · 2 `two({RD: RIDE8, SN24, BD13, HP: HP_ALL})` · 3 `two({RD: RIDE8, SN24, BD13, HP: HP_OFF})` · 4 `two({RD: RIDE8, SN24, BD1_3A, HP: HP24})` · 5 `two({RD: RIDE8, SN24, BD_DBL, HP: HP24})` · 6 `two({RB: RB_Q, SN24, BD13, HP: HP24})` · 7 `two({SN: SN24G, BD13, HP: HP_ALL})` (Pedal als einziger Puls) · 8 `two({RD: RIDE8, SN24, BD_MIX, HP: HP24})` | 1, 3, 5, 8 |
| `feet_ostinatos` „Foot Ostinatos", 60–140, advanced, `sixteenth`, `allFour`, `['independence', 'groove']`, genres `['latin', 'jazz']` | 1 `two({HH8, SR: BOSSA_SR, BD: BOSSA_BD})` · 2 `two({RD: RIDE8, SR: BOSSA_SR, BD: BOSSA_BD, HP: HP24})` · 3 `two({HH16, SN24, BD: SAMBA_BD, HP: HP24})` · 4 `two({HH16A, SN: SAMBA_SN, BD: SAMBA_BD, HP: HP24})` · 5 `two({RD: RIDE_SW, HP: HP24, BD: BD_SW})` · 6 `two({RD: RIDE_SW, HP: HP24, BD: BD_SW, SN: SN_SW4})` · 7 `two({RD: RIDE_SW, HP: HP24, BD: BD_SW, SN: SN_SW2})` · 8 `two({RD: RIDE_SW_A, HP: HP24, BD: BD_SW, SR: SR4})` | 1, 3, 5, 8 |

Lektionen: vier Abschnitte je Blatt (Vorlage `LESSON_ROCK8` in `grooves.py`): Warum (was die Übung am Set bringt), Wie (Fußtechnik in einem Satz: Heel-up/Heel-down, bei Double Bass „beide Füße gleich laut, Rechts führt"), Üben (welche Zeile wozu), Hören (konkrete Songs: Double Bass z. B. Metallica „One" (Outro), Slayer, Dream Theater; Shuffle-Füße Bonham „Fool in the Rain"; Hi-hat-Fuß Jazz-Feathering; Samba/Bossa Jobim-Aufnahmen). Beschreibung ein Satz. Wenn eine Tabellenzeile nicht validiert, minimal korrigieren und im Bericht nennen.

`katalog.py`: `import feet` und `SheetSet(key='feet', step='B.4c', title='Füße: Kick, Double Bass, Hi-hat-Fuß', lead='Nachtrag B.4c: Fußübungen am Set — Kick-Kontrolle, Sechzehntel-Kombinationen, Double Bass (Fußseiten R/L nur in der App), Hi-hat-Fuß, Ostinati. Sag mir je Blatt und Zeilennummer, was raus, anders oder länger soll.', seed_marker='PHASE B.4c: feet', sheets=feet.SHEETS)`.

- [ ] **Step 3: Prüfen, erzeugen, Suite, Commit**

```bash
cd tool/katalog && python3 feet.py && python3 -m unittest -q && cd ../..
python3 tool/katalog/gen_dart.py lib/features/lessons/data/sheets feet
python3 tool/katalog/patch_seed.py lib/features/lessons/data/rudiments_seed.dart
dart format lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart
flutter analyze && flutter test
git add tool/katalog/feet.py tool/katalog/katalog.py lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart test/lessons/kit_seed_integrity_test.dart
git commit -m "feat(Katalog B.4c): sieben Fuß-Blätter — Kick Control, Kick Sixteenths, Double Bass 8tel/16tel/Triolen, Hi-hat Foot, Foot Ostinatos"
```

Expected: `7 Blätter ok`; `seed patched: 36 updated, 7 added`; Suite grün.

---

### Task 4: Inhalt — Satz `set_more`: Linear Fill, Double Bass Fill, Linear Groove, Sixteenth Kick Groove (+ optional Half-time Shuffle)

**Files:**
- Modify: `tool/katalog/set_fills.py` (`orchestrate` legt Fuß-Tokens auf `BD`/`HP`; `phrase`/`challenge` lassen `BD13` weg, wenn der Fill eigene Fuß-Tokens hat)
- Create: `tool/katalog/set_more.py`
- Modify: `tool/katalog/katalog.py` (Satz `set_more`, Schritt `B.4c`, `seed_marker='PHASE B.4c: more fills and grooves'`), `tool/katalog/test_kit.py` (Klasse `OrchestrateFeet`, Linearitäts-Helfer)
- Generated: `set_fill_linear_sheet.dart`, `set_fill_double_bass_sheet.dart`, `groove_linear_sheet.dart`, `groove_kick_sixteenths_sheet.dart` (+ `groove_halftime_shuffle_sheet.dart`), Seed
- Test: `test/lessons/kit_seed_integrity_test.dart` (Linearität, Formen)

**Interfaces:**
- `orchestrate(fill, plan)`: Hand-Tokens (`R`/`L`) gehen beat-weise auf die geplante Trommel; Fuß-Tokens `K`→`'BD'`, `P`→`'HP'` (mit Seiten, wenn vorhanden); eine Tuplet-Gruppe, die Hand- und Fuß-Tokens mischt, wird auf jede beteiligte Spur **als ganze Gruppe** geschrieben, die fremden Tokens darin als Pausen gleicher Länge (`6(R16 L16 -16 R16 L16 -16)` / `6(-16 -16 K16 -16 -16 K16)`); ein Beat ohne Hand-Token legt `-4` auf keine Trommel (die Trommel bekommt ihre Pause über `kit()`), der Plan hat trotzdem vier Einträge. `phrase`/`challenge`: `fill_bar = orchestrate(...)`; `if 'BD' not in fill_bar: fill_bar['BD'] = BD13`.
- Linearitäts-Helfer (Test + Integrität): keine zwei Spuren mit Einsatz auf demselben Tick.

- [ ] **Step 1: Failing tests** — `test_kit.py`:

```python
class OrchestrateFeet(unittest.TestCase):
    def test_foot_tokens_go_to_bd(self):
        from set_fills import orchestrate
        out = orchestrate('R16 L16 K16 K16 R16 L16 K16 K16 R16 L16 K16 K16 R16 L16 K16 K16',
                          ['SN', 'T1~', 'F1~', 'SN'])
        self.assertEqual(out['BD'], '-8 K16 K16 -8 K16 K16 -8 K16 K16 -8 K16 K16')
        self.assertEqual(out['SN'], 'R16 L16 -8 -4 -4 R16 L16 -8')
        self.assertEqual(out['T1~'], '-4 R16 L16 -8 -4 -4')
        self.assertNotIn('HP', out)

    def test_sided_feet_keep_their_side(self):
        from set_fills import orchestrate
        out = orchestrate('R16 L16 R16 L16 R16 L16 R16 L16 K16r K16l K16r K16l K16r K16l K16r K16l',
                          ['SN', 'T1~', 'F1~', 'SN'])
        self.assertEqual(out['BD'], '-4 -4 K16r K16l K16r K16l K16r K16l K16r K16l')
        self.assertNotIn('F1~', out)  # no hand token on beats 3–4 → no F1 track

    def test_mixed_tuplet_group_is_split_with_rests(self):
        from set_fills import orchestrate
        out = orchestrate('6(R16 L16 K16 R16 L16 K16) R4 R4 R4', ['SN', 'SN', 'SN', 'SN'])
        self.assertEqual(out['SN'].split(' ', 2)[:2], ['6(R16', 'L16'])
        self.assertIn('6(-16 -16 K16 -16 -16 K16)', out['BD'])
        self.assertIn('6(R16 L16 -16 R16 L16 -16)', out['SN'])

    def test_linear_check(self):
        from set_more import is_linear
        self.assertTrue(is_linear(parse_kit_line('HH: R8 -8 R8 -8 R8 -8 R8 -8\nSN: -8 L8 -8 L8 -8 L8 -8 L8')))
        self.assertFalse(is_linear(parse_kit_line('HH: R8 R8 R8 R8 R8 R8 R8 R8\nSN: -4 L4 -4 L4')))
```

Dart (`kit_seed_integrity_test.dart`):

```dart
  test('set_more: linear sheets are linear, fills carry their own feet', () {
    bool linear(ExerciseLine l) {
      final ticks = <int>{};
      for (final v in l.kitVoices) {
        for (final o in onsetsOf(v.beats, NoteGrid.sixteenth)) {
          if (!ticks.add(o.tick)) return false;
        }
      }
      return true;
    }
    final lin = rudimentsSeedData.firstWhere((r) => r.id == 'groove_linear');
    expect(lin.sheet.length, 9);
    expect(lin.lines.every(linear), isTrue, reason: 'groove_linear is not linear');
    final fill = rudimentsSeedData.firstWhere((r) => r.id == 'set_fill_linear');
    expect(sheetBars(fill), 40);
    final db = rudimentsSeedData.firstWhere((r) => r.id == 'set_fill_double_bass');
    expect(db.hasFootSides, isTrue);
    expect(db.limbs.contains(Limb.doubleBass), isTrue);
    final k16 = rudimentsSeedData.firstWhere((r) => r.id == 'groove_kick_sixteenths');
    expect(sheetBars(k16), 24);
  });
```

(`onsetsOf` aus `kit_layout.dart`; `groove_linear` nutzt `gridUnit: sixteenth`.)

- [ ] **Step 2: `orchestrate`-Erweiterung** (in `set_fills.py`): Tokens mit Fußbuchstaben (`_parse_token(tok).is_foot`) sammeln je Beat getrennt nach `K`→`'BD'`, `P`→`'HP'`; Hand-Tokens wie bisher auf `plan[beat]`. Je Beat und je beteiligter Spur: die Tokens der Spur in Reihenfolge, fremde Tokens als `-<wert>` (mit Punkt/Tuplet-Kontext: innerhalb einer Tuplet-Gruppe bleibt die Klammer, die Pause trägt denselben Wert). Spuren ohne Token in einem Beat bekommen `-4`. `phrase`/`challenge`: `BD13` nur, wenn der Fill keine `BD`-Spur erzeugt hat. Bestehende Tests (Task 8 Teil 1) müssen unverändert grün bleiben (`fills.FILLS` enthalten keine Fuß-Tokens).

- [ ] **Step 3: `set_more.py`**

Helfer `is_linear(kl: KitLine) -> bool` (kein Tick doppelt). Vokabular:

```python
# Linearer Groove (Sechzehntel-Indizes 0–15; kein Tick doppelt)
LIN_A = {'HH': '-16 R16 -16 R16 -16 R16 R16 -16 R16 R16 -16 R16 -16 R16 R16 R16',
         'SN': '-8 L16g -16 L16> -16 -4 L16g -16 L16> -8.',
         'BD': 'K16 -8. -8 -16 K16 -2'}  # HH 1,3,5,6,8,9,11,13,14,15 · SN 2g,4>,10g,12> · BD 0,7
# Kick-Sechzehntel-Grooves
BD_K16A = 'K4 -8. K16 K4 -8. K16'  # 1, „2 a", 3, „4 a"
BD_K16E = 'K4 -16 K16 -8 K4 -16 K16 -8'  # 1, „2 e", 3, „4 e"
BD_K16B = 'K8. K16 -4 K8. K16 -4'  # 1, „1 a", 3, „3 a"
BD_K16C = 'K4 -4 K8. K16 -8 K8'  # 1, 3, „3 a", „4 +"
# Half-time Shuffle (optional)
HTS_HH = '3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8)'
HTS_SN = '3(-8 L8g -8) 3(-8 L8g -8) 3(L8> -8 L8g) 3(-8 L8g -8)'  # Ghosts auf der Mitte, Backbeat auf 3
HTS_BD = 'K4 3(-8 -8 K8) -2'  # 1 und „let" von 2
```

Blätter:

| Blatt / Felder | Inhalt |
|---|---|
| `set_fill_linear` „Linear Fill (Kit)", 60–120, intermediate, `sixteenth`, `allFour`, `['fill', 'coordination']` | Groove `rock16` (aus `set_fills.GROOVES`), Fill-Takte (Plan je Zeile in Klammern): 1 `'R16 L16 K16 K16' ×4` (SN SN T1~ F1~) · 2 `'R16 L16 R16 K16' ×4` (SN T1~ T2~ F1~) · 3 `'R16 K16 L16 K16' ×4` (SN SN F1~ F1~) · 4 `'R16 L16 K16 R16 L16 K16 R16 L16 K16 R16 L16 K16 R16 L16 K16 K16'` (SN T1~ T2~ F1~) · 5 `'R16 L16 L16 K16' ×4` (SN T1~ F1~ F2~) · 6 `'R16 L16 K16 K16 R16 L16 R16 K16 R16 L16 K16 K16 R16 L16 R16 K16'` (SN SN T1~ F1~) · 7 `'R8 K16 K16 R8 K16 K16 R8 K16 K16 R8 K16 K16'` (T1~ T2~ F1~ F2~) · 8 `'6(R16 L16 K16 R16 L16 K16)' ×4` (SN T1~ T2~ F1~); Challenge Fills 1 und 4 |
| `set_fill_double_bass` „Double Bass Fill (Kit)", 60–140, advanced, `sixteenth`, `doubleBass`, `['fill', 'endurance']`, `['metal']` | Groove `rock16`; Fills: 1 Hände 1–2 `R16 L16 ×4`, Füße 3–4 `K16r K16l ×4` (SN T1~ – –) · 2 Hände 1 (SN), Füße 2–4 · 3 Hände 1–3 (SN T1~ F1~), Füße 4 · 4 abwechselnd Hand/Fuß je Zählzeit (SN – T1~ –) · 5 Füße 1–2, Hände 3–4 (– – T1~ F1~) · 6 Sextolen: Hände 1–2 `6(R16 L16 R16 L16 R16 L16)`, Füße 3–4 `6(K16r K16l …)` · 7 Hände Zweiunddreißigstel 1–2 `R32 L32 ×8`, Füße 3–4 · 8 Füße 1–4 `K16r K16l ×8` mit Crash auf der nächsten Eins (Plan egal); Challenge 1 und 8 |
| `groove_linear` „Linear Groove", 60–120, intermediate, `sixteenth`, `allFour`, `['groove', 'coordination']`, `['funk']` | 8 Zeilen à 2 Takte, Zeile 1 `two(LIN_A)`; Zeilen 2–8 vom Umsetzer nach der Regel komponiert (kein Tick doppelt; HH/SN/BD; Ghosts, ein Backbeat je Takt auf 2 oder 4, Kick auf 1, offene Hat als Abschluss in Zeile 8), Challenge 1, 3, 5, 8; `is_linear` prüft jede Zeile im `__main__`-Lauf |
| `groove_kick_sixteenths` „Sixteenth Kick Groove", 60–120, intermediate, `sixteenth`, `allFour`, `['groove', 'coordination']`, `['rock', 'funk']` | 1 `two({HH8, SN24, BD_K16A})` · 2 `two({HH8, SN24, BD_K16E})` · 3 `two({HH8, SN24, BD_K16B})` · 4 `two({HH8, SN24, BD_K16C})` · 5 `two({HH16, SN24G, BD_K16A})` · 6 `two({HH16, SN24G3, BD_K16E})` · 7 `two({HH8, SN3, BD_K16C})` · 8 `kit({C1~: C1_1, HH: HH8_NO1, SN24, BD_K16A}, {HH8, SN24, BD_K16B})`; Challenge 1, 2, 5, 8 |
| `groove_halftime_shuffle` (optional) „Half-time Shuffle", 60–110, advanced, `triplet`, `allFour`, `['groove', 'control']`, `['rock', 'funk']` | 1 `two({HH: HTS_HH, SN: HTS_SN, BD: HTS_BD})`; 2–8 Varianten (Ghosts weglassen/verdichten, Kick auf „let" von 4, Hat offen auf „let" von 4, Ride statt Hat, Backbeat mit Flam, Crash auf der Eins); Challenge 1, 2, 4, 8 |

Lektionen wie gehabt (Linear: Garibaldi/Tower of Power, Gadd; Kick-16tel: Rock/Funk; Double-Bass-Fill: Metal; Half-time Shuffle: Purdie „Babylon Sisters", Porcaro „Rosanna", Bonham „Fool in the Rain").

`katalog.py`: `import set_more`, `SheetSet(key='set_more', step='B.4c', title='Linear, Double-Bass-Fill, Kick-Sechzehntel, Half-time Shuffle', lead=…, seed_marker='PHASE B.4c: more fills and grooves', sheets=set_more.SHEETS)`.

- [ ] **Step 4: Prüfen, erzeugen, Suite, Commit**

```bash
cd tool/katalog && python3 -m unittest -q && python3 set_more.py && cd ../..
python3 tool/katalog/gen_dart.py lib/features/lessons/data/sheets set_more
python3 tool/katalog/patch_seed.py lib/features/lessons/data/rudiments_seed.dart
dart format lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart
flutter analyze && flutter test
git add tool/katalog/set_fills.py tool/katalog/set_more.py tool/katalog/katalog.py tool/katalog/test_kit.py lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart test/lessons/kit_seed_integrity_test.dart
git commit -m "feat(Katalog B.4c): Linear Fill, Double Bass Fill, Linear Groove, Sixteenth Kick Groove (+ Half-time Shuffle)"
```

---

### Task 5: Goldens, Doku, Builds, Kurationsseiten, Emulator

**Files:**
- Modify: `test/notation_kit_goldens_test.dart` (ids `feet_double_bass_sixteenths`, `feet_kick_control` als Pattern-Goldens; ganzes Blatt `feet_double_bass_eighths` mit `physicalSize` 360×2200)
- Modify: `docs/CLAUDE.md` (Absatz „Foot sides (Nachtrag B.4c)" im Abschnitt „Kit exercises")
- Create: Goldens `kit_pattern_feet_double_bass_sixteenths.png`, `kit_pattern_feet_kick_control.png`, `kit_sheet_feet_double_bass_eighths.png`
- Builds: `flutter build apk --debug` → `~/drum-coach-set-b1c.apk`; `flutter build linux --release`
- Kurationsseiten: `python3 tool/katalog/build_page.py $CLAUDE_JOB_DIR/tmp/feet.html feet` und `… set-more.html set_more`, Browser-Sichtprüfung wie Teil 1 Task 9 (Fußseiten erscheinen auf der Seite nicht; Legende sagt es)
- Emulator: Bibliothek mit Filter Limbs = „Double bass" (KIT-Badges), Info-Seite „Double Bass Sixteenths" (zweite Buchstabenzeile), Übungs-Screen „Kick Control" laufend — drei Screenshots nach `$CLAUDE_JOB_DIR/tmp/emu-b1c/`

- [ ] **Step 1: Goldens erzeugen und ansehen** (Checkliste: Fußbuchstaben R L unter den Kick-Sechzehnteln, Handbuchstaben darüber, Zählsilben darunter; Kick Control ohne zweite Zeile, Reihe 132)
- [ ] **Step 2: `docs/CLAUDE.md`**: unter „Kit exercises" ergänzen: „Foot sides (Nachtrag B.4c): `foot(v, side: R)` / `K16r` give a foot stroke its foot; a sheet with any sided foot stroke uses `kitRowPitchWithFeet` (146) and draws a second letter row under the feet stems (`_footLetterY`). Measurement ignores sides. Sets: `tool/katalog/feet.py` (7), `set_more.py` (4–5); `orchestrate` routes `K`/`P` tokens to the `BD`/`HP` tracks."
- [ ] **Step 3: Suite, Python, Builds, APK, Seiten, Emulator** (Kommandos wie Teil 1 Task 10; APK nach `~/drum-coach-set-b1c.apk`)
- [ ] **Step 4: Commit**

```bash
git add test/notation_kit_goldens_test.dart test/goldens docs/CLAUDE.md
git commit -m "docs+test(Phase B1c): Goldens Füße/Double Bass, CLAUDE.md Fußseiten, Builds"
```

---

## Selbstprüfung

- **Spec-Abdeckung:** §1 Fußseite → Task 1 (Modell/DSL/Notenschrift), Task 2 (Notenbild 146, zweite Buchstabenzeile, Legende), Integritätstest `Limb.doubleBass ⇒ hasFootSides` → Task 3; §2 Satz `feet` → Task 3 (7 Blätter mit Zeilen-Tabelle), Satz `set_more` → Task 4 (4 + optional 1); §3 Abnahme → Task 5 (Goldens, Emulator, APK, Seiten).
- **Platzhalter:** Zeilen 2–8 von `groove_linear` und die Varianten des optionalen Half-time Shuffle sind Kompositionsarbeit nach Regel + Prüfung (`is_linear`), wie in Teil 1 die Lektionstexte.
- **Typkonsistenz:** `foot(side:)`/`Hand?` in 1/2/3/4; `voicesHaveFootSides`/`Rudiment.hasFootSides` in 1/2/3/4/5; `kitRowPitchWithFeet` in 2/5; `orchestrate` mit `BD`/`HP` in 4; `is_linear` in 4.
- **Review Focus:** 1 → Task 2 Golden; 2 → Task 2 (bestehende Goldens); 3 → Task 1 Python-Test; 4 → Task 4 `OrchestrateFeet`; 5 → Task 3/4 `SheetPlan.wholeSheet` im Integritätstest.
