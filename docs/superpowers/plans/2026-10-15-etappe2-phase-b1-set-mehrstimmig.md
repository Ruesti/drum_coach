# Etappe 2 / Phase B Teil 1 — Mehrstimmig: Modell, Notenbild, Set-Übungen

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Übungen bestehen aus Stimmen (je Instrument eine Spur), werden in Standard-Schlagzeugnotation auf fünf Linien gezeichnet (Hände Hals oben, Füße Hals unten) und spielbar gemacht; der Katalog bekommt sechs Grooves, ein Hi-Hat-Blatt, acht Fill-Blätter mit echter Time und „Rund ums Set" — alles ohne Hardware prüfbar (Golden-Tests, Emulator). Messung pro Stimme (B.3) und Fähigkeit pro Kontext (B.5) sind **Teil 2**.

**Architecture:** `ExerciseLine` trägt wahlweise `kitVoices` (Liste `Voice(instrument, beats, accepts)`), `Rudiment` ein `patternVoices` für den PATTERN-Kasten; Pad-Übungen bleiben einstimmig und unverändert. Für das Notenbild werden die Stimmen in zwei **Schichten** (Hände, Füße) zu je einer Rhythmus-Spur („Layer-Track": Einsätze als Noten, Lücken als Pausen) gemischt, damit `computeStaffLayout` Balken und Triolenklammern wie heute liefert; beide Schichten teilen eine `StaffScale`, deshalb liegen gleiche Ticks auf gleichem x. Köpfe werden je Instrument auf ihrer Linie/ihrem Zwischenraum gezeichnet (Tabelle B.2). Wiedergabe: `buildVoicesPlayback` mischt Stimmen zur lautesten Pro-Tick-Lautstärke, der Cursor läuft über die Spalten (Vereinigung der Einsätze). Die Band schweigt in Stimmen, die der Nutzer spielt (Kick/Hi-Hat stummschaltbar im Loop-Plan). Der Katalog-Werkzeugkasten (`tool/katalog`) bekommt Spuren (`HH: … / SN: … / BD: …`), erzeugt daraus Dart (`kitLine`/`voice`/`foot`) und die abcjs-Kurationsseite.

**Tech Stack:** Flutter 3.44 / Dart 3, Riverpod, Bravura (SMuFL) für Köpfe/Fahnen, Python 3.13 für `tool/katalog`, abcjs 6.4.4 für die Kurationsseite, Playwright-MCP für die Sichtprüfung der Seite.

**Spec:** `docs/BRIEF_ETAPPE2_SET.md` — Phase B, Abschnitte **B.1, B.2, B.4**, „Technische Festlegungen" (Golden-Tests fürs mehrstimmige Notenbild), „Abnahme Phase B" (Notenbild von sechs Grooves und drei Fills als Golden-Test; Pad-Übungen unverändert). Hintergrund: `docs/CLAUDE.md` (Sheets, Katalog), `tool/katalog/README.md`.

## Global Constraints

- Raster: **24 Ticks je Viertel**; jede Stimme einer Zeile hat **dieselbe Tick-Länge** (ganze Takte 1–8); eine Zeile ≤ 8 Takte, ein Blatt ≤ 64 Takte (`maxBackingCycleBars`).
- `StrokeBeat.hand` wird **`Hand?`**: Fuß-Stimmen (Kick, Hi-Hat-Pedal) tragen `null`; Pausen tragen `null`. Hand-Zuordnung und Sticking-Buchstaben gelten nur für Hand-Stimmen.
- Pad-Übungen bleiben **unverändert**: `ExerciseLine(beats)` ist eine Zeile mit genau einer Stimme `pad`; `etude_dsl`, Pad-Notenbild (`_StaffPainter` ohne `voices`), `PatternPlayback.forRudiment`, Analyse: keine Verhaltensänderung. Bestehende Goldens (`sheet_staff_three_lines.png`, `result_sheet_preview.png`) bleiben byte-gleich.
- Positionen und Kopfformen exakt nach der Tabelle B.2 (unten in Task 3 als `kitStaffStep` / `kitHeadShape`). Hände Hals **oben**, Füße Hals **unten**. Gleichzeitige Schläge einer Schicht teilen sich den Hals.
- Set-Übungen: `voicing: ExerciseVoicing.kit`, `requiredSensor: SensorLevel.midi`, `limbs: {Limb.allFour}` (Hi-Hat-Blatt und Grooves) bzw. wie angegeben, `backing: null`. Band-Stimmen, die der Nutzer spielt, sind stumm (`backingKick`/`backingHihat` im Loop-Plan).
- **Keine Messung für Set-Übungen in Teil 1** (B.3 = Teil 2): der Übungs-Screen öffnet für `isKit` keine Schlagquelle, zeigt `NOT MEASURABLE` und im Chip-Tooltip „Full-kit measurement is not available yet"; Rohlog entfällt damit. Keine falsche Zahl (Leitprinzip).
- Katalog-Inhalt lebt **einmal** in Python (`tool/katalog/grooves.py`, `tool/katalog/set_fills.py`), generierte Dart-Dateien nie von Hand ändern. Alle UI-Strings und Lektionstexte Englisch.
- Keine neuen Pakete. Plattform-Weichen nur über `lib/app/platform_support.dart`.
- Jede Aufgabe: Test zuerst, dann Code, `flutter analyze` ohne neue Meldungen, `flutter test` grün (Stand bei Start: 558 Tests), Commit. Python-Tests: `cd tool/katalog && python3 -m unittest -v`.
- Basis-Branch `worktree-etappe2-phase-b` = Phase A (`origin/worktree-etappe2-phase-a`) + Katalog #30/#32 hineingemergt. Wenn #30/#32/#33/#34 auf `main` landen, wird der PR auf `main` umgezielt — kein Rebase nötig.

## Review Focus

1. **Zwei Stimmen auf demselben Tick (Hi-Hat + Snare auf 2):** ein Hals, zwei Köpfe, ein Balken; kein Sticking-Buchstabe, wenn die Köpfe verschiedenen Händen gehören. Test in Task 2 (`layerTrack` „shared column"), Golden in Task 3.
2. **Stimme, die in einer Zeile fehlt (Tom nur in Zeile 3):** im Ganz-Blatt-Modus wird sie in den anderen Zeilen mit Pausen aufgefüllt, Tick-Längen bleiben gleich, der Cursor läuft durch. Test in Task 4 (`SheetPlan.wholeSheet` rest fill).
3. **Kick-Einsatz, dessen Lücke bis zum nächsten Einsatz nicht als eine Note darstellbar ist (Kick auf 1 und „a von 2"):** der Layer-Track füllt mit Pausen auf, ohne dass eine Position wandert (Summe der Ticks = Taktlänge). Test in Task 2 (`layerTrack` „gap 42 ticks").
4. **Groove mit Kick + Hi-Hat + Snare bei eingeschalteter Band:** die Band fällt komplett aus (beide Stimmen stumm), der Klick läuft weiter, kein Absturz bei leerer Band. Test in Task 4 (`buildLoopPlan` both muted) und Task 5 (Screen übergibt die Flags).
5. **Set-Übung mit angeschlossenem MIDI-Modul in Teil 1:** keine Quelle wird geöffnet, kein Ergebnis mit Zahlen, Übung läuft; Pad-Übungen öffnen die Quelle wie bisher. Test in Task 5 („kit exercise opens no source").

---

## Dateistruktur

**Neu**

| Datei | Verantwortung |
|---|---|
| `lib/shared/widgets/kit_layout.dart` | `valueForGap`, `KitColumn`, `KitLayer`, `layerTrack`, `KitLineLayout`, `computeKitLineLayout` — reine Geometrie der mehrstimmigen Zeile |
| `lib/shared/widgets/kit_staff_painting.dart` | `part of` `notation_staff_widget.dart`: `kitStaffStep`, `kitHeadShape`, `_paintKitRow` und Helfer (Köpfe, Hälse unten, Balken unten, Hilfslinie, „o") |
| `lib/features/lessons/data/sheets/groove_*_sheet.dart`, `set_fill_*_sheet.dart`, `set_around_the_kit_sheet.dart` | generiert aus `tool/katalog` (Pattern-Stimmen, Zeilen, Lektion) |
| `tool/katalog/grooves.py` | sechs Grooves + Hi-Hat offen/geschlossen (7 Blätter) |
| `tool/katalog/set_fills.py` | acht Fill-Blätter mit echter Time + „Rund ums Set" (9 Blätter) |
| `tool/katalog/test_kit.py` | unittest für Spuren-Parser, Dart- und ABC-Ausgabe |
| `test/lessons/voice_model_test.dart`, `test/shared/kit_layout_test.dart`, `test/notation_kit_staff_test.dart`, `test/lessons/kit_seed_integrity_test.dart`, `test/notation_kit_goldens_test.dart` | Tests der Tasks 1, 2, 3, 7/8, 10 |
| `test/goldens/kit_staff_sheet.png`, `kit_staff_pattern.png`, `kit_pattern_<id>.png` ×9, `kit_sheet_groove_rock8.png` | Goldens |

**Geändert**

| Datei | Änderung |
|---|---|
| `lib/features/coaching/midi/kit_instrument.dart` | `InstrumentClass`, `KitInstrument.isFoot` |
| `lib/features/lessons/models/rudiment.dart` | `Hand?`, `Voice`, `ExerciseLine.kit`/`kitVoices`/`voices`/`isKit`, `Rudiment.patternVoices`/`isKit` |
| `lib/features/lessons/data/etude_dsl.dart` | `foot`, `voice`, `kitLine`, `kitBarsOrThrow` |
| `lib/features/coaching/models/session_analysis.dart`, `services/stroke_analysis.dart` | `MatchedHit.hand` nullable, Buchstabe nur bei Hand |
| `lib/shared/widgets/staff_layout.dart` | `StaffScale`, `chooseStaffScale`, `computeStaffLayout(scale:)`, `StaffLayout.originX/barGap/xOfTick/rowOfTick` |
| `lib/shared/widgets/sheet_geometry.dart` | `kitRowPitch`, `SheetGeometry.kitLayouts/rowOfTick`, Kit-Zeilen in `computeSheetGeometry` |
| `lib/shared/widgets/notation_staff_widget.dart` | `voices`/`activeTick` am Painter und beiden Widgets, Kit-Pfad, `part` |
| `lib/features/lessons/models/pattern_playback.dart`, `sheet_plan.dart` | `buildVoicesPlayback`; `SheetPlan.voices/isKit/locateTick/playsKick/playsHihat` |
| `lib/features/metronome/loop_voices.dart`, `metronome_engine.dart`, `metronome_provider.dart` | `backingKick`/`backingHihat` |
| `lib/features/practice/widgets/sheet_window.dart`, `practice_session_screen.dart` | `activeTick`, Kit-Einheit, Band-Stummschaltung, keine Quelle für Kit |
| `lib/features/lessons/lessons_screen.dart` | `KIT`-Badge |
| `lib/features/lessons/data/rudiments_seed.dart` | 16 neue Einträge (generiert von `patch_seed.py`) |
| `tool/katalog/sheetlang.py`, `blatt.py`, `katalog.py`, `gen_dart.py`, `patch_seed.py`, `build_page.py`, `fills.py`, `README.md` | Spuren, Kit-Blätter, Dart/ABC-Ausgabe, Sätze `grooves`/`set_fills`, `FILLS`-Export |
| `docs/CLAUDE.md` | Abschnitt „Kit exercises (Etappe 2, Phase B.1/B.2/B.4)" |

---

### Task 1: Stimmen-Modell — `Hand?`, `Voice`, `InstrumentClass`, `ExerciseLine.kit`, `Rudiment.patternVoices`, DSL

**Files:**
- Modify: `lib/features/coaching/midi/kit_instrument.dart` (nach dem `KitInstrument`-Enum)
- Modify: `lib/features/lessons/models/rudiment.dart` (`Hand`, `StrokeBeat`, `ExerciseLine`, `Rudiment`)
- Modify: `lib/features/lessons/data/etude_dsl.dart`
- Modify: `lib/shared/widgets/notation_staff_widget.dart:527-533` (Buchstabe nur bei Hand)
- Modify: `lib/features/coaching/models/session_analysis.dart:235-244` (`MatchedHit.hand` nullable)
- Modify: `lib/features/coaching/services/stroke_analysis.dart:259-266` (Buchstabe nur bei Hand)
- Test: `test/lessons/voice_model_test.dart`, `test/coaching/stroke_analysis_test.dart` (ein Test dazu)

**Interfaces:**
- Consumes: `KitInstrument` (Phase A), `StrokeBeat`, `ExerciseLine`, `Rudiment`, `ExerciseVoicing`, `SensorLevel`.
- Produces:
  - `enum InstrumentClass { anyTom, anyCrash, anyCymbal }` mit `String label`, `Set<KitInstrument> members`.
  - `extension KitInstrumentFoot on KitInstrument { bool get isFoot }` (true für `kick`, `hiHatPedal`).
  - `enum Hand { right, left }` unverändert; `StrokeBeat.hand` ist `Hand?` (weiter `required`); `StrokeBeat.rest(...)` hat `hand == null`.
  - `class Voice { final KitInstrument instrument; final InstrumentClass? accepts; final List<StrokeBeat> beats; const Voice(this.instrument, this.beats, {this.accepts}); bool get isFoot; bool matches(KitInstrument played); }`
  - `ExerciseLine`: `final List<Voice> kitVoices` (leer = Pad-Zeile), `ExerciseLine.kit(List<Voice> voices, {repeat, title, counts})` (nicht const; `beats` = Beats der ersten Stimme), `bool get isKit`, `List<Voice> get voices` (Pad-Zeile ⇒ `[Voice(KitInstrument.pad, beats)]`).
  - `Rudiment`: `final List<Voice> patternVoices` (Vorgabe `const []`), `bool get isKit => voicing == ExerciseVoicing.kit`; `withSticking` kopiert `patternVoices` mit.
  - DSL: `StrokeBeat foot(NoteValue v, {bool accent = false, bool ghost = false, bool dotted = false, Tuplet tuplet = Tuplet.none})`, `Voice voice(KitInstrument instrument, List<StrokeBeat> beats, {InstrumentClass? accepts})`, `ExerciseLine kitLine(List<Voice> voices, {bool repeat = true, String? title, bool counts = false})`, `int kitBarsOrThrow(List<Voice> voices, {required int beatsPerBar, required NoteGrid grid})`.
  - `MatchedHit.hand` ist `Hand?`.

- [ ] **Step 1: Failing tests**

`test/lessons/voice_model_test.dart`:

```dart
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hand is optional (Brief B.1)', () {
    test('foot() carries no hand, rests carry none either', () {
      expect(foot(NoteValue.quarter).hand, isNull);
      expect(foot(NoteValue.eighth, accent: true).isAccent, isTrue);
      expect(rest(NoteValue.quarter).hand, isNull);
      expect(note(R, NoteValue.quarter).hand, Hand.right);
    });
  });

  group('InstrumentClass', () {
    test('members per class, every class has a label', () {
      expect(InstrumentClass.anyTom.members, {
        KitInstrument.tom1,
        KitInstrument.tom2,
        KitInstrument.floorTom1,
        KitInstrument.floorTom2,
      });
      expect(InstrumentClass.anyCrash.members, {
        KitInstrument.crash1,
        KitInstrument.crash2,
        KitInstrument.china,
        KitInstrument.splash,
      });
      expect(InstrumentClass.anyCymbal.members.contains(KitInstrument.ride),
          isTrue);
      expect(InstrumentClass.anyCymbal.members.contains(KitInstrument.snare),
          isFalse);
      for (final c in InstrumentClass.values) {
        expect(c.label, isNotEmpty);
      }
    });
    test('kick and hi-hat pedal are foot instruments', () {
      expect(KitInstrument.kick.isFoot, isTrue);
      expect(KitInstrument.hiHatPedal.isFoot, isTrue);
      expect(KitInstrument.hiHatClosed.isFoot, isFalse);
      expect(KitInstrument.snare.isFoot, isFalse);
    });
  });

  group('Voice', () {
    final kick = voice(KitInstrument.kick, [foot(NoteValue.quarter)]);
    final tom = voice(KitInstrument.tom1, [note(R, NoteValue.quarter)],
        accepts: InstrumentClass.anyTom);
    test('isFoot follows the instrument', () {
      expect(kick.isFoot, isTrue);
      expect(tom.isFoot, isFalse);
    });
    test('matches: the instrument itself, or any member of the class', () {
      expect(kick.matches(KitInstrument.kick), isTrue);
      expect(kick.matches(KitInstrument.snare), isFalse);
      expect(tom.matches(KitInstrument.tom1), isTrue);
      expect(tom.matches(KitInstrument.floorTom2), isTrue);
      expect(tom.matches(KitInstrument.crash1), isFalse);
    });
  });

  group('ExerciseLine', () {
    final hh = voice(KitInstrument.hiHatClosed, eighths([R, R, R, R, R, R, R, R]));
    final sn = voice(KitInstrument.snare, [
      rest(NoteValue.quarter),
      note(L, NoteValue.quarter, accent: true),
      rest(NoteValue.quarter),
      note(L, NoteValue.quarter, accent: true),
    ]);
    final bd = voice(KitInstrument.kick, [
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
    ]);
    test('a pad line is one pad voice', () {
      final l = line(eighths([R, L, R, L, R, L, R, L]));
      expect(l.isKit, isFalse);
      expect(l.kitVoices, isEmpty);
      expect(l.voices.length, 1);
      expect(l.voices.single.instrument, KitInstrument.pad);
      expect(l.voices.single.beats, same(l.beats));
    });
    test('a kit line: beats are the first voice, voices as given', () {
      final l = kitLine([hh, sn, bd], counts: true, title: 'Groove');
      expect(l.isKit, isTrue);
      expect(l.beats, same(hh.beats));
      expect(l.voices.map((v) => v.instrument), [
        KitInstrument.hiHatClosed,
        KitInstrument.snare,
        KitInstrument.kick,
      ]);
      expect(l.counts, isTrue);
      expect(l.title, 'Groove');
      expect(l.repeat, isTrue);
    });
    test('kitLine() with no voices throws', () {
      expect(() => kitLine(const []), throwsA(isA<AssertionError>()));
    });
    test('kitBarsOrThrow: equal whole bars pass, unequal lengths throw', () {
      expect(
          kitBarsOrThrow([hh, sn, bd], beatsPerBar: 4, grid: NoteGrid.eighth),
          1);
      final short = voice(KitInstrument.tom1, [note(R, NoteValue.half)]);
      expect(
          () => kitBarsOrThrow([hh, short],
              beatsPerBar: 4, grid: NoteGrid.eighth),
          throwsArgumentError);
    });
  });

  group('Rudiment', () {
    test('isKit follows voicing; patternVoices default empty; withSticking '
        'keeps both', () {
      final pad = Rudiment(
          id: 'p',
          name: 'P',
          description: '',
          minBpm: 60,
          targetBpm: 100,
          difficulty: Difficulty.beginner,
          sticking: eighths([R, L]));
      expect(pad.isKit, isFalse);
      expect(pad.patternVoices, isEmpty);
      final kit = Rudiment(
          id: 'k',
          name: 'K',
          description: '',
          minBpm: 60,
          targetBpm: 100,
          difficulty: Difficulty.beginner,
          sticking: eighths([R, R, R, R, R, R, R, R]),
          voicing: ExerciseVoicing.kit,
          requiredSensor: SensorLevel.midi,
          patternVoices: [
            voice(KitInstrument.hiHatClosed, eighths([R, R, R, R, R, R, R, R])),
          ]);
      expect(kit.isKit, isTrue);
      final unit = kit.withSticking(eighths([R, R]));
      expect(unit.isKit, isTrue);
      expect(unit.patternVoices.length, 1);
      expect(unit.requiredSensor, SensorLevel.midi);
    });
  });
}
```

In `test/coaching/stroke_analysis_test.dart` einen Test ergänzen (die Datei importiert bereits `stroke_analysis.dart`, `stroke_source.dart`, `kit_instrument.dart`, `rudiment.dart`; fehlende Importe nachziehen):

```dart
  test('a beat without a hand (foot voice) yields a hit without hand letter',
      () {
    final t0 = DateTime(2026, 1, 1, 12).microsecondsSinceEpoch / 1000.0;
    final sticking = [
      const StrokeBeat(hand: null, value: NoteValue.quarter),
      const StrokeBeat(hand: null, value: NoteValue.quarter),
      const StrokeBeat(hand: null, value: NoteValue.quarter),
      const StrokeBeat(hand: null, value: NoteValue.quarter),
    ];
    final beatLog = [
      for (var i = 0; i < 8; i++)
        (
          beatIndex: i % 4,
          timestamp: DateTime.fromMicrosecondsSinceEpoch(
              ((t0 + i * 500) * 1000).round()),
        ),
    ];
    final events = [
      for (var i = 0; i < 8; i++)
        StrokeEvent(
            timeMs: t0 + i * 500 + 3,
            instrument: KitInstrument.kick,
            velocity: 0.8,
            rawNote: 36,
            source: StrokeSourceKind.midi),
    ];
    final a = analyzeStrokes(
      events: events,
      beatLog: beatLog,
      sticking: sticking,
      source: StrokeSourceKind.midi,
      expectedInstrument: KitInstrument.kick,
      analysisMode: true,
    );
    expect(a.alignment!.hitCount, 8);
    expect(a.events.where((e) => e.notePosition != null).length, 8);
    expect(a.events.every((e) => e.hand == null), isTrue);
    // Per-hand values exist but carry nothing: no hand was assigned.
    expect(a.timing!.rightHandDeviationMs, 0);
    expect(a.timing!.leftHandDeviationMs, 0);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/lessons/voice_model_test.dart test/coaching/stroke_analysis_test.dart`
Expected: Kompilierfehler (`foot`, `voice`, `kitLine`, `InstrumentClass`, `isFoot`, `patternVoices` unbekannt; `hand: null` verletzt `Hand`).

- [ ] **Step 3: Implementation**

`lib/features/coaching/midi/kit_instrument.dart` — nach dem `KitInstrument`-Enum einfügen:

```dart
/// Kick and hi-hat pedal are played with the feet: their voices carry no
/// hand, their stems point down (Brief B.1/B.2).
extension KitInstrumentFoot on KitInstrument {
  bool get isFoot => this == KitInstrument.kick || this == KitInstrument.hiHatPedal;
}

/// A class of instruments a voice may accept instead of one (Brief B.3): a
/// fill over "any tom" is not wrong because the drummer chose the other
/// tom. Drawing and playback still use the voice's own instrument.
enum InstrumentClass {
  anyTom('Any tom', {
    KitInstrument.tom1,
    KitInstrument.tom2,
    KitInstrument.floorTom1,
    KitInstrument.floorTom2,
  }),
  anyCrash('Any crash', {
    KitInstrument.crash1,
    KitInstrument.crash2,
    KitInstrument.china,
    KitInstrument.splash,
  }),
  anyCymbal('Any cymbal', {
    KitInstrument.crash1,
    KitInstrument.crash2,
    KitInstrument.china,
    KitInstrument.splash,
    KitInstrument.ride,
    KitInstrument.rideBell,
    KitInstrument.hiHatClosed,
    KitInstrument.hiHatOpen,
  });

  const InstrumentClass(this.label, this.members);
  final String label;
  final Set<KitInstrument> members;
}
```

`lib/features/lessons/models/rudiment.dart`:

1. Import ergänzen: `import '../../coaching/midi/kit_instrument.dart';`
2. `StrokeBeat`: `final Hand hand;` → `final Hand? hand;` mit Doc-Kommentar `/// Playing hand; null for foot strokes (kick, hi-hat pedal) and rests.`; Konstruktor bleibt `required this.hand`. In `StrokeBeat.rest`: `hand = Hand.right,` → `hand = null,` und den Kommentar `/// A silent grid cell (rest). [hand] is ignored when rendering.` auf `/// A silent grid cell (rest): no hand.` ändern.
3. Vor `class ExerciseLine` einfügen:

```dart
/// One voice of a kit line (Brief B.1): what a whole pad exercise is today
/// — a beat list on the 24-tick grid — plus the instrument it is played on.
/// [accepts] widens the *measured* instrument to a class (B.3: a fill over
/// any tom); drawing and playback use [instrument]. Foot voices carry beats
/// without a hand.
class Voice {
  final KitInstrument instrument;
  final InstrumentClass? accepts;
  final List<StrokeBeat> beats;
  const Voice(this.instrument, this.beats, {this.accepts});

  bool get isFoot => instrument.isFoot;

  /// Whether a stroke on [played] belongs to this voice.
  bool matches(KitInstrument played) =>
      accepts?.members.contains(played) ?? played == instrument;
}
```

4. `ExerciseLine` ersetzen durch:

```dart
/// One line of a sheet (Blattform, 30.09.): a phrase of whole bars, drawn
/// with a number box, repeat signs when [repeat], an optional [title] above
/// the staff ("Challenge") and, when [counts], the count syllables under the
/// sticking letters.
///
/// A pad line is one voice (`pad`) — [beats]. A kit line (Brief B.1) carries
/// [kitVoices], one per instrument, all of the same tick length; [beats] is
/// then the first voice so every single-voice reader (bar count, library
/// meta) keeps working.
class ExerciseLine {
  final List<StrokeBeat> beats;
  final List<Voice> kitVoices;
  final bool repeat;
  final String? title;
  final bool counts;
  const ExerciseLine(this.beats,
      {this.repeat = true, this.title, this.counts = false})
      : kitVoices = const [];

  ExerciseLine.kit(List<Voice> voices,
      {this.repeat = true, this.title, this.counts = false})
      : assert(voices.isNotEmpty, 'a kit line needs at least one voice'),
        kitVoices = List.unmodifiable(voices),
        beats = voices.first.beats;

  bool get isKit => kitVoices.isNotEmpty;

  /// The voices of this line: the kit voices, or the pad voice of a pad line.
  List<Voice> get voices =>
      isKit ? kitVoices : [Voice(KitInstrument.pad, beats)];
}
```

5. `Rudiment`: nach `final List<ExerciseLine> lines;` ergänzen

```dart
  /// The PATTERN bar of a kit exercise (Brief B.1/B.2): one bar, every
  /// voice. [sticking] is then its first voice. Empty for pad exercises.
  final List<Voice> patternVoices;
```

   Konstruktor: `this.patternVoices = const [],` nach `this.lines = const [],`. Getter nach `sheet`: `/// Kit exercise: full-kit notation, MIDI only (Brief B).` `bool get isKit => voicing == ExerciseVoicing.kit;`. In `withSticking` die Zeile `patternVoices: patternVoices,` nach `backing: backing,` ergänzen. Doc-Kommentar von `ExerciseVoicing.kit` auf `/// `kit` = full kit notation, one voice per instrument (Etappe 2, Phase B).` kürzen.

`lib/features/lessons/data/etude_dsl.dart` — Import `import '../../coaching/midi/kit_instrument.dart';` und am Ende:

```dart
/// A foot stroke (kick, hi-hat pedal): no hand (Brief B.1).
StrokeBeat foot(NoteValue v,
        {bool accent = false,
        bool ghost = false,
        bool dotted = false,
        Tuplet tuplet = Tuplet.none}) =>
    StrokeBeat(
        hand: null,
        value: v,
        isAccent: accent,
        isGhost: ghost,
        dotted: dotted,
        tuplet: tuplet);

/// One voice of a kit line.
Voice voice(KitInstrument instrument, List<StrokeBeat> beats,
        {InstrumentClass? accepts}) =>
    Voice(instrument, beats, accepts: accepts);

/// One kit line (Brief B.1): voices of equal length, whole bars —
/// `kitBarsOrThrow` guards it in the integrity test.
ExerciseLine kitLine(List<Voice> voices,
        {bool repeat = true, String? title, bool counts = false}) =>
    ExerciseLine.kit(voices, repeat: repeat, title: title, counts: counts);

/// Bar count of a kit line; throws unless every voice fills the same
/// positive whole number of bars.
int kitBarsOrThrow(List<Voice> voices,
    {required int beatsPerBar, required NoteGrid grid}) {
  if (voices.isEmpty) throw ArgumentError('kit line without voices');
  final bars = [
    for (final v in voices)
      barCountOrThrow(v.beats, beatsPerBar: beatsPerBar, grid: grid),
  ];
  if (bars.any((b) => b != bars.first)) {
    throw ArgumentError('voices differ in length: $bars bars');
  }
  return bars.first;
}
```

`lib/shared/widgets/notation_staff_widget.dart:527-533` — den Buchstaben-Block ersetzen:

```dart
      // R/L letter — hand voices only (foot strokes have none).
      final letter = switch (beat.hand) {
        Hand.right => 'R',
        Hand.left => 'L',
        null => null,
      };
      if (showSticking && letter != null) {
        _drawText(canvas, letter, Offset(x, y0 + _letterY), _dim(_letterColor),
            12,
            bold: true);
      }
```

`lib/features/coaching/models/session_analysis.dart:238` — `final Hand hand;` → `/// Playing hand from the sticking; null for a foot voice.` `final Hand? hand;`.

`lib/features/coaching/services/stroke_analysis.dart:259-266` — den `hand:`-Ausdruck ersetzen:

```dart
        hand: noteByOnset[j] == null || !gateOpen
            ? null
            : switch (sticking[beatLog[noteByOnset[j]!.noteIndex].beatIndex %
                        sticking.length]
                    .hand) {
                Hand.right => 'R',
                Hand.left => 'L',
                null => null,
              },
```

`_calcTiming` / `_calcDynamics` bleiben unverändert (`m.hand == h` ist für `null` nie wahr).

- [ ] **Step 4: Run tests**

Run: `flutter analyze && flutter test`
Expected: analyze sauber; die beiden neuen Dateien grün; die ganze Suite grün (558 + neue). `exercise_generator_screen.dart` zählt `b.hand == Hand.right` — kompiliert mit `Hand?` unverändert.

- [ ] **Step 5: Commit**

```bash
git add lib/features/coaching/midi/kit_instrument.dart lib/features/lessons/models/rudiment.dart lib/features/lessons/data/etude_dsl.dart lib/shared/widgets/notation_staff_widget.dart lib/features/coaching/models/session_analysis.dart lib/features/coaching/services/stroke_analysis.dart test/lessons/voice_model_test.dart test/coaching/stroke_analysis_test.dart
git commit -m "feat(model): Stimmen — Hand optional, Voice + InstrumentClass, ExerciseLine.kit, patternVoices, DSL foot/voice/kitLine"
```

---

### Task 2: Reine Geometrie der mehrstimmigen Zeile — `StaffScale`, Layer-Tracks, `KitLineLayout`

**Files:**
- Modify: `lib/shared/widgets/staff_layout.dart` (`StaffScale`, `chooseStaffScale`, `computeStaffLayout(scale:)`, `StaffLayout.originX/barGap/xOfTick/rowOfTick`)
- Create: `lib/shared/widgets/kit_layout.dart`
- Test: `test/shared/kit_layout_test.dart`; `test/shared/staff_layout_test.dart` bleibt unverändert grün (reiner Refactor)

**Interfaces:**
- Consumes: `Voice`, `StrokeBeat` (`Hand?`), `resolveNote`, `ResolvedNote`, `NoteGrid`, `computeStaffLayout`, `KitInstrument.isFoot` (Task 1).
- Produces:
  - `class StaffScale { final double pxPerQuarter; final int barsPerRow; const StaffScale({required this.pxPerQuarter, required this.barsPerRow}); }`
  - `StaffScale chooseStaffScale({required double? finestQuarters, required int totalBars, required int beatsPerBar, required double maxWidth, double leftPad = 8, double rightPad = 12, double systemPad = 26, double barGap = 12, double preferredPxPerQuarter = 56, int targetBarsPerRow = 2})` — exakt die heutige Skalenwahl aus `computeStaffLayout`.
  - `computeStaffLayout(..., StaffScale? scale)` — gegeben ⇒ keine eigene Wahl. `StaffLayout` bekommt `final double originX` (= `leftPad + systemPad`), `final double barGap`, `double xOfTick(int tick)`, `int rowOfTick(int tick)`.
  - `kit_layout.dart`: `const int kitTicksPerQuarter = 24;` `ResolvedNote? valueForGap(int ticks)`; `typedef KitNote = ({Voice voice, StrokeBeat beat});` `class KitColumn { final int tick; final List<KitNote> notes; Iterable<KitNote> get hands; Iterable<KitNote> get feet; }`; `List<({int tick, StrokeBeat beat})> onsetsOf(List<StrokeBeat> beats, NoteGrid grid)`; `int ticksOf(List<StrokeBeat> beats, NoteGrid grid)`; `int ticksOfNote(ResolvedNote r)`; `class KitLayer { final List<StrokeBeat> track; final Map<int, int> indexOfTick; }`; `KitLayer layerTrack(List<Voice> voices, {required NoteGrid grid, required int totalTicks, int ticksPerBeat = kitTicksPerQuarter})`; `class KitLineLayout { StaffScale scale; int beatsPerBar; int totalTicks; int rowCount; StaffLayout hands; StaffLayout feet; List<StrokeBeat> handsTrack; List<StrokeBeat> feetTrack; Map<int,int> handsIndexOfTick; Map<int,int> feetIndexOfTick; List<KitColumn> columns; double xOfTick(int); int rowOfTick(int); }`; `KitLineLayout computeKitLineLayout({required List<Voice> voices, required NoteGrid grid, required int beatsPerBar, required double maxWidth, double leftPad = 8, double rightPad = 12, double systemPad = 26, double barGap = 12})`.

- [ ] **Step 1: Failing tests**

`test/shared/kit_layout_test.dart`:

```dart
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/kit_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<StrokeBeat> hh8() => eighths([R, R, R, R, R, R, R, R]);
  List<StrokeBeat> backbeat() => [
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
      ];
  List<StrokeBeat> kick13() => [
        foot(NoteValue.quarter),
        rest(NoteValue.quarter),
        foot(NoteValue.quarter),
        rest(NoteValue.quarter),
      ];
  Voice hh() => voice(KitInstrument.hiHatClosed, hh8());
  Voice sn() => voice(KitInstrument.snare, backbeat());
  Voice bd() => voice(KitInstrument.kick, kick13());

  group('valueForGap', () {
    test('largest drawable value that fits the gap; 0 and 1 tick undrawable',
        () {
      ({NoteValue v, bool d, Tuplet t}) f(int ticks) {
        final r = valueForGap(ticks)!;
        return (v: r.value, d: r.dotted, t: r.tuplet);
      }
      expect(f(24), (v: NoteValue.quarter, d: false, t: Tuplet.none));
      expect(f(18), (v: NoteValue.eighth, d: true, t: Tuplet.none));
      expect(f(16), (v: NoteValue.quarter, d: false, t: Tuplet.triplet));
      expect(f(12), (v: NoteValue.eighth, d: false, t: Tuplet.none));
      expect(f(9), (v: NoteValue.sixteenth, d: true, t: Tuplet.none));
      expect(f(8), (v: NoteValue.eighth, d: false, t: Tuplet.triplet));
      expect(f(6), (v: NoteValue.sixteenth, d: false, t: Tuplet.none));
      expect(f(4), (v: NoteValue.sixteenth, d: false, t: Tuplet.sextuplet));
      expect(f(3), (v: NoteValue.thirtySecond, d: false, t: Tuplet.none));
      expect(f(2), (v: NoteValue.thirtySecond, d: false, t: Tuplet.triplet));
      // Gaps between table entries take the next smaller value.
      expect(f(30).v, NoteValue.quarter);
      expect(f(5), (v: NoteValue.sixteenth, d: false, t: Tuplet.sextuplet));
      expect(valueForGap(1), isNull);
      expect(valueForGap(0), isNull);
      for (final ticks in [24, 18, 16, 12, 9, 8, 6, 4, 3, 2]) {
        expect(ticksOfNote(valueForGap(ticks)!), ticks);
      }
    });
  });

  group('onsetsOf / ticksOf', () {
    test('rests are no onsets; ticks add up', () {
      final o = onsetsOf(backbeat(), NoteGrid.eighth);
      expect(o.map((e) => e.tick), [24, 72]);
      expect(o.first.beat.isAccent, isTrue);
      expect(ticksOf(backbeat(), NoteGrid.eighth), 96);
      expect(ticksOf(hh8(), NoteGrid.eighth), 96);
    });
  });

  group('layerTrack', () {
    test('hi-hat eighths + backbeat: eight eighths, no letter where the hands '
        'differ (shared column), accent carried', () {
      final layer =
          layerTrack([hh(), sn()], grid: NoteGrid.eighth, totalTicks: 96);
      expect(layer.track.length, 8);
      expect(
          layer.track.every((b) => !b.isRest && b.value == NoteValue.eighth),
          isTrue);
      expect(layer.track.map((b) => b.hand).toList(),
          [R, R, null, R, R, R, null, R]);
      expect(layer.track[2].isAccent, isTrue);
      expect(layer.track[0].isAccent, isFalse);
      expect(layer.indexOfTick, {0: 0, 12: 1, 24: 2, 36: 3, 48: 4, 60: 5, 72: 6, 84: 7});
    });

    test('kick on 1 and 3: quarter, rest, quarter, rest — no hand', () {
      final layer = layerTrack([bd()], grid: NoteGrid.eighth, totalTicks: 96);
      expect(layer.track.map((b) => b.isRest).toList(),
          [false, true, false, true]);
      expect(layer.track.every((b) => b.value == NoteValue.quarter), isTrue);
      expect(layer.track[0].hand, isNull);
      expect(layer.indexOfTick, {0: 0, 48: 2});
    });

    test('gap of 42 ticks (kick on 1 and the "a" of 2): capped at the beat, '
        'rests fill up, nothing drifts', () {
      final kickBeats = [
        foot(NoteValue.quarter), // 0..24
        rest(NoteValue.eighth, dotted: true), // 24..42
        foot(NoteValue.sixteenth), // 42..48
        rest(NoteValue.sixteenth), // 48 is never reached by a note
        rest(NoteValue.quarter),
        rest(NoteValue.quarter),
      ];
      expect(ticksOf(kickBeats, NoteGrid.eighth), 96);
      final layer = layerTrack([voice(KitInstrument.kick, kickBeats)],
          grid: NoteGrid.eighth, totalTicks: 96);
      expect(layer.track.map((b) => (b.isRest, b.value, b.dotted)).toList(), [
        (false, NoteValue.quarter, false), // 0..24
        (true, NoteValue.eighth, true), // 24..42
        (false, NoteValue.sixteenth, false), // 42..48
        (true, NoteValue.quarter, false), // 48..72
        (true, NoteValue.quarter, false), // 72..96
      ]);
      expect(ticksOf(layer.track, NoteGrid.eighth), 96);
      expect(layer.indexOfTick, {0: 0, 42: 2});
    });

    test('a hole of two beats is two quarter rests, never a half rest', () {
      final beats = [
        note(R, NoteValue.quarter), // 0..24
        rest(NoteValue.half), // 24..72
        note(R, NoteValue.quarter), // 72..96
      ];
      final layer = layerTrack([voice(KitInstrument.snare, beats)],
          grid: NoteGrid.eighth, totalTicks: 96);
      expect(layer.track.map((b) => (b.isRest, b.value)).toList(), [
        (false, NoteValue.quarter),
        (true, NoteValue.quarter),
        (true, NoteValue.quarter),
        (false, NoteValue.quarter),
      ]);
      expect(layer.indexOfTick, {0: 0, 72: 3});
    });

    test('no voices: rests only, full length', () {
      final layer = layerTrack(const [], grid: NoteGrid.eighth, totalTicks: 96);
      expect(layer.track.length, 4);
      expect(layer.track.every((b) => b.isRest && b.value == NoteValue.quarter),
          isTrue);
      expect(layer.indexOfTick, isEmpty);
    });

    test('a one-tick gap between two voices is not drawable and throws', () {
      // Snare: 32nd on tick 3. Tom: 32nd triplet on tick 4.
      final a = [
        rest(NoteValue.thirtySecond),
        note(R, NoteValue.thirtySecond),
        rest(NoteValue.sixteenth),
        rest(NoteValue.eighth),
        rest(NoteValue.half),
        rest(NoteValue.quarter),
      ];
      final b = [
        rest(NoteValue.thirtySecond, tuplet: Tuplet.triplet),
        rest(NoteValue.thirtySecond, tuplet: Tuplet.triplet),
        note(L, NoteValue.thirtySecond, tuplet: Tuplet.triplet),
        for (var i = 0; i < 9; i++)
          rest(NoteValue.thirtySecond, tuplet: Tuplet.triplet),
        rest(NoteValue.half),
        rest(NoteValue.quarter),
      ];
      expect(ticksOf(a, NoteGrid.eighth), 96);
      expect(ticksOf(b, NoteGrid.eighth), 96);
      expect(
          () => layerTrack([
                voice(KitInstrument.snare, a),
                voice(KitInstrument.tom1, b),
              ], grid: NoteGrid.eighth, totalTicks: 96),
          throwsArgumentError);
    });
  });

  group('computeKitLineLayout', () {
    test('columns = union of onsets; both layers share the scale; x by tick',
        () {
      final kl = computeKitLineLayout(
          voices: [hh(), sn(), bd()],
          grid: NoteGrid.eighth,
          beatsPerBar: 4,
          maxWidth: 360);
      expect(kl.columns.map((c) => c.tick), [0, 12, 24, 36, 48, 60, 72, 84]);
      expect(kl.columns[0].notes.length, 2); // hi-hat + kick
      expect(kl.columns[0].feet.length, 1);
      expect(kl.columns[2].notes.length, 2); // hi-hat + snare
      expect(kl.columns[2].feet, isEmpty);
      expect(kl.columns[1].hands.length, 1);
      expect(kl.hands.pxPerQuarter, kl.feet.pxPerQuarter);
      expect(kl.hands.barsPerRow, kl.feet.barsPerRow);
      expect(kl.xOfTick(24) - kl.xOfTick(0),
          closeTo(kl.scale.pxPerQuarter, 1e-6));
      expect(kl.feet.xOfTick(48), closeTo(kl.hands.xOfTick(48), 1e-6));
      expect(kl.hands.placements[2].xCenter, closeTo(kl.xOfTick(24), 1e-6));
      expect(kl.rowCount, 1);
      expect(kl.rowOfTick(95), 0);
      expect(kl.totalTicks, 96);
      expect(kl.handsTrack.length, 8);
      expect(kl.feetTrack.length, 4);
      expect(kl.handsIndexOfTick[24], 2);
      expect(kl.feetIndexOfTick[48], 2);
    });

    test('rows wrap like a pad line: 2 bars = 1 row, 4 bars = 2 rows', () {
      Voice twice(Voice v) => voice(v.instrument, [...v.beats, ...v.beats]);
      final two = computeKitLineLayout(
          voices: [twice(hh()), twice(sn()), twice(bd())],
          grid: NoteGrid.eighth,
          beatsPerBar: 4,
          maxWidth: 360);
      expect(two.rowCount, 1);
      expect(two.scale.barsPerRow, 2);
      final four = computeKitLineLayout(
          voices: [twice(twice(hh())), twice(twice(sn())), twice(twice(bd()))],
          grid: NoteGrid.eighth,
          beatsPerBar: 4,
          maxWidth: 360);
      expect(four.rowCount, 2);
      expect(four.rowOfTick(0), 0);
      expect(four.rowOfTick(2 * 96), 1);
      expect(four.rowOfTick(4 * 96 - 1), 1);
      expect(four.xOfTick(2 * 96), closeTo(four.xOfTick(0), 1e-6));
    });

    test('voices of different length throw', () {
      expect(
          () => computeKitLineLayout(
              voices: [hh(), voice(KitInstrument.tom1, [note(R, NoteValue.half)])],
              grid: NoteGrid.eighth,
              beatsPerBar: 4,
              maxWidth: 360),
          throwsArgumentError);
    });

    test('the finest voice sets the scale, even when it is a foot voice', () {
      final hhQuarters = voice(KitInstrument.hiHatClosed,
          [for (var i = 0; i < 4; i++) note(R, NoteValue.quarter)]);
      final kick16 = voice(KitInstrument.kick,
          [for (var i = 0; i < 16; i++) foot(NoteValue.sixteenth)]);
      final kl = computeKitLineLayout(
          voices: [hhQuarters, kick16],
          grid: NoteGrid.eighth,
          beatsPerBar: 4,
          maxWidth: 120);
      // Legibility floor of a sixteenth-note piece: 9 px / 0.25 q = 36 px/q.
      expect(kl.scale.pxPerQuarter, 36);
      expect(kl.scale.barsPerRow, 1);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/shared/kit_layout_test.dart`
Expected: Kompilierfehler (`kit_layout.dart` fehlt).

- [ ] **Step 3: `staff_layout.dart` — Skala herausziehen, Tick-Geometrie am Layout**

Nach `class BeamGroup` einfügen:

```dart
/// Horizontal scale of a staff: px per quarter and bars per row. Chosen
/// once per line so that every voice of a kit line shares it and equal
/// ticks land on equal x (Brief B.2).
class StaffScale {
  final double pxPerQuarter;
  final int barsPerRow;
  const StaffScale({required this.pxPerQuarter, required this.barsPerRow});
}
```

`StaffLayout`: zwei Felder und zwei Methoden ergänzen (Konstruktor mit Vorgaben, damit bestehende Aufrufe unverändert bleiben):

```dart
  /// x of the first tick of a row (left pad + system pad), and the gap
  /// between bars — what [xOfTick] needs.
  final double originX;
  final double barGap;
  const StaffLayout({
    required this.rowCount,
    required this.pxPerQuarter,
    required this.beatsPerBar,
    required this.barsPerRow,
    required this.placements,
    required this.beams,
    this.xOffset = 0,
    this.originX = 0,
    this.barGap = 12,
  });

  /// x centre of [tick] in its row's coordinate space — the same formula
  /// the placements use, so a column of several voices lines up.
  double xOfTick(int tick) {
    final ticksPerBar = beatsPerBar * _ticksPerQuarter;
    final bar = tick ~/ ticksPerBar;
    final barInRow = bar % barsPerRow;
    final quartersInBar = (tick - bar * ticksPerBar) / _ticksPerQuarter;
    return originX +
        barInRow * (beatsPerBar * pxPerQuarter + barGap) +
        quartersInBar * pxPerQuarter;
  }

  int rowOfTick(int tick) =>
      (tick ~/ (beatsPerBar * _ticksPerQuarter)) ~/ barsPerRow;
```

`chooseStaffScale` vor `computeStaffLayout` einfügen — der Block von `final usable = …` bis zum Ende des `if (pxPerQuarter < minPxPerQuarter) { … }` wandert wörtlich hierher:

```dart
/// Chooses the scale of a line: rows are [targetBarsPerRow] bars wide and
/// the note width flexes to fit; short pieces take the whole row; a piece
/// too dense for that falls back to one bar per row, and legibility of its
/// finest note ([finestQuarters], null = no notes) wins over the width.
StaffScale chooseStaffScale({
  required double? finestQuarters,
  required int totalBars,
  required int beatsPerBar,
  required double maxWidth,
  double leftPad = 8,
  double rightPad = 12,
  double systemPad = 26,
  double barGap = 12,
  double preferredPxPerQuarter = 56,
  int targetBarsPerRow = 2,
}) {
  final usable = maxWidth - leftPad - rightPad - systemPad;
  final minPxPerQuarter =
      finestQuarters == null ? 8.0 : _minNoteWidthPx / finestQuarters;
  final shortPiece = totalBars < targetBarsPerRow;
  final cap = shortPiece ? preferredPxPerQuarter * 1.5 : preferredPxPerQuarter;
  var barsPerRow = shortPiece ? totalBars : targetBarsPerRow;
  var pxPerQuarter = ((usable + barGap) / barsPerRow - barGap) / beatsPerBar;
  if (pxPerQuarter > cap) pxPerQuarter = cap;
  if (pxPerQuarter < minPxPerQuarter) {
    barsPerRow = 1;
    pxPerQuarter = usable / beatsPerBar;
    if (pxPerQuarter > preferredPxPerQuarter) {
      pxPerQuarter = preferredPxPerQuarter;
    }
    if (pxPerQuarter < minPxPerQuarter) pxPerQuarter = minPxPerQuarter;
  }
  return StaffScale(pxPerQuarter: pxPerQuarter, barsPerRow: barsPerRow);
}
```

Die bestehenden Kommentare (Legibility floor, "Rows are a fixed …", "Extreme case …") mitnehmen. `computeStaffLayout` bekommt den Parameter `StaffScale? scale,` (nach `targetBarsPerRow`); im Rumpf ersetzt dieser Block die herausgezogenen Zeilen:

```dart
  var totalTicksAll = 0;
  for (final b in beats) {
    totalTicksAll += (resolveNote(b, grid).quarters * _ticksPerQuarter).round();
  }
  final totalBarsAll = (totalTicksAll / ticksPerBar).ceil().clamp(1, 1 << 30);
  final chosen = scale ??
      chooseStaffScale(
        finestQuarters: _finestDurationQuarters(beats, grid),
        totalBars: totalBarsAll,
        beatsPerBar: beatsPerBar,
        maxWidth: maxWidth,
        leftPad: leftPad,
        rightPad: rightPad,
        systemPad: systemPad,
        barGap: barGap,
        preferredPxPerQuarter: preferredPxPerQuarter,
        targetBarsPerRow: targetBarsPerRow,
      );
  final barsPerRow = chosen.barsPerRow;
  final pxPerQuarter = chosen.pxPerQuarter;
  final usable = maxWidth - leftPad - rightPad - systemPad;
```

(`usable` braucht die `xOffset`-Rechnung am Ende weiterhin.) Im `return StaffLayout(...)` ergänzen: `originX: leftPad + systemPad, barGap: barGap,`.

- [ ] **Step 4: `kit_layout.dart`**

```dart
import 'dart:collection';

import '../../features/coaching/midi/kit_instrument.dart';
import '../../features/lessons/models/rudiment.dart';
import 'staff_layout.dart';

/// Geometry of a kit line (Brief B.2): the voices are merged into two
/// layers — hands (stems up) and feet (stems down) — each a rhythm track
/// `computeStaffLayout` can beam like a pad line, both on one [StaffScale]
/// so equal ticks land on equal x. Pure, no Flutter.
const int kitTicksPerQuarter = 24;

const List<({int ticks, ResolvedNote note})> _gapValues = [
  (ticks: 24, note: ResolvedNote(NoteValue.quarter, false, Tuplet.none)),
  (ticks: 18, note: ResolvedNote(NoteValue.eighth, true, Tuplet.none)),
  (ticks: 16, note: ResolvedNote(NoteValue.quarter, false, Tuplet.triplet)),
  (ticks: 12, note: ResolvedNote(NoteValue.eighth, false, Tuplet.none)),
  (ticks: 9, note: ResolvedNote(NoteValue.sixteenth, true, Tuplet.none)),
  (ticks: 8, note: ResolvedNote(NoteValue.eighth, false, Tuplet.triplet)),
  (ticks: 6, note: ResolvedNote(NoteValue.sixteenth, false, Tuplet.none)),
  (ticks: 4, note: ResolvedNote(NoteValue.sixteenth, false, Tuplet.sextuplet)),
  (ticks: 3, note: ResolvedNote(NoteValue.thirtySecond, false, Tuplet.none)),
  (ticks: 2, note: ResolvedNote(NoteValue.thirtySecond, false, Tuplet.triplet)),
];

/// Drawn value for a gap of [ticks] inside one beat: the time from an onset
/// of a layer to the layer's next onset, capped at the beat. The largest
/// drawable value that fits; null for 0 or 1 tick.
ResolvedNote? valueForGap(int ticks) {
  for (final e in _gapValues) {
    if (e.ticks <= ticks) return e.note;
  }
  return null;
}

int ticksOfNote(ResolvedNote r) => (r.quarters * kitTicksPerQuarter).round();

int ticksOf(List<StrokeBeat> beats, NoteGrid grid) {
  var t = 0;
  for (final b in beats) {
    t += ticksOfNote(resolveNote(b, grid));
  }
  return t;
}

/// Onsets of [beats] (rests excluded) with their tick.
List<({int tick, StrokeBeat beat})> onsetsOf(
    List<StrokeBeat> beats, NoteGrid grid) {
  final out = <({int tick, StrokeBeat beat})>[];
  var cursor = 0;
  for (final b in beats) {
    if (!b.isRest) out.add((tick: cursor, beat: b));
    cursor += ticksOfNote(resolveNote(b, grid));
  }
  return out;
}

/// A sounding note of one voice at a column.
typedef KitNote = ({Voice voice, StrokeBeat beat});

/// Every voice that sounds at one tick of a kit line.
class KitColumn {
  final int tick;
  final List<KitNote> notes;
  const KitColumn(this.tick, this.notes);
  Iterable<KitNote> get hands => notes.where((n) => !n.voice.isFoot);
  Iterable<KitNote> get feet => notes.where((n) => n.voice.isFoot);
}

/// One layer merged into a rhythm track plus the track index of each onset.
class KitLayer {
  final List<StrokeBeat> track;
  final Map<int, int> indexOfTick;
  const KitLayer(this.track, this.indexOfTick);
}

SplayTreeMap<int, List<KitNote>> _columnsOf(List<Voice> voices, NoteGrid grid) {
  final byTick = SplayTreeMap<int, List<KitNote>>();
  for (final v in voices) {
    for (final o in onsetsOf(v.beats, grid)) {
      (byTick[o.tick] ??= []).add((voice: v, beat: o.beat));
    }
  }
  return byTick;
}

/// Merges the [voices] of one layer (hands or feet) into one rhythm track:
/// every onset becomes a note whose drawn value is the gap to the layer's
/// next onset, capped at the beat; the rest of the gap is rests, beat by
/// beat, so the track's ticks add up exactly and nothing drifts. The note
/// carries the one hand of the column (null when the hands differ or
/// there is none), an accent if any voice accents, the first hand voice's
/// graces. Throws when a gap is a single tick (undrawable).
KitLayer layerTrack(List<Voice> voices,
    {required NoteGrid grid,
    required int totalTicks,
    int ticksPerBeat = kitTicksPerQuarter}) {
  final byTick = _columnsOf(voices, grid);
  final ticks = byTick.keys.toList(growable: false);
  final track = <StrokeBeat>[];
  final index = <int, int>{};
  var cursor = 0;

  void restsUpTo(int upTo) {
    while (cursor < upTo) {
      final beatEnd = (cursor ~/ ticksPerBeat + 1) * ticksPerBeat;
      final end = upTo < beatEnd ? upTo : beatEnd;
      final r = valueForGap(end - cursor);
      if (r == null) {
        throw ArgumentError(
            'gap of ${end - cursor} tick(s) at tick $cursor is not drawable');
      }
      track.add(StrokeBeat.rest(value: r.value, dotted: r.dotted, tuplet: r.tuplet));
      cursor += ticksOfNote(r);
    }
  }

  for (var i = 0; i < ticks.length; i++) {
    final tick = ticks[i];
    restsUpTo(tick);
    final next = i + 1 < ticks.length ? ticks[i + 1] : totalTicks;
    final beatEnd = (tick ~/ ticksPerBeat + 1) * ticksPerBeat;
    final gap = (next < beatEnd ? next : beatEnd) - tick;
    final r = valueForGap(gap);
    if (r == null) {
      throw ArgumentError('gap of $gap tick(s) at tick $tick is not drawable');
    }
    final notes = byTick[tick]!;
    final hands = {for (final n in notes) if (n.beat.hand != null) n.beat.hand!};
    final lead = notes.firstWhere((n) => n.beat.hand != null,
        orElse: () => notes.first);
    index[tick] = track.length;
    track.add(StrokeBeat(
      hand: hands.length == 1 ? hands.first : null,
      value: r.value,
      dotted: r.dotted,
      tuplet: r.tuplet,
      isAccent: notes.any((n) => n.beat.isAccent),
      isGhost: notes.every((n) => n.beat.isGhost),
      graces: lead.beat.graces,
    ));
    cursor = tick + ticksOfNote(r);
  }
  restsUpTo(totalTicks);
  return KitLayer(track, index);
}

/// Layout of one kit line: both layers, their shared scale, the columns.
class KitLineLayout {
  final StaffScale scale;
  final int beatsPerBar;
  final int totalTicks;
  final int rowCount;
  final StaffLayout hands;
  final StaffLayout feet;
  final List<StrokeBeat> handsTrack;
  final List<StrokeBeat> feetTrack;
  final Map<int, int> handsIndexOfTick;
  final Map<int, int> feetIndexOfTick;
  final List<KitColumn> columns;
  const KitLineLayout({
    required this.scale,
    required this.beatsPerBar,
    required this.totalTicks,
    required this.rowCount,
    required this.hands,
    required this.feet,
    required this.handsTrack,
    required this.feetTrack,
    required this.handsIndexOfTick,
    required this.feetIndexOfTick,
    required this.columns,
  });

  double xOfTick(int tick) => hands.xOfTick(tick);
  int rowOfTick(int tick) => hands.rowOfTick(tick);
}

KitLineLayout computeKitLineLayout({
  required List<Voice> voices,
  required NoteGrid grid,
  required int beatsPerBar,
  required double maxWidth,
  double leftPad = 8,
  double rightPad = 12,
  double systemPad = 26,
  double barGap = 12,
}) {
  if (voices.isEmpty) throw ArgumentError('kit line without voices');
  final lengths = [for (final v in voices) ticksOf(v.beats, grid)];
  if (lengths.any((l) => l != lengths.first)) {
    throw ArgumentError('voices differ in length: $lengths ticks');
  }
  final totalTicks = lengths.first;
  final ticksPerBar = beatsPerBar * kitTicksPerQuarter;
  final totalBars = (totalTicks / ticksPerBar).ceil().clamp(1, 1 << 30);
  double? finest;
  for (final v in voices) {
    for (final b in v.beats) {
      final q = resolveNote(b, grid).quarters;
      if (q > 0 && (finest == null || q < finest)) finest = q;
    }
  }
  final scale = chooseStaffScale(
    finestQuarters: finest,
    totalBars: totalBars,
    beatsPerBar: beatsPerBar,
    maxWidth: maxWidth,
    leftPad: leftPad,
    rightPad: rightPad,
    systemPad: systemPad,
    barGap: barGap,
  );
  final handsLayer = layerTrack([for (final v in voices) if (!v.isFoot) v],
      grid: grid, totalTicks: totalTicks);
  final feetLayer = layerTrack([for (final v in voices) if (v.isFoot) v],
      grid: grid, totalTicks: totalTicks);
  StaffLayout lay(List<StrokeBeat> track) => computeStaffLayout(
        beats: track,
        grid: grid,
        beatsPerBar: beatsPerBar,
        maxWidth: maxWidth,
        leftPad: leftPad,
        rightPad: rightPad,
        systemPad: systemPad,
        barGap: barGap,
        scale: scale,
      );
  final columns = [
    for (final e in _columnsOf(voices, grid).entries)
      KitColumn(e.key, List.unmodifiable(e.value)),
  ];
  return KitLineLayout(
    scale: scale,
    beatsPerBar: beatsPerBar,
    totalTicks: totalTicks,
    rowCount: ((totalBars - 1) ~/ scale.barsPerRow) + 1,
    hands: lay(handsLayer.track),
    feet: lay(feetLayer.track),
    handsTrack: handsLayer.track,
    feetTrack: feetLayer.track,
    handsIndexOfTick: handsLayer.indexOfTick,
    feetIndexOfTick: feetLayer.indexOfTick,
    columns: columns,
  );
}
```

- [ ] **Step 5: Run tests**

Run: `flutter analyze && flutter test test/shared test/notation_staff_test.dart test/lessons`
Expected: alles grün, `sheet_staff_three_lines.png`-Golden unverändert (Skalenwahl ist ein wörtlicher Refactor).

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets/staff_layout.dart lib/shared/widgets/kit_layout.dart test/shared/kit_layout_test.dart
git commit -m "feat(notation): Kit-Geometrie — StaffScale geteilt, Layer-Tracks für Hände/Füße, Spalten, x und Reihe je Tick"
```

---

### Task 3: Notenbild B.2 — Kit-Zeilen im Painter, Blatt-Geometrie, Goldens

**Files:**
- Modify: `lib/shared/widgets/sheet_geometry.dart` (`kitRowPitch`, `SheetGeometry.kitLayouts/rowOfTick`, Kit-Zeilen in `computeSheetGeometry`)
- Modify: `lib/shared/widgets/notation_staff_widget.dart` (`part`, `voices`/`activeTick`, Kit-Pfad in `_paintRow`, Cursor-Helfer, Glyphen, vertikale Maße als Getter)
- Create: `lib/shared/widgets/kit_staff_painting.dart` (`part of`)
- Test: `test/notation_kit_staff_test.dart`, Goldens `test/goldens/kit_staff_sheet.png`, `test/goldens/kit_staff_pattern.png`; `test/shared/sheet_geometry_test.dart` (ein Test dazu)

**Interfaces:**
- Consumes: `KitLineLayout`, `computeKitLineLayout`, `KitColumn`, `KitNote` (Task 2); `Voice`, `ExerciseLine.isKit/kitVoices/voices`, `Rudiment.patternVoices` (Task 1); `beamCountFor`, `countLabelsFor`.
- Produces:
  - `const double kitRowPitch = 132;` `SheetGeometry(layouts, rowPitch, rowStart, totalRows, {List<KitLineLayout?> kitLayouts = const []})`, `SheetGeometry.isKit`, `int rowOfTick(int line, int tick)`.
  - `SheetStaffWidget({…, int? activeTick})` — für Kit-Zeilen setzt `activeTick` den Cursor (Tick innerhalb der Zeile), `activeIndex` wird dort ignoriert; `NotationStaffWidget` zeichnet `rudiment.patternVoices`, wenn vorhanden.
  - `int kitStaffStep(KitInstrument)`, `enum KitHeadShape { normal, x, diamond, circleX, xSmall }`, `KitHeadShape kitHeadShape(KitInstrument)` (öffentlich, im `part`).

Tabelle B.2 als Zahlen (`kitStaffStep`: halbe Linienabstände über der Mittellinie; Linien −4, −2, 0, 2, 4; Zwischenräume ungerade; −5 unter der ersten Linie, 5 über der fünften, 6 erste Hilfslinie):

| Instrument | Step | Kopf |
|---|---|---|
| hiHatPedal | −5 | x |
| kick | −3 | normal |
| floorTom2 | −2 | normal |
| floorTom1 | −1 | normal |
| snare / snareRim | 1 | normal / x |
| tom2 | 2 | normal |
| tom1 | 3 | normal |
| ride / rideBell | 4 | x / Raute |
| hiHatClosed / hiHatOpen | 5 | x / x mit „o" darüber |
| crash1, crash2 | 6 | x (+ Hilfslinie) |
| china | 6 | Kreis-x (+ Hilfslinie) |
| splash | 6 | x klein (+ Hilfslinie) |
| pad, unknown | 0 | normal |

Vertikale Maße der Kit-Reihe (Pad in Klammern): Akzent 6 (8), Hals-Oberkante 14 (18), Mittellinie 60 (54), Hals-Unterkante der Füße 96 (—), Titel 98 (69), Buchstaben 112 (90), Zählsilben 132 = `kitRowPitch` (104), Reihe 132 (104) + Zählband 14.

- [ ] **Step 1: Failing tests**

Die Vorlage `kitShowcase()` (unten im Test gezeigt) kommt als eigene Datei `test/helpers/kit_fixtures.dart` (nur die Funktion samt Imports von `kit_instrument.dart`, `stroke_source.dart`, `etude_dsl.dart`, `rudiment.dart`); Task 5 nutzt sie wieder. Der Test importiert sie mit `import 'helpers/kit_fixtures.dart';`.

`test/notation_kit_staff_test.dart`:

```dart
import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:drum_coach/shared/widgets/sheet_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// A showcase kit exercise: a rock groove and a line that touches every
/// head shape (toms, crash, open hat, ride bell, china, splash, cross-stick,
/// ghost, flam, hi-hat pedal) — the golden shows them all at once.
Rudiment kitShowcase() {
  List<StrokeBeat> hh8() => eighths([R, R, R, R, R, R, R, R]);
  List<StrokeBeat> backbeat() => [
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
      ];
  List<StrokeBeat> kick13() => [
        foot(NoteValue.quarter),
        rest(NoteValue.quarter),
        foot(NoteValue.quarter),
        rest(NoteValue.quarter),
      ];
  final pattern = [
    voice(KitInstrument.hiHatClosed, hh8()),
    voice(KitInstrument.snare, backbeat()),
    voice(KitInstrument.kick, kick13()),
  ];
  final groove = kitLine([
    voice(KitInstrument.hiHatClosed, [...hh8(), ...hh8()]),
    voice(KitInstrument.snare, [...backbeat(), ...backbeat()]),
    voice(KitInstrument.kick, [...kick13(), ...kick13()]),
  ], counts: true);
  // Bar 1: hi-hat eighths with the "&" of 4 open, snare ghost on the "e"
  // of 3, flam on 4, cross-stick on 2; kick 1 and "a" of 2; pedal on 2 + 4.
  // Bar 2: a sixteenth run snare → tom1 → tom2 → floor tom with ride bell
  // and china on 3, splash + crash on 4, kick under every beat.
  final fill = kitLine([
    voice(KitInstrument.hiHatClosed, [
      ...eighths([R, R, R, R, R, R, R]),
      rest(NoteValue.eighth),
      ...[for (var i = 0; i < 4; i++) rest(NoteValue.quarter)],
    ]),
    voice(KitInstrument.hiHatOpen, [
      rest(NoteValue.half),
      rest(NoteValue.quarter),
      rest(NoteValue.eighth),
      note(R, NoteValue.eighth),
      ...[for (var i = 0; i < 4; i++) rest(NoteValue.quarter)],
    ]),
    voice(KitInstrument.snare, [
      rest(NoteValue.quarter),
      rest(NoteValue.quarter),
      rest(NoteValue.sixteenth),
      note(L, NoteValue.sixteenth, ghost: true),
      rest(NoteValue.eighth),
      flam(L, NoteValue.quarter, accent: true),
      ...sixteenths([R, L, R, L]),
      ...[for (var i = 0; i < 3; i++) rest(NoteValue.quarter)],
    ]),
    voice(KitInstrument.snareRim, [
      rest(NoteValue.quarter),
      note(L, NoteValue.quarter),
      rest(NoteValue.half),
      rest(NoteValue.whole),
    ]),
    voice(KitInstrument.tom1, [
      rest(NoteValue.whole),
      rest(NoteValue.quarter),
      ...sixteenths([R, L, R, L]),
      rest(NoteValue.half),
    ], accepts: InstrumentClass.anyTom),
    voice(KitInstrument.tom2, [
      rest(NoteValue.whole),
      rest(NoteValue.half),
      ...sixteenths([R, L]),
      rest(NoteValue.eighth),
      rest(NoteValue.quarter),
    ], accepts: InstrumentClass.anyTom),
    voice(KitInstrument.floorTom1, [
      rest(NoteValue.whole),
      rest(NoteValue.half),
      rest(NoteValue.eighth),
      ...sixteenths([R, L]),
      rest(NoteValue.quarter),
    ], accepts: InstrumentClass.anyTom),
    voice(KitInstrument.rideBell, [
      rest(NoteValue.whole),
      rest(NoteValue.half),
      note(R, NoteValue.quarter),
      rest(NoteValue.quarter),
    ]),
    voice(KitInstrument.china, [
      rest(NoteValue.whole),
      rest(NoteValue.half),
      rest(NoteValue.eighth),
      note(R, NoteValue.eighth),
      rest(NoteValue.quarter),
    ]),
    voice(KitInstrument.crash1, [
      rest(NoteValue.whole),
      rest(NoteValue.half),
      rest(NoteValue.quarter),
      note(R, NoteValue.quarter, accent: true),
    ], accepts: InstrumentClass.anyCrash),
    voice(KitInstrument.splash, [
      rest(NoteValue.whole),
      rest(NoteValue.half),
      rest(NoteValue.quarter),
      rest(NoteValue.eighth),
      note(L, NoteValue.eighth),
    ]),
    voice(KitInstrument.kick, [
      foot(NoteValue.quarter),
      rest(NoteValue.eighth, dotted: true),
      foot(NoteValue.sixteenth),
      rest(NoteValue.half),
      ...[for (var i = 0; i < 4; i++) foot(NoteValue.quarter)],
    ]),
    voice(KitInstrument.hiHatPedal, [
      rest(NoteValue.quarter),
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
      foot(NoteValue.quarter),
      rest(NoteValue.whole),
    ]),
  ], repeat: false, title: 'Around');
  return Rudiment(
    id: 'kit_showcase',
    name: 'Kit showcase',
    description: '',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    sticking: pattern.first.beats,
    gridUnit: NoteGrid.eighth,
    voicing: ExerciseVoicing.kit,
    requiredSensor: SensorLevel.midi,
    limbs: {Limb.allFour},
    patternVoices: pattern,
    lines: [groove, fill],
  );
}

void main() {
  setUpAll(() async {
    final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
    final loader = FontLoader('Bravura')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    AppTypography.label;
    await GoogleFonts.pendingFonts();
  });

  group('kitStaffStep / kitHeadShape (Brief B.2 table)', () {
    test('every instrument has its line or space', () {
      expect(kitStaffStep(KitInstrument.hiHatPedal), -5);
      expect(kitStaffStep(KitInstrument.kick), -3);
      expect(kitStaffStep(KitInstrument.floorTom2), -2);
      expect(kitStaffStep(KitInstrument.floorTom1), -1);
      expect(kitStaffStep(KitInstrument.snare), 1);
      expect(kitStaffStep(KitInstrument.snareRim), 1);
      expect(kitStaffStep(KitInstrument.tom2), 2);
      expect(kitStaffStep(KitInstrument.tom1), 3);
      expect(kitStaffStep(KitInstrument.ride), 4);
      expect(kitStaffStep(KitInstrument.rideBell), 4);
      expect(kitStaffStep(KitInstrument.hiHatClosed), 5);
      expect(kitStaffStep(KitInstrument.hiHatOpen), 5);
      for (final c in [
        KitInstrument.crash1,
        KitInstrument.crash2,
        KitInstrument.china,
        KitInstrument.splash
      ]) {
        expect(kitStaffStep(c), 6, reason: c.name);
      }
      expect(kitStaffStep(KitInstrument.pad), 0);
    });
    test('head shapes', () {
      expect(kitHeadShape(KitInstrument.snare), KitHeadShape.normal);
      expect(kitHeadShape(KitInstrument.kick), KitHeadShape.normal);
      expect(kitHeadShape(KitInstrument.tom1), KitHeadShape.normal);
      for (final x in [
        KitInstrument.snareRim,
        KitInstrument.hiHatClosed,
        KitInstrument.hiHatOpen,
        KitInstrument.hiHatPedal,
        KitInstrument.ride,
        KitInstrument.crash1,
        KitInstrument.crash2
      ]) {
        expect(kitHeadShape(x), KitHeadShape.x, reason: x.name);
      }
      expect(kitHeadShape(KitInstrument.rideBell), KitHeadShape.diamond);
      expect(kitHeadShape(KitInstrument.china), KitHeadShape.circleX);
      expect(kitHeadShape(KitInstrument.splash), KitHeadShape.xSmall);
    });
  });

  group('kit sheet', () {
    final r = kitShowcase();
    Finder paints() => find.descendant(
        of: find.byType(SheetStaffWidget), matching: find.byType(CustomPaint));

    testWidgets('one CustomPaint per line at the kit pitch (+ count band)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(width: 360, child: SheetStaffWidget(rudiment: r)))));
      expect(tester.takeException(), isNull);
      expect(paints(), findsNWidgets(2));
      final h = [
        for (final e in paints().evaluate())
          (e.widget as CustomPaint).size.height
      ];
      const pitch = kitRowPitch + sheetCountBand;
      expect(h[0], pitch); // two bars, one row
      expect(h[1], pitch);
    });

    testWidgets('geometry of a kit sheet: kit pitch, kit layouts, row by tick',
        (tester) async {
      final g = computeSheetGeometry(r, 352, showCounts: true);
      expect(g.isKit, isTrue);
      expect(g.rowPitch, kitRowPitch + sheetCountBand);
      expect(g.kitLayouts.length, 2);
      expect(g.kitLayouts.every((k) => k != null), isTrue);
      expect(g.rowStart, [0, 1]);
      expect(g.rowOfTick(0, 0), 0);
      expect(g.rowOfTick(1, 100), 1);
      expect(computeSheetGeometry(r, 352, showCounts: false).rowPitch,
          kitRowPitch);
    });

    testWidgets('cursor by tick renders without throwing', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360,
                  child: SheetStaffWidget(
                      rudiment: r, activeLine: 1, activeTick: 24 * 6)))));
      expect(tester.takeException(), isNull);
    });

    testWidgets('golden: groove line with counts, showcase line', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(width: 360, child: SheetStaffWidget(rudiment: r)))));
      await expectLater(find.byType(SheetStaffWidget),
          matchesGoldenFile('goldens/kit_staff_sheet.png'));
    });

    testWidgets('golden: the PATTERN box draws the pattern voices',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(width: 360, child: NotationStaffWidget(rudiment: r)))));
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(NotationStaffWidget),
          matchesGoldenFile('goldens/kit_staff_pattern.png'));
    });
  });
}
```

In `test/shared/sheet_geometry_test.dart` einen Test ergänzen:

```dart
  test('a pad sheet has no kit layouts and keeps the pad pitch', () {
    final g = computeSheetGeometry(r, 360, showCounts: false);
    expect(g.isKit, isFalse);
    expect(g.kitLayouts, [null, null, null]);
    expect(g.rowPitch, sheetRowPitch);
    expect(g.rowOfTick(2, 0), 2);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/notation_kit_staff_test.dart test/shared/sheet_geometry_test.dart`
Expected: Kompilierfehler (`kitStaffStep`, `KitHeadShape`, `kitRowPitch`, `kitLayouts`, `activeTick` unbekannt).

- [ ] **Step 3: `sheet_geometry.dart`**

Import `kit_layout.dart`. Konstante nach `sheetRowPitchWithCounts`:

```dart
/// A kit row (Brief B.2): five lines with stems up (hands) and down (feet)
/// need more height than the pad row. One pitch for the whole sheet.
const double kitRowPitch = 132;
```

`SheetGeometry`:

```dart
class SheetGeometry {
  final List<StaffLayout> layouts;
  final double rowPitch;
  final List<int> rowStart;
  final int totalRows;

  /// Per line: the kit layout of a kit line, null for a pad line.
  final List<KitLineLayout?> kitLayouts;
  const SheetGeometry(this.layouts, this.rowPitch, this.rowStart, this.totalRows,
      {this.kitLayouts = const []});

  bool get isKit => kitLayouts.any((k) => k != null);

  /// Global row of note [index] in [line] (pad lines).
  int rowOf(int line, int index) =>
      rowStart[line] + layouts[line].placements[index].row;

  /// Global row of [tick] in [line] (kit lines); a pad line's first row.
  int rowOfTick(int line, int tick) {
    final kit = line < kitLayouts.length ? kitLayouts[line] : null;
    return rowStart[line] + (kit?.rowOfTick(tick) ?? 0);
  }
  // lineOfRow, height unverändert
}
```

`computeSheetGeometry`:

```dart
SheetGeometry computeSheetGeometry(Rudiment r, double maxWidth,
    {required bool showCounts}) {
  final sheet = r.sheet;
  final counts = showCounts && sheet.any((l) => l.counts);
  final kit = sheet.any((l) => l.isKit);
  final layouts = <StaffLayout>[];
  final kitLayouts = <KitLineLayout?>[];
  final starts = <int>[];
  var rows = 0;
  for (var i = 0; i < sheet.length; i++) {
    final l = sheet[i];
    starts.add(rows);
    final leftPad = leftPadFor(numbered: true);
    final rightPad = rightPadFor(repeat: l.repeat);
    final systemPad = systemPadFor(
        repeat: l.repeat,
        graces: l.voices.any((v) => leadsWithGraces(v.beats)),
        clef: i == 0);
    if (l.isKit) {
      final kl = computeKitLineLayout(
        voices: l.kitVoices,
        grid: r.gridUnit,
        beatsPerBar: r.beatsPerBar,
        maxWidth: maxWidth,
        leftPad: leftPad,
        rightPad: rightPad,
        systemPad: systemPad,
        barGap: sheetBarGap,
      );
      layouts.add(kl.hands);
      kitLayouts.add(kl);
      rows += kl.rowCount;
    } else {
      final layout = computeStaffLayout(
        beats: l.beats,
        grid: r.gridUnit,
        beatsPerBar: r.beatsPerBar,
        maxWidth: maxWidth,
        leftPad: leftPad,
        rightPad: rightPad,
        systemPad: systemPad,
        barGap: sheetBarGap,
      );
      layouts.add(layout);
      kitLayouts.add(null);
      rows += layout.rowCount;
    }
  }
  final base = kit ? kitRowPitch : sheetRowPitch;
  return SheetGeometry(layouts, counts ? base + sheetCountBand : base, starts, rows,
      kitLayouts: kitLayouts);
}
```

- [ ] **Step 4: `notation_staff_widget.dart` — Kit-Pfad**

1. Imports: `import '../../features/coaching/midi/kit_instrument.dart';` `import 'kit_layout.dart';` und nach den Imports `part 'kit_staff_painting.dart';`.
2. `_Smufl` ergänzen:

```dart
  static const noteheadXBlack = '\u{E0A9}';
  static const noteheadDiamondBlack = '\u{E0DB}';
  static const noteheadCircleX = '\u{E0B3}';
  static const flag8Down = '\u{E241}';
  static const flag16Down = '\u{E243}';
  static const flag32Down = '\u{E245}';
```

3. `_StaffPainter`: Felder `final List<Voice>? voices;` (Doc: `/// Voices of a kit line (Brief B.2); null = pad line drawn from [beats].`) und `final int? activeTick;` (`/// Cursor tick of a kit line; [activeIndex] is ignored there.`), Konstruktor `this.voices, this.activeTick,`. `bool get isKit => voices != null;`

   `_systemPad`: `graces: isKit ? voices!.any((v) => leadsWithGraces(v.beats)) : leadsWithGraces(beats)`.

   Layouts:

```dart
  late final KitLineLayout? _kit = !isKit
      ? null
      : computeKitLineLayout(
          voices: voices!,
          grid: grid,
          beatsPerBar: beatsPerBar,
          maxWidth: maxWidth,
          leftPad: _leftPad,
          rightPad: _rightPad,
          systemPad: _systemPad,
          barGap: sheetBarGap,
        );

  late final StaffLayout _layout = _kit?.hands ??
      computeStaffLayout(
        beats: beats, grid: grid, beatsPerBar: beatsPerBar, maxWidth: maxWidth,
        leftPad: _leftPad, rightPad: _rightPad, systemPad: _systemPad,
        barGap: sheetBarGap,
      );
```

   Die vertikalen `static const`-Maße `_staffBandH`, `_accentY`, `_stemTopY`, `_midY`, `_letterY`, `_countY`, `_titleY` werden Instanz-Getter (Pad-Werte unverändert):

```dart
  // Vertical positions within the staff band — pad row / kit row (B.2).
  double get _staffBandH => isKit ? kitRowPitch : sheetRowPitch;
  double get _accentY => isKit ? 6 : 8;
  double get _stemTopY => isKit ? 14 : 18;
  double get _midY => isKit ? 60 : 54;
  double get _letterY => isKit ? 112 : 90;
  double get _countY => isKit ? kitRowPitch : 104;
  double get _titleY => isKit ? 98 : 69;
  static const double _stemBottomY = 96; // feet stems of a kit row end here
```

4. In `_paintRow` den Cursor-Block (ab `// Cursor field:` bis vor `_paintBeamsAndNotes`) ersetzen:

```dart
    if (isKit) {
      final kit = _kit!;
      final tick = activeTick;
      if (tick != null && kit.rowOfTick(tick) == row) {
        _drawCursorField(canvas, kit.xOfTick(tick), y0);
      }
      _paintKitRow(canvas, row, y0, staffY);
      return;
    }

    // Cursor field: the active note's slot turns amber; ink stays black.
    if (activeIndex != null) {
      for (final p in rowPlacements) {
        if (p.index != activeIndex) continue;
        _drawCursorField(canvas, p.xCenter, y0);
        break;
      }
    }
```

   und den Helfer (der bisherige Rumpf des Cursor-Blocks) ergänzen:

```dart
  /// Amber field and line behind the active column; ink stays black.
  void _drawCursorField(Canvas canvas, double cx, double y0) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, y0 + _staffBandH / 2),
            width: _cursorW,
            height: _staffBandH - 16),
        const Radius.circular(8),
      ),
      Paint()..color = _cursorField,
    );
    final linePaint = Paint()
      ..color = _cursorLine
      ..strokeWidth = 3;
    canvas.drawLine(
        Offset(cx, y0 + 10), Offset(cx, y0 + _staffBandH - 10), linePaint);
  }
```

5. `shouldRepaint`: `|| old.voices != voices || old.activeTick != activeTick`.
6. `NotationStaffWidget.build`: `final kit = rudiment.patternVoices.isNotEmpty;` und am Painter `voices: kit ? rudiment.patternVoices : null, rowPitch: kit ? kitRowPitch : sheetRowPitch,`.
7. `SheetStaffWidget`: Feld `final int? activeTick;` (Konstruktor `this.activeTick,`), am Painter:

```dart
                    voices: sheet[i].isKit ? sheet[i].kitVoices : null,
                    activeTick: activeLine == i ? activeTick : null,
                    countLabels: showCounts && sheet[i].counts
                        ? countLabelsFor(
                            geo.kitLayouts.length > i && geo.kitLayouts[i] != null
                                ? geo.kitLayouts[i]!.handsTrack
                                : sheet[i].beats,
                            rudiment.gridUnit,
                            rudiment.beatsPerBar)
                        : null,
```

- [ ] **Step 5: `kit_staff_painting.dart` (part)**

```dart
part of 'notation_staff_widget.dart';

/// Staff step of an instrument's notehead (Brief B.2): half line-gaps above
/// the middle line. Lines are −4, −2, 0, 2, 4; spaces the odd steps; −5
/// sits under the first line, 5 above the fifth, 6 is the first ledger
/// line above the staff.
int kitStaffStep(KitInstrument i) => switch (i) {
      KitInstrument.hiHatPedal => -5,
      KitInstrument.kick => -3,
      KitInstrument.floorTom2 => -2,
      KitInstrument.floorTom1 => -1,
      KitInstrument.snare || KitInstrument.snareRim => 1,
      KitInstrument.tom2 => 2,
      KitInstrument.tom1 => 3,
      KitInstrument.ride || KitInstrument.rideBell => 4,
      KitInstrument.hiHatClosed || KitInstrument.hiHatOpen => 5,
      KitInstrument.crash1 ||
      KitInstrument.crash2 ||
      KitInstrument.china ||
      KitInstrument.splash =>
        6,
      KitInstrument.pad || KitInstrument.unknown => 0,
    };

/// Notehead shape per instrument (Brief B.2): drums normal, cymbals x,
/// ride bell a diamond, china a circled x, splash a small x.
enum KitHeadShape { normal, x, diamond, circleX, xSmall }

KitHeadShape kitHeadShape(KitInstrument i) => switch (i) {
      KitInstrument.snareRim ||
      KitInstrument.hiHatClosed ||
      KitInstrument.hiHatOpen ||
      KitInstrument.hiHatPedal ||
      KitInstrument.ride ||
      KitInstrument.crash1 ||
      KitInstrument.crash2 =>
        KitHeadShape.x,
      KitInstrument.rideBell => KitHeadShape.diamond,
      KitInstrument.china => KitHeadShape.circleX,
      KitInstrument.splash => KitHeadShape.xSmall,
      _ => KitHeadShape.normal,
    };

/// Kit rows: two layers on one staff — hands (stems up, beams above) and
/// feet (stems down, beams below); every column one stem per layer, heads
/// on their instrument's step. Beams, tuplet brackets and rests come from
/// the layer tracks (`KitLineLayout`), the heads from the columns.
extension _KitPainting on _StaffPainter {
  double _yOfStep(double staffY, int step) =>
      staffY - step * _StaffPainter._lineGap / 2;

  void _paintKitRow(Canvas canvas, int row, double y0, double staffY) {
    final kit = _kit!;
    final stemTopY = y0 + _stemTopY;
    final stemBottomY = y0 + _StaffPainter._stemBottomY;
    final handsBeamed =
        _paintLayerBeams(canvas, kit.hands, row, stemTopY, up: true);
    final feetBeamed =
        _paintLayerBeams(canvas, kit.feet, row, stemBottomY, up: false);
    _paintTuplets(canvas, kit.hands, row, y0 + _accentY);
    _paintTuplets(canvas, kit.feet, row, stemBottomY + 14);

    // Rests of the hands layer only — feet rests are left out, as drum
    // charts do.
    for (final p in kit.hands.placements) {
      if (p.row != row || !p.isRest) continue;
      _drawRest(canvas, Offset(p.xCenter, staffY), p.resolved.value,
          _dim(_StaffPainter._ghostColor));
    }

    for (final col in kit.columns) {
      if (kit.rowOfTick(col.tick) != row) continue;
      final x = kit.xOfTick(col.tick);
      final active = col.tick == activeTick;
      _paintLayerColumn(canvas, col.hands.toList(), x, y0, staffY,
          up: true,
          stemEndY: stemTopY,
          track: kit.handsTrack,
          layout: kit.hands,
          index: kit.handsIndexOfTick[col.tick],
          beamed: handsBeamed,
          active: active);
      _paintLayerColumn(canvas, col.feet.toList(), x, y0, staffY,
          up: false,
          stemEndY: stemBottomY,
          track: kit.feetTrack,
          layout: kit.feet,
          index: kit.feetIndexOfTick[col.tick],
          beamed: feetBeamed,
          active: active);
    }
  }

  /// Beam runs of one layer; returns the placement indices that are beamed.
  Set<int> _paintLayerBeams(
      Canvas canvas, StaffLayout layout, int row, double beamY,
      {required bool up}) {
    final beamed = <int>{};
    final dx = up ? _StaffPainter._headRx - 0.5 : -_StaffPainter._headRx + 0.5;
    for (final bg in layout.beams) {
      if (bg.row != row || bg.beamCount == 0) continue;
      final x0 = layout.placements[bg.startIndex].xCenter + dx;
      final x1 = layout.placements[bg.endIndex].xCenter + dx;
      final paint = Paint()
        ..color = _dim(_StaffPainter._inkColor)
        ..strokeWidth = 3.0;
      for (var b = 0; b < bg.beamCount; b++) {
        final y = up ? beamY + b * 5.0 : beamY - b * 5.0;
        canvas.drawLine(Offset(x0, y), Offset(x1, y), paint);
      }
      for (var idx = bg.startIndex; idx <= bg.endIndex; idx++) {
        beamed.add(idx);
      }
    }
    return beamed;
  }

  void _paintTuplets(Canvas canvas, StaffLayout layout, int row, double y) {
    for (final bg in layout.beams) {
      if (bg.row != row || bg.tuplet == Tuplet.none) continue;
      final x0 = layout.placements[bg.startIndex].xCenter;
      final x1 = layout.placements[bg.endIndex].xCenter;
      final label = bg.tuplet == Tuplet.sextuplet ? '6' : '3';
      _drawTupletBracket(canvas, x0, x1, y, label, _dim(_StaffPainter._inkColor));
    }
  }

  /// One layer at one column: heads on their steps, one stem from the
  /// farthest head to the layer's stem end, flag when not beamed, accent,
  /// ghost parentheses, dot, letter and count (hands only).
  void _paintLayerColumn(Canvas canvas, List<KitNote> notes, double x,
      double y0, double staffY,
      {required bool up,
      required double stemEndY,
      required List<StrokeBeat> track,
      required StaffLayout layout,
      required int? index,
      required Set<int> beamed,
      required bool active}) {
    if (notes.isEmpty || index == null) return;
    final drawn = track[index];
    final resolved = layout.placements[index].resolved;
    var topY = double.infinity;
    var bottomY = double.negativeInfinity;
    final anyAccent = notes.any((n) => n.beat.isAccent);
    for (final n in notes) {
      final step = kitStaffStep(n.voice.instrument);
      final y = _yOfStep(staffY, step);
      if (y < topY) topY = y;
      if (y > bottomY) bottomY = y;
      final color = _dim(n.beat.isAccent
          ? _StaffPainter._accentColor
          : n.beat.isGhost
              ? _StaffPainter._ghostColor
              : _StaffPainter._inkColor);
      if (step >= 6) _drawLedger(canvas, x, _yOfStep(staffY, 6));
      if (n.beat.graces.isNotEmpty) {
        _drawGraces(canvas, n.beat.graces, x, y, stemEndY,
            _dim(_StaffPainter._ghostColor));
      }
      _drawKitHead(canvas, Offset(x, y), kitHeadShape(n.voice.instrument), color,
          ghost: n.beat.isGhost, active: active);
      if (n.voice.instrument == KitInstrument.hiHatOpen) {
        _drawText(canvas, 'o', Offset(x, y - 10), color, 9, bold: true);
      }
      if (n.beat.isGhost) {
        final ink = _dim(_StaffPainter._ghostColor);
        _drawText(canvas, '(', Offset(x - _StaffPainter._headRx - 4, y), ink, 14);
        _drawText(canvas, ')', Offset(x + _StaffPainter._headRx + 4, y), ink, 14);
      }
      if (resolved.dotted) _drawDot(canvas, Offset(x, y), color);
    }

    final stemColor =
        _dim(anyAccent ? _StaffPainter._accentColor : _StaffPainter._inkColor);
    if (resolved.value != NoteValue.whole) {
      final stemX =
          up ? x + _StaffPainter._headRx - 0.6 : x - _StaffPainter._headRx + 0.6;
      canvas.drawLine(
          Offset(stemX, up ? bottomY - 1 : topY + 1),
          Offset(stemX, stemEndY),
          Paint()
            ..color = stemColor
            ..strokeWidth = 1.6);
      final bc = beamCountFor(resolved.value);
      if (bc > 0 && !beamed.contains(index)) {
        if (up) {
          _drawFlags(canvas, stemX, stemEndY, stemColor, bc);
        } else {
          _drawFlagsDown(canvas, stemX, stemEndY, stemColor, bc);
        }
      }
    }
    if (anyAccent) {
      _drawAccent(canvas, Offset(x, up ? y0 + _accentY : stemEndY + 8),
          _dim(_StaffPainter._accentColor));
    }
    if (!up) return;
    final letter = switch (drawn.hand) {
      Hand.right => 'R',
      Hand.left => 'L',
      null => null,
    };
    if (showSticking && letter != null) {
      _drawText(canvas, letter, Offset(x, y0 + _letterY),
          _dim(_StaffPainter._letterColor), 12,
          bold: true);
    }
    final count = countLabels == null || index >= countLabels!.length
        ? null
        : countLabels![index];
    if (count != null) {
      _drawText(canvas, count, Offset(x, y0 + _countY),
          _dim(_StaffPainter._letterColor), 10);
    }
  }

  void _drawKitHead(Canvas canvas, Offset c, KitHeadShape shape, Color color,
      {required bool ghost, required bool active}) {
    switch (shape) {
      case KitHeadShape.normal:
        _drawHead(canvas, c, color,
            ghost: ghost, active: active, value: NoteValue.quarter);
        return;
      case KitHeadShape.x:
        _drawGlyph(canvas, _Smufl.noteheadXBlack, c, color);
      case KitHeadShape.xSmall:
        _drawGlyph(canvas, _Smufl.noteheadXBlack, c, color, emScale: 3);
      case KitHeadShape.diamond:
        _drawGlyph(canvas, _Smufl.noteheadDiamondBlack, c, color);
      case KitHeadShape.circleX:
        _drawGlyph(canvas, _Smufl.noteheadCircleX, c, color);
    }
    if (active) {
      canvas.drawOval(
          Rect.fromCenter(
                  center: c,
                  width: _StaffPainter._headRx * 2,
                  height: _StaffPainter._headRy * 2)
              .inflate(2.5),
          Paint()
            ..color = _StaffPainter._cursorLine
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  /// Short ledger line through a head above the staff (crash, china, splash).
  void _drawLedger(Canvas canvas, double x, double y) {
    canvas.drawLine(
        Offset(x - 9, y),
        Offset(x + 9, y),
        Paint()
          ..color = _dim(_StaffPainter._staffColor)
          ..strokeWidth = 1.0);
  }

  void _drawFlagsDown(Canvas canvas, double stemX, double stemBottomY,
      Color color, int beamCount) {
    final glyph = switch (beamCount) {
      1 => _Smufl.flag8Down,
      2 => _Smufl.flag16Down,
      _ => _Smufl.flag32Down,
    };
    // The down flag hangs up from the stem's bottom end; nudge until it
    // sits on the stem end in the golden (start at 0).
    _drawGlyph(canvas, glyph, Offset(stemX + 3, stemBottomY), color,
        dyStaffSpaces: 0);
  }
}
```

`_StaffPainter._lineGap`, `_headRx`, `_headRy`, Farben und `_stemBottomY` sind `static const` der Klasse — aus der Extension als `_StaffPainter._x` erreichbar (gleiche Bibliothek). Die Pad-Helfer `_drawHead`, `_drawGlyph`, `_drawRest`, `_drawDot`, `_drawGraces`, `_drawAccent`, `_drawFlags`, `_drawTupletBracket`, `_drawText`, `_dim` werden unverändert wiederverwendet.

- [ ] **Step 6: Goldens erzeugen und ansehen**

Run: `flutter test --update-goldens test/notation_kit_staff_test.dart && flutter test test/notation_kit_staff_test.dart test/notation_staff_test.dart test/shared`
Expected: grün; `test/goldens/sheet_staff_three_lines.png` unverändert (`git status` zeigt es nicht).

Dann `test/goldens/kit_staff_sheet.png` und `kit_staff_pattern.png` mit dem Read-Werkzeug ansehen und prüfen (sonst Maße in Step 4/5 nachziehen und Goldens neu erzeugen):
- Zeile 1: Hi-Hat-x über der fünften Linie, Snare im dritten Zwischenraum, Kick im ersten Zwischenraum; auf 2 und 4 teilen sich x und Snare-Kopf einen Hals; Achtelbalken oben durchgehend je Zählzeit; Kick-Viertel mit Hals nach unten, keine Fußpausen; Zählsilben „1 + 2 + 3 + 4 +" unter den Buchstaben; „R" nur, wo die Hi-Hat allein spielt.
- Zeile 2: Takt 1: „o" über dem offenen Hat auf „4 +", Cross-Stick-x im Snare-Zwischenraum auf 2, Ghost in Klammern, Flam-Vorschlag vor der 4, Pedal-x unter der ersten Linie auf 2 und 4, Kick auf 1 und auf „a von 2" (Sechzehntel mit Fahne nach unten); Takt 2: Sechzehntel-Lauf Snare → Tom 1 (vierter Zwischenraum) → Tom 2 (vierte Linie) → Stand-Tom (zweiter Zwischenraum) mit Balken, Raute (Glocke) auf 3, Kreis-x (China) auf „3 +", Crash-x mit Hilfslinie auf 4, kleines Splash-x auf „4 +"; Titel „Around" links unter dem Fußhals-Bereich.
- Pattern-Kasten: eine Reihe, ohne Nummernkasten, Schlusstrich.

- [ ] **Step 7: Commit**

```bash
git add lib/shared/widgets/sheet_geometry.dart lib/shared/widgets/notation_staff_widget.dart lib/shared/widgets/kit_staff_painting.dart test/notation_kit_staff_test.dart test/shared/sheet_geometry_test.dart test/goldens/kit_staff_sheet.png test/goldens/kit_staff_pattern.png
git commit -m "feat(notation): Standard-Schlagzeugnotation — Köpfe je Instrument, Hände oben, Füße unten, Hilfslinie, offene Hat, Goldens"
```

---

### Task 4: Wiedergabe und Einheit mehrstimmig — `buildVoicesPlayback`, `SheetPlan.voices`, Band-Stummschaltung

**Files:**
- Modify: `lib/features/lessons/models/pattern_playback.dart` (`buildVoicesPlayback`)
- Modify: `lib/features/lessons/models/sheet_plan.dart` (`voices`, `lineTickStarts`, `totalTicks`, `isKit`, `locateTick`, `playsKick`, `playsHihat`)
- Modify: `lib/features/metronome/loop_voices.dart` (`backingKick`, `backingHihat`), `metronome_engine.dart:573-585` (`setBacking`), `metronome_provider.dart:187-202` (`setBacking`, `setBackingLevel`)
- Test: `test/lessons/pattern_playback_test.dart`, `test/lessons/sheet_plan_test.dart`, `test/metronome/loop_voices_test.dart`, `test/metronome/backing_provider_test.dart` (je ein Block dazu)

**Interfaces:**
- Consumes: `Voice`, `ExerciseLine.voices`, `KitInstrument` (Task 1); `buildPatternPlayback`, `PatternPlayback`.
- Produces:
  - `PatternPlayback buildVoicesPlayback(List<Voice> voices, NoteGrid grid, {int ticksPerQuarter = 24, double Function(StrokeBeat) volumeOf = defaultBeatVolume})` — Pro-Tick-Maximum, `onsetTicks` = sortierte Vereinigung der **klingenden** Einsätze (Pausen fehlen), `noteIndexAtTick` = Spaltenindex; wirft `ArgumentError` bei ungleicher Länge.
  - `SheetPlan`: `final List<Voice> voices`, `final List<int> lineTickStarts`, `final int totalTicks`, `bool get isKit`, `({int line, int tick}) locateTick(int tick)`, `bool get playsKick`, `bool get playsHihat`.
  - `buildLoopPlan({…, bool backingKick = true, bool backingHihat = true})`; `MetronomeEngine.setBacking(BackingStyle? style, {required double level, required int beatsPerBar, bool backingKick = true, bool backingHihat = true})`; `MetronomeNotifier.setBacking(String? styleId, {required int beatsPerBar, bool backingKick = true, bool backingHihat = true})` (Flags bleiben für `setBackingLevel` gemerkt).

- [ ] **Step 1: Failing tests**

`test/lessons/pattern_playback_test.dart`, neue Gruppe (Import `kit_instrument.dart` und `etude_dsl.dart` ergänzen):

```dart
  group('buildVoicesPlayback — kit unit (Brief B.1)', () {
    final hh = voice(KitInstrument.hiHatClosed, eighths([R, R, R, R, R, R, R, R]));
    final sn = voice(KitInstrument.snare, [
      rest(NoteValue.quarter),
      note(L, NoteValue.quarter, accent: true),
      rest(NoteValue.quarter),
      note(L, NoteValue.quarter, ghost: true),
    ]);
    final bd = voice(KitInstrument.kick, [
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
    ]);
    final pp = buildVoicesPlayback([hh, sn, bd], NoteGrid.eighth);

    test('one cycle of the common length, loudest voice per tick', () {
      expect(pp.totalTicks, 96);
      expect(pp.tickVolumes.length, 96);
      expect(pp.tickVolumes[0], 0.85); // hi-hat + kick, both plain
      expect(pp.tickVolumes[24], 2.0); // accent on the snare wins
      expect(pp.tickVolumes[72], 0.85); // ghost snare under the hi-hat
      expect(pp.tickVolumes[6], 0.0);
    });

    test('onsets are the union of sounding onsets — rests are no columns', () {
      expect(pp.onsetTicks, [0, 12, 24, 36, 48, 60, 72, 84]);
      expect(pp.isOnsetTick(24), isTrue);
      expect(pp.isOnsetTick(6), isFalse);
      expect(pp.noteIndexAtTick(30), 2);
    });

    test('a feet-only column is a column too', () {
      final sparseHh = voice(KitInstrument.hiHatClosed, [
        note(R, NoteValue.quarter),
        rest(NoteValue.quarter),
        rest(NoteValue.quarter),
        rest(NoteValue.quarter),
      ]);
      final p = buildVoicesPlayback([sparseHh, bd], NoteGrid.eighth);
      expect(p.onsetTicks, [0, 48]);
      expect(p.tickVolumes[48], 0.85);
    });

    test('voices of different length throw', () {
      final short = voice(KitInstrument.tom1, [note(R, NoteValue.half)]);
      expect(() => buildVoicesPlayback([hh, short], NoteGrid.eighth),
          throwsArgumentError);
      expect(() => buildVoicesPlayback(const [], NoteGrid.eighth),
          throwsArgumentError);
    });
  });
```

`test/lessons/sheet_plan_test.dart`, neue Gruppe (Imports `kit_instrument.dart` ergänzen):

```dart
  group('kit units (Brief B.1)', () {
    List<StrokeBeat> hh8() => eighths([R, R, R, R, R, R, R, R]);
    List<StrokeBeat> q4(StrokeBeat Function() b) =>
        [b(), rest(NoteValue.quarter), b(), rest(NoteValue.quarter)];
    final groove = kitLine([
      voice(KitInstrument.hiHatClosed, hh8()),
      voice(KitInstrument.snare, q4(() => note(L, NoteValue.quarter))),
      voice(KitInstrument.kick, q4(() => foot(NoteValue.quarter))),
    ]);
    // Line 2 adds a tom and drops the kick.
    final fill = kitLine([
      voice(KitInstrument.hiHatClosed, hh8()),
      voice(KitInstrument.snare, q4(() => note(L, NoteValue.quarter))),
      voice(KitInstrument.tom1, q4(() => note(R, NoteValue.quarter)),
          accepts: InstrumentClass.anyTom),
    ], repeat: false);
    final kit = Rudiment(
        id: 'k',
        name: 'K',
        description: '',
        minBpm: 60,
        targetBpm: 100,
        difficulty: Difficulty.beginner,
        sticking: hh8(),
        voicing: ExerciseVoicing.kit,
        lines: [groove, fill]);

    test('a pad plan is one pad voice and not a kit', () {
      final p = SheetPlan.line(r, 0);
      expect(p.isKit, isFalse);
      expect(p.voices.single.instrument, KitInstrument.pad);
      expect(p.voices.single.beats, same(l1.beats));
      expect(p.totalTicks, 96);
      expect(p.lineTickStarts, [0]);
      expect(p.playsKick, isFalse);
      expect(p.playsHihat, isFalse);
    });

    test('a kit line plan carries the voices, ticks and band flags', () {
      final p = SheetPlan.line(kit, 0);
      expect(p.isKit, isTrue);
      expect(p.beats, same(groove.beats));
      expect(p.voices.map((v) => v.instrument), [
        KitInstrument.hiHatClosed,
        KitInstrument.snare,
        KitInstrument.kick,
      ]);
      expect(p.totalTicks, 96);
      expect(p.playsKick, isTrue);
      expect(p.playsHihat, isTrue);
      expect(SheetPlan.line(kit, 1).playsKick, isFalse);
    });

    test('whole sheet: one voice per instrument, missing voices filled with '
        'rests, accepts kept', () {
      final p = SheetPlan.wholeSheet(kit);
      expect(p.isKit, isTrue);
      expect(p.totalTicks, 192);
      expect(p.lineTickStarts, [0, 96]);
      expect(p.voices.map((v) => v.instrument), [
        KitInstrument.hiHatClosed,
        KitInstrument.snare,
        KitInstrument.kick,
        KitInstrument.tom1,
      ]);
      final kick = p.voices[2];
      expect(kick.beats.length, 4 + 4); // its line + four quarter rests
      expect(kick.beats.sublist(4).every((b) => b.isRest), isTrue);
      final tom = p.voices[3];
      expect(tom.accepts, InstrumentClass.anyTom);
      expect(tom.beats.take(4).every((b) => b.isRest), isTrue);
      expect(tom.beats.sublist(4), same(fill.kitVoices[2].beats) ,
          skip: 'identity is not required');
      expect(tom.beats.length, 8);
      expect(p.playsKick, isTrue);
    });

    test('locateTick maps a unit tick to line and tick in line', () {
      final p = SheetPlan.wholeSheet(kit);
      expect(p.locateTick(0), (line: 0, tick: 0));
      expect(p.locateTick(95), (line: 0, tick: 95));
      expect(p.locateTick(96), (line: 1, tick: 0));
      expect(p.locateTick(150), (line: 1, tick: 54));
      expect(SheetPlan.line(kit, 1).locateTick(30), (line: 1, tick: 30));
    });
  });
```

(Die `skip`-Zeile weglassen — sie steht hier nur, um zu sagen: Identität der Listen ist nicht gefordert, nur Inhalt. Also schlicht `expect(tom.beats.length, 8);`.)

`test/metronome/loop_voices_test.dart`, Test dazu:

```dart
  test('backing voices the player covers are muted one by one (Brief B.4)',
      () {
    final rock = backingStyleById('rock8');
    final both = plan(backing: rock, pattern: List.filled(96, 0.85));
    expect(both.voices.length, 3); // pattern, kick, hi-hat
    final noKick = buildLoopPlan(
      patternVolumes: List.filled(96, 0.85),
      patternLoud: loud,
      patternSoft: soft,
      factor: 24,
      backing: rock,
      kickSound: kick,
      hihatLoud: hh,
      hihatSoft: hh,
      backingKick: false,
    );
    expect(noKick.voices.length, 2);
    expect(noKick.voices.last.loudSamples, same(hh));
    final none = buildLoopPlan(
      patternVolumes: List.filled(96, 0.85),
      patternLoud: loud,
      patternSoft: soft,
      factor: 24,
      backing: rock,
      kickSound: kick,
      hihatLoud: hh,
      hihatSoft: hh,
      backingKick: false,
      backingHihat: false,
    );
    expect(none.voices.length, 1);
    expect(none.cycleTicks, 96);
  });
```

`test/metronome/backing_provider_test.dart`, Test dazu:

```dart
  test('setBacking accepts mute flags without touching the state', () {
    final n = container.read(metronomeNotifierProvider.notifier);
    n.setBacking('rock8', beatsPerBar: 4, backingKick: false, backingHihat: false);
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    n.setBackingLevel(0.5);
    expect(container.read(metronomeNotifierProvider).backingLevel, 0.5);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/lessons/pattern_playback_test.dart test/lessons/sheet_plan_test.dart test/metronome/loop_voices_test.dart test/metronome/backing_provider_test.dart`
Expected: Kompilierfehler (`buildVoicesPlayback`, `voices`, `locateTick`, `backingKick` unbekannt).

- [ ] **Step 3: Implementation**

`pattern_playback.dart` — am Ende:

```dart
/// A kit unit (Brief B.1): every voice on the same tick grid, mixed — a
/// tick is as loud as its loudest voice (grace ticks included); the onset
/// ticks are the union of the voices' *sounding* onsets, so the cursor
/// steps per column, not per note. All voices must have the same length.
PatternPlayback buildVoicesPlayback(
  List<Voice> voices,
  NoteGrid grid, {
  int ticksPerQuarter = 24,
  double Function(StrokeBeat) volumeOf = defaultBeatVolume,
}) {
  if (voices.isEmpty) throw ArgumentError('kit unit without voices');
  final parts = [
    for (final v in voices)
      buildPatternPlayback(v.beats, grid,
          ticksPerQuarter: ticksPerQuarter, volumeOf: volumeOf),
  ];
  final total = parts.first.totalTicks;
  final lengths = [for (final p in parts) p.totalTicks];
  if (lengths.any((l) => l != total)) {
    throw ArgumentError('voices differ in length: $lengths ticks');
  }
  final vols = List<double>.filled(total, 0.0);
  final onsets = <int>{};
  for (final p in parts) {
    for (var t = 0; t < total; t++) {
      if (p.tickVolumes[t] > vols[t]) vols[t] = p.tickVolumes[t];
    }
    for (final t in p.onsetTicks) {
      if (p.tickVolumes[t] > 0) onsets.add(t);
    }
  }
  return PatternPlayback(
    ticksPerQuarter: ticksPerQuarter,
    totalTicks: total,
    tickVolumes: vols,
    onsetTicks: onsets.toList()..sort(),
  );
}
```

`sheet_plan.dart` — Import `../../coaching/midi/kit_instrument.dart`; Klasse:

```dart
class SheetPlan {
  final List<StrokeBeat> beats;
  final List<int> lineStarts;
  final List<int> lines;
  final bool wholeSheet;

  /// The unit's voices (Brief B.1): one per instrument across the covered
  /// lines, a voice missing in a line filled with that line's length of
  /// rests; a pad unit is one `pad` voice carrying [beats].
  final List<Voice> voices;

  /// Tick at which each covered line starts (parallel to [lines]).
  final List<int> lineTickStarts;
  final int totalTicks;

  const SheetPlan._({
    required this.beats,
    required this.lineStarts,
    required this.lines,
    required this.wholeSheet,
    required this.voices,
    required this.lineTickStarts,
    required this.totalTicks,
  });

  factory SheetPlan.line(Rudiment r, int lineIndex) {
    final sheet = r.sheet;
    final i = lineIndex.clamp(0, sheet.length - 1);
    final l = sheet[i];
    return SheetPlan._(
      beats: l.beats,
      lineStarts: const [0],
      lines: [i],
      wholeSheet: false,
      voices: l.voices,
      lineTickStarts: const [0],
      totalTicks: _ticks(l.beats, r.gridUnit),
    );
  }

  factory SheetPlan.wholeSheet(Rudiment r) {
    final sheet = r.sheet;
    final beats = <StrokeBeat>[];
    final starts = <int>[];
    final tickStarts = <int>[];
    var ticks = 0;
    for (final l in sheet) {
      starts.add(beats.length);
      tickStarts.add(ticks);
      beats.addAll(l.beats);
      ticks += _ticks(l.beats, r.gridUnit);
    }
    // Instruments in order of first appearance; accepts from the first
    // line that carries the voice.
    final order = <KitInstrument>[];
    final accepts = <KitInstrument, InstrumentClass?>{};
    for (final l in sheet) {
      for (final v in l.voices) {
        if (!order.contains(v.instrument)) {
          order.add(v.instrument);
          accepts[v.instrument] = v.accepts;
        }
      }
    }
    final voices = <Voice>[];
    for (final inst in order) {
      final all = <StrokeBeat>[];
      for (final l in sheet) {
        Voice? own;
        for (final v in l.voices) {
          if (v.instrument == inst) {
            own = v;
            break;
          }
        }
        all.addAll(own?.beats ?? _rests(_ticks(l.beats, r.gridUnit)));
      }
      voices.add(Voice(inst, all, accepts: accepts[inst]));
    }
    return SheetPlan._(
      beats: beats,
      lineStarts: starts,
      lines: [for (var i = 0; i < sheet.length; i++) i],
      wholeSheet: true,
      voices: voices,
      lineTickStarts: tickStarts,
      totalTicks: ticks,
    );
  }

  int get lineIndex => lines.first;

  /// A kit unit: anything but the single pad voice.
  bool get isKit =>
      voices.length != 1 || voices.first.instrument != KitInstrument.pad;

  /// Band voices the player covers (Brief B.4): the band keeps quiet there.
  bool get playsKick => voices.any((v) => v.instrument == KitInstrument.kick);
  bool get playsHihat => voices.any((v) => const {
        KitInstrument.hiHatClosed,
        KitInstrument.hiHatOpen,
        KitInstrument.hiHatPedal,
      }.contains(v.instrument));

  ({int line, int index}) locate(int noteIndex) { /* unverändert */ }

  /// Sheet line and tick within it for a tick of the unit.
  ({int line, int tick}) locateTick(int tick) {
    var k = 0;
    while (k + 1 < lineTickStarts.length && lineTickStarts[k + 1] <= tick) {
      k++;
    }
    return (line: lines[k], tick: tick - lineTickStarts[k]);
  }
}

int _ticks(List<StrokeBeat> beats, NoteGrid grid) {
  var t = 0;
  for (final b in beats) {
    t += (resolveNote(b, grid).quarters * 24).round();
  }
  return t;
}

/// Quarter rests covering [ticks] (lines are whole bars, so a multiple of 24).
List<StrokeBeat> _rests(int ticks) {
  if (ticks % 24 != 0) throw ArgumentError('$ticks ticks is not whole beats');
  return [
    for (var t = 0; t < ticks; t += 24)
      const StrokeBeat.rest(value: NoteValue.quarter),
  ];
}
```

`loop_voices.dart` — Parameter `bool backingKick = true, bool backingHihat = true,` nach `hihatSoft`; im `if (useBacking)`-Block: `if (backingKick) voices.add(LoopVoice(… kick …));` und `if (backingHihat) voices.add(LoopVoice(… hihat …));`; Doc-Zeile: `/// - [backingKick] / [backingHihat]: false mutes that band voice (Brief B.4: the band keeps quiet in the voices the player plays).`

`metronome_engine.dart` — Felder `bool _backingKick = true; bool _backingHihat = true;` neben `_backingLevel`; `setBacking(BackingStyle? style, {required double level, required int beatsPerBar, bool backingKick = true, bool backingHihat = true})`, Early-Return erweitert um `_backingKick == backingKick && _backingHihat == backingHihat`, Zuweisung beider Felder; im ersten `buildLoopPlan(...)`-Aufruf `backingKick: _backingKick, backingHihat: _backingHihat,` ergänzen.

`metronome_provider.dart` — Felder `bool _backingKick = true; bool _backingHihat = true;`; `setBacking(String? styleId, {required int beatsPerBar, bool backingKick = true, bool backingHihat = true})` speichert beide und reicht sie an `_engine?.setBacking(..., backingKick: backingKick, backingHihat: backingHihat)`; `setBackingLevel` reicht `_backingKick`/`_backingHihat` mit.

- [ ] **Step 4: Run tests**

Run: `flutter analyze && flutter test test/lessons test/metronome test/features/practice`
Expected: grün (der Übungs-Screen ruft `setBacking` noch ohne Flags — Vorgabe `true`).

- [ ] **Step 5: Commit**

```bash
git add lib/features/lessons/models/pattern_playback.dart lib/features/lessons/models/sheet_plan.dart lib/features/metronome/loop_voices.dart lib/features/metronome/metronome_engine.dart lib/features/metronome/metronome_provider.dart test/lessons/pattern_playback_test.dart test/lessons/sheet_plan_test.dart test/metronome/loop_voices_test.dart test/metronome/backing_provider_test.dart
git commit -m "feat(playback): Stimmen gemischt — Spalten-Cursor, SheetPlan mit Stimmen und Tick-Ortung, Band schweigt in gespielten Stimmen"
```

---

### Task 5: Übungs-Screen, Blattfenster, Bibliothek — Set-Übungen spielbar

**Files:**
- Modify: `lib/features/practice/widgets/sheet_window.dart` (`activeTick`)
- Modify: `lib/features/practice/practice_session_screen.dart` (`_buildUnit` 266-272, `_openSourceOrThrow` 466-468, `_applyExtras` 643-652, Cursor 1107-1114, `SheetWindow` 1226-1234, `_ModeChip` 1190-1200 + 1596-1625)
- Modify: `lib/features/lessons/lessons_screen.dart:249-256` (`KIT`-Badge)
- Test: `test/features/practice/sheet_window_test.dart`, `test/features/practice/practice_session_screen_test.dart` (je ein Block dazu), Fixture `test/helpers/kit_fixtures.dart` (Task 3)

**Interfaces:**
- Consumes: `buildVoicesPlayback`, `SheetPlan.isKit/voices/locateTick/playsKick/playsHihat` (Task 4); `SheetStaffWidget.activeTick`, `SheetGeometry.rowOfTick/kitLayouts` (Task 3); `Rudiment.isKit` (Task 1); `MetronomeNotifier.setBacking(backingKick:, backingHihat:)` (Task 4).
- Produces: `SheetWindow({…, int? activeTick})`; `_ModeChip({…, required bool kit})` (privat); Übungs-Screen spielt Set-Übungen mit Spalten-Cursor, stummer Band in gespielten Stimmen und **ohne** Schlagquelle.

- [ ] **Step 1: Failing tests**

`test/features/practice/sheet_window_test.dart`, Test dazu (Import `../../helpers/kit_fixtures.dart`):

```dart
  testWidgets('a kit sheet window follows the tick: line 2, tick 0 is the '
      'row after line 1', (tester) async {
    final kit = kitShowcase(); // line 1: 2 bars = 1 row; line 2: 2 bars = 1 row
    await pump(tester, SheetWindow(rudiment: kit, activeLine: 0, activeTick: 0));
    final top = offsetOf(tester);
    await pump(tester,
        SheetWindow(rudiment: kit, activeLine: 1, activeTick: 24));
    await tester.pumpAndSettle();
    expect(top - offsetOf(tester), kitRowPitch + sheetCountBand);
    expect(tester.takeException(), isNull);
  });
```

`test/features/practice/practice_session_screen_test.dart` — `_pumpScreen` bekommt `List<Override> extraOverrides = const []` und hängt sie an die Override-Liste; ein Notifier, der die Band-Flags mitschreibt:

```dart
/// Idle metronome that records the last backing call's mute flags.
class _BackingFlagsMetronomeNotifier extends MetronomeNotifier {
  ({bool kick, bool hihat})? last;
  @override
  MetronomeState build() => const MetronomeState();
  @override
  void setBacking(String? styleId,
      {required int beatsPerBar,
      bool backingKick = true,
      bool backingHihat = true}) {
    last = (kick: backingKick, hihat: backingHihat);
    super.setBacking(styleId,
        beatsPerBar: beatsPerBar,
        backingKick: backingKick,
        backingHihat: backingHihat);
  }
}
```

und die Tests (Imports `lessons_provider.dart`, `../../helpers/kit_fixtures.dart`):

```dart
  group('kit exercises (Etappe 2, Phase B.1)', () {
    List<Override> kitCatalog() => [
          rudimentsProvider
              .overrideWithValue([...rudimentsSeedData, kitShowcase()]),
        ];

    testWidgets('loads the mixed unit: one cycle of every voice', (tester) async {
      final rec = _RecordingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: 'kit_showcase'),
          metronome: () => rec,
          extraOverrides: kitCatalog());
      expect(rec.volumes.last, 2 * 96); // line 1: two bars
      expect(find.byType(SheetWindow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mutes the band voices the player covers', (tester) async {
      final rec = _BackingFlagsMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: 'kit_showcase'),
          metronome: () => rec,
          extraOverrides: kitCatalog());
      await tester.pump();
      expect(rec.last, (kick: false, hihat: false));
    });

    testWidgets('opens no stroke source even with a MIDI module at hand',
        (tester) async {
      SharedPreferences.setMockInitialValues({'measurement_source': 'midi'});
      await SettingsService.init();
      final port = FakeMidiPort();
      final ports = FakeMidiPorts(port: port);
      await _pumpScreen(tester,
          screen: PracticeSessionScreen(
              rudimentId: 'kit_showcase', isFromRoutine: false, ports: ports),
          extraOverrides: kitCatalog());
      await tester.pump();
      expect(ports.opened, 0);
      expect(find.text('NOT MEASURABLE'), findsOneWidget);
      expect(find.textContaining('MIDI ·'), findsNothing);
    });

    testWidgets('the mode chip explains why: full-kit measurement is not '
        'available yet', (tester) async {
      await _pumpScreen(tester,
          screen: _screen(id: 'kit_showcase'), extraOverrides: kitCatalog());
      await tester.pump();
      expect(find.byTooltip('Full-kit measurement is not available yet'),
          findsOneWidget);
    });
  });
```

Vorher prüfen: wie die bestehenden Tests `SettingsService` initialisieren und das Messquellen-Setting setzen (`grep -n "setMockInitialValues\|SettingsService.init\|measurement_source" test/features/practice/practice_session_screen_test.dart`), und den Schlüssel-Namen in `lib/data/local/settings_service.dart` (`grep -n "measurement_source\|measurementSource" lib/data/local/settings_service.dart`); Zeilen entsprechend angleichen. `FakeMidiPorts.opened` zählt `open`-Aufrufe (`test/helpers/midi_fakes.dart:43`).

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/practice/sheet_window_test.dart test/features/practice/practice_session_screen_test.dart`
Expected: Kompilierfehler (`activeTick`, `extraOverrides`, `backingKick` im Override); nach Stubs: `opened` 1 statt 0, Tooltip fehlt.

- [ ] **Step 3: `sheet_window.dart`**

Feld `final int? activeTick;` (`/// Cursor tick within [activeLine] for kit lines; [activeIndex] is ignored there.`), Konstruktor `this.activeTick,`. `_rowFor`:

```dart
  int _rowFor(SheetGeometry geo) {
    final line = widget.activeLine.clamp(0, geo.layouts.length - 1);
    if (line < geo.kitLayouts.length && geo.kitLayouts[line] != null) {
      return geo.rowOfTick(line, widget.activeTick ?? 0);
    }
    final notes = geo.layouts[line].placements.length;
    if (notes == 0) return geo.rowStart[line];
    final index = (widget.activeIndex ?? 0).clamp(0, notes - 1);
    return geo.rowOf(line, index);
  }
```

Am ersten `SheetStaffWidget(...)` in `build` (`sheet`) `activeTick: widget.activeTick,` ergänzen (das Vorschau-Blatt bleibt ohne Cursor).

- [ ] **Step 4: `practice_session_screen.dart`**

1. `_buildUnit`:

```dart
  void _buildUnit(Rudiment rudiment) {
    _plan = _sheetMode
        ? SheetPlan.wholeSheet(rudiment)
        : SheetPlan.line(rudiment, _lineIndex);
    _unit = rudiment.withSticking(_plan.beats);
    // A kit unit mixes its voices; the cursor then steps per column.
    _playback = _plan.isKit
        ? buildVoicesPlayback(_plan.voices, rudiment.gridUnit)
        : PatternPlayback.forRudiment(_unit);
  }
```

2. `_openSourceOrThrow`, direkt nach `final rudiment = ref.read(...)`:

```dart
    // Kit exercises are measured per voice (Brief B.3) — not in this step:
    // no source, no number; sheet, click and cursor run (Leitprinzip: no
    // number is better than a wrong one).
    if (rudiment.isKit) return;
```

3. `_applyExtras`:

```dart
    _metronomeNotifier
      ..setClickTrack(SettingsService.clickTrackEnabled && _extrasAllowed)
      ..setBacking(backingOn ? _backingStyleId : null,
          beatsPerBar: _unit.beatsPerBar,
          // Brief B.4: the band keeps quiet in the voices the player plays.
          backingKick: !_plan.playsKick,
          backingHihat: !_plan.playsHihat);
```

4. Cursor im `build` (nach `activeBeat`):

```dart
    // Which sheet line and note (pad) or tick (kit) the cursor is on.
    final loc =
        activeBeat == null || _plan.isKit ? null : _plan.locate(activeBeat);
    final tickLoc = activeBeat == null || !_plan.isKit
        ? null
        : _plan.locateTick(_playback.onsetTicks[activeBeat]);
```

   und am `SheetWindow(...)`:

```dart
                          activeLine:
                              tickLoc?.line ?? loc?.line ?? _plan.lineIndex,
                          activeIndex: loc?.index,
                          activeTick: tickLoc?.tick,
```

5. `_ModeChip`: Feld `final bool kit;` (`/// Kit exercise: measured per voice from B.3 on — not yet.`), Konstruktor `required this.kit,`; Tooltip:

```dart
      message: kit
          ? 'Full-kit measurement is not available yet'
          : unavailable
              ? 'Not measurable with this setup'
              : analysis
                  ? 'Analysis mode (per-hand values) — tap for Learn mode'
                  : 'Learn mode — tap for hand analysis',
```

   Aufruf (um Zeile 1192): `kit: rudiment.isKit,`.

6. `lessons_screen.dart`, `_RudimentTile.trailing` vor dem Difficulty-Badge:

```dart
          if (rudiment.isKit) ...[
            const AppBadge(label: 'KIT'),
            const SizedBox(width: 6),
          ],
```

- [ ] **Step 5: Run tests**

Run: `flutter analyze && flutter test`
Expected: alles grün (Pad-Tests unverändert: `_openSourceOrThrow` kehrt nur für `isKit` früh zurück; `activeTick` ist für Pad-Zeilen null).

- [ ] **Step 6: Commit**

```bash
git add lib/features/practice/widgets/sheet_window.dart lib/features/practice/practice_session_screen.dart lib/features/lessons/lessons_screen.dart test/features/practice/sheet_window_test.dart test/features/practice/practice_session_screen_test.dart test/helpers/kit_fixtures.dart
git commit -m "feat(practice): Set-Übungen spielbar — gemischte Einheit, Spalten-Cursor, Band schweigt, keine Messung (B.3 folgt), KIT-Badge"
```

---

### Task 6: Katalog-Werkzeug — Spuren in `sheetlang`, Kit-Blätter in `blatt`, Dart- und ABC-Ausgabe

**Files:**
- Modify: `tool/katalog/sheetlang.py` (`K`/`P`-Hände, `TRACKS`, `Track`, `KitLine`, `is_kit_text`, `parse_kit_line`, `note_to_dart` für Füße, `kit_line_to_dart`, `voice_to_dart`, `kit_line_to_abc`, `KIT_ABC_HEADER`)
- Modify: `tool/katalog/blatt.py` (`Sheet.kit`, `Sheet.limbs`, `parsed`/`pattern_line` für Kit, `print_table`)
- Modify: `tool/katalog/gen_dart.py` (Kit-Blätter: `xPatternVoices`, `kitLine`, Import), `tool/katalog/patch_seed.py` (`voicing`, `requiredSensor`, `patternVoices`, `limbs`, Import `stroke_source.dart`)
- Modify: `tool/katalog/fills.py` (`FILLS`-Export der acht Fill-Listen), `tool/katalog/README.md`
- Create: `tool/katalog/test_kit.py`

**Interfaces:**
- Consumes: `parse_line`, `Note`, `Line`, `_abc_len`, `note_to_dart`, `line_to_dart`, `Sheet`, `select`, `camel`, `dart_str`.
- Produces (Python):
  - Token-Hände `R L K P` (`K` = Kick, `P` = Hi-Hat-Pedal; `Note.is_foot`). Fußnoten tragen keine Vorschläge (`f`/`d` ⇒ `ValueError`).
  - `TRACKS: dict[str, tuple[str, bool]]` Spurkopf → (`KitInstrument`-Name, Fuß?): `HH hiHatClosed, HO hiHatOpen, HP hiHatPedal*, SN snare, SR snareRim, BD kick*, T1 tom1, T2 tom2, F1 floorTom1, F2 floorTom2, C1 crash1, C2 crash2, RD ride, RB rideBell, CH china, SP splash` (`*` = Fuß). `CLASSES`: `T1 T2 F1 F2 → anyTom`, `C1 C2 CH SP → anyCrash`, `RD RB HH HO → anyCymbal`; Suffix `~` am Spurkopf (`T1~:`) setzt `accepts`.
  - `@dataclass Track(key, instrument, foot, accepts, notes, bars)`, `@dataclass KitLine(tracks, repeat, title, counts, bars)`.
  - `is_kit_text(text) -> bool` (erste nicht-leere Zeile beginnt mit `XX:`), `parse_kit_line(text, beats_per_bar=4, *, repeat=True, title=None, counts=False) -> KitLine` — jede Spur eine Zeile `KEY[~]: tokens | tokens`, alle Spuren gleich viele Takte, Spur höchstens einmal, Hände/Füße passend zur Spur.
  - `note_to_dart(n)`: Fußnote ⇒ `foot(NoteValue.x[, accent: true][, ghost: true][, dotted: true][, tuplet: …])`. `voice_to_dart(track, indent)` ⇒ `voice(KitInstrument.<instrument>, [ … ][, accepts: InstrumentClass.<cls>]),`. `kit_line_to_dart(kl, indent='  ')` ⇒ `kitLine([ voices… ][, repeat: false][, title: '…'][, counts: true]),`.
  - `kit_line_to_abc(kl, beats_per_bar=4, marks=None) -> str` — zwei ABC-Stimmen `[V:H] … [V:F] …` auf einem Schlagzeug-System (Hände Hals oben, Füße Hals unten), je Schicht die vereinigte Rhythmik wie `layerTrack` (Lücke bis zum nächsten Einsatz, am Schlag gedeckelt, Rest = Pausen; Fußpausen als unsichtbare `x`-Pausen); Akkorde `[ce]`; `KIT_ABC_HEADER` mit `%%score (H F)`, `V:H clef=perc stem=up`, `V:F clef=perc stem=down`, `%%percmap`-Zeilen je Tonhöhe.
  - `Sheet(kit=False, limbs=('hands',))`; `Sheet.parsed()` liefert `list[Line | KitLine]`; `Sheet.pattern_line()` entsprechend.
  - `fills.FILLS: dict[str, list[str]]` — die acht Fill-Listen unter ihren Blatt-Ids.
- Produces (Dart, generiert): `final List<Voice> {c}PatternVoices`, `{c}Pattern` (erste Stimme), `{c}Sheet` aus `kitLine(...)`; Seed-Einträge mit `voicing: ExerciseVoicing.kit, requiredSensor: SensorLevel.midi, limbs: {…}, patternVoices: {c}PatternVoices`.

- [ ] **Step 1: Failing tests**

`tool/katalog/test_kit.py`:

```python
"""Spuren-Notenschrift (Phase B.1): Parser, Dart- und ABC-Ausgabe. Aufruf: cd tool/katalog && python3 -m unittest -v"""
import unittest

from sheetlang import (KitLine, is_kit_text, kit_line_to_abc, kit_line_to_dart, note_to_dart,
                       parse_kit_line, parse_line)

ROCK8 = '''
HH: R8 R8 R8 R8 R8 R8 R8 R8
SN: -4 L4> -4 L4>
BD: K4 -4 K4 -4
'''


class ParseKitLine(unittest.TestCase):
    def test_tracks_instruments_bars(self):
        kl = parse_kit_line(ROCK8)
        self.assertIsInstance(kl, KitLine)
        self.assertEqual([t.key for t in kl.tracks], ['HH', 'SN', 'BD'])
        self.assertEqual([t.instrument for t in kl.tracks], ['hiHatClosed', 'snare', 'kick'])
        self.assertEqual([t.foot for t in kl.tracks], [False, False, True])
        self.assertEqual(kl.bars, 1)
        self.assertTrue(kl.repeat)
        self.assertIsNone(kl.tracks[0].accepts)

    def test_class_suffix(self):
        kl = parse_kit_line('T1~: R16 L16 R16 L16 -4 -2\nC1~: -2. R4>')
        self.assertEqual(kl.tracks[0].accepts, 'anyTom')
        self.assertEqual(kl.tracks[1].accepts, 'anyCrash')
        with self.assertRaises(ValueError):
            parse_kit_line('SN~: R4 L4 R4 L4')  # snare has no class

    def test_feet_and_hands_are_checked(self):
        with self.assertRaises(ValueError):
            parse_kit_line('BD: R4 -4 R4 -4')  # a foot track with hand letters
        with self.assertRaises(ValueError):
            parse_kit_line('SN: K4 -4 K4 -4')  # a hand track with foot letters
        with self.assertRaises(ValueError):
            parse_kit_line('BD: K4f -4 K4 -4')  # no graces on a foot

    def test_lengths_must_agree(self):
        with self.assertRaises(ValueError):
            parse_kit_line('HH: R8 R8 R8 R8 R8 R8 R8 R8 | R8 R8 R8 R8 R8 R8 R8 R8\nBD: K4 -4 K4 -4')
        with self.assertRaises(ValueError):
            parse_kit_line('HH: R4 R4 R4 R4\nHH: R4 R4 R4 R4')  # track twice
        with self.assertRaises(ValueError):
            parse_kit_line('XX: R4 R4 R4 R4')  # unknown track
        with self.assertRaises(ValueError):
            parse_kit_line('')

    def test_is_kit_text(self):
        self.assertTrue(is_kit_text(ROCK8))
        self.assertFalse(is_kit_text('R8 L8 R8 L8 R8 L8 R8 L8'))


class DartOutput(unittest.TestCase):
    def test_foot_note(self):
        self.assertEqual(note_to_dart(parse_line('K4 -2.').notes[0]), 'foot(NoteValue.quarter)')
        self.assertEqual(note_to_dart(parse_line('K8>g -8. -2').notes[0]),
                         'foot(NoteValue.eighth, accent: true, ghost: true)')
        self.assertEqual(note_to_dart(parse_line('3(K8 -8 -8) -2.').notes[0]),
                         'foot(NoteValue.eighth, tuplet: Tuplet.triplet)')

    def test_kit_line(self):
        out = kit_line_to_dart(parse_kit_line('T1~: R16 L16 R16 L16 -4 -2\nBD: K4 -4 K4 -4', counts=True, title='Fill'))
        self.assertTrue(out.startswith('  kitLine([\n'))
        self.assertIn('voice(KitInstrument.tom1, [', out)
        self.assertIn('], accepts: InstrumentClass.anyTom),', out)
        self.assertIn('voice(KitInstrument.kick, [', out)
        self.assertIn('foot(NoteValue.quarter),', out)
        self.assertIn('note(R, NoteValue.sixteenth),', out)
        self.assertTrue(out.rstrip().endswith("], title: 'Fill', counts: true),"))


class AbcOutput(unittest.TestCase):
    def test_two_voices_chords_and_rests(self):
        abc = kit_line_to_abc(parse_kit_line(ROCK8))
        self.assertIn('[V:H]', abc)
        self.assertIn('[V:F]', abc)
        hands = abc.split('[V:H]')[1].split('[V:F]')[0]
        feet = abc.split('[V:F]')[1]
        # Hands: hi-hat eighths, snare joins on 2 and 4 as a chord.
        self.assertEqual(hands.count('['), 2)
        self.assertIn('[cg]', hands)
        # Feet: kick on 1 and 3, invisible rests between.
        self.assertEqual(feet.count('F'), 2)
        self.assertIn('x', feet)
        self.assertTrue(abc.strip().endswith(':|') or abc.strip().endswith('|'))


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd tool/katalog && python3 -m unittest -v test_kit`
Expected: `ImportError` (`KitLine`, `parse_kit_line` … fehlen).

- [ ] **Step 3: `sheetlang.py`**

1. Modul-Docstring um die Spuren ergänzen (Kopf `HH:`, Hände `R L`, Füße `K P`, `~` = Instrument-Klasse). `_TOKEN = re.compile(r'^([RLKP])(32|16|8|4|2|1)([.>gfd]*)$')`. In `Note`:

```python
    @property
    def is_foot(self) -> bool:
        return self.hand in ('K', 'P')
```

   In `_parse_token` nach dem Setzen der Flags: `if n.is_foot and n.graces: raise ValueError(f'foot note {tok!r} cannot carry a flam/drag')`.

2. Spuren (nach `parse_line`/`_parse_token`):

```python
# ── Spuren (Phase B.1): eine Zeile je Instrument ─────────────────────────────

TRACKS: dict[str, tuple[str, bool]] = {  # Spurkopf → (KitInstrument, Fuß?)
    'HH': ('hiHatClosed', False), 'HO': ('hiHatOpen', False), 'HP': ('hiHatPedal', True),
    'SN': ('snare', False), 'SR': ('snareRim', False), 'BD': ('kick', True),
    'T1': ('tom1', False), 'T2': ('tom2', False), 'F1': ('floorTom1', False), 'F2': ('floorTom2', False),
    'C1': ('crash1', False), 'C2': ('crash2', False), 'RD': ('ride', False), 'RB': ('rideBell', False),
    'CH': ('china', False), 'SP': ('splash', False),
}
CLASSES: dict[str, str] = {  # Spurkopf mit `~` → InstrumentClass (Brief B.3)
    'T1': 'anyTom', 'T2': 'anyTom', 'F1': 'anyTom', 'F2': 'anyTom',
    'C1': 'anyCrash', 'C2': 'anyCrash', 'CH': 'anyCrash', 'SP': 'anyCrash',
    'RD': 'anyCymbal', 'RB': 'anyCymbal', 'HH': 'anyCymbal', 'HO': 'anyCymbal',
}
_HEAD = re.compile(r'^([A-Z][A-Z0-9])(~?):\s*(.*)$')


@dataclass
class Track:
    key: str
    instrument: str
    foot: bool
    accepts: str | None
    notes: list[Note]
    bars: int


@dataclass
class KitLine:
    tracks: list[Track]
    repeat: bool = True
    title: str | None = None
    counts: bool = False
    bars: int = 0


def is_kit_text(text: str) -> bool:
    first = next((ln.strip() for ln in text.splitlines() if ln.strip()), '')
    return bool(_HEAD.match(first))


def parse_kit_line(text: str, beats_per_bar: int = 4, *, repeat: bool = True,
                   title: str | None = None, counts: bool = False) -> KitLine:
    """Eine Zeile je Spur (`HH: …`), alle Spuren gleich lang; Füße spielen K/P, Hände R/L."""
    tracks: list[Track] = []
    for raw in text.splitlines():
        raw = raw.strip()
        if not raw:
            continue
        m = _HEAD.match(raw)
        if not m:
            raise ValueError(f'track line without head: {raw!r}')
        key, tilde, body = m.groups()
        if key not in TRACKS:
            raise ValueError(f'unknown track {key!r} (known: {" ".join(TRACKS)})')
        if any(t.key == key for t in tracks):
            raise ValueError(f'track {key} twice in: {text}')
        instrument, foot = TRACKS[key]
        line = parse_line(body, beats_per_bar)
        for n in line.notes:
            if not n.rest and n.is_foot != foot:
                raise ValueError(f'{key}: {"feet play K/P" if foot else "hands play R/L"}, got {n.hand}')
        accepts = CLASSES.get(key) if tilde else None
        if tilde and accepts is None:
            raise ValueError(f'{key} has no instrument class')
        tracks.append(Track(key, instrument, foot, accepts, line.notes, line.bars))
    if not tracks:
        raise ValueError('kit line without tracks')
    bars = {t.bars for t in tracks}
    if len(bars) != 1:
        raise ValueError(f'tracks differ in length: {sorted(bars)} bars in: {text}')
    return KitLine(tracks, repeat=repeat, title=title, counts=counts, bars=bars.pop())
```

3. Dart: in `note_to_dart` als erste Verzweigung nach `extras` und der Pausen-Rückgabe:

```python
    if n.is_foot:
        args = []
        if n.accent:
            args.append('accent: true')
        if n.ghost:
            args.append('ghost: true')
        args += extras
        return f'foot({v}' + (', ' + ', '.join(args) if args else '') + ')'
```

   und am Ende des Dart-Abschnitts:

```python
def voice_to_dart(t: Track, indent: str = '  ') -> str:
    notes = '\n'.join(indent + '    ' + note_to_dart(n) + ',' for n in t.notes)
    tail = f', accepts: InstrumentClass.{t.accepts}' if t.accepts else ''
    return f'{indent}  voice(KitInstrument.{t.instrument}, [\n{notes}\n{indent}  ]{tail}),'


def kit_line_to_dart(kl: KitLine, indent: str = '  ') -> str:
    opts = []
    if not kl.repeat:
        opts.append('repeat: false')
    if kl.title:
        opts.append(f"title: '{kl.title}'")
    if kl.counts:
        opts.append('counts: true')
    body = '\n'.join(voice_to_dart(t, indent) for t in kl.tracks)
    tail = (', ' + ', '.join(opts)) if opts else ''
    return f'{indent}kitLine([\n{body}\n{indent}]{tail}),'
```

4. ABC (Kurationsseite; spiegelt `layerTrack`): nach `line_to_abc`:

```python
# ── abcjs, Kit: zwei Stimmen auf einem Schlagzeug-System ─────────────────────

_ABC_PITCH = {'HP': 'D', 'BD': 'F', 'F2': 'G', 'F1': 'A', 'SN': 'c', 'SR': 'c', 'T2': 'd', 'T1': 'e',
              'RD': 'f', 'RB': 'f', 'HH': 'g', 'HO': 'g', 'C1': 'a', 'C2': 'a', 'CH': 'a', 'SP': 'a'}
_ABC_HEAD = {'HH': 'x', 'HO': 'x', 'HP': 'x', 'SR': 'x', 'RD': 'x', 'C1': 'x', 'C2': 'x', 'SP': 'x',
             'RB': 'diamond', 'CH': 'x'}
KIT_ABC_HEADER = ('X:1\\nT:\\nM:4/4\\nL:1/8\\nK:perc\\n%%stretchlast 1\\n%%staffsep 110\\n'
                  '%%score (H F)\\nV:H clef=perc stem=up\\nV:F clef=perc stem=down\\n'
                  '%%percmap D 44 x\\n%%percmap F 36\\n%%percmap G 43\\n%%percmap A 45\\n%%percmap c 38\\n'
                  '%%percmap d 47\\n%%percmap e 48\\n%%percmap f 51 x\\n%%percmap g 42 x\\n%%percmap a 49 x\\n')

# Lücke (Ticks, am Schlag gedeckelt) → (Wert, punktiert, Tuplet), größter passender Wert.
_GAP_VALUES = [(24, 4, False, 0), (18, 8, True, 0), (16, 4, False, 3), (12, 8, False, 0), (9, 16, True, 0),
               (8, 8, False, 3), (6, 16, False, 0), (4, 16, False, 6), (3, 32, False, 0), (2, 32, False, 3)]


def _value_for_gap(ticks: int) -> tuple[int, int, bool, int]:
    for entry in _GAP_VALUES:
        if entry[0] <= ticks:
            return entry
    raise ValueError(f'gap of {ticks} tick(s) is not drawable')


def _layer_tokens(tracks: list[Track], total: int, *, feet: bool) -> list[tuple[int, str]]:
    """(Tick, ABC-Token) je Einsatz/Pause einer Schicht — Akkord je Spalte, Pausen bis zum nächsten Einsatz."""
    by_tick: dict[int, list[tuple[Track, Note]]] = {}
    for t in tracks:
        tick = 0
        for n in t.notes:
            if not n.rest:
                by_tick.setdefault(tick, []).append((t, n))
            tick += n.ticks()
    ticks = sorted(by_tick)
    out: list[tuple[int, str]] = []
    cursor = 0

    def rests(up_to: int) -> None:
        nonlocal cursor
        while cursor < up_to:
            beat_end = (cursor // TPQ + 1) * TPQ
            g, value, dotted, _ = _value_for_gap(min(up_to, beat_end) - cursor)
            out.append((cursor, ('x' if feet else 'z') + _abc_len(value, dotted)))
            cursor += g

    for i, tick in enumerate(ticks):
        rests(tick)
        nxt = ticks[i + 1] if i + 1 < len(ticks) else total
        beat_end = (tick // TPQ + 1) * TPQ
        g, value, dotted, tuplet = _value_for_gap(min(nxt, beat_end) - tick)
        notes = by_tick[tick]
        deco = '!>!' if any(n.accent for _, n in notes) else ''
        grace = '{B}' if any(n.graces for _, n in notes) else ''
        pitches = ''.join(sorted({_ABC_PITCH[t.key] for t, _ in notes}, key=lambda p: (p.islower(), p)))
        body = pitches if len(pitches) == 1 else f'[{pitches}]'
        out.append((tick, f'{grace}{deco}{body}{_abc_len(value, dotted)}'))
        cursor = tick + g
    rests(total)
    return out


def kit_line_to_abc(kl: KitLine, beats_per_bar: int = 4, marks: dict[int, str] | None = None) -> str:
    bar_ticks = beats_per_bar * TPQ
    total = kl.bars * bar_ticks

    def voice(tokens: list[tuple[int, str]]) -> str:
        bars: list[list[str]] = [[] for _ in range(kl.bars)]
        for tick, tok in tokens:
            b = tick // bar_ticks
            if marks and tick % bar_ticks == 0 and b in marks:
                tok = f'"^{marks[b]}"' + tok
            bars[b].append(tok)
        body = ' | '.join(' '.join(b) for b in bars)
        return f'|: {body} :|' if kl.repeat else f'{body} |'

    hands = _layer_tokens([t for t in kl.tracks if not t.foot], total, feet=False)
    feet = _layer_tokens([t for t in kl.tracks if t.foot], total, feet=True)
    return f'[V:H] {voice(hands)}\\n[V:F] {voice(feet)}\\n'
```

   Triolen in der Schicht werden hier ohne `(3`-Klammer gesetzt (Längen stimmen, abcjs zeigt sie als punktierte Werte); das ist eine bekannte Vereinfachung der Kurationsseite, kein App-Verhalten — in `README.md` notieren.

- [ ] **Step 4: `blatt.py`, `gen_dart.py`, `patch_seed.py`, `fills.py`**

`blatt.py`:

```python
from sheetlang import KitLine, Line, check_sheet, parse_kit_line, parse_line
…
    grid: str = 'eighth'
    kit: bool = False  # Spuren-Blatt (Phase B.1): Zeilen als `HH: … / SN: … / BD: …`
    limbs: tuple[str, ...] = ('hands',)  # Limb-Tags des Seed-Eintrags

    def _parse(self, text: str, **kw) -> Line | KitLine:
        return parse_kit_line(text, **kw) if self.kit else parse_line(text, **kw)

    def parsed(self) -> list[Line | KitLine]:
        out = [self._parse(t, counts=i < self.count_lines) for i, t in enumerate(self.lines)]
        out.append(self._parse(self.challenge, repeat=False, title='Challenge'))
        … (Prüfungen unverändert, sie lesen nur `.bars`)

    def pattern_line(self) -> Line | KitLine:
        ln = self._parse(self.pattern, repeat=False)
        …
```

`print_table`: `notes = sum((sum(len(t.notes) for t in ln.tracks) if isinstance(ln, KitLine) else len(ln.notes)) for ln in lines)`.

`gen_dart.py`, `render`:

```python
    from sheetlang import KitLine, kit_line_to_dart, note_to_dart, voice_to_dart
    c = camel(sheet.id)
    lines = sheet.parsed()
    pat = sheet.pattern_line()
    if sheet.kit:
        body = '\n'.join(kit_line_to_dart(ln) for ln in lines)
        pattern = '\n'.join('  ' + note_to_dart(n) + ',' for n in pat.tracks[0].notes)
        voices = '\n'.join(voice_to_dart(t, '') for t in pat.tracks)
        extra_import = "import '../../../coaching/midi/kit_instrument.dart';\n"
        pattern_voices = (f'\n/// {sheet.name}: the PATTERN bar, every voice (Brief B.1).\n'
                          f'final List<Voice> {c}PatternVoices = [\n{voices}\n];\n')
    else:
        body = '\n'.join(line_to_dart(ln) for ln in lines)
        pattern = '\n'.join('  ' + note_to_dart(n) + ',' for n in pat.notes)
        extra_import = ''
        pattern_voices = ''
    form = ('8 lines of two bars' if sheet.line_bars == 2
            else '8 lines of four bars (three bars of time, one bar of fill)')
```

   Vorlage: `extra_import` nach `import '../../models/rudiment.dart';`, `pattern_voices` nach dem `{c}Pattern`-Block. Doc der Pattern-Liste für Kit: „the first voice of the PATTERN bar — see {c}PatternVoices".

`patch_seed.py`, `_entry(s)`:

```python
    limbs = ', '.join(f'Limb.{l}' for l in s.limbs)
    kit = (f"    voicing: ExerciseVoicing.kit,\n    requiredSensor: SensorLevel.midi,\n"
           f"    patternVoices: {c}PatternVoices,\n") if s.kit else ''
    return (
        … bisher …
        + (f"    limbs: {{{limbs}}},\n" if s.limbs != ('hands',) else '')
        + kit
        + f"    sticking: {c}Pattern,\n    technique: {c}Lesson,\n    lines: {c}Sheet,\n  ),\n")
```

   In `patch()` nach dem Import-Block: `if "coaching/services/stroke_source.dart" not in src: src = src.replace("import '../models/rudiment.dart';\n", "import '../../coaching/services/stroke_source.dart';\nimport '../models/rudiment.dart';\n", 1)`.

`fills.py` — nach den acht Listen: `FILLS: dict[str, list[str]] = {'fill_sixteenth_singles': _SX, 'fill_doubles': _DB, 'fill_paradiddle': _PD, 'fill_triplets': _TR, 'fill_flams': _FL, 'fill_sextuplets': _SE, 'fill_six_groups': _SG, 'fill_roll': _RO}`.

`README.md`: Abschnitt „Spuren (Phase B.1)" mit Spurköpfen, `K`/`P`, `~`, `kit=True`, Zwei-Stimmen-ABC und der Triolen-Vereinfachung.

- [ ] **Step 5: Tests**

Run: `cd tool/katalog && python3 -m unittest -v && python3 rudimente.py && python3 fills.py && python3 gen_dart.py /tmp/katalog-check && diff -r /tmp/katalog-check ../../lib/features/lessons/data/sheets | head`
Expected: unittest grün; beide Sätze „ok"; die neu erzeugten Pad-Blätter sind **byte-gleich** mit den eingecheckten (kein diff-Ausgabe) — die Pad-Ausgabe hat sich nicht geändert.

- [ ] **Step 6: Commit**

```bash
git add tool/katalog/sheetlang.py tool/katalog/blatt.py tool/katalog/gen_dart.py tool/katalog/patch_seed.py tool/katalog/fills.py tool/katalog/README.md tool/katalog/test_kit.py
git commit -m "feat(katalog): Spuren-Notenschrift — HH/SN/BD-Zeilen, K/P für Füße, ~ für Instrument-Klassen, Dart kitLine/voice/foot, Zwei-Stimmen-ABC"
```

---

### Task 7: Inhalt — sechs Grooves und „Open Hi-hat" (`grooves.py`), Seed, Integritätstests

**Files:**
- Create: `tool/katalog/grooves.py`
- Modify: `tool/katalog/katalog.py` (Satz `grooves`, Schritt `B.4a`)
- Generated: `lib/features/lessons/data/sheets/groove_*_sheet.dart` (7), `lib/features/lessons/data/rudiments_seed.dart` (7 Einträge)
- Test: `test/lessons/kit_seed_integrity_test.dart`, `test/lessons/lessons_screen_meta_test.dart` (ein Test dazu)

**Interfaces:**
- Consumes: `Sheet(kit=True, limbs=…)`, `parse_kit_line`, `gen_dart.py`, `patch_seed.py` (Task 6); `Rudiment.isKit/patternVoices`, `kitBarsOrThrow`, `computeKitLineLayout`.
- Produces: Blätter `groove_rock8`, `groove_rock16`, `groove_halftime`, `groove_shuffle`, `groove_swing`, `groove_funk16`, `groove_hihat_open` — je 8 Zeilen à 2 Takte + Challenge 8 Takte, `kit=True`, `limbs=('allFour',)`, `skills=['groove', …]`, `backing=None`; Takt-Vokabular `grooves.HH8 …` (Task 8 importiert es); Helfer `kit(*bars) -> str`.

- [ ] **Step 1: Failing tests**

`test/lessons/kit_seed_integrity_test.dart`:

```dart
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:drum_coach/shared/widgets/kit_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final kits = rudimentsSeedData.where((r) => r.isKit).toList();

  test('there are kit exercises, all MIDI-only with pattern voices', () {
    expect(kits, isNotEmpty);
    for (final r in kits) {
      expect(r.requiredSensor, SensorLevel.midi, reason: r.id);
      expect(r.voicing, ExerciseVoicing.kit, reason: r.id);
      expect(r.patternVoices, isNotEmpty, reason: r.id);
      expect(r.backing, isNull, reason: '${r.id}: the player is the band');
      expect(r.limbs.contains(Limb.allFour) || r.limbs.contains(Limb.feet),
          isTrue,
          reason: r.id);
      // The PATTERN bar: one bar in every voice, sticking = its first voice.
      expect(
          kitBarsOrThrow(r.patternVoices,
              beatsPerBar: r.beatsPerBar, grid: r.gridUnit),
          1,
          reason: r.id);
      expect(r.sticking, same(r.patternVoices.first.beats), reason: r.id);
    }
  });

  test('every kit line: kit voices of equal whole bars (1..8), drawable '
      'layers, sheet ≤ 64 bars; a line never holds the same instrument twice',
      () {
    for (final r in kits) {
      for (var i = 0; i < r.lines.length; i++) {
        final l = r.lines[i];
        expect(l.isKit, isTrue, reason: '${r.id} line ${i + 1}');
        final bars = kitBarsOrThrow(l.kitVoices,
            beatsPerBar: r.beatsPerBar, grid: r.gridUnit);
        expect(bars, inInclusiveRange(1, 8), reason: '${r.id} line ${i + 1}');
        final instruments = l.kitVoices.map((v) => v.instrument).toList();
        expect(instruments.toSet().length, instruments.length,
            reason: '${r.id} line ${i + 1} repeats an instrument');
        expect(
            () => computeKitLineLayout(
                voices: l.kitVoices,
                grid: r.gridUnit,
                beatsPerBar: r.beatsPerBar,
                maxWidth: 360),
            returnsNormally,
            reason: '${r.id} line ${i + 1} is not drawable');
      }
      expect(sheetBars(r), lessThanOrEqualTo(64), reason: r.id);
      expect(() => SheetPlan.wholeSheet(r), returnsNormally, reason: r.id);
    }
  });

  test('the seven groove sheets: 8 lines + Challenge, 24 bars, hi-hat/ride, '
      'snare and kick in line 1, four lesson sections', () {
    const ids = [
      'groove_rock8',
      'groove_rock16',
      'groove_halftime',
      'groove_shuffle',
      'groove_swing',
      'groove_funk16',
      'groove_hihat_open',
    ];
    for (final id in ids) {
      final r = rudimentsSeedData.firstWhere((r) => r.id == id);
      expect(r.sheet.length, 9, reason: id);
      expect(r.sheet.take(8).every((l) => l.repeat), isTrue, reason: id);
      expect(r.sheet.last.repeat, isFalse, reason: id);
      expect(r.sheet.last.title, 'Challenge', reason: id);
      expect(sheetBars(r), 24, reason: id);
      expect(r.skills.contains(Skill.groove), isTrue, reason: id);
      final first = r.sheet.first.kitVoices.map((v) => v.instrument).toSet();
      expect(first.contains(KitInstrument.kick), isTrue, reason: id);
      expect(
          first.contains(KitInstrument.hiHatClosed) ||
              first.contains(KitInstrument.ride),
          isTrue,
          reason: id);
      expect(
          r.technique.map((s) => s.title),
          ['Why it matters', 'How to play it', 'Practice tips', 'Where you hear it'],
          reason: id);
    }
    final hats = rudimentsSeedData.firstWhere((r) => r.id == 'groove_hihat_open');
    expect(
        hats.lines.every((l) =>
            l.kitVoices.any((v) => v.instrument == KitInstrument.hiHatOpen) ||
            l.kitVoices.any((v) => v.instrument == KitInstrument.hiHatPedal)),
        isTrue,
        reason: 'every hi-hat line opens or pedals');
  });
}
```

`test/lessons/lessons_screen_meta_test.dart`, Test dazu (nach dem Muster der bestehenden Tests dieser Datei, Pump-Helfer wiederverwenden):

```dart
  testWidgets('kit exercises carry a KIT badge in the library', (tester) async {
    // Pump the library the way the other tests here do, then:
    await tester.scrollUntilVisible(find.text('Rock 8ths Groove'), 300);
    final tile = find.ancestor(
        of: find.text('Rock 8ths Groove'), matching: find.byType(ListTile));
    expect(find.descendant(of: tile, matching: find.text('KIT')), findsOneWidget);
    expect(find.descendant(of: find.ancestor(
        of: find.text('Single Stroke Roll'), matching: find.byType(ListTile)),
        matching: find.text('KIT')), findsNothing);
  });
```

Vorher prüfen: Pump-Helfer und ob die Liste gefiltert/gescrollt wird (`sed -n 1,60p test/lessons/lessons_screen_meta_test.dart`).

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/lessons/kit_seed_integrity_test.dart test/lessons/lessons_screen_meta_test.dart`
Expected: „there are kit exercises" fällt (`kits` leer); Badge-Test findet „Rock 8ths Groove" nicht.

- [ ] **Step 3: `grooves.py` — Vokabular, Helfer, die sieben Blätter**

```python
"""Sechs Grooves und ein Hi-Hat-Blatt (Phase B.4), frei komponiert.

Jedes Blatt: 8 Zeilen à 2 Takte mit Wiederholung + Challenge 8 Takte, als
Spuren (sheetlang: `HH: … / SN: … / BD: …`). Zeile 1 ist der Groove der
gleichnamigen Band-Stimme (backing_styles.dart), die Zeilen 2–8 variieren
Kick, Hi-Hat (Akzent, offen), Snare (Ghosts, Cross-Stick) und den Crash
auf der Eins. Regel (Uli, 30.09.): so abwechslungsreich und groovy wie
möglich. Texte Englisch (App-Sprache).
"""
from __future__ import annotations

from blatt import Sheet, print_table


def kit(*bars: dict[str, str]) -> str:
    """Takte als Spur-Dicts → Spurentext; eine Spur, die in einem Takt fehlt, pausiert dort."""
    keys: list[str] = []
    for b in bars:
        for k in b:
            if k not in keys:
                keys.append(k)
    return '\n'.join(f'{k}: ' + ' | '.join(b.get(k, '-1') for b in bars) for k in keys)


# ── Takt-Vokabular (je ein Takt) ─────────────────────────────────────────────
# Hi-Hat / Ride
HH8 = 'R8 R8 R8 R8 R8 R8 R8 R8'
HH8A = 'R8> R8 R8> R8 R8> R8 R8> R8'  # Akzent auf den Zählzeiten
HH8_HT = 'R8> R8 R8 R8 R8> R8 R8 R8'  # Half-time: Akzent auf 1 und 3
HH8_NO1 = '-8 R8 R8 R8 R8 R8 R8 R8'  # die Eins gehört dem Crash
HH8_O4 = 'R8 R8 R8 R8 R8 R8 R8 -8'  # „4 +" offen (HO-Spur)
HH8_O24 = 'R8 R8 R8 -8 R8 R8 R8 -8'  # „2 +" und „4 +" offen
HH8_DISCO = 'R8 -8 R8 -8 R8 -8 R8 -8'  # jedes „+" offen
HH16 = 'R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16'
HH16A = 'R16> L16 R16 L16 R16> L16 R16 L16 R16> L16 R16 L16 R16> L16 R16 L16'
HH16_NO1 = '-16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16'
HH16_O = 'R16 L16 R16 -16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 -16'  # „a" von 2 und 4 offen
HO_4A = '-2 -4 -8 R8'
HO_2A4A = '-4 -8 R8 -4 -8 R8'
HO_ALL = '-8 R8 -8 R8 -8 R8 -8 R8'
HO_1 = 'R4 -2.'
HO_16 = '-8. R16 -2 -8. R16'  # „a" von 2 und 4
SHUF = '3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8)'
SHUF_A = '3(R8> -8 R8) 3(R8> -8 R8) 3(R8> -8 R8) 3(R8> -8 R8)'
SHUF_NO1 = '3(-8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8)'
RIDE_SW = 'R4 3(R8 -8 R8) R4 3(R8 -8 R8)'
RIDE_SW_A = 'R4> 3(R8 -8 R8) R4> 3(R8 -8 R8)'
RIDE8 = 'R8 R8 R8 R8 R8 R8 R8 R8'
HP24 = '-4 P4 -4 P4'
HP1 = 'P4 -4 -2'
HP_ALL = 'P4 P4 P4 P4'
# Snare
SN24 = '-4 L4> -4 L4>'
SN3 = '-2 L4> -4'  # Half-time
SN24G = '-4 L4> -16 L16g -8 L4>'  # Ghost auf „e" von 3
SN24G2 = '-8 L16g -16 L4> -8 L16g -16 L4>'  # Ghosts auf „+" von 1 und 3
SN24G3 = '-16 L16g -8 L4> -16 L16g -8 L4>'  # Ghosts auf „e" von 1 und 3
SN_FUNK = '-4 L4> -8 L16g L16g L4>'  # Ghosts auf „3 +" und „3 a"
SN3G = '-4 -8 L16g L16g L4> -4'  # Ghosts vor der 3
SN24_T = '-4 L4> 3(-8 -8 L8g) L4>'  # Shuffle: Ghost auf „3 a"
SN_SW4 = '-2 -4 3(-8 -8 L8)'  # Swing: „a" von 4
SN_SW2 = '-4 3(-8 -8 L8) -2'  # Swing: „a" von 2
SN_SW3 = '-2 3(L8 -8 L8) -4'
SN_SW24 = '-4 3(-8 -8 L8) -4 3(-8 -8 L8)'
SN_SW2A = '-4 L4> -2'
SN_24_4A = '-4 L4> -4 -8 L8>'
SR3 = '-2 L4 -4'  # Cross-Stick auf 3
SR4 = '-2 -4 L4'
# Kick
BD13 = 'K4 -4 K4 -4'
BD1_3A = 'K4 -4 -8 K8 -4'  # 1 und „3 +"
BD1_2A_3 = 'K4 -8 K8 K4 -4'  # 1, „2 +", 3
BD1_2a_3 = 'K4 -8. K16 K4 -4'  # 1, „2 a", 3
BD_ROCK16 = 'K4 -4 K8 K8 -4'  # 1, 3, „3 +"
BD_R16B = 'K4 -16 K16 -8 K4 -8. K16'  # 1, „2 e", 3, „4 a"
BD_HALF = 'K4 -8 K8 -2'  # 1 und „2 +"
BD_HT2 = 'K4 -8 K8 -4 -8 K8'  # 1, „2 +", „4 +"
BD_FUNK = 'K8. K16 -8 K16 -16 K8. K16 -4'  # 1, „1 a", „2 +", 3, „3 a"
BD_FUNK2 = 'K4 -8. K16 -4 K8 K8'  # 1, „2 a", 4, „4 +"
BD_FUNK3 = 'K8 -8 K8 -8 -4 K8. K16'  # 1, 2, 4, „4 a"
BD_DBL = 'K8 K8 -4 K8 K8 -4'
BD_ALL = 'K4 K4 K4 K4'
BD_SHUF13 = 'K4 -4 3(K8 -8 K8) -4'  # 1, 3, „3 a"
BD_SHUF_ALL = '3(K8 -8 K8) -4 3(K8 -8 K8) -4'
BD_SW = 'K4g K4g K4g K4g'  # feathered: leise Viertel
BD_SW4 = 'K4g K4g K4g 3(K8g -8 K8)'
# Crash
C1_1 = 'R4> -4 -2'

LESSON_ROCK8 = {
    'Why it matters': 'The rock eighth groove is the sentence every other groove is a variation of: hi-hat keeps the eighths, snare marks 2 and 4, the kick says where the song leans. If this one sits, the rest of the kit is details.',
    'How to play it': 'Right hand on the hi-hat, loose wrist, every eighth the same. Left hand hits 2 and 4 as a backbeat — louder than the hi-hat, never rushed. The kick lands under the hi-hat on 1 and 3 so that two sounds become one.',
    'Practice tips': 'Play line 1 until the three limbs feel like one hand. Then take the kick variations slowly; the hi-hat must not flinch when the kick moves. Lines 4 and 7 add the open hat and the crash — keep the backbeat in place.',
    'Where you hear it': 'AC/DC "Back in Black", most of the Beatles, every pop song with a drummer. Count-in, hi-hat, go.',
}


def groove(**kw) -> Sheet:
    kw.setdefault('kit', True)
    kw.setdefault('limbs', ('allFour',))
    kw.setdefault('line_bars', 2)
    kw.setdefault('new_seed', True)
    kw.setdefault('genres', [])
    kw.setdefault('count_lines', 2)
    return Sheet(**kw)


def two(bar: dict[str, str]) -> str:
    return kit(bar, bar)


R8_1 = {'HH': HH8, 'SN': SN24, 'BD': BD13}
R8_2 = {'HH': HH8, 'SN': SN24, 'BD': BD1_3A}
R8_3 = {'HH': HH8, 'SN': SN24, 'BD': BD1_2A_3}
R8_4 = {'HH': HH8_O4, 'HO': HO_4A, 'SN': SN24, 'BD': BD13}
R8_5 = {'HH': HH8, 'SN': SN24G, 'BD': BD13}
R8_6 = {'HH': HH8, 'SN': SN24, 'BD': BD_DBL}
R8_7 = {'C1~': C1_1, 'HH': HH8_NO1, 'SN': SN24, 'BD': BD13}
R8_8 = {'HH': HH8A, 'SN': SN24, 'BD': BD1_2a_3}

SHEETS: list[Sheet] = [
    groove(
        id='groove_rock8', name='Rock 8ths Groove', min_bpm=60, target_bpm=140,
        difficulty='beginner', skills=['groove', 'coordination'], genres=['rock'], grid='eighth',
        description='Hi-hat eighths, backbeat on 2 and 4, kick on 1 and 3 — the groove the band played for you at the pad. Now you are the band.',
        pattern=kit(R8_1),
        lines=[
            two(R8_1),
            kit(R8_1, R8_2),
            two(R8_3),
            two(R8_4),
            kit(R8_5, {'HH': HH8, 'SN': SN24G, 'BD': BD1_3A}),
            two(R8_6),
            kit(R8_7, R8_3),
            two(R8_8),
        ],
        challenge=kit(R8_1, R8_1, R8_3, R8_3, R8_4, R8_4, R8_8, R8_8),
        lesson=LESSON_ROCK8,
    ),
    # … sechs weitere Blätter, Zeilen nach der Tabelle unten, Lektion je vier Abschnitte
]

if __name__ == '__main__':
    print_table(SHEETS)
```

Die sechs weiteren Blätter, Zeile für Zeile als Takt-Dicts (`two(x)` = Takt zweimal; `kit(a, b)` = zwei verschiedene Takte; Challenge = die vier genannten Zeilen hintereinander, je zwei Takte):

| Blatt / Felder | Zeilen 1–8 | Challenge |
|---|---|---|
| `groove_rock16` „Rock 16ths Groove", 60–120, intermediate, rock, grid `sixteenth` | 1 `two({HH16, SN24, BD_ROCK16})` · 2 `kit({HH16, SN24, BD13}, {HH16, SN24, BD_ROCK16})` · 3 `two({HH16A, SN24, BD_ROCK16})` · 4 `two({HH16, SN24, BD1_2a_3})` · 5 `two({HH16, SN24G, BD_ROCK16})` · 6 `two({HH16, SN24, BD_DBL})` · 7 `kit({C1~: C1_1, HH16_NO1, SN24, BD_ROCK16}, {HH16, SN24, BD_ROCK16})` · 8 `two({HH16, SN24, BD_R16B})` | 1, 3, 4, 8 |
| `groove_halftime` „Half-time Groove", 60–110, beginner, rock, `eighth` | 1 `two({HH8_HT, SN3, BD_HALF})` · 2 `two({HH8_HT, SN3, BD13})` · 3 `two({HH8_HT, SN3, BD_HT2})` · 4 `two({HH8_HT, SR: SR3, BD_HALF})` · 5 `two({HH8_HT, SN3G, BD_HALF})` · 6 `two({HH8_O4, HO_4A, SN3, BD_HALF})` · 7 `kit({C1~: C1_1, HH8_NO1, SN3, BD_HALF}, {HH8_HT, SN3, BD_HT2})` · 8 `two({HH16, SN3, BD_HALF})` | 1, 3, 6, 8 |
| `groove_shuffle` „Shuffle Groove", 60–130, intermediate, rock, `triplet` | 1 `two({SHUF, SN24, BD13})` · 2 `two({SHUF, SN24, BD_SHUF13})` · 3 `two({SHUF, SN24, BD_SHUF_ALL})` · 4 `two({SHUF, SN24_T, BD13})` · 5 `kit({SHUF, SN24, BD13}, {SHUF, SN24, BD_SHUF13})` · 6 `two({RD: SHUF, HP: HP24, SN24, BD13})` · 7 `kit({C1~: C1_1, HH: SHUF_NO1, SN24, BD13}, {SHUF, SN24, BD_SHUF13})` · 8 `two({SHUF_A, SN24, BD_SHUF_ALL})` | 1, 2, 3, 8 |
| `groove_swing` „Swing Ride", 60–180, intermediate, jazz, `triplet` | 1 `two({RD: RIDE_SW, HP: HP24, BD: BD_SW})` · 2 `two({RD, HP24, BD_SW, SN: SN_SW4})` · 3 `two({RD, HP24, BD_SW, SN: SN_SW2})` · 4 `two({RD, HP24, BD_SW, SR: SR4})` · 5 `two({RD, HP24, BD_SW, SN: SN_SW2A})` · 6 `two({RD, HP24, BD: BD_SW4})` · 7 `two({RD, HP24, BD_SW, SN: SN_SW3})` · 8 `two({RD: RIDE_SW_A, HP24, BD_SW, SN: SN_SW24})` | 1, 2, 5, 8 |
| `groove_funk16` „Funk 16ths Groove", 60–110, advanced, funk, `sixteenth` | 1 `two({HH16A, SN24, BD_FUNK})` · 2 `two({HH16A, SN_FUNK, BD_FUNK})` · 3 `two({HH16A, SN24, BD_FUNK2})` · 4 `two({HH16_O, HO_16, SN24, BD_FUNK})` · 5 `two({HH16A, SN24G2, BD_FUNK})` · 6 `two({HH16A, SN_24_4A, BD_FUNK3})` · 7 `kit({C1~: C1_1, HH16_NO1, SN24, BD_FUNK}, {HH16A, SN_FUNK, BD_FUNK})` · 8 `two({HH16A, SN24G3, BD_FUNK2})` | 1, 2, 4, 8 |
| `groove_hihat_open` „Open Hi-hat", 60–130, intermediate, rock, `eighth`, `skills=['groove', 'control']` | 1 `two({HH8_O4, HO_4A, SN24, BD13})` · 2 `two({HH8_O24, HO_2A4A, SN24, BD13})` · 3 `two({HH8_DISCO, HO_ALL, SN24, BD_ALL})` · 4 `two({HH8_O4, HO_4A, HP: HP1, SN24, BD13})` · 5 `two({RD: RIDE8, HP: HP_ALL, SN24, BD13})` · 6 `kit({HH8_NO1, HO: HO_1, SN24, BD13}, {HH8, SN24, BD13})` · 7 `two({HH: 'R8 R8 R8 -8 R8 R8 R8 R8', HO: '-4 -8 R8 -2', SN24, BD1_2A_3})` · 8 `two({HH16_O, HO_16, SN24, BD_ROCK16})` | 1, 2, 3, 7 |

Schreibweise in der Tabelle: `{HH16, SN24, BD13}` meint `{'HH': HH16, 'SN': SN24, 'BD': BD13}` — Spurkopf aus dem Konstantennamen (HH…/HO…/HP…/SN…/SR…/BD…/C1…/RD…/RIDE…→`RD`, SHUF→`HH`), wo nicht ausdrücklich `KEY: wert` steht. `pattern` = erster Takt der Zeile 1. Lektionen: vier Abschnitte in der Art von `LESSON_ROCK8` (Warum, Wie, Üben, Hören — je 2–4 Sätze, Englisch, konkrete Songs/Bands bei „Where you hear it"), für jedes Blatt eigen.

`katalog.py`:

```python
import grooves
…
    SheetSet(
        key='grooves', step='B.4a', title='Sechs Grooves und Open Hi-hat',
        lead='Phase B.4: der Groove der Band-Stimme als Blatt — Hi-Hat, Snare, Kick spielst du jetzt selbst, die Band '
             'schweigt in den Stimmen, die du spielst. Hände Hals oben, Füße Hals unten. Sag mir je Blatt und '
             'Zeilennummer, was raus, anders oder länger soll.',
        seed_marker='PHASE B.4: kit grooves',
        sheets=grooves.SHEETS,
    ),
```

- [ ] **Step 4: Prüfen, erzeugen, formatieren**

```bash
cd tool/katalog && python3 grooves.py && cd ../..
python3 tool/katalog/gen_dart.py lib/features/lessons/data/sheets grooves
python3 tool/katalog/patch_seed.py lib/features/lessons/data/rudiments_seed.dart
dart format lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart
flutter analyze && flutter test test/lessons test/shared test/notation_kit_staff_test.dart test/notation_staff_test.dart
```

Expected: `7 Blätter ok`; `seed patched: 20 updated, 7 added`; alle Tests grün (auch „every seeded exercise renders as a sheet without throwing" in `notation_staff_test.dart` — es zeichnet jetzt Kit-Blätter mit).

- [ ] **Step 5: Commit**

```bash
git add tool/katalog/grooves.py tool/katalog/katalog.py lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart test/lessons/kit_seed_integrity_test.dart test/lessons/lessons_screen_meta_test.dart
git commit -m "feat(Katalog B.4a): sechs Grooves und Open Hi-hat als Set-Blätter — Hi-Hat, Snare, Kick selbst gespielt"
```

---

### Task 8: Inhalt — acht Fill-Blätter mit echter Time und „Rund ums Set" (`set_fills.py`)

**Files:**
- Create: `tool/katalog/set_fills.py`
- Modify: `tool/katalog/katalog.py` (Satz `set_fills`, Schritt `B.4b`)
- Generated: `lib/features/lessons/data/sheets/set_fill_*_sheet.dart` (8), `set_around_the_kit_sheet.dart`, Seed (9 Einträge)
- Test: `test/lessons/kit_seed_integrity_test.dart` (Test dazu), `tool/katalog/test_kit.py` (Test für `orchestrate`)

**Interfaces:**
- Consumes: `fills.FILLS` (Task 6), `grooves.kit/HH8/HH8_NO1/SN24/BD13/…` (Task 7), `sheetlang._parse_token`, `Note.ticks`.
- Produces: `orchestrate(fill: str, plan: list[str]) -> dict[str, str]`; Blätter `set_fill_sixteenth_singles`, `set_fill_doubles`, `set_fill_paradiddle`, `set_fill_triplets`, `set_fill_flams`, `set_fill_sextuplets`, `set_fill_six_groups`, `set_fill_roll` (je 8 Zeilen à 4 Takte: drei Takte Groove + ein Takt Fill über Snare und Toms, Crash auf der Eins danach, Kick hält die Time im Fill-Takt) und `set_around_the_kit` (8 Zeilen à 2 Takte).

- [ ] **Step 1: Failing tests**

`tool/katalog/test_kit.py`, Klasse dazu:

```python
class Orchestrate(unittest.TestCase):
    def test_beats_go_to_their_drums_tuplets_stay_whole(self):
        from set_fills import orchestrate
        out = orchestrate('R16 L16 R16 L16 R8 L8 3(R8 L8 R8) R4>', ['SN', 'T1~', 'F1~', 'SN'])
        self.assertEqual(out['SN'], 'R16 L16 R16 L16 -4 -4 R4>')
        self.assertEqual(out['T1~'], '-4 R8 L8 -4 -4')
        self.assertEqual(out['F1~'], '-4 -4 3(R8 L8 R8) -4')
        self.assertEqual(set(out), {'SN', 'T1~', 'F1~'})

    def test_a_beat_split_across_tokens_is_refused(self):
        from set_fills import orchestrate
        plan = ['SN', 'T1~', 'F1~', 'SN']
        self.assertEqual(orchestrate('R8. L16 R8. L16 R4 R4', plan)['SN'], 'R8. L16 -4 -4 R4')
        with self.assertRaises(ValueError):
            orchestrate('R4. L8 R4 R4', plan)  # R4. crosses into beat 2
        with self.assertRaises(ValueError):
            orchestrate('R4 R4 R4', plan)  # three quarters, not a bar
```

`test/lessons/kit_seed_integrity_test.dart`, Test dazu:

```dart
  test('the eight set fills: 3 bars of groove + 1 bar of fill per line, the '
      'one after the fill on a crash, kick under the fill; around the kit', () {
    const ids = [
      'set_fill_sixteenth_singles',
      'set_fill_doubles',
      'set_fill_paradiddle',
      'set_fill_triplets',
      'set_fill_flams',
      'set_fill_sextuplets',
      'set_fill_six_groups',
      'set_fill_roll',
    ];
    for (final id in ids) {
      final r = rudimentsSeedData.firstWhere((r) => r.id == id);
      expect(r.sheet.length, 9, reason: id);
      expect(sheetBars(r), 40, reason: id);
      expect(r.skills.contains(Skill.fill), isTrue, reason: id);
      for (var i = 0; i < 8; i++) {
        final l = r.sheet[i];
        final crash = l.kitVoices.where(
            (v) => InstrumentClass.anyCrash.members.contains(v.instrument));
        expect(crash, isNotEmpty, reason: '$id line ${i + 1}: no crash');
        expect(crash.first.accepts, InstrumentClass.anyCrash, reason: id);
        expect(crash.first.beats.first.isRest, isFalse,
            reason: '$id line ${i + 1}: the crash is the one');
        final toms = l.kitVoices.where(
            (v) => InstrumentClass.anyTom.members.contains(v.instrument));
        expect(toms.every((v) => v.accepts == InstrumentClass.anyTom), isTrue,
            reason: '$id line ${i + 1}: toms accept any tom');
        expect(l.kitVoices.any((v) => v.instrument == KitInstrument.kick), isTrue,
            reason: '$id line ${i + 1}: no kick');
      }
    }
    final around = rudimentsSeedData.firstWhere((r) => r.id == 'set_around_the_kit');
    expect(around.sheet.length, 9);
    expect(sheetBars(around), 24);
    final cymbals = {
      for (final l in around.sheet)
        ...l.kitVoices
            .map((v) => v.instrument)
            .where((i) => InstrumentClass.anyCymbal.members.contains(i))
    };
    expect(cymbals.contains(KitInstrument.china), isTrue);
    expect(cymbals.contains(KitInstrument.rideBell), isTrue);
    expect(cymbals.contains(KitInstrument.crash1), isTrue);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd tool/katalog && python3 -m unittest -v test_kit.Orchestrate; cd ../.. && flutter test test/lessons/kit_seed_integrity_test.dart`
Expected: `ImportError` (`set_fills` fehlt); Dart-Test findet `set_fill_*` nicht.

- [ ] **Step 3: `set_fills.py`**

```python
"""Acht Fill-Blätter mit echter Time und „Rund ums Set" (Phase B.4), frei komponiert.

Die Fill-Takte stammen aus fills.py (Katalog 3b); hier werden sie über
Snare und Toms verteilt (orchestrate), die drei Time-Takte davor sind ein
Groove aus grooves.py, der Fuß hält im Fill-Takt die Time, und die Eins
danach ist ein Crash (jede Zeile wird geloopt: Takt 1 beginnt mit dem
Crash). Texte Englisch (App-Sprache).
"""
from __future__ import annotations

from blatt import Sheet, print_table
from fills import FILLS
from grooves import (BD13, BD_FUNK, BD_ROCK16, C1_1, HH16A, HH16_NO1, HH8, HH8_NO1, SHUF, SHUF_NO1,
                     SN24, kit)
from sheetlang import TPQ, _parse_token


def orchestrate(fill: str, plan: list[str]) -> dict[str, str]:
    """Verteilt einen Fill-Takt beat-weise auf Trommeln: plan[i] = Spur der Zählzeit i (z. B. 'T1~').

    Tuplet-Gruppen bleiben zusammen (sie füllen genau eine Zählzeit); eine Note, die eine
    Zählzeit überschreitet, wird abgelehnt.
    """
    beats: list[list[str]] = [[] for _ in range(4)]
    tick = 0
    tuplet = 0
    for raw in fill.split():
        tok = raw
        if tok.startswith(('3(', '6(')):
            tuplet, tok = int(tok[0]), tok[2:]
        closing = tok.endswith(')')
        if closing:
            tok = tok[:-1]
        n = _parse_token(tok)
        n.tuplet = tuplet
        beat, in_beat = divmod(tick, TPQ)
        if in_beat + n.ticks() > TPQ:
            raise ValueError(f'{tok} crosses beat {beat + 1} in: {fill}')
        beats[beat].append(raw)
        tick += n.ticks()
        if closing:
            tuplet = 0
    if tick != 4 * TPQ:
        raise ValueError(f'fill is {tick / TPQ:g} quarters long: {fill}')
    out: dict[str, str] = {}
    for drum in dict.fromkeys(plan):
        out[drum] = ' '.join(' '.join(beats[i]) if plan[i] == drum else '-4' for i in range(4))
    return out


# Trommel-Pläne je Zeile (Zählzeit 1–4). Toms und Crash immer mit `~` (Instrument-Klasse).
PLANS: list[list[str]] = [
    ['SN', 'SN', 'T1~', 'F1~'],
    ['SN', 'T1~', 'T2~', 'F1~'],
    ['SN', 'SN', 'SN', 'T1~'],
    ['T1~', 'T1~', 'F1~', 'F1~'],
    ['SN', 'SN', 'SN', 'F1~'],
    ['SN', 'T1~', 'SN', 'F1~'],
    ['T1~', 'T2~', 'F1~', 'F2~'],
    ['SN', 'T1~', 'F1~', 'SN'],
]

GROOVES: dict[str, tuple[dict[str, str], dict[str, str]]] = {  # (Takt 1 mit Crash, Time-Takt)
    'rock8': ({'C1~': C1_1, 'HH': HH8_NO1, 'SN': SN24, 'BD': BD13}, {'HH': HH8, 'SN': SN24, 'BD': BD13}),
    'rock16': ({'C1~': C1_1, 'HH': HH16_NO1, 'SN': SN24, 'BD': BD_ROCK16},
               {'HH': HH16A, 'SN': SN24, 'BD': BD_ROCK16}),
    'funk16': ({'C1~': C1_1, 'HH': HH16_NO1, 'SN': SN24, 'BD': BD_FUNK}, {'HH': HH16A, 'SN': SN24, 'BD': BD_FUNK}),
    'shuffle': ({'C1~': C1_1, 'HH': SHUF_NO1, 'SN': SN24, 'BD': BD13}, {'HH': SHUF, 'SN': SN24, 'BD': BD13}),
}


def phrase(groove: str, fill: str, plan: list[str]) -> str:
    first, time = GROOVES[groove]
    fill_bar = {**orchestrate(fill, plan), 'BD': BD13}
    return kit(first, time, time, fill_bar)


def challenge(groove: str, fill_a: str, plan_a: list[str], fill_b: str, plan_b: list[str]) -> str:
    """Acht Takte in einem kit(...)-Aufruf: zweimal drei Time-Takte und ein Fill."""
    first, time = GROOVES[groove]
    a = {**orchestrate(fill_a, plan_a), 'BD': BD13}
    b = {**orchestrate(fill_b, plan_b), 'BD': BD13}
    return kit(first, time, time, a, first, time, time, b)


def set_fill(pad_id: str, *, groove: str, name: str, description: str, lesson: dict[str, str], **kw) -> Sheet:
    fills = FILLS[pad_id]
    kw.setdefault('kit', True)
    kw.setdefault('limbs', ('allFour',))
    kw.setdefault('line_bars', 4)
    kw.setdefault('new_seed', True)
    kw.setdefault('genres', [])
    kw.setdefault('skills', ['fill', 'coordination'])
    first, _ = GROOVES[groove]
    return Sheet(
        id='set_' + pad_id, name=name, description=description, lesson=lesson,
        pattern=kit({**orchestrate(fills[0], PLANS[0]), 'BD': BD13}),
        lines=[phrase(groove, fills[i], PLANS[i]) for i in range(8)],
        challenge=challenge(groove, fills[0], PLANS[0], fills[3], PLANS[3]),
        **kw,
    )
```

Die acht Blätter (`min_bpm`/`target_bpm`/`difficulty`/`grid` wie das Pad-Original in `fills.py`, `count_lines` 0):

| Id (`set_` + Pad-Id) | Name | Groove |
|---|---|---|
| `fill_sixteenth_singles` | Sixteenth Singles Fill (Kit) | `rock8` |
| `fill_doubles` | Doubles Fill (Kit) | `rock8` |
| `fill_paradiddle` | Paradiddle Fill (Kit) | `funk16` |
| `fill_triplets` | Triplet Fill (Kit) | `shuffle` |
| `fill_flams` | Flam Fill (Kit) | `rock8` |
| `fill_sextuplets` | Sextuplet Fill (Kit) | `rock8` |
| `fill_six_groups` | Six-Note Groups Fill (Kit) | `funk16` |
| `fill_roll` | Roll Fill (Kit) | `rock16` |

Beschreibung je Blatt: ein Satz, was aus dem Pad-Blatt am Set wird („The pad fill spread over snare and toms …"); Lektion vier Abschnitte wie bei den Grooves, mit Bezug auf das Pad-Blatt gleichen Namens.

„Rund ums Set" (`set_around_the_kit`, „Around the Kit", 60–120, intermediate, `skills=['fill', 'coordination']`, grid `sixteenth`, `line_bars=2`): Zeile = `kit(first_with_cymbal, figure)`; `first_with_cymbal` = `{CYM: C1_1-artig, HH: HH8_NO1, SN: SN24, BD: BD13}` mit `CYM` = `C1~` (Zeilen 1–3), `CH` (4–6), `RB` (7–8; Glocke mit Hals oben, `RB: R4> -4 -2`); `figure` = `orchestrate(f, plan)` + `BD13` mit:

| Zeile | Figur (ein Takt) | Plan |
|---|---|---|
| 1 | `R16 L16 R16 L16` ×4 | SN T1~ T2~ F1~ |
| 2 | `R16 L16 R16 L16` ×4 | T1~ T2~ F1~ F2~ |
| 3 | `R16 L16 R16 R16 L16 R16 L16 L16` ×2 (Paradiddle) | SN T1~ SN F1~ |
| 4 | `6(R16 L16 R16 L16 R16 L16)` ×4 | SN T1~ T2~ F1~ |
| 5 | `R16> L16 R16 L16 R16 L16 R16> L16 R16 L16 R16 L16 R16> L16 R16 L16` (6-6-4) | SN SN T1~ F1~ |
| 6 | `R16 R16 L16 L16` ×4 (Doubles) | T1~ T1~ F1~ F2~ |
| 7 | `R4f> L4f> R4f> L4f>` (Flam je Trommel) | SN T1~ F1~ F2~ |
| 8 | `R16 L16 R16 L16 R16 L16 R16 L16 R32 L32 R32 L32 R32 L32 R32 L32 R16 L16 R16 L16` | SN T1~ F1~ F2~ |

Pattern = Figur der Zeile 1 mit `BD13`; Challenge = Zeilen 1, 3, 4, 8 hintereinander (acht Takte in einem `kit(...)`).

`katalog.py`: Satz `set_fills` (`step='B.4b'`, `title='Acht Fill-Blätter am Set und Rund ums Set'`, `seed_marker='PHASE B.4: kit fills'`, `sheets=set_fills.SHEETS`).

- [ ] **Step 4: Prüfen, erzeugen, formatieren**

```bash
cd tool/katalog && python3 -m unittest -v && python3 set_fills.py && cd ../..
python3 tool/katalog/gen_dart.py lib/features/lessons/data/sheets set_fills
python3 tool/katalog/patch_seed.py lib/features/lessons/data/rudiments_seed.dart
dart format lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart
flutter analyze && flutter test
```

Expected: `9 Blätter ok`; `seed patched: 27 updated, 9 added`; volle Suite grün.

- [ ] **Step 5: Commit**

```bash
git add tool/katalog/set_fills.py tool/katalog/katalog.py tool/katalog/test_kit.py lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart test/lessons/kit_seed_integrity_test.dart
git commit -m "feat(Katalog B.4b): acht Fill-Blätter mit echter Time über Snare und Toms, Crash auf der Eins, Rund ums Set"
```

---

### Task 9: Kurationsseite für Set-Blätter (abcjs, zwei Stimmen) und Sichtprüfung im Browser

**Files:**
- Modify: `tool/katalog/build_page.py` (Kit-Zeilen über `kit_line_to_abc`, `KIT_ABC_HEADER`, Legende)
- Test: Sichtprüfung mit Playwright (Screenshot), `python3 build_page.py` für alle Sätze läuft durch

**Interfaces:**
- Consumes: `kit_line_to_abc`, `KIT_ABC_HEADER`, `KitLine`, `Sheet.parsed()` (Task 6), Sätze `grooves`/`set_fills` (Task 7/8).
- Produces: `build_page.py <ausgabe.html> [grooves|set_fills]` rendert Kit-Blätter zweistimmig; Pad-Sätze unverändert.

- [ ] **Step 1: `build_page.py` erweitern**

```python
from sheetlang import KIT_ABC_HEADER, KitLine, counts_words, kit_line_to_abc, line_to_abc, sticking_words


def abc_for_kit_sheet(sheet) -> str:
    parts = []
    fill_every = 4 if sheet.line_bars == 4 else 0
    for i, ln in enumerate(sheet.parsed()):
        label = f'{i + 1} {ln.title}' if ln.title else str(i + 1)
        marks = {b: 'Fill' for b in range(ln.bars) if fill_every and (b + 1) % fill_every == 0} or None
        parts.append(f'P:{label}\\n' + kit_line_to_abc(ln, marks=marks))
    return KIT_ABC_HEADER + ''.join(parts)


def abc_for_kit_pattern(sheet) -> str:
    return KIT_ABC_HEADER + kit_line_to_abc(sheet.pattern_line())
```

In `main`: `data[s.id] = abc_for_kit_sheet(s) if s.kit else abc_for_sheet(s)` und ebenso für `_pattern`. Unter dem `lead` eine Legende für Kit-Sätze (nur wenn ein Satz `kit` enthält): „Hände Hals oben, Füße Hals unten · x = Becken/Hi-Hat · Raute = Glocke · Crash/China/Splash auf der Hilfslinie · Kick erster Zwischenraum · Pedal unter der ersten Linie". Lange Kit-Zeilen werden nicht in Reihen geteilt — abcjs bricht mit `responsive: 'resize'` selbst um (Zeilen à 4 Takte passen bei 920 px).

- [ ] **Step 2: Seite bauen und ansehen**

```bash
python3 tool/katalog/build_page.py "$CLAUDE_JOB_DIR/tmp/kit.html" grooves
python3 tool/katalog/build_page.py "$CLAUDE_JOB_DIR/tmp/kit-fills.html" set_fills
python3 tool/katalog/build_page.py "$CLAUDE_JOB_DIR/tmp/all.html"
(cd "$CLAUDE_JOB_DIR/tmp" && python3 -m http.server 8765 >/dev/null 2>&1 &)
```

Mit dem Playwright-MCP `browser_navigate` auf `http://localhost:8765/kit.html`, `browser_take_screenshot` (ganze Seite) und ansehen. Prüfen: beide Stimmen auf **einem** System; x-Köpfe für Hi-Hat/Becken (wenn abcjs `%%percmap`-Köpfe nicht setzt: normale Köpfe sind hinnehmbar, dann in `README.md` vermerken „Kurationsseite: Kopfformen nur in der App"); Kick im ersten Zwischenraum mit Hals unten; Snare im dritten Zwischenraum; „Fill" über dem vierten Takt der Fill-Blätter; keine abcjs-Fehlermeldung (rote Warnbox) auf der Seite. Dann den Server beenden (`pkill -f "http.server 8765"`).

- [ ] **Step 3: Commit**

```bash
git add tool/katalog/build_page.py tool/katalog/README.md
git commit -m "feat(katalog): Kurationsseite zweistimmig für Set-Blätter (Hände oben, Füße unten, Fill-Marke)"
```

---

### Task 10: Goldens der Grooves und Fills, Doku, Builds, Sichtprüfung im Emulator

**Files:**
- Create: `test/notation_kit_goldens_test.dart`, `test/goldens/kit_pattern_<id>.png` (9), `test/goldens/kit_sheet_groove_rock8.png`
- Modify: `docs/CLAUDE.md` (Abschnitt „Kit exercises (Etappe 2, Phase B.1/B.2/B.4)"), `README.md` (ein Satz)
- Test: volle Suite, `flutter build apk --debug`, `flutter build linux --release`, Emulator-Screenshots

- [ ] **Step 1: Golden-Test der Abnahme (Brief: „Notenbild von sechs Grooves und drei Fills als Golden-Test")**

`test/notation_kit_goldens_test.dart`:

```dart
import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() async {
    final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
    final loader = FontLoader('Bravura')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    AppTypography.label;
    await GoogleFonts.pendingFonts();
  });

  const ids = [
    'groove_rock8',
    'groove_rock16',
    'groove_halftime',
    'groove_shuffle',
    'groove_swing',
    'groove_funk16',
    'set_fill_sixteenth_singles',
    'set_fill_paradiddle',
    'set_fill_triplets',
  ];

  for (final id in ids) {
    testWidgets('golden: PATTERN bar of $id', (tester) async {
      final r = rudimentsSeedData.firstWhere((r) => r.id == id);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(width: 360, child: NotationStaffWidget(rudiment: r)))));
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(NotationStaffWidget),
          matchesGoldenFile('goldens/kit_pattern_$id.png'));
    });
  }

  testWidgets('golden: the whole Rock 8ths sheet', (tester) async {
    final r = rudimentsSeedData.firstWhere((r) => r.id == 'groove_rock8');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(width: 360, child: SheetStaffWidget(rudiment: r))))));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(SheetStaffWidget),
        matchesGoldenFile('goldens/kit_sheet_groove_rock8.png'));
  });
}
```

Run: `flutter test --update-goldens test/notation_kit_goldens_test.dart && flutter test test/notation_kit_goldens_test.dart`. Jede PNG mit dem Read-Werkzeug ansehen: Grooves mit Hi-Hat/Ride oben, Snare, Kick unten; Shuffle und Swing mit Triolenklammern; Fill-Pattern mit Toms, Crash auf der Eins (Hilfslinie) — Auffälligkeiten (überlappende Köpfe, Fahnen neben dem Hals) in Task 3 beheben und Goldens neu erzeugen.

- [ ] **Step 2: Doku**

`docs/CLAUDE.md`, neuer Abschnitt nach „Sheets (Blattform, 2026-09-30)":

```
### Kit exercises (Etappe 2, Phase B.1/B.2/B.4)
Spec: `docs/BRIEF_ETAPPE2_SET.md`, Phase B. Plan: `docs/superpowers/plans/2026-10-15-etappe2-phase-b1-set-mehrstimmig.md`.
- A kit line is `ExerciseLine.kit(voices)`: one `Voice(instrument, beats, {accepts})` per
  instrument, all of the same tick length; `beats` is the first voice. Foot voices
  (kick, hi-hat pedal) carry `hand: null` (`foot(...)` in the DSL); rests carry none.
  `Rudiment.patternVoices` is the PATTERN bar; `isKit` = `voicing == kit`;
  `requiredSensor: midi`. `InstrumentClass` (`anyTom`, `anyCrash`, `anyCymbal`) widens
  the *measured* instrument (B.3), drawing and playback use the voice's own.
- Notation (`kit_staff_painting.dart`, part of `notation_staff_widget.dart`): five
  lines, heads per `kitStaffStep` (B.2 table), hands stems up / feet stems down, one
  stem per layer and column; both layers are rhythm tracks (`layerTrack`,
  `kit_layout.dart`: onset value = gap to the next onset capped at the beat, rests
  fill the rest) laid out on one `StaffScale`, so equal ticks share x. Rows are
  `kitRowPitch` (132) high. Cursor by tick (`activeTick`), `SheetGeometry.rowOfTick`.
- Playback: `buildVoicesPlayback` mixes the voices (loudest per tick), onsets = union
  of sounding columns; `SheetPlan.voices` concatenates per instrument (rests where a
  line lacks the voice). The band keeps quiet in the voices the player plays
  (`backingKick`/`backingHihat` on `setBacking`).
- Measurement of kit exercises is **Phase B.3** (not yet): the practice screen opens
  no source for `isKit`, header `NOT MEASURABLE`, chip tooltip "Full-kit measurement
  is not available yet".
- Catalog: `tool/katalog/grooves.py` (six grooves + Open Hi-hat) and `set_fills.py`
  (eight fills with real time, Around the Kit) in the track notation (`HH: … / SN: … /
  BD: …`, `K`/`P` for feet, `~` = instrument class, see `tool/katalog/README.md`);
  generated like the pad sheets. Goldens: `test/goldens/kit_*.png`.
```

Folder Structure: `kit_layout.dart`, `kit_staff_painting.dart` unter `shared/widgets/` ergänzen. `README.md`: „… on a practice pad and, with an electronic kit via MIDI, on the full kit (grooves and fills in standard drum notation)".

- [ ] **Step 3: Suite, Builds, Emulator**

```bash
flutter analyze
flutter test
cd tool/katalog && python3 -m unittest && cd ../..
flutter build apk --debug && cp build/app/outputs/flutter-apk/app-debug.apk ~/drum-coach-set-b1.apk
flutter build linux --release
```

Expected: analyze sauber, alle Tests grün (Stand + ~45 neue), Python grün, beide Builds `✓ Built`.

Emulator (NUC, `~/bin/emu-nuc.sh`, siehe Gedächtnis „Android-Build + Emulator auf dem NUC"): APK installieren, drei Screenshots nach `$CLAUDE_JOB_DIR/tmp/emu/`: Library mit `KIT`-Badge (Filter Limbs → All four), Info-Seite „Rock 8ths Groove" (PATTERN + THE SHEET), Übungs-Screen „Paradiddle Fill (Kit)" nach Start (Cursor auf einer Spalte, Kopfzeile `NOT MEASURABLE`). Screenshots mit Read ansehen: Köpfe auf den richtigen Linien, keine Überlappung mit dem Zählband, Cursor sitzt auf einer Spalte.

- [ ] **Step 4: Commit**

```bash
git add test/notation_kit_goldens_test.dart test/goldens docs/CLAUDE.md README.md
git commit -m "docs+test(Phase B1): Goldens der sechs Grooves und drei Fills, CLAUDE.md Kit-Übungen, Builds"
```

---

## Selbstprüfung (durchgeführt beim Schreiben)

- **Spec-Abdeckung:** B.1 Stimmen-Modell → Task 1 (Modell, `Hand?`, DSL), Task 4 (`PatternPlayback` mischt, `SheetPlan`), Task 6 (sheetlang-Spuren, Rudiment-Blätter ohne Spurkopf bleiben gültig = `ExerciseLine(beats)`); B.2 Notenbild → Task 2 (Geometrie, geteilte Skala), Task 3 (Positionen/Köpfe exakt nach Tabelle, Hälse oben/unten, geteilter Hals, höhere Zeile), Task 10 (Goldens sechs Grooves + drei Fills); B.4 Set-Übungen → Task 7 (sechs Band-Muster als Grooves, Hi-Hat offen/geschlossen), Task 8 (acht Fill-Blätter mit echter Time über Snare und Toms, Crash-Abschluss, „Rund ums Set" mit Crash/China/Glocke), „Band schweigt in gespielten Stimmen" → Task 4/5; „alle über tool/katalog, kuratiert" → Task 6–9. Technische Festlegung „Golden-Tests fürs mehrstimmige Notenbild" → Task 3/10. Abnahme-Punkt „Pad-Übungen unverändert" → Regressionsschutz in Task 2 (bestehender Golden byte-gleich), Task 6 (Pad-Dart byte-gleich). **Nicht in Teil 1 (bewusst, Teil 2):** B.3 Messung pro Stimme, Instrument-Klasse in der Messung, Hand-Fuß-Versatz, Stimmen-Trefferquote; B.5 Fähigkeit pro Kontext; Rohlog für Set-Übungen.
- **Platzhalter:** keine „TBD". Die Lektionstexte und Beschreibungen der Blätter in Task 7/8 sind Inhaltsarbeit nach Vorlage (`LESSON_ROCK8`), die Zeilen aller 16 Blätter stehen als Takt-Dicts bzw. Pläne fest.
- **Typkonsistenz:** `Voice(instrument, beats, {accepts})` in Task 1/2/4/6/7; `ExerciseLine.kitVoices`/`voices`/`isKit` in 1/3/4/5; `KitLineLayout.hands/feet/handsTrack/feetTrack/handsIndexOfTick/feetIndexOfTick/columns/xOfTick/rowOfTick` in 2/3; `SheetGeometry.kitLayouts/rowOfTick` in 3/5; `buildVoicesPlayback`, `SheetPlan.voices/locateTick/playsKick/playsHihat/isKit` in 4/5; `setBacking(backingKick:, backingHihat:)` in 4/5; `kitStaffStep`/`kitHeadShape` in 3/10; `foot`/`voice`/`kitLine`/`kitBarsOrThrow` in 1/3/4/7/8; Python `parse_kit_line`/`KitLine`/`Track`/`kit_line_to_dart`/`kit_line_to_abc`/`KIT_ABC_HEADER`/`orchestrate`/`kit` in 6/7/8/9.
- **Review Focus:** 1 → Task 2 („shared column", Buchstabe null) + Golden Task 3; 2 → Task 4 (`wholeSheet` rest fill, `locateTick`); 3 → Task 2 („gap of 42 ticks"); 4 → Task 4 (`buildLoopPlan` both muted) + Task 5 („mutes the band voices"); 5 → Task 5 („opens no stroke source", Tooltip).
