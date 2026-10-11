# Etappe 2 / Phase A — Set-Minimum: Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Alle vorhandenen Übungen laufen am E-Set, gemessen über MIDI statt Mikrofon, auf dem Linux-Laptop und auf dem S23 per OTG, mit Lernschritt für das volle Set, Latenz-Abgleich, Sensorstufe und erweitertem Rohlog.

**Architecture:** Eine Schnittstelle `StrokeSource` mit zwei Umsetzungen (Mikrofon, MIDI) liefert `StrokeEvent`s (Zeit auf der Epoche-Millisekunden-Achse, Instrument, Velocity). Der heutige Analyse-Kern aus `MicAnalysisService.analyzeHits` zieht nach `stroke_analysis.dart` um und arbeitet auf `StrokeEvent`s, gefiltert auf das erwartete Instrument; `analyzeHits` bleibt als dünne Hülle, damit die Etappe-1-Tests unverändert grün bleiben. MIDI kommt über `flutter_midi_command` 1.4.0; der Linux-Teil liegt als gepatchte Kopie unter `packages/` (Stempel im Empfangs-Isolate, virtuelle Ports sichtbar; Befund §0).

**Tech Stack:** Flutter 3.44 / Dart 3, Riverpod, Isar 3, shared_preferences, `flutter_midi_command` 1.4.0 (+ `flutter_midi_command_linux` 1.4.0 gepatcht), Python 3 für den Linux-Integrationstest (ALSA virmidi).

**Spec:** `docs/BRIEF_ETAPPE2_SET.md` (Phase A, Entscheidungen, Technische Festlegungen) und `docs/BERICHT_ETAPPE2_§0.md` (Zeitbasis, Plugin-Patch).

## Global Constraints

- Zeitachse aller Schlag- und Klickzeiten: **Epoche-Millisekunden als `double`** (wie `BeatRecord.timestamp` und `SessionLog.clickTimesMs`); Rohlog speichert Zeiten **ohne** Latenz-Korrektur, der angewandte Versatz steht im Kopf (Etappe 1, Phase 2).
- MIDI-Zeitstempel **nie im Haupt-Isolate** nehmen (§0). Linux: µs-Epoche aus dem gepatchten Empfangs-Isolate. Android: Zeitstempel des Systems (ns, monoton), per `MidiTimestampMapper` auf die Epoche-Achse gebracht.
- MIDI-Quelle: Note-On mit Velocity > 0 zählt; Note-Off, Velocity 0, Aftertouch, Controller werden verworfen; **kein Mindestabstand** zwischen Ereignissen (Flams sind zwei Noten).
- Mikrofon-Schwellen (`minStrokeLevel = 0.18`, Onset-Detektor) bleiben **nur** in der Mikrofon-Quelle.
- `KitInstrument` trägt General-MIDI-Nummern (Tabelle A.2 im Brief). Vorgabe-Zuordnung ist General MIDI.
- Einstellung „Messung": `auto` (Vorgabe) | `mic` | `midi` | `off`. Auf dem Desktop ist das Mikrofon nur bei ausdrücklicher Wahl `mic` aktiv.
- `requiredSensor` je Übung: `none` | `mic` | `midi`; MIDI erfüllt `mic`, Mikrofon erfüllt nicht `midi`. Nicht erfüllt ⇒ „not measurable with this setup", keine Zahl, üben geht.
- Kopfhörer-Regel (Band/Klick nur mit Kopfhörer) gilt **nur**, wenn die Mikrofon-Quelle aktiv ist.
- Plattform-Weichen ausschließlich über `lib/app/platform_support.dart`; keine verstreuten `Platform.is*`.
- Alle UI-Strings Englisch (Code Style der App). Keine neuen Pakete außer `flutter_midi_command` (exakt `1.4.0`); kein BLE-Paket.
- Jede Aufgabe: Test zuerst, dann Code, `flutter analyze` ohne neue Warnungen, `flutter test` grün, Commit.
- Basis-Branch: `main` nach Merge von #30 und #32; sind sie beim Start offen, von `main` branchen (siehe Brief „Leitprinzip").

## Review Focus

1. **Flam am Set:** Vorschlag + Hauptschlag kommen als zwei MIDI-Noten 20–30 ms auseinander; der Vorschlag darf weder Treffer noch Zusatzschlag sein, der Hauptschlag muss treffen. Test in Task 4 (`splitGraceEvents`, „flam played").
2. **Gerät während der Sitzung abgezogen:** Die Sitzung läuft weiter, am Ende keine Zahl, sondern „MIDI device lost — not measurable", Rohlog mit dem bis dahin Gesammelten. Test in Task 9 (`MidiStrokeSource` lost device) und Task 11 (Announcement).
3. **Kick/Hi-Hat während einer Snare-Übung:** landen im Rohlog mit Instrument, zählen nicht als Zusatzschläge. Test in Task 4 („off-instrument events are logged, not counted").
4. **Modul sendet eine Note, die zwei Instrumenten zugeordnet wurde:** Der Lernschritt hängt die Note um, nie doppelt. Test in Task 2 (`KitMapping.assign` moves note).
5. **Alter Schalter „Microphone analysis = aus":** Nach dem Update darf die Messung nicht plötzlich anspringen; die Migration liest den alten Schlüssel. Test in Task 7 (`measurementSource` migration).

---

## Dateistruktur

**Neu**

| Datei | Verantwortung |
|---|---|
| `packages/flutter_midi_command_linux/` | Gepatchte Kopie 1.4.0 (zwei Patches aus §0) + `PATCH.md` |
| `lib/features/coaching/midi/kit_instrument.dart` | `KitInstrument` (GM-Nummern, Labels, Lernreihenfolge), `KitMapping` (Note ↔ Instrument, JSON) |
| `lib/features/coaching/services/stroke_source.dart` | `StrokeEvent`, `StrokeSourceKind`, `StrokeSourceStatus`, `SensorLevel`, `StrokeSource` (abstrakt) |
| `lib/features/coaching/services/stroke_analysis.dart` | `analyzeStrokes` (Analyse-Kern), `splitGraceEvents`, `accentAnalysis` |
| `lib/features/coaching/services/mic_stroke_source.dart` | `MicStrokeSource` (Hülle um `MicAnalysisService`) |
| `lib/features/coaching/midi/midi_timestamp_mapper.dart` | `MidiTimestampMapper` (Bibliotheks-Stempel → Epoche-ms) |
| `lib/features/coaching/midi/midi_port_service.dart` | `MidiPortService` (Geräte, Verbindung, Note-On-Strom), `parseNoteOn`, `chooseMidiDevice` |
| `lib/features/coaching/midi/midi_stroke_source.dart` | `MidiStrokeSource` (Note-On → `StrokeEvent`, Status, Geräteverlust) |
| `lib/features/coaching/midi/midi_latency.dart` | `estimateMidiLatency` (Schläge auf Klick → Versatz + Streuung) |
| `lib/features/coaching/midi/kit_learn_session.dart` | `KitLearnSession` (reiner Zustandsautomat des Lernschritts) |
| `lib/features/settings/kit_learn_screen.dart` | Lernschritt-Screen |
| `lib/features/settings/midi_calibration_screen.dart` | MIDI-Latenz-Abgleich-Screen |
| `lib/app/platform_support.dart` | `isDesktopPlatform`, `aiCoachingAvailable`, `localNotificationsAvailable`, `desktopContentMaxWidth` |
| `test/integration_linux/midi_virtual_port_test.dart`, `tool/midi/virtual_port_test.sh` | Linux-Integrationstest über virtuellen ALSA-Port |

**Geändert**

| Datei | Änderung |
|---|---|
| `pubspec.yaml` | `flutter_midi_command: 1.4.0`, `dependency_overrides` auf `packages/flutter_midi_command_linux` |
| `lib/features/coaching/models/session_analysis.dart` | `OnsetEventData` + `instrument`, `rawNote`, `grace`; `SessionAnalysis` + `source`, `velocityExact`, `accents`, `notMeasurable`; neu `AccentAnalysis` |
| `lib/features/coaching/services/mic_analysis_service.dart` | `strokeEvents`-Getter; `analyzeHits` delegiert an `analyzeStrokes` |
| `lib/features/lessons/models/rudiment.dart` | `Rudiment.requiredSensor` |
| `lib/data/local/models/session_log.dart`, `session_log_codec.dart`, `session_log_service.dart` | Kopf + `source`, `midiDevice`, `kitMapping`; `OnsetEvent` + `instrument`, `rawNote`, `grace` |
| `lib/data/local/settings_service.dart` | `measurementSource` (+Migration), `midiLastDeviceId`, `kitMappingFor`, `midiLatencyOffsetMsFor`, `padRoleInstrument` |
| `lib/features/practice/practice_session_screen.dart` | Quellenwahl, Messung, Chip, Analyse über `analyzeStrokes`, Log-Felder, Tastenkürzel |
| `lib/features/practice/analysis_announcement.dart`, `widgets/result_sheet.dart` | „not measurable", Akzent-Zeile |
| `lib/features/settings/settings_screen.dart` | Abschnitt MEASUREMENT, KI-Coaching auf Desktop aus |
| `lib/app/router.dart`, `lib/main.dart`, `lib/services/notification_service.dart` | Routen, Breitendeckel, Notifications No-Op |
| `linux/runner/my_application.cc` | Mindest-Fenstergröße |
| `android/app/src/main/AndroidManifest.xml` | `uses-feature usb.host` (nicht zwingend) |
| `docs/CLAUDE.md` | Messquellen, Linux-Build, MIDI-Test |

---

### Task 1: Gepatchte Linux-MIDI-Kopie und Paket einbinden

**Files:**
- Create: `packages/flutter_midi_command_linux/` (Kopie von `~/.pub-cache/hosted/pub.dev/flutter_midi_command_linux-1.4.0`), `packages/flutter_midi_command_linux/PATCH.md`
- Modify: `pubspec.yaml`
- Test: `test/midi/vendored_plugin_test.dart`

**Interfaces:**
- Produces: `package:flutter_midi_command/flutter_midi_command.dart` (`MidiCommand`, `MidiDevice`, `MidiPacket` mit `data`, `timestamp`, `device`; `onMidiPacketReceived`, `onMidiSetupChanged`, `devices`, `connectToDevice`, `disconnectDevice`); unter Linux liefert `MidiPacket.timestamp` **Epoche-Mikrosekunden** aus dem Empfangs-Isolate.

- [ ] **Step 1: Paket hinzufügen und Kopie anlegen**

```bash
flutter pub add flutter_midi_command:1.4.0
mkdir -p packages
cp -r ~/.pub-cache/hosted/pub.dev/flutter_midi_command_linux-1.4.0 packages/flutter_midi_command_linux
rm -rf packages/flutter_midi_command_linux/example
python3 -I tool/midi/spike/patch_plugin.py packages/flutter_midi_command_linux/lib/src/alsa_seq_linux_device.dart
python3 -I tool/midi/spike/patch_plugin2.py packages/flutter_midi_command_linux/lib/src/alsa_seq_linux_device.dart
```

Erwartung: beide Skripte melden „Plugin gepatcht" bzw. „Filter gelockert". Prüfen: `grep -n "rxUs" packages/flutter_midi_command_linux/lib/src/alsa_seq_linux_device.dart` zeigt drei Treffer, `grep -n "message.length == 5"` einen.

- [ ] **Step 2: Override in pubspec.yaml eintragen**

Am Ende von `pubspec.yaml` (nach dem `flutter:`-Block) ergänzen:

```yaml
dependency_overrides:
  # §0 (docs/BERICHT_ETAPPE2_§0.md): timestamp taken in the receive isolate,
  # virtual (virmidi) ports visible. Upstream PR pending; see packages/…/PATCH.md.
  flutter_midi_command_linux:
    path: packages/flutter_midi_command_linux
```

Dann `flutter pub get`; Erwartung: keine Fehler, `flutter_midi_command_linux 1.4.0 from path packages/flutter_midi_command_linux` in der Ausgabe.

- [ ] **Step 3: PATCH.md schreiben**

`packages/flutter_midi_command_linux/PATCH.md`:

```markdown
# Lokaler Patch gegenüber flutter_midi_command_linux 1.4.0

Grund: docs/BERICHT_ETAPPE2_§0.md. Zwei Änderungen in
`lib/src/alsa_seq_linux_device.dart`:

1. `_seqRxIsolateEntry`: `rxUs = DateTime.now().microsecondsSinceEpoch` direkt
   nach `snd_seq_event_input`, als fünftes Element der `'midi'`-Nachricht;
   der Listener im Haupt-Isolate übernimmt es als `timestamp` (statt
   `DateTime.now().millisecondsSinceEpoch` dort). Ergebnis: Stempel in µs
   Epoche, unabhängig von der Last des Haupt-Isolates.
2. Geräte-Erkennung: Ports ohne `SND_SEQ_PORT_TYPE_HARDWARE` erscheinen,
   wenn sie `SND_SEQ_PORT_TYPE_MIDI_GENERIC` tragen (virtuelle Ports für den
   Integrationstest).

Beim Update der Bibliothek beide Stellen neu anwenden
(`tool/midi/spike/patch_plugin.py`, `patch_plugin2.py`) oder den
Upstream-Stand prüfen.
```

- [ ] **Step 4: Test schreiben, dass der Patch wirklich im Build steckt**

`test/midi/vendored_plugin_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vendored flutter_midi_command_linux carries the §0 patch', () {
    final src = File(
            'packages/flutter_midi_command_linux/lib/src/alsa_seq_linux_device.dart')
        .readAsStringSync();
    expect(src, contains('final rxUs = DateTime.now().microsecondsSinceEpoch;'));
    expect(src, contains("tag == 'midi' && message.length == 5"));
    expect(src, contains('SND_SEQ_PORT_TYPE_MIDI_GENERIC) == 0'));
    expect(src, isNot(contains(
        'final timestamp = DateTime.now().millisecondsSinceEpoch;')));
  });

  test('pubspec overrides the linux implementation with the vendored copy', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('flutter_midi_command: 1.4.0'));
    expect(pubspec, contains('path: packages/flutter_midi_command_linux'));
  });
}
```

- [ ] **Step 5: Tests laufen lassen**

Run: `flutter test test/midi/vendored_plugin_test.dart`
Expected: 2 PASS. Dann `flutter analyze` — keine neuen Meldungen (die Kopie unter `packages/` wird nicht analysiert, weil sie kein Teil des Pakets ist; falls doch, in `analysis_options.yaml` unter `analyzer: exclude:` den Eintrag `packages/**` ergänzen).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml packages/flutter_midi_command_linux test/midi/vendored_plugin_test.dart analysis_options.yaml
git commit -m "build(midi): flutter_midi_command 1.4.0 + gepatchte Linux-Kopie (§0: Stempel im Rx-Isolate, virtuelle Ports)"
```

---

### Task 2: Instrument-Modell `KitInstrument` und `KitMapping`

**Files:**
- Create: `lib/features/coaching/midi/kit_instrument.dart`
- Test: `test/midi/kit_instrument_test.dart`

**Interfaces:**
- Produces:
  - `enum KitInstrument { kick, snare, snareRim, hiHatClosed, hiHatOpen, hiHatPedal, tom1, tom2, floorTom1, floorTom2, crash1, crash2, ride, rideBell, china, splash, pad }` mit `int? gmNote`, `String label`, `static const List<KitInstrument> learnOrder`, `static KitInstrument? fromName(String)`.
  - `class KitMapping { Map<KitInstrument, Set<int>> get notes; KitInstrument? instrumentFor(int note); KitMapping assign(KitInstrument i, int note); KitMapping remove(KitInstrument i); factory KitMapping.gm(); Map<String, Object> toJson(); factory KitMapping.fromJson(Map<String, Object?>); String encode(); factory KitMapping.decode(String); }`

- [ ] **Step 1: Failing test**

`test/midi/kit_instrument_test.dart`:

```dart
import 'dart:convert';

import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KitInstrument', () {
    test('carries the General MIDI defaults from the brief', () {
      expect(KitInstrument.kick.gmNote, 36);
      expect(KitInstrument.snare.gmNote, 38);
      expect(KitInstrument.snareRim.gmNote, 37);
      expect(KitInstrument.hiHatClosed.gmNote, 42);
      expect(KitInstrument.hiHatOpen.gmNote, 46);
      expect(KitInstrument.hiHatPedal.gmNote, 44);
      expect(KitInstrument.tom1.gmNote, 48);
      expect(KitInstrument.tom2.gmNote, 47);
      expect(KitInstrument.floorTom1.gmNote, 45);
      expect(KitInstrument.floorTom2.gmNote, 43);
      expect(KitInstrument.crash1.gmNote, 49);
      expect(KitInstrument.crash2.gmNote, 57);
      expect(KitInstrument.ride.gmNote, 51);
      expect(KitInstrument.rideBell.gmNote, 53);
      expect(KitInstrument.china.gmNote, 52);
      expect(KitInstrument.splash.gmNote, 55);
      expect(KitInstrument.pad.gmNote, isNull);
    });

    test('learn order starts with snare and kick and never contains pad', () {
      expect(KitInstrument.learnOrder.first, KitInstrument.snare);
      expect(KitInstrument.learnOrder[1], KitInstrument.kick);
      expect(KitInstrument.learnOrder, isNot(contains(KitInstrument.pad)));
      expect(KitInstrument.learnOrder.length, 16);
    });

    test('fromName round-trips and rejects unknown names', () {
      expect(KitInstrument.fromName('floorTom2'), KitInstrument.floorTom2);
      expect(KitInstrument.fromName('bongo'), isNull);
    });
  });

  group('KitMapping', () {
    test('GM default maps every instrument note and nothing else', () {
      final m = KitMapping.gm();
      expect(m.instrumentFor(38), KitInstrument.snare);
      expect(m.instrumentFor(36), KitInstrument.kick);
      expect(m.instrumentFor(99), isNull);
      expect(m.notes[KitInstrument.pad], isNull);
    });

    test('assign moves a note away from its previous instrument', () {
      // The module sends 38 for the snare head AND the user maps 38 to the
      // rim by mistake: the note must live in exactly one place.
      final m = KitMapping.gm().assign(KitInstrument.snareRim, 38);
      expect(m.instrumentFor(38), KitInstrument.snareRim);
      expect(m.notes[KitInstrument.snare], isEmpty);
      // Original mapping is untouched (value semantics).
      expect(KitMapping.gm().instrumentFor(38), KitInstrument.snare);
    });

    test('assign adds a second zone to the same instrument', () {
      final m = KitMapping.gm().assign(KitInstrument.snare, 40);
      expect(m.notes[KitInstrument.snare], {38, 40});
      expect(m.instrumentFor(40), KitInstrument.snare);
    });

    test('remove clears an instrument', () {
      final m = KitMapping.gm().remove(KitInstrument.splash);
      expect(m.notes[KitInstrument.splash], isEmpty);
      expect(m.instrumentFor(55), isNull);
    });

    test('json round-trip keeps every note', () {
      final m = KitMapping.gm().assign(KitInstrument.snare, 40);
      final back = KitMapping.decode(m.encode());
      expect(back.notes, m.notes);
      expect(jsonDecode(m.encode()), isA<Map<String, Object?>>());
    });

    test('decode tolerates unknown instrument names and bad values', () {
      final back = KitMapping.decode('{"snare":[38,"x"],"bongo":[60]}');
      expect(back.notes[KitInstrument.snare], {38});
      expect(back.instrumentFor(60), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/midi/kit_instrument_test.dart`
Expected: FAIL, „Target of URI doesn't exist".

- [ ] **Step 3: Implementation**

`lib/features/coaching/midi/kit_instrument.dart`:

```dart
import 'dart:convert';

/// Every instrument of a full kit (Brief Etappe 2, A.2) with its General
/// MIDI default note. `pad` is the microphone's "instrument": one voice,
/// no note number.
enum KitInstrument {
  kick(36, 'Kick'),
  snare(38, 'Snare'),
  snareRim(37, 'Snare rim / cross-stick'),
  hiHatClosed(42, 'Hi-hat closed'),
  hiHatOpen(46, 'Hi-hat open'),
  hiHatPedal(44, 'Hi-hat pedal'),
  tom1(48, 'Tom 1 (high rack)'),
  tom2(47, 'Tom 2 (low rack)'),
  floorTom1(45, 'Floor tom 1 (high)'),
  floorTom2(43, 'Floor tom 2 (low)'),
  crash1(49, 'Crash 1'),
  crash2(57, 'Crash 2'),
  ride(51, 'Ride'),
  rideBell(53, 'Ride bell'),
  china(52, 'China'),
  splash(55, 'Splash'),
  pad(null, 'Pad (microphone)');

  const KitInstrument(this.gmNote, this.label);

  /// General MIDI percussion note, null for the microphone pad.
  final int? gmNote;
  final String label;

  /// Order of the learn step ("hit the …"): set order from the brief.
  static const List<KitInstrument> learnOrder = [
    snare,
    kick,
    hiHatClosed,
    hiHatOpen,
    hiHatPedal,
    tom1,
    tom2,
    floorTom1,
    floorTom2,
    crash1,
    crash2,
    ride,
    rideBell,
    china,
    splash,
    snareRim,
  ];

  static KitInstrument? fromName(String name) {
    for (final i in values) {
      if (i.name == name) return i;
    }
    return null;
  }
}

/// Which MIDI notes a module sends for each instrument. A pad may send
/// several notes (head and rim zones); a note belongs to at most one
/// instrument. Immutable: every change returns a new mapping.
class KitMapping {
  KitMapping._(Map<KitInstrument, Set<int>> notes)
      : _notes = {
          for (final e in notes.entries) e.key: Set.unmodifiable(e.value),
        };

  final Map<KitInstrument, Set<int>> _notes;

  Map<KitInstrument, Set<int>> get notes => Map.unmodifiable(_notes);

  /// General MIDI defaults — what nearly every module sends out of the box.
  factory KitMapping.gm() => KitMapping._({
        for (final i in KitInstrument.values)
          if (i.gmNote != null) i: {i.gmNote!},
      });

  KitInstrument? instrumentFor(int note) {
    for (final e in _notes.entries) {
      if (e.value.contains(note)) return e.key;
    }
    return null;
  }

  /// Puts [note] on [instrument]; a note already used elsewhere moves.
  KitMapping assign(KitInstrument instrument, int note) {
    final next = {
      for (final e in _notes.entries)
        e.key: {for (final n in e.value) if (n != note) n},
    };
    next[instrument] = {...(next[instrument] ?? const <int>{}), note};
    return KitMapping._(next);
  }

  KitMapping remove(KitInstrument instrument) =>
      KitMapping._({..._notes, instrument: const <int>{}});

  Map<String, Object> toJson() => {
        for (final e in _notes.entries)
          if (e.value.isNotEmpty) e.key.name: (e.value.toList()..sort()),
      };

  factory KitMapping.fromJson(Map<String, Object?> json) {
    final notes = <KitInstrument, Set<int>>{
      for (final i in KitInstrument.values)
        if (i != KitInstrument.pad) i: <int>{},
    };
    for (final e in json.entries) {
      final instrument = KitInstrument.fromName(e.key);
      final raw = e.value;
      if (instrument == null || raw is! List) continue;
      notes[instrument] = {for (final n in raw) if (n is int) n};
    }
    return KitMapping._(notes);
  }

  String encode() => jsonEncode(toJson());

  factory KitMapping.decode(String s) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, Object?>) return KitMapping.fromJson(decoded);
    } catch (_) {}
    return KitMapping.gm();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/midi/kit_instrument_test.dart`
Expected: 9 PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/coaching/midi/kit_instrument.dart test/midi/kit_instrument_test.dart
git commit -m "feat(midi): KitInstrument mit GM-Nummern und KitMapping (Zuordnung, JSON)"
```

---

### Task 3: Schlagquellen-Typen und `requiredSensor` an der Übung

**Files:**
- Create: `lib/features/coaching/services/stroke_source.dart`
- Modify: `lib/features/lessons/models/rudiment.dart` (Klasse `Rudiment`: Feld, Konstruktor, `withSticking`)
- Test: `test/coaching/stroke_source_test.dart`, `test/lessons/rudiment_sensor_test.dart`

**Interfaces:**
- Produces:
  - `enum StrokeSourceKind { mic, midi }`
  - `enum StrokeSourceStatus { ready, noDevice, notMeasurable }`
  - `enum SensorLevel { none, mic, midi }` mit `bool satisfiedBy(StrokeSourceKind? active)`
  - `class StrokeEvent { final double timeMs; final KitInstrument instrument; final double velocity; final int? rawNote; final StrokeSourceKind source; }`
  - `abstract class StrokeSource { StrokeSourceKind get kind; bool get velocityExact; StrokeSourceStatus get status; Stream<StrokeSourceStatus> get statusChanges; String? get deviceName; Future<void> start(); Future<void> stop(); List<StrokeEvent> get events; Map<String, Object>? describeSetup(); void dispose(); }`
  - `Rudiment.requiredSensor` (`SensorLevel`, Vorgabe `SensorLevel.mic`)

- [ ] **Step 1: Failing tests**

`test/coaching/stroke_source_test.dart`:

```dart
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SensorLevel: midi satisfies mic, mic does not satisfy midi', () {
    expect(SensorLevel.none.satisfiedBy(null), isTrue);
    expect(SensorLevel.mic.satisfiedBy(null), isFalse);
    expect(SensorLevel.mic.satisfiedBy(StrokeSourceKind.mic), isTrue);
    expect(SensorLevel.mic.satisfiedBy(StrokeSourceKind.midi), isTrue);
    expect(SensorLevel.midi.satisfiedBy(StrokeSourceKind.mic), isFalse);
    expect(SensorLevel.midi.satisfiedBy(StrokeSourceKind.midi), isTrue);
  });

  test('StrokeEvent is a plain value with raw epoch time', () {
    const e = StrokeEvent(
      timeMs: 1700000000000.25,
      instrument: KitInstrument.snare,
      velocity: 0.8,
      rawNote: 38,
      source: StrokeSourceKind.midi,
    );
    expect(e.timeMs, 1700000000000.25);
    expect(e.instrument, KitInstrument.snare);
    expect(e.source, StrokeSourceKind.midi);
    expect(e.toString(), contains('snare'));
  });
}
```

`test/lessons/rudiment_sensor_test.dart`:

```dart
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const r = Rudiment(
    id: 'x',
    name: 'X',
    description: '',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: [StrokeBeat(hand: Hand.right), StrokeBeat(hand: Hand.left)],
  );

  test('pad exercises require the microphone level by default', () {
    expect(r.requiredSensor, SensorLevel.mic);
  });

  test('withSticking keeps the sensor level', () {
    const kit = Rudiment(
      id: 'k',
      name: 'K',
      description: '',
      minBpm: 60,
      targetBpm: 120,
      difficulty: Difficulty.beginner,
      sticking: [StrokeBeat(hand: Hand.right)],
      requiredSensor: SensorLevel.midi,
    );
    expect(kit.withSticking(const [StrokeBeat(hand: Hand.left)]).requiredSensor,
        SensorLevel.midi);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/coaching/stroke_source_test.dart test/lessons/rudiment_sensor_test.dart`
Expected: FAIL (URI/`requiredSensor` unbekannt). Prüfe vorher, dass `Difficulty.beginner` existiert: `grep -n "enum Difficulty" -A3 lib/features/lessons/models/rudiment.dart`; sonst den ersten Enum-Wert einsetzen.

- [ ] **Step 3: Implementation**

`lib/features/coaching/services/stroke_source.dart`:

```dart
import '../midi/kit_instrument.dart';

/// Where strokes come from (Brief Etappe 2, A.1).
enum StrokeSourceKind { mic, midi }

enum StrokeSourceStatus { ready, noDevice, notMeasurable }

/// Sensor level an exercise or gate needs (Brief A.6). MIDI satisfies the
/// microphone level; the microphone never satisfies MIDI.
enum SensorLevel {
  none,
  mic,
  midi;

  bool satisfiedBy(StrokeSourceKind? active) => switch (this) {
        SensorLevel.none => true,
        SensorLevel.mic => active != null,
        SensorLevel.midi => active == StrokeSourceKind.midi,
      };
}

/// One stroke on the shared time axis: raw epoch milliseconds (no latency
/// correction), the instrument that was hit, its strength 0–1, the MIDI
/// note it came from (null for the microphone) and the source.
class StrokeEvent {
  final double timeMs;
  final KitInstrument instrument;
  final double velocity;
  final int? rawNote;
  final StrokeSourceKind source;

  const StrokeEvent({
    required this.timeMs,
    required this.instrument,
    required this.velocity,
    required this.rawNote,
    required this.source,
  });

  @override
  String toString() =>
      'StrokeEvent(${timeMs.toStringAsFixed(1)} ${instrument.name} '
      'v=${velocity.toStringAsFixed(2)} note=$rawNote ${source.name})';
}

/// A stroke source collects [StrokeEvent]s between [start] and [stop].
/// Neither implementation knows hands — the hand comes from the sticking
/// via the sequence alignment (Etappe 1, §1.2).
abstract class StrokeSource {
  StrokeSourceKind get kind;

  /// True when [StrokeEvent.velocity] is an exact measurement (MIDI), false
  /// for the microphone's rough peak level.
  bool get velocityExact;

  StrokeSourceStatus get status;
  Stream<StrokeSourceStatus> get statusChanges;

  /// Device label for the session log header, null for the microphone.
  String? get deviceName;

  Future<void> start();
  Future<void> stop();

  /// Events collected since [start], raw times, all instruments.
  List<StrokeEvent> get events;

  /// Header fields for the raw log (`audioSource`, `sampleRate`, …).
  Map<String, Object>? describeSetup();

  void dispose();
}
```

In `lib/features/lessons/models/rudiment.dart`:

1. Import oben ergänzen: `import '../../coaching/services/stroke_source.dart';`
2. In `class Rudiment` nach `final String? backing;` einfügen:

```dart
  /// Sensor level this exercise needs to be measured (Brief Etappe 2, A.6).
  /// Pad exercises need the microphone; MIDI satisfies it as well.
  final SensorLevel requiredSensor;
```

3. Im Konstruktor nach `this.backing,` ergänzen: `this.requiredSensor = SensorLevel.mic,`
4. In `withSticking` nach `voicing: voicing,` ergänzen: `requiredSensor: requiredSensor,`

- [ ] **Step 4: Run tests**

Run: `flutter test test/coaching/stroke_source_test.dart test/lessons/rudiment_sensor_test.dart`
Expected: 4 PASS. Dann `flutter test` komplett: alle grün (die Vorgabe ändert kein Verhalten).

- [ ] **Step 5: Commit**

```bash
git add lib/features/coaching/services/stroke_source.dart lib/features/lessons/models/rudiment.dart test/coaching/stroke_source_test.dart test/lessons/rudiment_sensor_test.dart
git commit -m "feat(coaching): StrokeSource-Typen, SensorLevel und requiredSensor an der Übung"
```

---

### Task 4: Analyse-Kern auf `StrokeEvent` umziehen (`analyzeStrokes`, Vorschläge, Fremdinstrumente)

**Files:**
- Create: `lib/features/coaching/services/stroke_analysis.dart`
- Modify: `lib/features/coaching/models/session_analysis.dart` (`OnsetEventData`, `SessionAnalysis`), `lib/features/coaching/services/mic_analysis_service.dart` (`analyzeHits` wird Hülle, neuer Getter `strokeEvents`)
- Test: `test/coaching/stroke_analysis_test.dart`; bestehende `test/coaching/mic_analysis_test.dart` bleibt unverändert grün

**Interfaces:**
- Consumes: `StrokeEvent`, `StrokeSourceKind`, `KitInstrument` (Task 2, 3); `BeatRecord`, `alignSequences`, `detectLapses`, `computeUnassignedMetrics`, `MicAnalysisService.minStrokeLevel`, `jitterGateMs`.
- Produces:
  - `SessionAnalysis analyzeStrokes({required List<StrokeEvent> events, required List<BeatRecord> beatLog, required List<StrokeBeat> sticking, required StrokeSourceKind source, KitInstrument expectedInstrument = KitInstrument.pad, double latencyOffsetMs = 0, bool analysisMode = false, Map<String, Object>? recordingSetup, double graceWindowMs = 40})`
  - `({List<StrokeEvent> main, List<StrokeEvent> grace}) splitGraceEvents({required List<StrokeEvent> events, required List<double> expectedMs, required List<bool> hasGrace, double windowMs = 40})` — Zeiten hier bereits latenzkorrigiert.
  - `OnsetEventData` + `String? instrument`, `int? rawNote`, `bool grace` (Vorgabe false)
  - `SessionAnalysis` + `StrokeSourceKind? source`, `bool velocityExact` (false), `bool notMeasurable` (false), `AccentAnalysis? accents` (Task 5 füllt es; hier nur das Feld mit `null`)
  - `class AccentAnalysis { final double accentRatio; final int accentsLouder; final int accentCount; }` (Definition hier, Berechnung Task 5)
  - `MicAnalysisService.strokeEvents` (`List<StrokeEvent>`, Epoche-ms, Instrument `pad`)

- [ ] **Step 1: Failing tests**

`test/coaching/stroke_analysis_test.dart`:

```dart
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/mic_analysis_service.dart';
import 'package:drum_coach/features/coaching/services/stroke_analysis.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const t0 = 1700000000000.0; // epoch ms
  const rlrl = [
    StrokeBeat(hand: Hand.right),
    StrokeBeat(hand: Hand.left),
    StrokeBeat(hand: Hand.right),
    StrokeBeat(hand: Hand.left),
  ];

  List<BeatRecord> beats(List<double> relMs) => [
        for (var i = 0; i < relMs.length; i++)
          (
            beatIndex: i,
            timestamp: DateTime.fromMicrosecondsSinceEpoch(
                ((t0 + relMs[i]) * 1000).round()),
          ),
      ];

  StrokeEvent midi(double relMs,
          {KitInstrument instrument = KitInstrument.snare,
          double velocity = 0.8,
          int rawNote = 38}) =>
      StrokeEvent(
        timeMs: t0 + relMs,
        instrument: instrument,
        velocity: velocity,
        rawNote: rawNote,
        source: StrokeSourceKind.midi,
      );

  group('splitGraceEvents', () {
    test('flam played: the earlier of two notes in the window is the grace',
        () {
      final r = splitGraceEvents(
        events: [midi(475), midi(500)],
        expectedMs: const [t0 + 500],
        hasGrace: const [true],
      );
      expect(r.grace.map((e) => e.timeMs), [t0 + 475]);
      expect(r.main.map((e) => e.timeMs), [t0 + 500]);
    });

    test('flam not played: the single note stays the main stroke', () {
      final r = splitGraceEvents(
        events: [midi(492)],
        expectedMs: const [t0 + 500],
        hasGrace: const [true],
      );
      expect(r.grace, isEmpty);
      expect(r.main.length, 1);
    });

    test('no grace expected: two close notes are both main (extra counts)',
        () {
      final r = splitGraceEvents(
        events: [midi(475), midi(500)],
        expectedMs: const [t0 + 500],
        hasGrace: const [false],
      );
      expect(r.grace, isEmpty);
      expect(r.main.length, 2);
    });

    test('neighbouring sixteenths at 200 BPM are not swallowed as graces',
        () {
      // 75 ms apart: outside the ±40 ms window of each other.
      final r = splitGraceEvents(
        events: [midi(425), midi(500)],
        expectedMs: const [t0 + 425, t0 + 500],
        hasGrace: const [true, true],
      );
      expect(r.grace, isEmpty);
      expect(r.main.length, 2);
    });
  });

  group('analyzeStrokes (midi)', () {
    test('clean snare run through MIDI: hand values, velocityExact, source',
        () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [for (final g in grid) midi(g + 5)],
        beatLog: beats(grid),
        sticking: rlrl,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
        analysisMode: true,
      );
      expect(a.source, StrokeSourceKind.midi);
      expect(a.velocityExact, isTrue);
      expect(a.alignment!.hitCount, 8);
      expect(a.timing!.overallDeviationMs, closeTo(5, 0.5));
      expect(a.events.every((e) => e.instrument == 'snare'), isTrue);
      expect(a.events.first.rawNote, 38);
    });

    test('off-instrument events are logged, not counted as extras', () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [
          for (final g in grid) midi(g),
          for (final g in grid)
            midi(g + 250, instrument: KitInstrument.kick, rawNote: 36),
        ],
        beatLog: beats(grid),
        sticking: rlrl,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
        analysisMode: true,
      );
      expect(a.alignment!.extraCount, 0);
      expect(a.alignment!.handValuesAllowed, isTrue);
      final kicks = a.events.where((e) => e.instrument == 'kick').toList();
      expect(kicks.length, 8);
      expect(kicks.every((e) => e.notePosition == null), isTrue);
      expect(a.detectedHits, 8);
    });

    test('flam notes become grace events, main strokes still hit', () {
      const flamSticking = [
        StrokeBeat(hand: Hand.right, graces: [Hand.left]),
        StrokeBeat(hand: Hand.left),
      ];
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final events = <StrokeEvent>[];
      for (var i = 0; i < 8; i++) {
        if (i.isEven) events.add(midi(grid[i] - 25, velocity: 0.3));
        events.add(midi(grid[i]));
      }
      final a = analyzeStrokes(
        events: events,
        beatLog: beats(grid),
        sticking: flamSticking,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
        analysisMode: true,
      );
      expect(a.alignment!.hitCount, 8);
      expect(a.alignment!.extraCount, 0);
      expect(a.events.where((e) => e.grace).length, 4);
      expect(a.detectedHits, 8);
    });

    test('no stroke-level filter for MIDI: quiet ghost notes still count', () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [for (final g in grid) midi(g, velocity: 0.05)],
        beatLog: beats(grid),
        sticking: rlrl,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
      );
      expect(a.signalTooWeak, isFalse);
      expect(a.alignment!.hitCount, 8);
    });

    test('mic source keeps the stroke-level filter', () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [
          for (final g in grid)
            StrokeEvent(
                timeMs: t0 + g,
                instrument: KitInstrument.pad,
                velocity: 0.05,
                rawNote: null,
                source: StrokeSourceKind.mic),
        ],
        beatLog: beats(grid),
        sticking: rlrl,
        source: StrokeSourceKind.mic,
      );
      expect(a.signalTooWeak, isTrue);
    });

    test('latency offset is subtracted for matching, raw times stay in log',
        () {
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [for (final g in grid) midi(g + 30)],
        beatLog: beats(grid),
        sticking: rlrl,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
        latencyOffsetMs: 30,
        analysisMode: true,
      );
      expect(a.timing!.overallDeviationMs, closeTo(0, 0.5));
      expect(a.events.first.timeMs, closeTo(t0 + 30, 0.001));
      expect(a.latencyOffsetAppliedMs, 30);
    });
  });

  test('analyzeHits still delegates with identical results (mic path)', () {
    final anchor = DateTime.fromMicrosecondsSinceEpoch((t0 * 1000).round());
    final grid = [for (var i = 0; i < 8; i++) i * 500.0];
    final a = MicAnalysisService.analyzeHits(
      hits: [for (final g in grid) OnsetHit(timeMs: g + 10, amplitude: 0.5)],
      anchor: anchor,
      beatLog: beats(grid),
      sticking: rlrl,
      analysisMode: true,
    );
    expect(a.source, StrokeSourceKind.mic);
    expect(a.velocityExact, isFalse);
    expect(a.timing!.overallDeviationMs, closeTo(10, 0.5));
    expect(a.events.first.instrument, 'pad');
  });
}
```

Im Test wird `OnsetHit` benutzt: `import 'package:drum_coach/features/coaching/services/onset_detector.dart';` oben ergänzen.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/coaching/stroke_analysis_test.dart`
Expected: FAIL (URI `stroke_analysis.dart` fehlt).

- [ ] **Step 3: Modelle erweitern**

In `lib/features/coaching/models/session_analysis.dart`:

Import oben: `import '../services/stroke_source.dart';`

`OnsetEventData` ersetzen durch:

```dart
class OnsetEventData {
  final double timeMs;      // raw epoch ms on the shared time axis
  final double peakLevel;   // mic: peak level; midi: velocity 0–1
  final int? notePosition;  // assigned note index, null = surplus onset
  final String? hand;       // 'R'/'L', only when assigned and gate open
  final double? deviationMs;

  /// `KitInstrument.name` the stroke came from (`pad` for the microphone).
  final String? instrument;

  /// MIDI note number, null for the microphone.
  final int? rawNote;

  /// True for a grace note absorbed by a flam/drag main stroke (Brief A.1):
  /// logged, never a hit and never an extra.
  final bool grace;

  const OnsetEventData({
    required this.timeMs,
    required this.peakLevel,
    this.notePosition,
    this.hand,
    this.deviationMs,
    this.instrument,
    this.rawNote,
    this.grace = false,
  });
}
```

Vor `class SessionAnalysis` einfügen:

```dart
/// Accent evaluation from exact velocities (Brief A.5): only computed for
/// MIDI. [accentRatio] = mean velocity of accented notes / mean of plain
/// notes; [accentsLouder] = how many accented notes beat the plain median.
class AccentAnalysis {
  final double accentRatio;
  final int accentsLouder;
  final int accentCount;

  const AccentAnalysis({
    required this.accentRatio,
    required this.accentsLouder,
    required this.accentCount,
  });
}
```

In `class SessionAnalysis` nach `final bool signalTooWeak;` ergänzen (und im Konstruktor mit Vorgaben):

```dart
  /// Which source measured this session; null = nothing measured.
  final StrokeSourceKind? source;

  /// Velocities are exact (MIDI) — accent and ghost values may show numbers.
  final bool velocityExact;

  /// Set when the exercise could not be measured with this setup (device
  /// lost, sensor level unmet). No numbers are shown then.
  final bool notMeasurable;

  final AccentAnalysis? accents;
```

Konstruktor-Parameter: `this.source, this.velocityExact = false, this.notMeasurable = false, this.accents,`.

- [ ] **Step 4: `stroke_analysis.dart` schreiben (Kern aus `analyzeHits` umgezogen)**

```dart
import '../../lessons/models/rudiment.dart';
import '../midi/kit_instrument.dart';
import '../models/session_analysis.dart';
import 'lapse_detector.dart';
import 'mic_analysis_service.dart' show BeatRecord, MicAnalysisService;
import 'sequence_aligner.dart';
import 'stroke_source.dart';
import 'unassigned_metrics.dart';

/// Grace handling (Brief A.1): MIDI delivers a flam as two notes. Inside a
/// ±[windowMs] window around an expected note that carries graces, all but
/// the latest event are graces. Without graces expected, nothing is split
/// (an early double stroke stays an extra). Times are latency-corrected.
({List<StrokeEvent> main, List<StrokeEvent> grace}) splitGraceEvents({
  required List<StrokeEvent> events,
  required List<double> expectedMs,
  required List<bool> hasGrace,
  double windowMs = 40,
}) {
  final sorted = List<StrokeEvent>.of(events)
    ..sort((a, b) => a.timeMs.compareTo(b.timeMs));
  final isGrace = List<bool>.filled(sorted.length, false);
  for (var n = 0; n < expectedMs.length; n++) {
    if (!hasGrace[n]) continue;
    final lo = expectedMs[n] - windowMs;
    final hi = expectedMs[n] + windowMs;
    final inWindow = <int>[];
    for (var j = 0; j < sorted.length; j++) {
      if (isGrace[j]) continue;
      final t = sorted[j].timeMs;
      if (t >= lo && t <= hi) inWindow.add(j);
    }
    if (inWindow.length < 2) continue;
    for (var k = 0; k < inWindow.length - 1; k++) {
      isGrace[inWindow[k]] = true;
    }
  }
  return (
    main: [for (var j = 0; j < sorted.length; j++) if (!isGrace[j]) sorted[j]],
    grace: [for (var j = 0; j < sorted.length; j++) if (isGrace[j]) sorted[j]],
  );
}

/// Pure analysis core (Etappe 1 §1.2/§1.4, now source-agnostic): aligns
/// expected notes and strokes of [expectedInstrument] as two sequences,
/// derives hands only from assigned notes, reports per-hand values only
/// above the confidence gate. Strokes of other instruments are logged
/// unassigned (Brief A.1/A.9). [latencyOffsetMs] is subtracted before
/// matching; logged times stay raw.
SessionAnalysis analyzeStrokes({
  required List<StrokeEvent> events,
  required List<BeatRecord> beatLog,
  required List<StrokeBeat> sticking,
  required StrokeSourceKind source,
  KitInstrument expectedInstrument = KitInstrument.pad,
  double latencyOffsetMs = 0,
  bool analysisMode = false,
  Map<String, Object>? recordingSetup,
  double graceWindowMs = 40,
}) {
  final velocityExact = source == StrokeSourceKind.midi;
  if (events.isEmpty || beatLog.isEmpty || sticking.isEmpty) {
    return SessionAnalysis(
      detectedHits: events.length,
      expectedHits: beatLog.length,
      recordingSetup: recordingSetup,
      source: source,
      velocityExact: velocityExact,
    );
  }

  OnsetEventData unassigned(StrokeEvent e, {bool grace = false}) =>
      OnsetEventData(
        timeMs: e.timeMs,
        peakLevel: e.velocity,
        instrument: e.instrument.name,
        rawNote: e.rawNote,
        grace: grace,
      );

  final onInstrument = [
    for (final e in events)
      if (e.instrument == expectedInstrument) e,
  ];
  final offInstrument = [
    for (final e in events)
      if (e.instrument != expectedInstrument) e,
  ];

  // Stroke-level filter (13.09.) — microphone only: headphone click bleed
  // registers as quiet on-grid onsets. MIDI velocities are exact; a quiet
  // ghost note is a stroke.
  final strokes = <StrokeEvent>[];
  final dropped = <StrokeEvent>[];
  for (final e in onInstrument) {
    if (source == StrokeSourceKind.mic &&
        e.velocity < MicAnalysisService.minStrokeLevel) {
      dropped.add(e);
    } else {
      strokes.add(e);
    }
  }
  if (source == StrokeSourceKind.mic &&
      onInstrument.length >= 8 &&
      strokes.length < onInstrument.length * 0.2) {
    return SessionAnalysis(
      detectedHits: strokes.length,
      expectedHits: beatLog.length,
      recordingSetup: recordingSetup,
      signalTooWeak: true,
      peakLevels: [for (final e in onInstrument) e.velocity],
      events: [for (final e in events) unassigned(e)]
        ..sort((a, b) => a.timeMs.compareTo(b.timeMs)),
      source: source,
      velocityExact: velocityExact,
    );
  }

  final expectedMs = [
    for (final b in beatLog) b.timestamp.microsecondsSinceEpoch / 1000.0,
  ];
  final hasGrace = [
    for (final b in beatLog)
      sticking[b.beatIndex % sticking.length].graces.isNotEmpty,
  ];
  final corrected = [
    for (final e in strokes)
      StrokeEvent(
        timeMs: e.timeMs - latencyOffsetMs,
        instrument: e.instrument,
        velocity: e.velocity,
        rawNote: e.rawNote,
        source: e.source,
      ),
  ];
  final split = splitGraceEvents(
    events: corrected,
    expectedMs: expectedMs,
    hasGrace: hasGrace,
    windowMs: graceWindowMs,
  );
  final mainStrokes = split.main;
  final onsetMs = [for (final e in mainStrokes) e.timeMs];
  final amplitudes = [for (final e in mainStrokes) e.velocity];

  final aligned = alignSequences(expectedMs: expectedMs, onsetMs: onsetMs);

  // Assess only the window from the first to the last note actually hit
  // (phantom misses before joining / after stopping, device test Etappe 1).
  var firstHit = -1, lastHit = -1;
  for (var i = 0; i < aligned.notes.length; i++) {
    if (!aligned.notes[i].hit) continue;
    if (firstHit < 0) firstHit = i;
    lastHit = i;
  }
  final assessed = firstHit < 0
      ? aligned.notes
      : aligned.notes.sublist(firstHit, lastHit + 1);

  final hitCount = assessed.where((n) => n.hit).length;
  final assessedDevs = [
    for (final n in assessed)
      if (n.hit) n.deviationMs!,
  ];
  final jitterMs = _stdDev(assessedDevs);
  final jitterExceeded =
      assessedDevs.length >= 4 && jitterMs > MicAnalysisService.jitterGateMs;
  final sessionStartMs = expectedMs.isNotEmpty ? expectedMs.first : 0.0;
  final lapses = detectLapses(
    noteTimesMs: [for (final n in assessed) n.expectedMs - sessionStartMs],
    deviationsMs: [for (final n in assessed) n.hit ? n.deviationMs : null],
  );
  final summary = AlignmentSummary(
    expectedCount: assessed.length,
    hitCount: hitCount,
    missedCount: assessed.length - hitCount,
    extraCount: aligned.extraCount,
    handValuesAllowed: assessed.isNotEmpty &&
        hitCount / assessed.length >= 0.9 &&
        aligned.extraCount / assessed.length < 0.05 &&
        !jitterExceeded &&
        lapses.isEmpty,
    jitterLimitExceeded: jitterExceeded,
    lapses: lapses,
  );

  final unassignedMetrics = computeUnassignedMetrics(
    clickMs: [for (final n in assessed) n.expectedMs],
    onsetMs: onsetMs,
    amplitudes: amplitudes,
  );

  final matched = <MatchedHit>[];
  final deviations = <double>[];
  for (final note in assessed) {
    if (!note.hit) continue;
    deviations.add(note.deviationMs!);
    final patternPos = beatLog[note.noteIndex].beatIndex % sticking.length;
    matched.add(MatchedHit(
      hitTimestamp: DateTime.fromMicrosecondsSinceEpoch(
          (onsetMs[note.onsetIndex!] * 1000).round()),
      amplitude: amplitudes[note.onsetIndex!],
      deviationMs: note.deviationMs!,
      hand: sticking[patternPos].hand,
    ));
  }

  final gateOpen =
      analysisMode && summary.handValuesAllowed && matched.length >= 4;

  final noteByOnset = <int, AlignedNote>{
    for (final n in assessed)
      if (n.hit) n.onsetIndex!: n,
  };
  final logged = <OnsetEventData>[
    for (var j = 0; j < mainStrokes.length; j++)
      OnsetEventData(
        timeMs: mainStrokes[j].timeMs + latencyOffsetMs,
        peakLevel: amplitudes[j],
        notePosition: noteByOnset[j] == null
            ? null
            : beatLog[noteByOnset[j]!.noteIndex].beatIndex,
        hand: noteByOnset[j] == null || !gateOpen
            ? null
            : (sticking[beatLog[noteByOnset[j]!.noteIndex].beatIndex %
                            sticking.length]
                        .hand ==
                    Hand.right
                ? 'R'
                : 'L'),
        deviationMs: noteByOnset[j]?.deviationMs,
        instrument: mainStrokes[j].instrument.name,
        rawNote: mainStrokes[j].rawNote,
      ),
    for (final e in split.grace)
      OnsetEventData(
        timeMs: e.timeMs + latencyOffsetMs,
        peakLevel: e.velocity,
        instrument: e.instrument.name,
        rawNote: e.rawNote,
        grace: true,
      ),
    for (final e in dropped) unassigned(e),
    for (final e in offInstrument) unassigned(e),
  ]..sort((a, b) => a.timeMs.compareTo(b.timeMs));

  return SessionAnalysis(
    timing: gateOpen ? _calcTiming(matched) : null,
    dynamics: gateOpen ? _calcDynamics(matched) : null,
    unassigned: unassignedMetrics,
    alignment: summary,
    peakLevels: amplitudes,
    deviationsMs: deviations,
    events: logged,
    latencyOffsetAppliedMs: latencyOffsetMs,
    detectedHits: mainStrokes.length,
    expectedHits: beatLog.length,
    recordingSetup: recordingSetup,
    source: source,
    velocityExact: velocityExact,
  );
}

TimingAnalysis _calcTiming(List<MatchedHit> hits) {
  List<double> devs(Hand h) =>
      [for (final m in hits) if (m.hand == h) m.deviationMs];
  final all = [for (final m in hits) m.deviationMs];
  return TimingAnalysis(
    overallDeviationMs: _mean(all),
    rightHandDeviationMs: _meanOrZero(devs(Hand.right)),
    leftHandDeviationMs: _meanOrZero(devs(Hand.left)),
    jitterMs: _stdDev(all),
  );
}

DynamicsAnalysis _calcDynamics(List<MatchedHit> hits) {
  List<double> amps(Hand h) =>
      [for (final m in hits) if (m.hand == h) m.amplitude];
  return DynamicsAnalysis(
    rightHandLevel: _meanOrZero(amps(Hand.right)),
    leftHandLevel: _meanOrZero(amps(Hand.left)),
  );
}

double _mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;
double _meanOrZero(List<double> v) => v.isEmpty ? 0 : _mean(v);

double _stdDev(List<double> v) {
  if (v.length < 2) return 0;
  final m = _mean(v);
  final sq = v.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b);
  return math.sqrt(sq / v.length);
}
```

(`import 'dart:math' as math;` oben in der Datei ergänzen.)

**Achtung:** `_calcTiming`/`_calcDynamics`/`_mean`/`_stdDev` existieren bereits in `mic_analysis_service.dart` (Zeilen 329–372). Vor dem Übernehmen die dortigen Rümpfe lesen und **exakt** übernehmen (Konstruktor-Parameter von `TimingAnalysis`/`DynamicsAnalysis` prüfen); die obigen Rümpfe sind der Erwartungswert, nicht die Vorlage.

- [ ] **Step 5: `MicAnalysisService` auf die Hülle umbauen**

In `mic_analysis_service.dart`:

1. Imports ergänzen: `import '../midi/kit_instrument.dart';`, `import 'stroke_analysis.dart';`, `import 'stroke_source.dart';`
2. Nach `clockDriftMs` einfügen:

```dart
  /// Detected strokes as [StrokeEvent]s on the shared time axis (epoch ms),
  /// instrument `pad`, rough peak level as velocity — the microphone's half
  /// of the StrokeSource contract (Brief Etappe 2, A.1).
  List<StrokeEvent> get strokeEvents {
    if (_clock.timeAt(0) == null) return const [];
    return [
      for (final h in _detector.hits)
        StrokeEvent(
          timeMs: _clock.timeAt(h.timeMs)!.microsecondsSinceEpoch / 1000.0,
          instrument: KitInstrument.pad,
          velocity: h.amplitude,
          rawNote: null,
          source: StrokeSourceKind.mic,
        ),
    ];
  }
```

3. Den Rumpf von `analyzeHits` (ab `if (hits.isEmpty || anchor == null …` bis zum `return SessionAnalysis(…)` am Ende) ersetzen durch:

```dart
    if (anchor == null) {
      return SessionAnalysis(
        detectedHits: hits.length,
        expectedHits: beatLog.length,
        recordingSetup: recordingSetup,
        source: StrokeSourceKind.mic,
      );
    }
    final anchorMs = anchor.microsecondsSinceEpoch / 1000.0;
    return analyzeStrokes(
      events: [
        for (final h in hits)
          StrokeEvent(
            timeMs: anchorMs + h.timeMs,
            instrument: KitInstrument.pad,
            velocity: h.amplitude,
            rawNote: null,
            source: StrokeSourceKind.mic,
          ),
      ],
      beatLog: beatLog,
      sticking: sticking,
      source: StrokeSourceKind.mic,
      expectedInstrument: KitInstrument.pad,
      latencyOffsetMs: latencyOffsetMs,
      analysisMode: analysisMode,
      recordingSetup: recordingSetup,
    );
```

4. `_calcTiming`, `_calcDynamics`, `_mean`, `_stdDev`, `_stdDevWithMean` aus `mic_analysis_service.dart` entfernen, nachdem sie nach `stroke_analysis.dart` übernommen wurden (Schritt 4). Nicht mehr benötigte Imports (`lapse_detector`, `sequence_aligner`, `unassigned_metrics`, `dart:math`) entfernen, wenn `flutter analyze` sie als unbenutzt meldet.

- [ ] **Step 6: Tests**

Run: `flutter test test/coaching/`
Expected: alle grün, einschließlich der unveränderten `mic_analysis_test.dart` (Beweis, dass der Umzug verhaltensgleich ist) und der neuen Datei. Falls ein Etappe-1-Test an einem Zählwert hängt (`detectedHits`, `events`-Reihenfolge), **den Kern angleichen, nicht den alten Test**.

- [ ] **Step 7: Commit**

```bash
git add lib/features/coaching/services/stroke_analysis.dart lib/features/coaching/services/mic_analysis_service.dart lib/features/coaching/models/session_analysis.dart test/coaching/stroke_analysis_test.dart
git commit -m "refactor(coaching): Analyse-Kern als analyzeStrokes auf StrokeEvent — Instrument-Filter, Vorschläge, Fremdinstrumente im Log"
```

---
### Task 5: Akzent-Bewertung aus exakter Velocity

**Files:**
- Modify: `lib/features/coaching/services/stroke_analysis.dart` (neue Funktion `accentAnalysis`, Aufruf in `analyzeStrokes`), `lib/features/practice/widgets/result_sheet.dart` (`_DetailsSection`, eine Zeile)
- Test: `test/coaching/accent_analysis_test.dart`

**Interfaces:**
- Consumes: `MatchedHit` (hat `amplitude`, `hand`, `deviationMs`, `hitTimestamp`), `AccentAnalysis` (Task 4), `AlignedNote.noteIndex`, `beatLog`, `sticking[...].isAccent / isGhost`.
- Produces: `AccentAnalysis? accentAnalysis({required List<double> velocities, required List<bool> accented, required List<bool> ghost})` — nur Treffer; null bei weniger als 2 Akzenten oder 2 Normalnoten. `SessionAnalysis.accents` gefüllt, wenn `velocityExact && gateOpen`.

- [ ] **Step 1: Failing test**

`test/coaching/accent_analysis_test.dart`:

```dart
import 'package:drum_coach/features/coaching/services/stroke_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accents louder than plain notes: ratio and count', () {
    final a = accentAnalysis(
      velocities: const [0.9, 0.5, 0.8, 0.4, 0.95, 0.5],
      accented: const [true, false, true, false, true, false],
      ghost: const [false, false, false, false, false, false],
    )!;
    expect(a.accentCount, 3);
    expect(a.accentsLouder, 3);
    expect(a.accentRatio, closeTo((0.9 + 0.8 + 0.95) / 3 / (1.4 / 3), 0.01));
  });

  test('one accent swallowed: counts 2 of 3 louder', () {
    final a = accentAnalysis(
      velocities: const [0.9, 0.5, 0.45, 0.5, 0.95, 0.5],
      accented: const [true, false, true, false, true, false],
      ghost: const [false, false, false, false, false, false],
    )!;
    expect(a.accentsLouder, 2);
  });

  test('ghost notes are excluded from the plain reference', () {
    final a = accentAnalysis(
      velocities: const [0.9, 0.5, 0.1, 0.5, 0.9, 0.1],
      accented: const [true, false, false, false, true, false],
      ghost: const [false, false, true, false, false, true],
    )!;
    expect(a.accentRatio, closeTo(0.9 / 0.5, 0.01));
  });

  test('too few notes: null', () {
    expect(
      accentAnalysis(
          velocities: const [0.9, 0.5],
          accented: const [true, false],
          ghost: const [false, false]),
      isNull,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/coaching/accent_analysis_test.dart`
Expected: FAIL, `accentAnalysis` undefined.

- [ ] **Step 3: Implementation**

In `stroke_analysis.dart` ergänzen:

```dart
/// Accent evaluation (Brief A.5): mean accented velocity over mean plain
/// velocity (ghosts excluded), and how many accents beat the plain median.
/// Null below two accents or two plain notes — no number from thin air.
AccentAnalysis? accentAnalysis({
  required List<double> velocities,
  required List<bool> accented,
  required List<bool> ghost,
}) {
  final acc = <double>[];
  final plain = <double>[];
  for (var i = 0; i < velocities.length; i++) {
    if (accented[i]) {
      acc.add(velocities[i]);
    } else if (!ghost[i]) {
      plain.add(velocities[i]);
    }
  }
  if (acc.length < 2 || plain.length < 2) return null;
  final sortedPlain = List<double>.of(plain)..sort();
  final mid = sortedPlain.length ~/ 2;
  final plainMedian = sortedPlain.length.isOdd
      ? sortedPlain[mid]
      : (sortedPlain[mid - 1] + sortedPlain[mid]) / 2;
  return AccentAnalysis(
    accentRatio: _mean(acc) / _mean(plain),
    accentsLouder: acc.where((v) => v > plainMedian).length,
    accentCount: acc.length,
  );
}
```

In `analyzeStrokes` direkt nach `final gateOpen = …;` einfügen:

```dart
  AccentAnalysis? accents;
  if (velocityExact && gateOpen) {
    final velocities = <double>[];
    final accented = <bool>[];
    final ghost = <bool>[];
    for (final note in assessed) {
      if (!note.hit) continue;
      final beat = sticking[beatLog[note.noteIndex].beatIndex % sticking.length];
      velocities.add(amplitudes[note.onsetIndex!]);
      accented.add(beat.isAccent);
      ghost.add(beat.isGhost);
    }
    accents = accentAnalysis(
        velocities: velocities, accented: accented, ghost: ghost);
  }
```

und im `return SessionAnalysis(…)` am Ende `accents: accents,` ergänzen.

In `result_sheet.dart`, `_DetailsSection.build`: nach der Zeile mit `row('Dynamics spread', …)` (ca. Zeile 452) ergänzen:

```dart
            if (analysis.accents != null)
              row(
                'Accents (MIDI velocity)',
                '${analysis.accents!.accentRatio.toStringAsFixed(1)}× louder, '
                    '${analysis.accents!.accentsLouder} of '
                    '${analysis.accents!.accentCount} above plain',
              ),
```

Vorher die lokale `row`-Funktion in `_DetailsSection` ansehen (Signatur `Widget row(String label, String value)` erwartet; sonst angleichen).

- [ ] **Step 4: Tests**

Run: `flutter test test/coaching/accent_analysis_test.dart test/coaching/stroke_analysis_test.dart test/practice/`
Expected: grün. Zusätzlich in `stroke_analysis_test.dart` im Test „clean snare run" ergänzen: `expect(a.accents, isNull);` (keine Akzente im Sticking) und einen neuen Test:

```dart
    test('accents computed for MIDI when the gate is open', () {
      const acc = [
        StrokeBeat(hand: Hand.right, isAccent: true),
        StrokeBeat(hand: Hand.left),
        StrokeBeat(hand: Hand.right),
        StrokeBeat(hand: Hand.left),
      ];
      final grid = [for (var i = 0; i < 8; i++) i * 500.0];
      final a = analyzeStrokes(
        events: [
          for (var i = 0; i < 8; i++)
            midi(grid[i], velocity: i % 4 == 0 ? 0.9 : 0.5),
        ],
        beatLog: beats(grid),
        sticking: acc,
        source: StrokeSourceKind.midi,
        expectedInstrument: KitInstrument.snare,
        analysisMode: true,
      );
      expect(a.accents, isNotNull);
      expect(a.accents!.accentCount, 2);
      expect(a.accents!.accentsLouder, 2);
    });
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/coaching/services/stroke_analysis.dart lib/features/practice/widgets/result_sheet.dart test/coaching/accent_analysis_test.dart test/coaching/stroke_analysis_test.dart
git commit -m "feat(coaching): Akzent-Bewertung aus MIDI-Velocity, Zeile in den Messdetails"
```

---

### Task 6: Rohlog um Quelle, Gerät, Zuordnung, Instrument erweitern

**Files:**
- Modify: `lib/data/local/models/session_log.dart`, `lib/data/local/session_log_codec.dart`, `lib/data/local/session_log_service.dart`
- Test: `test/data/session_log_builder_test.dart` (erweitern), `test/data/session_log_codec_test.dart` (erweitern)

**Interfaces:**
- Consumes: `OnsetEventData.instrument/rawNote/grace` (Task 4).
- Produces: `SessionLog.source` (`String`, `'mic' | 'midi' | 'off'`), `SessionLog.midiDevice` (`String?`), `SessionLog.kitMapping` (`String?`, JSON), `OnsetEvent.instrument` (`String?`), `OnsetEvent.rawNote` (`int?`), `OnsetEvent.grace` (`bool`); `buildSessionLog(…, String source = 'off', String? midiDevice, String? kitMapping)`.

- [ ] **Step 1: Failing tests**

In `test/data/session_log_builder_test.dart` einen Test ergänzen (die Hilfsfunktionen `beatLog`, `started` existieren dort):

```dart
  test('midi session: source, device, mapping and per-event instrument', () {
    final analysis = SessionAnalysis(
      detectedHits: 1,
      expectedHits: 1,
      events: const [
        OnsetEventData(
            timeMs: 1000,
            peakLevel: 0.8,
            notePosition: 0,
            instrument: 'snare',
            rawNote: 38),
        OnsetEventData(
            timeMs: 975, peakLevel: 0.3, instrument: 'snare', rawNote: 38,
            grace: true),
        OnsetEventData(
            timeMs: 1250, peakLevel: 0.9, instrument: 'kick', rawNote: 36),
      ],
      recordingSetup: const {'audioSource': 'midi', 'sampleRate': 0},
    );
    final log = buildSessionLog(
      analysis: analysis,
      beatLog: beatLog([1000]),
      exerciseId: 'single_stroke_roll',
      bpm: 100,
      durationSeconds: 30,
      rating: 2,
      startedAt: started,
      headphones: 'none',
      device: const DeviceInfo(model: 'laptop', androidVersion: 'linux'),
      latencyOffsetMs: 12,
      source: 'midi',
      midiDevice: 'Millenium MPS-850',
      kitMapping: '{"snare":[38]}',
    );
    expect(log.source, 'midi');
    expect(log.midiDevice, 'Millenium MPS-850');
    expect(log.kitMapping, '{"snare":[38]}');
    expect(log.audioSource, 'midi');
    expect(log.events[0].instrument, 'snare');
    expect(log.events[0].rawNote, 38);
    expect(log.events[0].grace, isFalse);
    expect(log.events[1].grace, isTrue);
    expect(log.events[2].instrument, 'kick');
  });

  test('default source is off and mic sessions say mic', () {
    final log = buildSessionLog(
      analysis: null,
      beatLog: const [],
      exerciseId: 'x',
      bpm: 100,
      durationSeconds: 1,
      rating: 1,
      startedAt: started,
      headphones: 'none',
      device: const DeviceInfo(model: 'm', androidVersion: 'v'),
      latencyOffsetMs: null,
    );
    expect(log.source, 'off');
    expect(log.midiDevice, isNull);
  });
```

In `test/data/session_log_codec_test.dart` einen Test ergänzen (vorhandene Hilfen dort nutzen; sonst einen `SessionLog` wie im Builder-Test bauen):

```dart
  test('jsonl carries source, device, mapping, instrument, rawNote, grace',
      () {
    final log = SessionLog()
      ..sessionUid = 'u'
      ..startedAt = DateTime.utc(2026, 10, 11)
      ..exerciseId = 'x'
      ..mode = 'learn'
      ..bpm = 100
      ..durationSeconds = 1
      ..deviceModel = 'laptop'
      ..androidVersion = 'linux'
      ..audioSource = 'midi'
      ..sampleRate = 0
      ..autoGain = false
      ..echoCancel = false
      ..noiseSuppress = false
      ..headphones = 'none'
      ..source = 'midi'
      ..midiDevice = 'Millenium'
      ..kitMapping = '{"snare":[38]}'
      ..clickTimesMs = const [1000]
      ..clickNoteIndices = const [0]
      ..events = [
        OnsetEvent()
          ..timeMs = 1000
          ..peakLevel = 0.8
          ..instrument = 'snare'
          ..rawNote = 38
          ..grace = false,
      ];
    final lines = sessionLogToJsonl(log).trim().split('\n');
    final header = jsonDecode(lines[0]) as Map<String, Object?>;
    final onset = jsonDecode(lines[1]) as Map<String, Object?>;
    expect(header['source'], 'midi');
    expect(header['midiDevice'], 'Millenium');
    expect(header['kitMapping'], '{"snare":[38]}');
    expect(onset['instrument'], 'snare');
    expect(onset['rawNote'], 38);
    expect(onset['grace'], false);
  });
```

(`import 'dart:convert';` und `import 'package:drum_coach/data/local/models/session_log.dart';` im Codec-Test prüfen/ergänzen.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/session_log_builder_test.dart test/data/session_log_codec_test.dart`
Expected: FAIL (unbekannte Parameter/Felder).

- [ ] **Step 3: Modell, Builder, Codec**

`session_log.dart`, in `class SessionLog` nach `String? sheetMode;`:

```dart
  /// Measurement source of this session: `mic` | `midi` | `off`
  /// (Brief Etappe 2, A.9). Older rows read back as `off`/`mic` via the
  /// default below.
  String source = 'off';

  /// MIDI device name and the kit mapping (JSON) in force — reproducible
  /// instrument assignment for every logged note.
  String? midiDevice;
  String? kitMapping;
```

In `class OnsetEvent`:

```dart
  /// `KitInstrument.name`; `pad` for the microphone, null in old rows.
  String? instrument;
  int? rawNote;
  bool grace = false;
```

Dann Isar-Code neu erzeugen: `dart run build_runner build --delete-conflicting-outputs` (erzeugt `session_log.g.dart` neu; Isar 3 fügt Felder mit Vorgabewerten ohne Migration hinzu).

`session_log_service.dart`, `buildSessionLog`: Parameter `String source = 'off', String? midiDevice, String? kitMapping,` ergänzen und im Kaskaden-Ausdruck nach `..sheetMode = sheetMode`:

```dart
    ..source = source
    ..midiDevice = midiDevice
    ..kitMapping = kitMapping
```

und im `events`-Mapping:

```dart
          ..deviationMs = e.deviationMs
          ..instrument = e.instrument
          ..rawNote = e.rawNote
          ..grace = e.grace,
```

`session_log_codec.dart`: im Kopf nach `'sheetMode': log.sheetMode,` → `'source': log.source, 'midiDevice': log.midiDevice, 'kitMapping': log.kitMapping,`; im Onset-Objekt nach `'deviationMs': e.deviationMs,` → `'instrument': e.instrument, 'rawNote': e.rawNote, 'grace': e.grace,`.

- [ ] **Step 4: Tests**

Run: `flutter test test/data/`
Expected: grün.

- [ ] **Step 5: Commit**

```bash
git add lib/data/local/models/session_log.dart lib/data/local/models/session_log.g.dart lib/data/local/session_log_codec.dart lib/data/local/session_log_service.dart test/data/session_log_builder_test.dart test/data/session_log_codec_test.dart
git commit -m "feat(log): Rohlog mit Quelle, MIDI-Gerät, Kit-Zuordnung und Instrument je Ereignis"
```

---

### Task 7: Einstellungen — Messquelle (mit Migration), MIDI-Schlüssel, Pad-Rolle

**Files:**
- Modify: `lib/data/local/settings_service.dart`
- Test: `test/data/settings_measurement_test.dart`

**Interfaces:**
- Produces:
  - `enum MeasurementSource { auto, mic, midi, off }` (in `settings_service.dart`) mit `bool get mayUseMic` (`auto || mic`), `bool get mayUseMidi` (`auto || midi`)
  - `SettingsService.measurementSource` / `setMeasurementSource(MeasurementSource)`
  - `SettingsService.micAnalysisEnabled` bleibt als **abgeleiteter** Getter (`measurementSource.mayUseMic`); `setMicAnalysisEnabled` wird entfernt (Aufrufer: `settings_screen.dart`, wird in Task 13 ersetzt — bis dahin bleibt der Setter und schreibt `measurement_source`)
  - `midiLastDeviceId` / `setMidiLastDeviceId(String?)`
  - `KitMapping kitMappingFor(String deviceName)` / `setKitMappingFor(String deviceName, KitMapping)`
  - `double? midiLatencyOffsetMsFor(String deviceName)` / `setMidiLatencyOffsetMsFor(String deviceName, double)`
  - `KitInstrument padRoleInstrument` (Vorgabe `snare`) / `setPadRoleInstrument(KitInstrument)`

- [ ] **Step 1: Failing test**

`test/data/settings_measurement_test.dart`:

```dart
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> init(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    await SettingsService.init();
  }

  test('measurement source defaults to auto', () async {
    await init({});
    expect(SettingsService.measurementSource, MeasurementSource.auto);
    expect(SettingsService.micAnalysisEnabled, isTrue);
  });

  test('legacy "mic analysis off" migrates to off, never to auto', () async {
    await init({'mic_analysis_enabled': false});
    expect(SettingsService.measurementSource, MeasurementSource.off);
    expect(SettingsService.micAnalysisEnabled, isFalse);
  });

  test('legacy "mic analysis on" migrates to auto', () async {
    await init({'mic_analysis_enabled': true});
    expect(SettingsService.measurementSource, MeasurementSource.auto);
  });

  test('explicit source wins over the legacy key and round-trips', () async {
    await init({'mic_analysis_enabled': false});
    await SettingsService.setMeasurementSource(MeasurementSource.midi);
    expect(SettingsService.measurementSource, MeasurementSource.midi);
    expect(SettingsService.micAnalysisEnabled, isFalse);
    expect(MeasurementSource.midi.mayUseMidi, isTrue);
    expect(MeasurementSource.mic.mayUseMidi, isFalse);
  });

  test('kit mapping is stored per device and defaults to GM', () async {
    await init({});
    expect(SettingsService.kitMappingFor('Millenium').instrumentFor(38),
        KitInstrument.snare);
    await SettingsService.setKitMappingFor(
        'Millenium', KitMapping.gm().assign(KitInstrument.snare, 40));
    expect(SettingsService.kitMappingFor('Millenium').instrumentFor(40),
        KitInstrument.snare);
    expect(SettingsService.kitMappingFor('Other').instrumentFor(40), isNull);
  });

  test('midi latency per device, last device id, pad role', () async {
    await init({});
    expect(SettingsService.midiLatencyOffsetMsFor('Millenium'), isNull);
    await SettingsService.setMidiLatencyOffsetMsFor('Millenium', 18.5);
    expect(SettingsService.midiLatencyOffsetMsFor('Millenium'), 18.5);
    expect(SettingsService.midiLastDeviceId, isNull);
    await SettingsService.setMidiLastDeviceId('20:0');
    expect(SettingsService.midiLastDeviceId, '20:0');
    expect(SettingsService.padRoleInstrument, KitInstrument.snare);
    await SettingsService.setPadRoleInstrument(KitInstrument.tom1);
    expect(SettingsService.padRoleInstrument, KitInstrument.tom1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/settings_measurement_test.dart`
Expected: FAIL (`MeasurementSource` unbekannt).

- [ ] **Step 3: Implementation**

In `settings_service.dart`: Import `../../features/coaching/midi/kit_instrument.dart` ergänzen. Vor `class SettingsService`:

```dart
/// Which stroke source may measure (Brief Etappe 2, A.6). `auto` = MIDI when
/// a device is connected, otherwise the microphone where allowed.
enum MeasurementSource {
  auto,
  mic,
  midi,
  off;

  bool get mayUseMic => this == auto || this == mic;
  bool get mayUseMidi => this == auto || this == midi;

  static MeasurementSource fromName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return auto;
  }
}
```

Den Block `micAnalysisEnabled` / `setMicAnalysisEnabled` (Zeilen 55–58) ersetzen durch:

```dart
  /// Measurement source. Migration: the Etappe-1 switch `mic_analysis_enabled`
  /// = false must not come back as "auto" — a user who turned the mic off
  /// stays off until they choose a source.
  static MeasurementSource get measurementSource {
    final stored = _prefs.getString('measurement_source');
    if (stored != null) return MeasurementSource.fromName(stored);
    final legacy = _prefs.getBool('mic_analysis_enabled');
    return legacy == false ? MeasurementSource.off : MeasurementSource.auto;
  }

  static Future<void> setMeasurementSource(MeasurementSource s) =>
      _prefs.setString('measurement_source', s.name);

  /// Derived: may the microphone listen at all. Kept for the practice
  /// screen's backing/click rules.
  static bool get micAnalysisEnabled => measurementSource.mayUseMic;

  /// Transitional (removed with the settings screen rebuild, Task 13).
  static Future<void> setMicAnalysisEnabled(bool v) =>
      setMeasurementSource(v ? MeasurementSource.auto : MeasurementSource.off);

  static String? get midiLastDeviceId => _prefs.getString('midi_last_device');
  static Future<void> setMidiLastDeviceId(String? id) => id == null
      ? _prefs.remove('midi_last_device')
      : _prefs.setString('midi_last_device', id);

  static String _deviceKey(String prefix, String deviceName) =>
      '$prefix${deviceName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}';

  static KitMapping kitMappingFor(String deviceName) {
    final raw = _prefs.getString(_deviceKey('kit_mapping_', deviceName));
    return raw == null ? KitMapping.gm() : KitMapping.decode(raw);
  }

  static Future<void> setKitMappingFor(String deviceName, KitMapping m) =>
      _prefs.setString(_deviceKey('kit_mapping_', deviceName), m.encode());

  static double? midiLatencyOffsetMsFor(String deviceName) =>
      _prefs.getDouble(_deviceKey('midi_latency_', deviceName));

  static Future<void> setMidiLatencyOffsetMsFor(String deviceName, double v) =>
      _prefs.setDouble(_deviceKey('midi_latency_', deviceName), v);

  /// Instrument that plays the pad's role in pad exercises at the set
  /// (Brief A.5), default snare.
  static KitInstrument get padRoleInstrument =>
      KitInstrument.fromName(_prefs.getString('pad_role_instrument') ?? '') ??
      KitInstrument.snare;

  static Future<void> setPadRoleInstrument(KitInstrument i) =>
      _prefs.setString('pad_role_instrument', i.name);
```

- [ ] **Step 4: Tests**

Run: `flutter test test/data/ test/features/`
Expected: grün (bestehende Settings-Tests unverändert).

- [ ] **Step 5: Commit**

```bash
git add lib/data/local/settings_service.dart test/data/settings_measurement_test.dart
git commit -m "feat(settings): Messquelle auto/mic/midi/off mit Migration, MIDI-Gerät, Kit-Zuordnung, Latenz je Gerät, Pad-Rolle"
```

---

### Task 8: Reine MIDI-Bausteine — Zeitstempel-Abbildung, Note-On-Parser, Gerätewahl

**Files:**
- Create: `lib/features/coaching/midi/midi_timestamp_mapper.dart`, `lib/features/coaching/midi/midi_port_service.dart` (in dieser Aufgabe nur die reinen Funktionen; die Klasse `MidiPortService` folgt in Task 9)
- Test: `test/midi/midi_timestamp_mapper_test.dart`, `test/midi/midi_parse_test.dart`

**Interfaces:**
- Produces:
  - `enum MidiTimestampUnit { epochMicros, monotonicNanos, none }` und `MidiTimestampUnit midiTimestampUnitForPlatform({required bool isAndroid, required bool isLinux})`
  - `class MidiTimestampMapper { MidiTimestampMapper(MidiTimestampUnit unit); double toEpochMs({required int libTimestamp, required int arrivalEpochUs}); }`
  - `class MidiNoteOn { final int note; final int velocity; final int channel; final int libTimestamp; final int arrivalEpochUs; }`
  - `MidiNoteOn? parseNoteOn(Uint8List data, {required int libTimestamp, required int arrivalEpochUs})` — null für alles außer Note-On mit Velocity > 0
  - `String? chooseMidiDevice(List<({String id, String name, bool hasInput})> devices, {String? lastId})`

- [ ] **Step 1: Failing tests**

`test/midi/midi_timestamp_mapper_test.dart`:

```dart
import 'package:drum_coach/features/coaching/midi/midi_timestamp_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('epochMicros: library stamp is the time, arrival ignored', () {
    final m = MidiTimestampMapper(MidiTimestampUnit.epochMicros);
    expect(m.toEpochMs(libTimestamp: 1700000000123456, arrivalEpochUs: 0),
        closeTo(1700000000123.456, 1e-6));
  });

  test('none or zero stamp: arrival time is used', () {
    final m = MidiTimestampMapper(MidiTimestampUnit.none);
    expect(m.toEpochMs(libTimestamp: 42, arrivalEpochUs: 1700000000000500),
        closeTo(1700000000000.5, 1e-6));
    final e = MidiTimestampMapper(MidiTimestampUnit.epochMicros);
    expect(e.toEpochMs(libTimestamp: 0, arrivalEpochUs: 1700000000000500),
        closeTo(1700000000000.5, 1e-6));
  });

  test('monotonicNanos: offset learned as the minimum arrival delay', () {
    final m = MidiTimestampMapper(MidiTimestampUnit.monotonicNanos);
    const base = 1700000000000000; // µs epoch
    // Event 1: true time base, arrived 9 ms late (main isolate busy).
    final t1 = m.toEpochMs(
        libTimestamp: 5000000000, arrivalEpochUs: base + 9000);
    // Event 2: true time base+500 ms, arrived 1 ms late → offset shrinks.
    final t2 = m.toEpochMs(
        libTimestamp: 5500000000, arrivalEpochUs: base + 500000 + 1000);
    // Event 3: true time base+1000 ms, arrived 12 ms late → uses the learned
    // 1 ms offset, not its own late arrival.
    final t3 = m.toEpochMs(
        libTimestamp: 6000000000, arrivalEpochUs: base + 1000000 + 12000);
    expect(t2 - t1, closeTo(500 - 8, 1e-6)); // first event carried 8 ms extra
    expect(t3 - t2, closeTo(500, 1e-6));
  });
}
```

`test/midi/midi_parse_test.dart`:

```dart
import 'dart:typed_data';

import 'package:drum_coach/features/coaching/midi/midi_port_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MidiNoteOn? parse(List<int> bytes) => parseNoteOn(Uint8List.fromList(bytes),
      libTimestamp: 7, arrivalEpochUs: 9);

  test('note on with velocity on channel 10', () {
    final n = parse([0x99, 38, 100])!;
    expect(n.note, 38);
    expect(n.velocity, 100);
    expect(n.channel, 9);
    expect(n.libTimestamp, 7);
    expect(n.arrivalEpochUs, 9);
  });

  test('note off, velocity 0, aftertouch, controller, short: null', () {
    expect(parse([0x89, 38, 0]), isNull);
    expect(parse([0x99, 38, 0]), isNull);
    expect(parse([0xA9, 38, 40]), isNull);
    expect(parse([0xB9, 4, 127]), isNull);
    expect(parse([0x99, 38]), isNull);
    expect(parse([]), isNull);
  });

  test('chooseMidiDevice: single input wins, last id preferred, else first',
      () {
    final one = [(id: '20:0', name: 'Millenium', hasInput: true)];
    expect(chooseMidiDevice(one), '20:0');
    final two = [
      (id: '20:0', name: 'Millenium', hasInput: true),
      (id: '24:0', name: 'Keyboard', hasInput: true),
    ];
    expect(chooseMidiDevice(two, lastId: '24:0'), '24:0');
    expect(chooseMidiDevice(two, lastId: '99:0'), '20:0');
    expect(chooseMidiDevice(two), '20:0');
    final outputOnly = [(id: '1:0', name: 'Synth', hasInput: false)];
    expect(chooseMidiDevice(outputOnly), isNull);
    expect(chooseMidiDevice(const []), isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/midi/midi_timestamp_mapper_test.dart test/midi/midi_parse_test.dart`
Expected: FAIL (URIs fehlen).

- [ ] **Step 3: Implementation**

`lib/features/coaching/midi/midi_timestamp_mapper.dart`:

```dart
/// What `MidiPacket.timestamp` means per platform (docs/BERICHT_ETAPPE2_§0.md):
/// Linux (vendored patch) = epoch microseconds from the receive isolate;
/// Android = `android.media.midi` nanoseconds on the system's monotonic
/// clock; anything else = unknown, use the arrival time.
enum MidiTimestampUnit { epochMicros, monotonicNanos, none }

MidiTimestampUnit midiTimestampUnitForPlatform({
  required bool isAndroid,
  required bool isLinux,
}) {
  if (isLinux) return MidiTimestampUnit.epochMicros;
  if (isAndroid) return MidiTimestampUnit.monotonicNanos;
  return MidiTimestampUnit.none;
}

/// Brings a library timestamp onto the shared epoch-ms axis. For monotonic
/// stamps the constant offset to the wall clock is learned as the *minimum*
/// arrival delay seen so far: arrival is always later than the true event,
/// and the smallest delay is the closest to the truth (§0: never trust a
/// single arrival time, the main isolate may be busy).
class MidiTimestampMapper {
  MidiTimestampMapper(this.unit);

  final MidiTimestampUnit unit;
  int? _offsetUs; // arrivalEpochUs - libTimestampUs, minimum so far

  double toEpochMs({required int libTimestamp, required int arrivalEpochUs}) {
    if (libTimestamp == 0 || unit == MidiTimestampUnit.none) {
      return arrivalEpochUs / 1000.0;
    }
    switch (unit) {
      case MidiTimestampUnit.epochMicros:
        return libTimestamp / 1000.0;
      case MidiTimestampUnit.monotonicNanos:
        final libUs = libTimestamp ~/ 1000;
        final delay = arrivalEpochUs - libUs;
        if (_offsetUs == null || delay < _offsetUs!) _offsetUs = delay;
        return (libUs + _offsetUs!) / 1000.0;
      case MidiTimestampUnit.none:
        return arrivalEpochUs / 1000.0;
    }
  }
}
```

`lib/features/coaching/midi/midi_port_service.dart` (reine Teile; die Klasse kommt in Task 9 in dieselbe Datei):

```dart
import 'dart:typed_data';

/// One Note-On as it left the module: note, velocity, channel, the library's
/// timestamp (unit per platform) and when it reached Dart (epoch µs).
class MidiNoteOn {
  final int note;
  final int velocity;
  final int channel;
  final int libTimestamp;
  final int arrivalEpochUs;

  const MidiNoteOn({
    required this.note,
    required this.velocity,
    required this.channel,
    required this.libTimestamp,
    required this.arrivalEpochUs,
  });
}

/// Note-On with velocity > 0 only. Note-Off, velocity 0, aftertouch,
/// controllers (hi-hat pedal position), SysEx: null (Brief A.1).
MidiNoteOn? parseNoteOn(
  Uint8List data, {
  required int libTimestamp,
  required int arrivalEpochUs,
}) {
  if (data.length < 3) return null;
  final status = data[0] & 0xF0;
  if (status != 0x90) return null;
  final velocity = data[2] & 0x7F;
  if (velocity == 0) return null;
  return MidiNoteOn(
    note: data[1] & 0x7F,
    velocity: velocity,
    channel: data[0] & 0x0F,
    libTimestamp: libTimestamp,
    arrivalEpochUs: arrivalEpochUs,
  );
}

/// Port choice (Brief A.3): exactly one input → that one; several → the
/// last used if still present, else the first; none → null.
String? chooseMidiDevice(
  List<({String id, String name, bool hasInput})> devices, {
  String? lastId,
}) {
  final inputs = [for (final d in devices) if (d.hasInput) d];
  if (inputs.isEmpty) return null;
  if (inputs.length == 1) return inputs.single.id;
  for (final d in inputs) {
    if (d.id == lastId) return d.id;
  }
  return inputs.first.id;
}
```

- [ ] **Step 4: Tests**

Run: `flutter test test/midi/`
Expected: grün.

- [ ] **Step 5: Commit**

```bash
git add lib/features/coaching/midi/midi_timestamp_mapper.dart lib/features/coaching/midi/midi_port_service.dart test/midi/midi_timestamp_mapper_test.dart test/midi/midi_parse_test.dart
git commit -m "feat(midi): Zeitstempel-Abbildung je Plattform, Note-On-Parser, Gerätewahl (rein, getestet)"
```

---
### Task 9: `MidiPortService`, `MidiStrokeSource`, `MicStrokeSource` und der Linux-Integrationstest

**Files:**
- Modify: `lib/features/coaching/midi/midi_port_service.dart` (Klasse ergänzen)
- Create: `lib/features/coaching/midi/midi_stroke_source.dart`, `lib/features/coaching/services/mic_stroke_source.dart`, `test/integration_linux/midi_virtual_port_test.dart`, `tool/midi/virtual_port_test.sh`
- Test: `test/midi/midi_stroke_source_test.dart` (mit Fake-Port), Integrationstest (nur Linux, nur mit `DRUM_COACH_ALSA_TEST=1`)

**Interfaces:**
- Consumes: `MidiCommand` (Task 1), `parseNoteOn`, `chooseMidiDevice`, `MidiTimestampMapper` (Task 8), `KitMapping` (Task 2), `StrokeSource`/`StrokeEvent` (Task 3), `MicAnalysisService.strokeEvents` (Task 4).
- Produces:
  - `abstract class MidiPort { Stream<MidiNoteOn> get noteOns; Stream<bool> get connection; String get deviceName; String get deviceId; Future<void> close(); }`
  - `class MidiPortService { MidiPortService({MidiCommand? midi}); Future<List<({String id, String name, bool hasInput})>> inputDevices(); Future<MidiPort?> open(String deviceId); Stream<void> get setupChanges; }`
  - `class MidiStrokeSource implements StrokeSource { MidiStrokeSource({required MidiPort port, required KitMapping mapping, required MidiTimestampMapper mapper}); bool get deviceLost; }`
  - `class MicStrokeSource implements StrokeSource { MicStrokeSource({MicAnalysisService? service}); MicAnalysisService get service; }`

- [ ] **Step 1: Failing unit test mit Fake-Port**

`test/midi/midi_stroke_source_test.dart`:

```dart
import 'dart:async';

import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/midi/midi_port_service.dart';
import 'package:drum_coach/features/coaching/midi/midi_stroke_source.dart';
import 'package:drum_coach/features/coaching/midi/midi_timestamp_mapper.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePort implements MidiPort {
  final notes = StreamController<MidiNoteOn>.broadcast();
  final conn = StreamController<bool>.broadcast();
  bool closed = false;
  @override
  Stream<MidiNoteOn> get noteOns => notes.stream;
  @override
  Stream<bool> get connection => conn.stream;
  @override
  String get deviceName => 'Fake Module';
  @override
  String get deviceId => '20:0';
  @override
  Future<void> close() async => closed = true;
}

void main() {
  MidiNoteOn on(int note, int vel, int us) => MidiNoteOn(
      note: note,
      velocity: vel,
      channel: 9,
      libTimestamp: us,
      arrivalEpochUs: us + 1200);

  test('maps notes to instruments, velocity to 0–1, time to epoch ms',
      () async {
    final port = FakePort();
    final src = MidiStrokeSource(
      port: port,
      mapping: KitMapping.gm(),
      mapper: MidiTimestampMapper(MidiTimestampUnit.epochMicros),
    );
    await src.start();
    port.notes.add(on(38, 127, 1700000000000000));
    port.notes.add(on(36, 64, 1700000000250000));
    port.notes.add(on(99, 64, 1700000000300000)); // unmapped note
    await Future<void>.delayed(Duration.zero);
    await src.stop();
    expect(src.events.length, 2);
    expect(src.events[0].instrument, KitInstrument.snare);
    expect(src.events[0].velocity, closeTo(1.0, 1e-9));
    expect(src.events[0].timeMs, closeTo(1700000000000.0, 1e-6));
    expect(src.events[0].rawNote, 38);
    expect(src.events[0].source, StrokeSourceKind.midi);
    expect(src.events[1].instrument, KitInstrument.kick);
    expect(src.events[1].velocity, closeTo(64 / 127, 1e-9));
    expect(src.unmappedNotes, {99});
    expect(src.velocityExact, isTrue);
    expect(src.deviceName, 'Fake Module');
    expect(src.describeSetup()!['audioSource'], 'midi');
  });

  test('events before start and after stop are ignored', () async {
    final port = FakePort();
    final src = MidiStrokeSource(
      port: port,
      mapping: KitMapping.gm(),
      mapper: MidiTimestampMapper(MidiTimestampUnit.epochMicros),
    );
    port.notes.add(on(38, 100, 1));
    await Future<void>.delayed(Duration.zero);
    await src.start();
    port.notes.add(on(38, 100, 2));
    await Future<void>.delayed(Duration.zero);
    await src.stop();
    port.notes.add(on(38, 100, 3));
    await Future<void>.delayed(Duration.zero);
    expect(src.events.map((e) => e.rawNote), [38]);
    expect(src.events.length, 1);
  });

  test('device lost mid-session: status notMeasurable, events kept', () async {
    final port = FakePort();
    final src = MidiStrokeSource(
      port: port,
      mapping: KitMapping.gm(),
      mapper: MidiTimestampMapper(MidiTimestampUnit.epochMicros),
    );
    final seen = <StrokeSourceStatus>[];
    src.statusChanges.listen(seen.add);
    await src.start();
    expect(src.status, StrokeSourceStatus.ready);
    port.notes.add(on(38, 100, 1000));
    port.conn.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(src.status, StrokeSourceStatus.notMeasurable);
    expect(src.deviceLost, isTrue);
    expect(seen, [StrokeSourceStatus.notMeasurable]);
    await src.stop();
    expect(src.events.length, 1);
    src.dispose();
    expect(port.closed, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/midi/midi_stroke_source_test.dart`
Expected: FAIL (URIs/Klassen fehlen).

- [ ] **Step 3: `MidiPortService` und `MidiPort` in `midi_port_service.dart` ergänzen**

Imports oben: `import 'dart:async';`, `import 'package:flutter_midi_command/flutter_midi_command.dart';`

```dart
/// An open input port: parsed Note-Ons, connection state, identity.
abstract class MidiPort {
  Stream<MidiNoteOn> get noteOns;

  /// false when the device disappears (unplugged / client exit).
  Stream<bool> get connection;
  String get deviceName;
  String get deviceId;
  Future<void> close();
}

class _CommandPort implements MidiPort {
  _CommandPort(this._midi, this._device)
      : deviceId = _device.id,
        deviceName = _device.name {
    _packets = _midi.onMidiPacketReceived?.listen((packet) {
      if (packet.device.id != _device.id) return;
      final arrival = DateTime.now().microsecondsSinceEpoch;
      final note = parseNoteOn(packet.data,
          libTimestamp: packet.timestamp, arrivalEpochUs: arrival);
      if (note != null) _notes.add(note);
    });
    _setup = _midi.onMidiSetupChanged?.listen((_) async {
      final still = (await _midi.devices ?? const <MidiDevice>[])
          .any((d) => d.id == _device.id);
      if (!still) _connection.add(false);
    });
  }

  final MidiCommand _midi;
  final MidiDevice _device;
  final _notes = StreamController<MidiNoteOn>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  StreamSubscription<MidiPacket>? _packets;
  StreamSubscription<MidiSetupChange>? _setup;

  @override
  final String deviceId;
  @override
  final String deviceName;
  @override
  Stream<MidiNoteOn> get noteOns => _notes.stream;
  @override
  Stream<bool> get connection => _connection.stream;

  @override
  Future<void> close() async {
    await _packets?.cancel();
    await _setup?.cancel();
    await _notes.close();
    await _connection.close();
    try {
      _midi.disconnectDevice(_device);
    } catch (_) {}
  }
}

/// Thin wrapper over `flutter_midi_command` (Brief A.3): device list,
/// open/close, hot-plug notifications. Everything testable lives in the
/// pure functions above and in [MidiStrokeSource].
class MidiPortService {
  MidiPortService({MidiCommand? midi}) : _midi = midi ?? MidiCommand();

  final MidiCommand _midi;

  Future<List<({String id, String name, bool hasInput})>> inputDevices() async {
    List<MidiDevice> devices;
    try {
      devices = await _midi.devices ?? const <MidiDevice>[];
    } catch (_) {
      return const [];
    }
    return [
      for (final d in devices)
        (id: d.id, name: d.name, hasInput: d.inputPorts.isNotEmpty),
    ];
  }

  Future<MidiPort?> open(String deviceId) async {
    final devices = await _midi.devices ?? const <MidiDevice>[];
    for (final d in devices) {
      if (d.id != deviceId) continue;
      try {
        await _midi.connectToDevice(d);
      } catch (_) {
        return null;
      }
      return _CommandPort(_midi, d);
    }
    return null;
  }

  Stream<void> get setupChanges =>
      _midi.onMidiSetupChanged?.map((_) {}) ?? const Stream.empty();
}
```

Prüfen, ob `MidiDevice.inputPorts` existiert (`grep -n "inputPorts" ~/.pub-cache/hosted/pub.dev/flutter_midi_command_platform_interface-1.4.0/lib/midi_device.dart`); falls das Feld anders heißt, dort nachsehen und angleichen. Ebenso `MidiSetupChange` als Typ des Setup-Stroms.

- [ ] **Step 4: `MidiStrokeSource`**

`lib/features/coaching/midi/midi_stroke_source.dart`:

```dart
import 'dart:async';

import '../services/stroke_source.dart';
import 'kit_instrument.dart';
import 'midi_port_service.dart';
import 'midi_timestamp_mapper.dart';

/// Strokes from a MIDI module (Brief A.1). No minimum gap, no level
/// threshold: a Note-On is a stroke. Notes the mapping does not know are
/// counted in [unmappedNotes] for the learn step's hint and dropped.
class MidiStrokeSource implements StrokeSource {
  MidiStrokeSource({
    required MidiPort port,
    required KitMapping mapping,
    required MidiTimestampMapper mapper,
  })  : _port = port,
        _mapping = mapping,
        _mapper = mapper {
    _connSub = _port.connection.listen((connected) {
      if (!connected && _status != StrokeSourceStatus.notMeasurable) {
        deviceLost = true;
        _setStatus(StrokeSourceStatus.notMeasurable);
      }
    });
  }

  final MidiPort _port;
  final KitMapping _mapping;
  final MidiTimestampMapper _mapper;
  final List<StrokeEvent> _events = [];
  final Set<int> unmappedNotes = {};
  final _statusCtrl = StreamController<StrokeSourceStatus>.broadcast();
  StreamSubscription<MidiNoteOn>? _noteSub;
  StreamSubscription<bool>? _connSub;
  StrokeSourceStatus _status = StrokeSourceStatus.ready;
  bool deviceLost = false;

  void _setStatus(StrokeSourceStatus s) {
    _status = s;
    if (!_statusCtrl.isClosed) _statusCtrl.add(s);
  }

  @override
  StrokeSourceKind get kind => StrokeSourceKind.midi;
  @override
  bool get velocityExact => true;
  @override
  StrokeSourceStatus get status => _status;
  @override
  Stream<StrokeSourceStatus> get statusChanges => _statusCtrl.stream;
  @override
  String? get deviceName => _port.deviceName;
  @override
  List<StrokeEvent> get events => List.unmodifiable(_events);

  @override
  Future<void> start() async {
    _events.clear();
    unmappedNotes.clear();
    _noteSub ??= _port.noteOns.listen((n) {
      final instrument = _mapping.instrumentFor(n.note);
      if (instrument == null) {
        unmappedNotes.add(n.note);
        return;
      }
      _events.add(StrokeEvent(
        timeMs: _mapper.toEpochMs(
            libTimestamp: n.libTimestamp, arrivalEpochUs: n.arrivalEpochUs),
        instrument: instrument,
        velocity: n.velocity / 127.0,
        rawNote: n.note,
        source: StrokeSourceKind.midi,
      ));
    });
  }

  @override
  Future<void> stop() async {
    await _noteSub?.cancel();
    _noteSub = null;
  }

  @override
  Map<String, Object>? describeSetup() => {
        'audioSource': 'midi',
        'sampleRate': 0,
        'autoGain': false,
        'echoCancel': false,
        'noiseSuppress': false,
        'midiDevice': _port.deviceName,
        'timestampUnit': _mapper.unit.name,
      };

  @override
  void dispose() {
    _noteSub?.cancel();
    _connSub?.cancel();
    _statusCtrl.close();
    _port.close();
  }
}
```

- [ ] **Step 5: `MicStrokeSource`**

`lib/features/coaching/services/mic_stroke_source.dart`:

```dart
import 'dart:async';

import 'mic_analysis_service.dart';
import 'stroke_source.dart';

/// The microphone as a [StrokeSource]: wraps the Etappe-1 recording chain
/// unchanged (thresholds, sample clock, latency loopback stay inside
/// [MicAnalysisService]).
class MicStrokeSource implements StrokeSource {
  MicStrokeSource({MicAnalysisService? service})
      : service = service ?? MicAnalysisService();

  final MicAnalysisService service;
  final _statusCtrl = StreamController<StrokeSourceStatus>.broadcast();
  StrokeSourceStatus _status = StrokeSourceStatus.ready;

  @override
  StrokeSourceKind get kind => StrokeSourceKind.mic;
  @override
  bool get velocityExact => false;
  @override
  StrokeSourceStatus get status => _status;
  @override
  Stream<StrokeSourceStatus> get statusChanges => _statusCtrl.stream;
  @override
  String? get deviceName => null;
  @override
  List<StrokeEvent> get events => service.strokeEvents;

  @override
  Future<void> start() async {
    try {
      await service.startRecording();
      _status = StrokeSourceStatus.ready;
    } catch (_) {
      _status = StrokeSourceStatus.notMeasurable;
      _statusCtrl.add(_status);
      rethrow;
    }
  }

  @override
  Future<void> stop() => service.stopRecording();

  @override
  Map<String, Object>? describeSetup() => service.setup?.describe();

  @override
  void dispose() {
    _statusCtrl.close();
    service.dispose();
  }
}
```

- [ ] **Step 6: Unit-Tests laufen lassen**

Run: `flutter test test/midi/midi_stroke_source_test.dart`
Expected: 3 PASS.

- [ ] **Step 7: Linux-Integrationstest über den virtuellen Port**

`test/integration_linux/midi_virtual_port_test.dart`:

```dart
@Tags(['alsa'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/midi/midi_port_service.dart';
import 'package:drum_coach/features/coaching/midi/midi_stroke_source.dart';
import 'package:drum_coach/features/coaching/midi/midi_timestamp_mapper.dart';
import 'package:flutter_midi_command_linux/flutter_midi_command_linux.dart';
import 'package:flutter_midi_command_platform_interface/flutter_midi_command_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end over ALSA virmidi (docs/BERICHT_ETAPPE2_§0.md): the Python
/// sender writes 64 notes to /dev/snd/midiC1D0, the real plugin + source
/// receive them. Runs only with DRUM_COACH_ALSA_TEST=1 on Linux.
void main() {
  final enabled =
      Platform.isLinux && Platform.environment['DRUM_COACH_ALSA_TEST'] == '1';

  test('64 of 64 notes, p95 jitter < 0.5 ms, flams 25 ± 1 ms', () async {
    MidiCommandPlatform.instance = FlutterMidiCommandLinux();
    final service = MidiPortService();
    final devices = await service.inputDevices();
    final virt = devices.where((d) => d.name.contains('Virtual Raw MIDI 1-0'));
    expect(virt, isNotEmpty, reason: 'modprobe snd-virmidi + audio group');
    final port = (await service.open(virt.first.id))!;
    final src = MidiStrokeSource(
      port: port,
      mapping: KitMapping.gm(),
      mapper: MidiTimestampMapper(MidiTimestampUnit.epochMicros),
    );
    await src.start();

    final sendLog = '${Directory.systemTemp.path}/drum_coach_send.jsonl';
    final proc = await Process.run('python3', [
      'tool/midi/spike/send_pattern.py',
      '/dev/snd/midiC1D0',
      sendLog,
      '--quick',
    ]);
    expect(proc.exitCode, 0, reason: proc.stderr.toString());
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await src.stop();
    src.dispose();

    final sent = [
      for (final l in File(sendLog).readAsLinesSync())
        if (l.trim().isNotEmpty) jsonDecode(l) as Map<String, Object?>,
    ];
    final recv = src.events;
    expect(recv.length, sent.length);

    // Jitter: receive interval minus send interval, relative to note 0.
    // Clocks differ (monotonic vs wall) — only the differences matter.
    final s0 = sent.first['send_us'] as int;
    final r0 = recv.first.timeMs;
    final dev = <double>[];
    for (var i = 0; i < sent.length; i++) {
      final ds = ((sent[i]['send_us'] as int) - s0) / 1000.0;
      final dr = recv[i].timeMs - r0;
      dev.add(dr - ds);
    }
    final sorted = List<double>.of(dev)..sort();
    final median = sorted[sorted.length ~/ 2];
    final abs = [for (final d in dev) (d - median).abs()]..sort();
    final p95 = abs[(abs.length * 0.95).floor().clamp(0, abs.length - 1)];
    expect(p95, lessThan(0.5), reason: 'p95 |jitter| ms');

    for (var i = 1; i < sent.length; i++) {
      if (sent[i]['tag'] == 'B2' && sent[i - 1]['tag'] == 'B1') {
        expect(recv[i].timeMs - recv[i - 1].timeMs, closeTo(25, 1));
      }
    }
  }, skip: enabled ? false : 'needs Linux + DRUM_COACH_ALSA_TEST=1');
}
```

`tool/midi/virtual_port_test.sh`:

```bash
#!/usr/bin/env bash
# Linux-Integrationstest über den virtuellen ALSA-Port (Brief A, Technische
# Festlegungen). Voraussetzungen: modprobe snd-virmidi, Benutzer in audio.
set -euo pipefail
cd "$(dirname "$0")/../.."
exec sg audio -c "DRUM_COACH_ALSA_TEST=1 flutter test --tags alsa test/integration_linux/"
```

`chmod +x tool/midi/virtual_port_test.sh`. In `dart_test.yaml` (anlegen, falls nicht vorhanden) den Tag deklarieren:

```yaml
tags:
  alsa:
    skip: false
```

- [ ] **Step 8: Integrationstest auf dem NUC laufen lassen**

Run: `tool/midi/virtual_port_test.sh`
Expected: 1 PASS mit `64 of 64`. Falls `MidiCommandPlatform.instance` nicht setzbar ist (Setter fehlt), die Zuweisung weglassen — `flutter test` registriert Dart-Plugins für den Host; dann prüfen, dass `inputDevices()` den virtuellen Port liefert. Ohne Umgebungsvariable muss `flutter test` den Test als „skipped" zeigen, nicht als Fehler.

- [ ] **Step 9: Commit**

```bash
git add lib/features/coaching/midi/midi_port_service.dart lib/features/coaching/midi/midi_stroke_source.dart lib/features/coaching/services/mic_stroke_source.dart test/midi/midi_stroke_source_test.dart test/integration_linux/midi_virtual_port_test.dart tool/midi/virtual_port_test.sh dart_test.yaml
git commit -m "feat(midi): MidiPortService, MidiStrokeSource, MicStrokeSource + Linux-Integrationstest über virtuellen Port"
```

---

### Task 10: Desktop-Grundlage — `platform_support`, Notifications No-Op, Breitendeckel, Mindestfenster

**Files:**
- Create: `lib/app/platform_support.dart`
- Modify: `lib/main.dart`, `lib/services/notification_service.dart`, `linux/runner/my_application.cc`
- Test: `test/app/platform_support_test.dart`, `test/app/content_width_cap_test.dart`

**Interfaces:**
- Produces: `bool get isDesktopPlatform`, `bool get aiCoachingAvailable`, `bool get localNotificationsAvailable`, `bool get micAllowedByDefault`, `const double desktopContentMaxWidth = 900`, `@visibleForTesting bool? debugDesktopOverride`, `Widget capContentWidth(BuildContext, Widget?)`.

- [ ] **Step 1: Failing tests**

`test/app/platform_support_test.dart`:

```dart
import 'package:drum_coach/app/platform_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDesktopOverride = null);

  test('desktop override drives every derived flag', () {
    debugDesktopOverride = true;
    expect(isDesktopPlatform, isTrue);
    expect(aiCoachingAvailable, isFalse);
    expect(localNotificationsAvailable, isFalse);
    expect(micAllowedByDefault, isFalse);
    debugDesktopOverride = false;
    expect(isDesktopPlatform, isFalse);
    expect(aiCoachingAvailable, isTrue);
    expect(localNotificationsAvailable, isTrue);
    expect(micAllowedByDefault, isTrue);
  });

  test('without override the host decides (test host is desktop)', () {
    // flutter test runs on a desktop OS; the real app on the phone sees
    // false. This only pins that the getter reads the platform.
    expect(isDesktopPlatform, isTrue);
  });
}
```

`test/app/content_width_cap_test.dart`:

```dart
import 'package:drum_coach/app/platform_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDesktopOverride = null);

  testWidgets('desktop: content is centered and capped at 900', (t) async {
    debugDesktopOverride = true;
    await t.binding.setSurfaceSize(const Size(1400, 800));
    await t.pumpWidget(MaterialApp(
      builder: capContentWidth,
      home: const SizedBox.expand(key: Key('content')),
    ));
    expect(t.getSize(find.byKey(const Key('content'))).width, 900);
  });

  testWidgets('mobile: content fills the width', (t) async {
    debugDesktopOverride = false;
    await t.binding.setSurfaceSize(const Size(1400, 800));
    await t.pumpWidget(MaterialApp(
      builder: capContentWidth,
      home: const SizedBox.expand(key: Key('content')),
    ));
    expect(t.getSize(find.byKey(const Key('content'))).width, 1400);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/app/platform_support_test.dart test/app/content_width_cap_test.dart`
Expected: FAIL (URI fehlt).

- [ ] **Step 3: Implementation**

`lib/app/platform_support.dart`:

```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The one place that knows whether we run on a desktop (Brief Etappe 2,
/// A.7). Tests inject [debugDesktopOverride]; production reads the host.
@visibleForTesting
bool? debugDesktopOverride;

bool get isDesktopPlatform =>
    debugDesktopOverride ??
    (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS));

/// AI coaching needs the phone-only flow (API key, share sheet).
bool get aiCoachingAvailable => !isDesktopPlatform;

/// flutter_local_notifications 17 has no Linux/Windows implementation.
bool get localNotificationsAvailable => !isDesktopPlatform;

/// Desktop microphone capture (`record_linux`) is untested: off unless the
/// user picks "Mic" explicitly.
bool get micAllowedByDefault => !isDesktopPlatform;

/// Phone layout, centered, capped — no desktop redesign in Phase A.
const double desktopContentMaxWidth = 900;

Widget capContentWidth(BuildContext context, Widget? child) {
  if (!isDesktopPlatform || child == null) return child ?? const SizedBox();
  return ColoredBox(
    color: const Color(0xFF111111),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: desktopContentMaxWidth),
        child: child,
      ),
    ),
  );
}
```

`lib/main.dart`: Import `app/platform_support.dart`; den `try { await NotificationService.init() … }`-Block in `if (localNotificationsAvailable) { … }` einschließen. In `DrumCoachApp.build`: `MaterialApp.router(title: 'DrumCoach', theme: drumCoachTheme, routerConfig: router, builder: capContentWidth)`.

`lib/services/notification_service.dart`: Import `../app/platform_support.dart`; am Anfang von `init`, `scheduleDailyReminder` und jeder weiteren öffentlichen Methode, die `_plugin` berührt: `if (!localNotificationsAvailable) return;` (Methodenliste vorher mit `grep -n "static Future" lib/services/notification_service.dart` prüfen).

`linux/runner/my_application.cc`: nach `gtk_window_set_default_size(window, 1280, 720);` ergänzen:

```c
  // Brief Etappe 2, A.7: never let sheet, tempo row and buttons squeeze.
  gtk_widget_set_size_request(GTK_WIDGET(window), 720, 640);
```

- [ ] **Step 4: Tests + Linux-Build**

Run: `flutter test test/app/` → grün. Run: `flutter build linux --release` (auf dem NUC; braucht die Pakete aus dem Brief A.7) → `✓ Built build/linux/x64/release/bundle/drum_coach`. Start unter Xvfb zur Rauchprobe (nur, dass das Fenster hochkommt):

```bash
NO_AT_BRIDGE=1 GTK_A11Y=none LIBGL_ALWAYS_SOFTWARE=1 timeout 20 xvfb-run -a build/linux/x64/release/bundle/drum_coach; echo "exit=$?"
```

Expected: exit 124 (lief bis zum Timeout, kein Absturz); keine `Unhandled Exception` in der Ausgabe.

- [ ] **Step 5: Commit**

```bash
git add lib/app/platform_support.dart lib/main.dart lib/services/notification_service.dart linux/runner/my_application.cc test/app/platform_support_test.dart test/app/content_width_cap_test.dart
git commit -m "feat(desktop): platform_support, Notifications No-Op, Breitendeckel 900, Mindestfenster — Linux-Build läuft"
```

---

### Task 11: Übungs-Screen — Quellenwahl, Messung, Chip, Analyse, Log, „not measurable"

**Files:**
- Modify: `lib/features/practice/practice_session_screen.dart`, `lib/features/practice/analysis_announcement.dart`
- Test: `test/practice/analysis_announcement_test.dart` (erweitern), `test/practice/measurement_plan_test.dart` (neu, reine Quellenwahl)

**Interfaces:**
- Consumes: `MeasurementSource`, `SettingsService.*` (Task 7), `MidiPortService`, `MidiStrokeSource`, `MicStrokeSource` (Task 9), `analyzeStrokes` (Task 4), `buildSessionLog(source:, midiDevice:, kitMapping:)` (Task 6), `isDesktopPlatform`, `micAllowedByDefault` (Task 10), `Rudiment.requiredSensor` (Task 3).
- Produces: reine Funktion `MeasurementPlan planMeasurement({required MeasurementSource preference, required bool midiDeviceAvailable, required bool isDesktop})` → `enum MeasurementPlan { midi, mic, none }` in `lib/features/practice/measurement_plan.dart`; `analysisAnnouncement` kennt `notMeasurable`.

- [ ] **Step 1: Failing tests**

`test/practice/measurement_plan_test.dart`:

```dart
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/practice/measurement_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auto: midi when a device is there, else mic on the phone', () {
    expect(
        planMeasurement(
            preference: MeasurementSource.auto,
            midiDeviceAvailable: true,
            isDesktop: false),
        MeasurementPlan.midi);
    expect(
        planMeasurement(
            preference: MeasurementSource.auto,
            midiDeviceAvailable: false,
            isDesktop: false),
        MeasurementPlan.mic);
  });

  test('auto on desktop without midi: nothing (mic untested there)', () {
    expect(
        planMeasurement(
            preference: MeasurementSource.auto,
            midiDeviceAvailable: false,
            isDesktop: true),
        MeasurementPlan.none);
  });

  test('explicit mic on desktop is honoured', () {
    expect(
        planMeasurement(
            preference: MeasurementSource.mic,
            midiDeviceAvailable: true,
            isDesktop: true),
        MeasurementPlan.mic);
  });

  test('midi without device: nothing; off: nothing', () {
    expect(
        planMeasurement(
            preference: MeasurementSource.midi,
            midiDeviceAvailable: false,
            isDesktop: false),
        MeasurementPlan.none);
    expect(
        planMeasurement(
            preference: MeasurementSource.off,
            midiDeviceAvailable: true,
            isDesktop: false),
        MeasurementPlan.none);
  });
}
```

In `test/practice/analysis_announcement_test.dart` ergänzen:

```dart
  test('not measurable beats every other verdict', () {
    final a = analysisAnnouncement(
      const SessionAnalysis(
          detectedHits: 0, expectedHits: 8, notMeasurable: true),
      analysisMode: true,
    )!;
    expect(a.positive, isFalse);
    expect(a.text, contains('not measurable'));
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/practice/measurement_plan_test.dart test/practice/analysis_announcement_test.dart`
Expected: FAIL.

- [ ] **Step 3: Reine Quellenwahl und Announcement**

`lib/features/practice/measurement_plan.dart`:

```dart
import '../../data/local/settings_service.dart';

enum MeasurementPlan { midi, mic, none }

/// Which source the practice screen opens (Brief A.6/A.7): MIDI whenever
/// allowed and present; the microphone where allowed — on the desktop only
/// on explicit request.
MeasurementPlan planMeasurement({
  required MeasurementSource preference,
  required bool midiDeviceAvailable,
  required bool isDesktop,
}) {
  if (preference.mayUseMidi && midiDeviceAvailable) return MeasurementPlan.midi;
  if (preference == MeasurementSource.mic) return MeasurementPlan.mic;
  if (preference == MeasurementSource.auto && !isDesktop) {
    return MeasurementPlan.mic;
  }
  return MeasurementPlan.none;
}
```

`analysis_announcement.dart`, als erste Prüfung in `analysisAnnouncement`:

```dart
  if (analysis.notMeasurable) {
    return const Announcement(
      'Not measurable with this setup — MIDI device lost or missing.',
      positive: false,
    );
  }
```

- [ ] **Step 4: Übungs-Screen umbauen**

In `practice_session_screen.dart`:

1. Imports ergänzen: `../../app/platform_support.dart`, `../coaching/midi/midi_port_service.dart`, `../coaching/midi/midi_stroke_source.dart`, `../coaching/midi/midi_timestamp_mapper.dart`, `../coaching/services/mic_stroke_source.dart`, `../coaching/services/stroke_analysis.dart`, `../coaching/services/stroke_source.dart`, `measurement_plan.dart`. `dart:io` für `Platform.isAndroid/isLinux` **nicht** importieren — die Einheit kommt über `midiTimestampUnitForPlatform(isAndroid: !isDesktopPlatform, isLinux: isDesktopPlatform)` (Phase A kennt nur Android und Linux-Desktop; Windows folgt mit Superior Drummer).

2. Felder (Zeilen 149–151) ersetzen:

```dart
  // Measurement (Brief Etappe 2, A.1): one stroke source, mic or MIDI.
  StrokeSource? _source;
  bool _measuring = false;
  String? _midiDeviceName;
  StreamSubscription<StrokeSourceStatus>? _sourceStatusSub;
  bool _sourceLost = false;
```

3. `_backingAllowed` (Zeile 179) ersetzen:

```dart
  /// Backing: silent whenever the *microphone* listens without headphones.
  /// MIDI cannot hear the speaker (Brief A.5).
  bool get _micListens =>
      _source?.kind == StrokeSourceKind.mic ||
      (_source == null &&
          planMeasurement(
                preference: SettingsService.measurementSource,
                midiDeviceAvailable: false,
                isDesktop: isDesktopPlatform,
              ) ==
              MeasurementPlan.mic);
  bool get _backingAllowed => !_micListens || _headphones;
```

4. `_initMicIfEnabled` (Zeilen 375–381) ersetzen durch:

```dart
  Future<void> _initMeasurement() async {
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final ports = MidiPortService();
    final devices = await ports.inputDevices();
    final chosen = chooseMidiDevice(devices,
        lastId: SettingsService.midiLastDeviceId);
    final plan = planMeasurement(
      preference: SettingsService.measurementSource,
      midiDeviceAvailable: chosen != null,
      isDesktop: isDesktopPlatform,
    );
    if (!mounted) return;
    switch (plan) {
      case MeasurementPlan.midi:
        final port = await ports.open(chosen!);
        if (port == null || !mounted) return;
        await SettingsService.setMidiLastDeviceId(chosen);
        _midiDeviceName = port.deviceName;
        _source = MidiStrokeSource(
          port: port,
          mapping: SettingsService.kitMappingFor(port.deviceName),
          mapper: MidiTimestampMapper(midiTimestampUnitForPlatform(
              isAndroid: !isDesktopPlatform, isLinux: isDesktopPlatform)),
        );
      case MeasurementPlan.mic:
        final status = await Permission.microphone.request();
        if (status.isGranted && mounted) _source = MicStrokeSource();
      case MeasurementPlan.none:
        return;
    }
    final src = _source;
    if (src == null) return;
    // Sensor level (Brief A.6): an exercise above the source's level is
    // played without numbers.
    if (!rudiment.requiredSensor.satisfiedBy(src.kind)) {
      src.dispose();
      _source = null;
      return;
    }
    _sourceStatusSub = src.statusChanges.listen((s) {
      if (s == StrokeSourceStatus.notMeasurable && mounted) {
        setState(() => _sourceLost = true);
      }
    });
    if (mounted) setState(() {});
  }
```

Den Aufruf `_initMicIfEnabled()` in `initState` durch `_initMeasurement()` ersetzen (`grep -n "_initMicIfEnabled" …` zeigt die Stelle).

5. `dispose`: `_micService?.stopRecording(); _micService?.dispose();` ersetzen durch `_sourceStatusSub?.cancel(); _source?.stop(); _source?.dispose();`.

6. `_startMicRecording`/`_stopMicRecording` (Zeilen 462–476) ersetzen:

```dart
  Future<void> _startMeasuring() async {
    final src = _source;
    if (src == null || _measuring) return;
    try {
      await src.start();
      if (mounted) setState(() => _measuring = true);
    } catch (_) {}
  }

  Future<void> _stopMeasuring() async {
    if (!_measuring) return;
    try {
      await _source!.stop();
      _measuring = false;
    } catch (_) {}
  }
```

Alle Aufrufer umbenennen (`grep -n "_startMicRecording\|_stopMicRecording\|_micRecording" …`): `_micRecording` → `_measuring`.

7. Analyse in `_finishSession` (Zeilen 635–647) ersetzen:

```dart
    final src = _source;
    if (src != null && _beatLog.isNotEmpty) {
      try {
        if (_sourceLost || src.status == StrokeSourceStatus.notMeasurable) {
          analysis = SessionAnalysis(
            detectedHits: src.events.length,
            expectedHits: _beatLog.length,
            notMeasurable: true,
            source: src.kind,
            recordingSetup: src.describeSetup(),
            events: [
              for (final e in src.events)
                OnsetEventData(
                  timeMs: e.timeMs,
                  peakLevel: e.velocity,
                  instrument: e.instrument.name,
                  rawNote: e.rawNote,
                ),
            ],
          );
        } else {
          final isMidi = src.kind == StrokeSourceKind.midi;
          analysis = analyzeStrokes(
            events: src.events,
            beatLog: _beatLog,
            sticking: _unit.sticking,
            source: src.kind,
            expectedInstrument: isMidi
                ? SettingsService.padRoleInstrument
                : KitInstrument.pad,
            latencyOffsetMs: isMidi
                ? (SettingsService.midiLatencyOffsetMsFor(
                        _midiDeviceName ?? '') ??
                    0)
                : (SettingsService.latencyOffsetMs ?? 0),
            analysisMode: _analysisMode,
            recordingSetup: src.describeSetup(),
          );
        }
      } catch (e) {
        debugPrint('analysis failed: $e');
      }
    }
```

(`KitInstrument`-Import: `../coaching/midi/kit_instrument.dart`.)

8. `buildSessionLog`-Aufruf (Zeilen 761–776) erweitern:

```dart
        latencyOffsetMs: _source?.kind == StrokeSourceKind.midi
            ? SettingsService.midiLatencyOffsetMsFor(_midiDeviceName ?? '')
            : SettingsService.latencyOffsetMs,
        source: _source?.kind.name ?? 'off',
        midiDevice: _midiDeviceName,
        kitMapping: _midiDeviceName == null
            ? null
            : SettingsService.kitMappingFor(_midiDeviceName!).encode(),
```

(die bestehende Zeile `latencyOffsetMs: SettingsService.latencyOffsetMs,` ersetzen).

9. Beat-Log-Bedingung (Zeile 878): `if (_micRecording && newTick && !stale)` → `if (_measuring && newTick && !stale)`.

10. Chip (Zeile 988 ff.): `SettingsService.micAnalysisEnabled ? _ModeChip(analysis: …, micOn: _micRecording, …)` ersetzen durch

```dart
                  modeChip: SettingsService.measurementSource !=
                          MeasurementSource.off
                      ? _ModeChip(
                          analysis: _analysisMode,
                          source: _source?.kind,
                          active: _measuring && !_sourceLost,
                          unavailable: _source == null || _sourceLost,
                          onTap: () { /* unverändert */ },
                        )
                      : null,
```

und `_ModeChip` (Zeile 1341 ff.) umbauen: Parameter `micOn` → `source` (`StrokeSourceKind?`), `active` (`bool`), `unavailable` (`bool`); Icon: `source == StrokeSourceKind.midi ? Icons.piano : Icons.mic` bzw. `Icons.mic_off` bei `unavailable`; Farbe `active ? accent : textFaint`; Tooltip bei `unavailable`: `'Not measurable with this setup'`, sonst wie bisher. Label bleibt `ANALYSIS`/`LEARN`.

- [ ] **Step 5: Tests, Analyse, Gerät**

Run: `flutter analyze` → keine Fehler. Run: `flutter test` → grün. Rauchprobe im Emulator (NUC, `~/bin/emu-nuc.sh`): Übung starten, Mikrofon-Weg wie bisher (Regressionsprüfung Pad), Ergebnis-Blatt erscheint, Export enthält `"source":"mic"`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/practice/practice_session_screen.dart lib/features/practice/measurement_plan.dart lib/features/practice/analysis_announcement.dart test/practice/measurement_plan_test.dart test/practice/analysis_announcement_test.dart
git commit -m "feat(practice): Schlagquelle wählen (MIDI/Mikro), Messung über analyzeStrokes, Chip mit Quelle, not measurable, Log-Felder"
```

---

### Task 12: Tastenkürzel auf dem Desktop

**Files:**
- Modify: `lib/features/practice/practice_session_screen.dart` (um das `Scaffold` ab Zeile 941)
- Create: `lib/features/practice/practice_shortcuts.dart`
- Test: `test/practice/practice_shortcuts_test.dart`

**Interfaces:**
- Produces: `Map<ShortcutActivator, VoidCallback> practiceShortcuts({required VoidCallback toggle, required ValueChanged<int> bumpBpm, required VoidCallback leave})` — Leertaste → `toggle`; Pfeil hoch / `+` → `bumpBpm(1)`, mit Umschalt `bumpBpm(5)`; Pfeil runter / `-` → `bumpBpm(-1)` / `-5`; Esc → `leave`.

- [ ] **Step 1: Failing test**

`test/practice/practice_shortcuts_test.dart`:

```dart
import 'package:drum_coach/features/practice/practice_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('space toggles, arrows bump, shift bumps by 5, esc leaves',
      (t) async {
    var toggles = 0, left = 0;
    final bumps = <int>[];
    await t.pumpWidget(MaterialApp(
      home: CallbackShortcuts(
        bindings: practiceShortcuts(
          toggle: () => toggles++,
          bumpBpm: bumps.add,
          leave: () => left++,
        ),
        child: const Focus(autofocus: true, child: SizedBox.expand()),
      ),
    ));
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(toggles, 1);
    expect(bumps, [1, -1, 5]);
    expect(left, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/practice/practice_shortcuts_test.dart`
Expected: FAIL (URI fehlt).

- [ ] **Step 3: Implementation**

`lib/features/practice/practice_shortcuts.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Desktop keys for the practice screen (Brief Etappe 2, A.7).
Map<ShortcutActivator, VoidCallback> practiceShortcuts({
  required VoidCallback toggle,
  required ValueChanged<int> bumpBpm,
  required VoidCallback leave,
}) =>
    {
      const SingleActivator(LogicalKeyboardKey.space): toggle,
      const SingleActivator(LogicalKeyboardKey.arrowUp): () => bumpBpm(1),
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () =>
          bumpBpm(5),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () => bumpBpm(-1),
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () =>
          bumpBpm(-5),
      const SingleActivator(LogicalKeyboardKey.equal): () => bumpBpm(1),
      const SingleActivator(LogicalKeyboardKey.add): () => bumpBpm(1),
      const SingleActivator(LogicalKeyboardKey.minus): () => bumpBpm(-1),
      const SingleActivator(LogicalKeyboardKey.numpadSubtract): () =>
          bumpBpm(-1),
      const SingleActivator(LogicalKeyboardKey.escape): leave,
    };
```

Im Übungs-Screen das `Scaffold` (Zeile 941) einhüllen, nur auf dem Desktop:

```dart
        child: isDesktopPlatform
            ? CallbackShortcuts(
                bindings: practiceShortcuts(
                  toggle: notifier.toggle,
                  bumpBpm: (d) => _onUserBpmChanged(
                      (ref.read(metronomeNotifierProvider).bpm + d)
                          .clamp(40, 240)),
                  leave: () {
                    if (ref.read(metronomeNotifierProvider).isPlaying) {
                      notifier.toggle();
                    } else {
                      context.pop();
                    }
                  },
                ),
                child: Focus(autofocus: true, child: scaffold),
              )
            : scaffold,
```

Dafür das bestehende `Scaffold(...)` in eine lokale Variable `final scaffold = Scaffold(…);` vor dem `return` ziehen. `notifier` ist die im `build` vorhandene `MetronomeNotifier`-Referenz (siehe `onPressed: notifier.toggle`, Zeile 1086); `context.pop` kommt aus `go_router`.

- [ ] **Step 4: Tests**

Run: `flutter test test/practice/` → grün; `flutter analyze` sauber.

- [ ] **Step 5: Commit**

```bash
git add lib/features/practice/practice_shortcuts.dart lib/features/practice/practice_session_screen.dart test/practice/practice_shortcuts_test.dart
git commit -m "feat(desktop): Tastenkürzel im Übungs-Screen — Leertaste, Pfeile/±, Esc"
```

---
### Task 13: Einstellungen — Abschnitt MEASUREMENT, Routen, KI-Coaching auf dem Desktop aus

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`, `lib/app/router.dart`, `lib/data/local/settings_service.dart` (Setter `setMicAnalysisEnabled` entfernen)
- Test: `test/features/settings/settings_measurement_section_test.dart`

**Interfaces:**
- Consumes: `MeasurementSource`, `SettingsService.measurementSource/padRoleInstrument` (Task 7), `MidiPortService.inputDevices()` (Task 9), `aiCoachingAvailable` (Task 10).
- Produces: Routen `/settings/kit-learn` → `KitLearnScreen` (Task 14) und `/settings/midi-calibration` → `MidiCalibrationScreen` (Task 15); in dieser Aufgabe zeigen beide Routen vorläufig `const Scaffold(body: Center(child: Text('Coming in the next task')))` und werden in Task 14/15 ersetzt. Widget `MeasurementSection({required MidiPortService ports})`.

- [ ] **Step 1: Failing widget test**

`test/features/settings/settings_measurement_section_test.dart`:

```dart
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/coaching/midi/midi_port_service.dart';
import 'package:drum_coach/features/settings/measurement_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePorts implements MidiPortService {
  FakePorts(this.list);
  final List<({String id, String name, bool hasInput})> list;
  @override
  Future<List<({String id, String name, bool hasInput})>> inputDevices() async =>
      list;
  @override
  Future<MidiPort?> open(String deviceId) async => null;
  @override
  Stream<void> get setupChanges => const Stream.empty();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });

  testWidgets('shows the four sources, saves the choice, lists the device',
      (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MeasurementSection(
          ports: FakePorts([(id: '20:0', name: 'Millenium', hasInput: true)]),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Mic'), findsOneWidget);
    expect(find.text('MIDI'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.textContaining('Millenium'), findsOneWidget);
    await t.tap(find.text('MIDI'));
    await t.pumpAndSettle();
    expect(SettingsService.measurementSource, MeasurementSource.midi);
  });

  testWidgets('no device: says so and still offers the learn step', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: MeasurementSection(ports: FakePorts(const []))),
    ));
    await t.pumpAndSettle();
    expect(find.textContaining('No MIDI device'), findsOneWidget);
    expect(find.text('Learn kit'), findsOneWidget);
    expect(find.text('MIDI latency'), findsOneWidget);
  });
}
```

Damit `FakePorts implements MidiPortService` kompiliert, darf `MidiPortService` keine weiteren öffentlichen Mitglieder haben als die drei oben; private `_midi` ist unproblematisch.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings/settings_measurement_section_test.dart`
Expected: FAIL (`measurement_section.dart` fehlt).

- [ ] **Step 3: `MeasurementSection` als eigenes Widget**

`lib/features/settings/measurement_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../data/local/settings_service.dart';
import '../../shared/widgets/app_card.dart';
import '../coaching/midi/kit_instrument.dart';
import '../coaching/midi/midi_port_service.dart';

/// Settings block "MEASUREMENT" (Brief Etappe 2, A.3/A.6): source choice,
/// MIDI device status, learn step, latency, pad role.
class MeasurementSection extends StatefulWidget {
  const MeasurementSection({super.key, required this.ports});

  final MidiPortService ports;

  @override
  State<MeasurementSection> createState() => _MeasurementSectionState();
}

class _MeasurementSectionState extends State<MeasurementSection> {
  List<({String id, String name, bool hasInput})> _devices = const [];
  late MeasurementSource _source = SettingsService.measurementSource;
  late KitInstrument _padRole = SettingsService.padRoleInstrument;

  @override
  void initState() {
    super.initState();
    _refresh();
    widget.ports.setupChanges.listen((_) => _refresh());
  }

  Future<void> _refresh() async {
    final devices = await widget.ports.inputDevices();
    if (!mounted) return;
    setState(() => _devices = [for (final d in devices) if (d.hasInput) d]);
  }

  @override
  Widget build(BuildContext context) {
    final device = _devices.isEmpty ? null : _devices.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<MeasurementSource>(
          segments: const [
            ButtonSegment(value: MeasurementSource.auto, label: Text('Auto')),
            ButtonSegment(value: MeasurementSource.mic, label: Text('Mic')),
            ButtonSegment(value: MeasurementSource.midi, label: Text('MIDI')),
            ButtonSegment(value: MeasurementSource.off, label: Text('Off')),
          ],
          selected: {_source},
          onSelectionChanged: (s) async {
            await SettingsService.setMeasurementSource(s.first);
            if (mounted) setState(() => _source = s.first);
          },
        ),
        const SizedBox(height: 6),
        const Text(
          'Auto: MIDI when a module is connected, otherwise the microphone.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            children: [
              Icon(device == null ? Icons.usb_off : Icons.piano,
                  size: 20, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  device == null
                      ? 'No MIDI device connected'
                      : 'MIDI: ${device.name}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => context.push('/settings/kit-learn'),
          child: const Row(
            children: [
              Icon(Icons.school_outlined, size: 20, color: AppColors.textMuted),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learn kit',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Hit each pad once so the app knows your module',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => context.push('/settings/midi-calibration'),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 20, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MIDI latency',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      device != null &&
                              SettingsService.midiLatencyOffsetMsFor(
                                      device.name) !=
                                  null
                          ? 'Saved: ${SettingsService.midiLatencyOffsetMsFor(device.name)!.round()} ms'
                          : 'Not calibrated yet — play 16 quarters to the click',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textFaint),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text('Pad role at the set',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            DropdownButton<KitInstrument>(
              value: _padRole,
              items: [
                for (final i in KitInstrument.learnOrder)
                  DropdownMenuItem(value: i, child: Text(i.label)),
              ],
              onChanged: (i) async {
                if (i == null) return;
                await SettingsService.setPadRoleInstrument(i);
                if (mounted) setState(() => _padRole = i);
              },
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Settings-Screen und Router**

`settings_screen.dart`:
- Import `measurement_section.dart`, `../coaching/midi/midi_port_service.dart`, `../../app/platform_support.dart`.
- Felder `_micEnabled` und `_setMicEnabled` entfernen; den `_SettingsTile`-Block „Microphone analysis" (Zeilen 140–146) ersetzen durch `_SectionLabel('MEASUREMENT'), const SizedBox(height: 10), MeasurementSection(ports: MidiPortService()), const SizedBox(height: 28),` und darunter den bisherigen `_SectionLabel('AI COACHING')` behalten.
- Den gesamten AI-Coaching-Teil (API-Key-Feld, „Save API Key", „Exercise Generator") in `if (aiCoachingAvailable) ...[ … ]` einschließen (Collection-if in der `children`-Liste). Export der Session-Logs und Latenz-Kalibrierung (Mikrofon) bleiben sichtbar.
- In `settings_service.dart` den „Transitional"-Setter `setMicAnalysisEnabled` löschen; `flutter analyze` muss danach keinen Aufrufer mehr finden.

`router.dart`: nach der Route `/settings/latency-calibration` ergänzen:

```dart
    GoRoute(
      path: '/settings/kit-learn',
      builder: (context, state) => const KitLearnScreen(),
    ),
    GoRoute(
      path: '/settings/midi-calibration',
      builder: (context, state) => const MidiCalibrationScreen(),
    ),
```

Für diese Aufgabe beide Screens als Platzhalter in ihren Dateien anlegen (`lib/features/settings/kit_learn_screen.dart`, `midi_calibration_screen.dart`):

```dart
import 'package:flutter/material.dart';

class KitLearnScreen extends StatelessWidget {
  const KitLearnScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Learn kit')),
        body: const Center(child: Text('Coming in the next task')),
      );
}
```

(analog `MidiCalibrationScreen` mit Titel `'MIDI latency'`). Task 14/15 ersetzen sie.

- [ ] **Step 5: Tests**

Run: `flutter test test/features/settings/ test/app/` → grün (`router_test.dart` prüfen: falls es Routen zählt, die zwei neuen ergänzen). `flutter analyze` sauber.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/measurement_section.dart lib/features/settings/settings_screen.dart lib/features/settings/kit_learn_screen.dart lib/features/settings/midi_calibration_screen.dart lib/app/router.dart lib/data/local/settings_service.dart test/features/settings/settings_measurement_section_test.dart
git commit -m "feat(settings): Abschnitt MEASUREMENT (Quelle, Gerät, Lernschritt, Latenz, Pad-Rolle), KI-Coaching auf Desktop aus"
```

---

### Task 14: Lernschritt „Hit the …" — Zustandsautomat und Screen

**Files:**
- Create: `lib/features/coaching/midi/kit_learn_session.dart`
- Modify: `lib/features/settings/kit_learn_screen.dart` (Platzhalter ersetzen)
- Test: `test/midi/kit_learn_session_test.dart`

**Interfaces:**
- Consumes: `KitInstrument.learnOrder`, `KitMapping` (Task 2), `MidiPortService`, `MidiPort.noteOns` (Task 9), `SettingsService.kitMappingFor/setKitMappingFor/midiLastDeviceId` (Task 7).
- Produces: `class KitLearnSession { KitLearnSession({required KitMapping start}); KitInstrument? get current; int get index; int get total; KitMapping get mapping; bool get done; String? get hint; void hit(int note); void skip(); void back(); }`

- [ ] **Step 1: Failing test**

`test/midi/kit_learn_session_test.dart`:

```dart
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/midi/kit_learn_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('walks the learn order, assigns notes, finishes', () {
    final s = KitLearnSession(start: KitMapping.gm());
    expect(s.current, KitInstrument.snare);
    expect(s.total, KitInstrument.learnOrder.length);
    s.hit(40);
    expect(s.mapping.instrumentFor(40), KitInstrument.snare);
    expect(s.mapping.notes[KitInstrument.snare], {40});
    expect(s.current, KitInstrument.kick);
    for (var i = 1; i < s.total; i++) {
      s.skip();
    }
    expect(s.done, isTrue);
    expect(s.current, isNull);
  });

  test('a note already used elsewhere moves and leaves a hint', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.skip(); // snare
    s.hit(38); // kick ← 38 was the snare's note
    expect(s.mapping.instrumentFor(38), KitInstrument.kick);
    expect(s.mapping.notes[KitInstrument.snare], isEmpty);
    expect(s.hint, contains('Snare'));
  });

  test('a repeated note for the same instrument is a second zone', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.hit(38);
    s.back();
    s.hit(40);
    expect(s.mapping.notes[KitInstrument.snare], {38, 40});
  });

  test('skip keeps the existing assignment', () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.skip();
    expect(s.mapping.instrumentFor(38), KitInstrument.snare);
  });

  test('back from the first step is a no-op; hits after done are ignored',
      () {
    final s = KitLearnSession(start: KitMapping.gm());
    s.back();
    expect(s.index, 0);
    for (var i = 0; i < s.total; i++) {
      s.skip();
    }
    s.hit(60);
    expect(s.mapping.instrumentFor(60), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/midi/kit_learn_session_test.dart`
Expected: FAIL (URI fehlt).

- [ ] **Step 3: Implementation**

`lib/features/coaching/midi/kit_learn_session.dart`:

```dart
import 'kit_instrument.dart';

/// Pure state of the learn step (Brief A.2): walks [KitInstrument.learnOrder],
/// every hit assigns the note to the current instrument (moving it away from
/// a previous owner, with a hint), skip keeps what is there.
class KitLearnSession {
  KitLearnSession({required KitMapping start}) : _mapping = start;

  KitMapping _mapping;
  int _index = 0;
  String? _hint;

  /// Assigning the first note of a step replaces the instrument's old
  /// notes; further hits on the same step add zones.
  bool _replacedThisStep = false;

  List<KitInstrument> get _order => KitInstrument.learnOrder;

  KitInstrument? get current => done ? null : _order[_index];
  int get index => _index;
  int get total => _order.length;
  KitMapping get mapping => _mapping;
  bool get done => _index >= _order.length;
  String? get hint => _hint;

  void hit(int note) {
    final instrument = current;
    if (instrument == null) return;
    final previous = _mapping.instrumentFor(note);
    _hint = previous != null && previous != instrument
        ? 'Note $note moved from ${previous.label} to ${instrument.label}'
        : null;
    if (!_replacedThisStep) {
      _mapping = _mapping.remove(instrument);
      _replacedThisStep = true;
    }
    _mapping = _mapping.assign(instrument, note);
    _advance();
  }

  void skip() {
    if (done) return;
    _hint = null;
    _advance();
  }

  void back() {
    if (_index == 0) return;
    _index--;
    _replacedThisStep = false;
    _hint = null;
  }

  void _advance() {
    _index++;
    _replacedThisStep = false;
  }
}
```

Der Test „a repeated note … second zone" verlangt: nach `hit(38)` → `back()` → `hit(40)` beide Noten auf der Snare. Mit obigem Code ersetzt `hit(40)` nach `back()` die Snare erneut (nur 40). Deshalb `back()` so lassen, aber `_replacedThisStep` beim `back()` auf **true** setzen (der Schritt wurde schon einmal ersetzt; weitere Treffer ergänzen Zonen):

```dart
  void back() {
    if (_index == 0) return;
    _index--;
    _replacedThisStep = true;
    _hint = null;
  }
```

- [ ] **Step 4: Screen**

`lib/features/settings/kit_learn_screen.dart` (ersetzt den Platzhalter):

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/local/settings_service.dart';
import '../coaching/midi/kit_instrument.dart';
import '../coaching/midi/kit_learn_session.dart';
import '../coaching/midi/midi_port_service.dart';

/// "Hit the …" (Brief A.2): one instrument after another, under two minutes
/// for a full kit. Saved per device name.
class KitLearnScreen extends StatefulWidget {
  const KitLearnScreen({super.key, this.ports});

  final MidiPortService? ports;

  @override
  State<KitLearnScreen> createState() => _KitLearnScreenState();
}

class _KitLearnScreenState extends State<KitLearnScreen> {
  MidiPort? _port;
  KitLearnSession? _session;
  StreamSubscription<MidiNoteOn>? _sub;
  int? _lastNote;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final ports = widget.ports ?? MidiPortService();
    final devices = await ports.inputDevices();
    final id = chooseMidiDevice(devices, lastId: SettingsService.midiLastDeviceId);
    if (id == null) {
      setState(() => _error = 'No MIDI device connected. Plug in the module.');
      return;
    }
    final port = await ports.open(id);
    if (port == null) {
      setState(() => _error = 'Could not open the MIDI device.');
      return;
    }
    if (!mounted) {
      await port.close();
      return;
    }
    setState(() {
      _port = port;
      _session =
          KitLearnSession(start: SettingsService.kitMappingFor(port.deviceName));
    });
    _sub = port.noteOns.listen((n) {
      final s = _session;
      if (s == null || s.done) return;
      setState(() {
        _lastNote = n.note;
        s.hit(n.note);
      });
    });
  }

  Future<void> _save() async {
    final port = _port;
    final s = _session;
    if (port == null || s == null) return;
    await SettingsService.setKitMappingFor(port.deviceName, s.mapping);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Kit mapping saved')));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _port?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return Scaffold(
      appBar: AppBar(title: const Text('Learn kit')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _error != null
            ? Text(_error!, style: const TextStyle(color: AppColors.textMuted))
            : s == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('${_port!.deviceName}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 24),
                      if (!s.done) ...[
                        Text('Hit the ${s.current!.label}',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('${s.index + 1} of ${s.total}',
                            style: const TextStyle(
                                color: AppColors.textMuted)),
                        if (_lastNote != null)
                          Text('Last note: $_lastNote',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        if (s.hint != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(s.hint!,
                                style: const TextStyle(
                                    color: AppColors.accent, fontSize: 12)),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            TextButton(
                                onPressed: () => setState(s.back),
                                child: const Text('Back')),
                            const Spacer(),
                            OutlinedButton(
                                onPressed: () => setState(s.skip),
                                child: const Text('Skip')),
                          ],
                        ),
                      ] else ...[
                        const Text('All done.',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        for (final e in s.mapping.notes.entries)
                          if (e.value.isNotEmpty)
                            Text('${e.key.label}: ${e.value.join(', ')}',
                                style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: _save, child: const Text('Save')),
                      ],
                      const Spacer(),
                      TextButton(
                        onPressed: s.done ? null : _save,
                        child: const Text('Save what I have so far'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
```

`AppColors.accent` prüfen (`grep -n "accent" lib/app/design_tokens.dart`); sonst die dort vorhandene Akzentfarbe nehmen.

- [ ] **Step 5: Tests + Sichtprüfung**

Run: `flutter test test/midi/ test/features/settings/` → grün; `flutter analyze` sauber. Linux-Sichtprüfung auf dem NUC: `tool/midi/virtual_port_test.sh` bleibt grün; Screen mit virtuellem Port öffnen (Xvfb-Screenshot per `import -window root` oder einfach Rauchprobe ohne Absturz).

- [ ] **Step 6: Commit**

```bash
git add lib/features/coaching/midi/kit_learn_session.dart lib/features/settings/kit_learn_screen.dart test/midi/kit_learn_session_test.dart
git commit -m "feat(midi): Lernschritt „Hit the …“ — Zustandsautomat + Screen, Zuordnung je Gerät gespeichert"
```

---

### Task 15: MIDI-Latenz-Abgleich — Schätzer und Screen

**Files:**
- Create: `lib/features/coaching/midi/midi_latency.dart`
- Modify: `lib/features/settings/midi_calibration_screen.dart` (Platzhalter ersetzen)
- Test: `test/midi/midi_latency_test.dart`

**Interfaces:**
- Consumes: `estimateLatencyOffset`, `LatencyEstimate.blockSpreadMs` (`latency_estimator.dart`), `MetronomeNotifier` (`metronomeNotifierProvider`: `setBpm`, `setClickTrack`, `toggle`/`start`/`stop`, Zustand `isPlaying`, `currentBeatIndex`, `lastBeatPlannedAt`), `MidiStrokeSource` (Task 9), `SettingsService.setMidiLatencyOffsetMsFor` (Task 7).
- Produces: `class MidiLatencyResult { final double offsetMs; final double spreadMs; final int matched; final int clicks; bool get unsure; }`, `MidiLatencyResult? estimateMidiLatency({required List<double> clickMs, required List<double> strokeMs, double unsureAboveMs = 10})`.

- [ ] **Step 1: Failing test**

`test/midi/midi_latency_test.dart`:

```dart
import 'package:drum_coach/features/coaching/midi/midi_latency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final clicks = [for (var i = 0; i < 16; i++) 1000.0 + i * 600];

  test('steady player 18 ms late: offset 18, small spread, sure', () {
    final r = estimateMidiLatency(
      clickMs: clicks,
      strokeMs: [for (final c in clicks) c + 18 + (c % 2 == 0 ? 1 : -1)],
    )!;
    expect(r.offsetMs, closeTo(18, 1.5));
    expect(r.spreadMs, lessThan(10));
    expect(r.unsure, isFalse);
    expect(r.matched, 16);
    expect(r.clicks, 16);
  });

  test('wobbly player: spread above 10 ms flags unsure', () {
    final r = estimateMidiLatency(
      clickMs: clicks,
      strokeMs: [
        for (var i = 0; i < 16; i++) clicks[i] + 18 + (i < 8 ? -12 : 12)
      ],
    )!;
    expect(r.unsure, isTrue);
  });

  test('nothing played: null', () {
    expect(estimateMidiLatency(clickMs: clicks, strokeMs: const []), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/midi/midi_latency_test.dart`
Expected: FAIL (URI fehlt).

- [ ] **Step 3: Implementation**

`lib/features/coaching/midi/midi_latency.dart`:

```dart
import '../services/latency_estimator.dart';

/// Result of "play 16 quarters to the click" (Brief A.4): the systematic
/// offset between MIDI stroke and planned click, and the spread between
/// four blocks of the run. Above [MidiLatencyResult.unsure] the screen asks
/// for a repeat instead of saving.
class MidiLatencyResult {
  final double offsetMs;
  final double spreadMs;
  final int matched;
  final int clicks;
  final double unsureAboveMs;

  const MidiLatencyResult({
    required this.offsetMs,
    required this.spreadMs,
    required this.matched,
    required this.clicks,
    required this.unsureAboveMs,
  });

  bool get unsure => spreadMs > unsureAboveMs || matched < clicks * 0.75;
}

MidiLatencyResult? estimateMidiLatency({
  required List<double> clickMs,
  required List<double> strokeMs,
  double unsureAboveMs = 10,
}) {
  final est =
      estimateLatencyOffset(plannedClickMs: clickMs, onsetMs: strokeMs);
  if (est == null) return null;
  return MidiLatencyResult(
    offsetMs: est.offsetMs,
    spreadMs: est.blockSpreadMs(4) ?? 0,
    matched: est.matchedClicks,
    clicks: est.totalClicks,
    unsureAboveMs: unsureAboveMs,
  );
}
```

- [ ] **Step 4: Screen**

`lib/features/settings/midi_calibration_screen.dart` (ersetzt den Platzhalter). Ablauf: Gerät öffnen → „Start" → Metronom 100 BPM mit Klick-Track, 20 Klicks → Stopp → Schätzung → „Save" oder „Repeat".

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/platform_support.dart';
import '../../data/local/settings_service.dart';
import '../coaching/midi/kit_instrument.dart';
import '../coaching/midi/midi_latency.dart';
import '../coaching/midi/midi_port_service.dart';
import '../coaching/midi/midi_stroke_source.dart';
import '../coaching/midi/midi_timestamp_mapper.dart';
import '../metronome/metronome_provider.dart';

/// MIDI latency (Brief A.4): the click leaves the app late (audio → AUX →
/// module → headphones), the MIDI note arrives at once. Sixteen quarters on
/// the pad-role instrument give the offset; the spread says whether to
/// trust it.
class MidiCalibrationScreen extends ConsumerStatefulWidget {
  const MidiCalibrationScreen({super.key});

  @override
  ConsumerState<MidiCalibrationScreen> createState() =>
      _MidiCalibrationScreenState();
}

class _MidiCalibrationScreenState extends ConsumerState<MidiCalibrationScreen> {
  static const int _clicks = 20;
  static const int _bpm = 100;

  MidiPort? _port;
  MidiStrokeSource? _source;
  String? _error;
  bool _running = false;
  final List<double> _clickMs = [];
  MidiLatencyResult? _result;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final ports = MidiPortService();
    final devices = await ports.inputDevices();
    final id =
        chooseMidiDevice(devices, lastId: SettingsService.midiLastDeviceId);
    if (id == null) {
      setState(() => _error = 'No MIDI device connected.');
      return;
    }
    final port = await ports.open(id);
    if (port == null || !mounted) return;
    setState(() {
      _port = port;
      _source = MidiStrokeSource(
        port: port,
        mapping: SettingsService.kitMappingFor(port.deviceName),
        mapper: MidiTimestampMapper(midiTimestampUnitForPlatform(
            isAndroid: !isDesktopPlatform, isLinux: isDesktopPlatform)),
      );
    });
  }

  Future<void> _start() async {
    final src = _source;
    if (src == null) return;
    _clickMs.clear();
    _result = null;
    await src.start();
    final notifier = ref.read(metronomeNotifierProvider.notifier);
    notifier
      ..setBpm(_bpm)
      ..setClickTrack(true)
      ..setBacking(null, beatsPerBar: 4);
    setState(() => _running = true);
    notifier.toggle();
  }

  Future<void> _finish() async {
    final notifier = ref.read(metronomeNotifierProvider.notifier);
    if (ref.read(metronomeNotifierProvider).isPlaying) notifier.toggle();
    await _source?.stop();
    final role = SettingsService.padRoleInstrument;
    final strokes = [
      for (final e in _source!.events)
        if (e.instrument == role || e.instrument == KitInstrument.snare)
          e.timeMs,
    ];
    setState(() {
      _running = false;
      _result =
          estimateMidiLatency(clickMs: List.of(_clickMs), strokeMs: strokes);
    });
  }

  Future<void> _save() async {
    final r = _result;
    final port = _port;
    if (r == null || port == null) return;
    await SettingsService.setMidiLatencyOffsetMsFor(port.deviceName, r.offsetMs);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('MIDI latency saved: ${r.offsetMs.round()} ms')));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    final notifier = ref.read(metronomeNotifierProvider.notifier);
    if (ref.read(metronomeNotifierProvider).isPlaying) notifier.toggle();
    _source?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MetronomeState>(metronomeNotifierProvider, (prev, next) {
      if (!_running) return;
      final newTick = next.isPlaying &&
          next.currentBeatIndex >= 0 &&
          next.currentBeatIndex != (prev?.currentBeatIndex ?? -2);
      if (!newTick || next.lastBeatPlannedAt == null) return;
      _clickMs.add(next.lastBeatPlannedAt!.microsecondsSinceEpoch / 1000.0);
      if (_clickMs.length >= _clicks) unawaited(_finish());
    });
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('MIDI latency')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _error != null
            ? Text(_error!)
            : _source == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_port!.deviceName,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 16),
                      const Text(
                        'Play quarter notes on the snare with the click, '
                        '20 clicks at 100 BPM. The app measures how late the '
                        'click reaches your ears.',
                      ),
                      const SizedBox(height: 24),
                      if (_running)
                        Text('Clicks: ${_clickMs.length} / $_clicks',
                            style: const TextStyle(fontSize: 22)),
                      if (!_running && r == null)
                        FilledButton(
                            onPressed: _start, child: const Text('Start')),
                      if (r != null) ...[
                        Text('Offset: ${r.offsetMs.round()} ms',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w700)),
                        Text(
                            'Spread ${r.spreadMs.toStringAsFixed(1)} ms, '
                            '${r.matched} of ${r.clicks} clicks matched',
                            style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        if (r.unsure)
                          const Text(
                              'Too uneven to trust — play it again, relaxed.',
                              style: TextStyle(color: AppColors.accent)),
                        const SizedBox(height: 16),
                        Row(children: [
                          OutlinedButton(
                              onPressed: _start, child: const Text('Repeat')),
                          const SizedBox(width: 12),
                          FilledButton(
                              onPressed: r.unsure ? null : _save,
                              child: const Text('Save')),
                        ]),
                      ],
                    ],
                  ),
      ),
    );
  }
}
```

Vorher prüfen: `MetronomeNotifier` hat `toggle`, `setBpm`, `setClickTrack`, `setBacking(String?, {required int beatsPerBar})` (`grep -n "void toggle\|void setBpm\|void setClickTrack\|void setBacking" lib/features/metronome/metronome_provider.dart`); Namen bei Abweichung angleichen.

- [ ] **Step 5: Tests + Rauchprobe**

Run: `flutter test test/midi/` → grün; `flutter analyze` sauber. Rauchprobe auf dem NUC mit virtuellem Port: Screen öffnen, Start; mit `python3 tool/midi/spike/send_pattern.py /dev/snd/midiC1D0 /tmp/s.jsonl --quick` Noten einspeisen (nur Segment A ist regelmäßig, das genügt: ein Ergebnis erscheint, „unsure" ist dabei erwartbar, weil der Sender nicht auf den Klick spielt).

- [ ] **Step 6: Commit**

```bash
git add lib/features/coaching/midi/midi_latency.dart lib/features/settings/midi_calibration_screen.dart test/midi/midi_latency_test.dart
git commit -m "feat(midi): Latenz-Abgleich — 20 Klicks, Versatz + Streuung, je Gerät gespeichert"
```

---

### Task 16: Android-Manifest, Dokumentation, Builds, Abnahme-Vorbereitung

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`, `docs/CLAUDE.md`, `README.md`
- Create: `docs/BERICHT_ETAPPE2_A.md` (Gerüst für den Gerätetest)
- Test: `flutter build apk --debug`, `flutter build linux --release`, `tool/midi/virtual_port_test.sh`, volle Suite

- [ ] **Step 1: Manifest**

In `AndroidManifest.xml` nach den `uses-permission`-Zeilen:

```xml
    <!-- MIDI module via USB-OTG (Brief Etappe 2, A.8); not required so the
         app still installs on devices without host mode. -->
    <uses-feature android:name="android.hardware.usb.host" android:required="false"/>
```

- [ ] **Step 2: Doku**

`docs/CLAUDE.md`:
- Unter „Tech Stack" die Zeile `| MIDI input | flutter_midi_command 1.4.0 (Linux: vendored patched copy under packages/, see PATCH.md) |` ergänzen.
- Neuer Abschnitt „Measurement sources (Etappe 2, Phase A)": `StrokeSource` (mic/midi), `analyzeStrokes` als Kern, `measurementSource`-Einstellung, `requiredSensor`, Zeitachse Epoche-ms, Stempel nie im Haupt-Isolate, Kit-Zuordnung je Gerät, Latenz je Gerät, Rohlog-Felder. Zehn Zeilen genügen; auf den Brief verweisen.
- Neuer Abschnitt „Desktop (Linux)": `flutter build linux --release`, Pakete (`clang cmake ninja-build pkg-config libgtk-3-dev libasound2-dev`), `platform_support.dart` als einzige Weiche, Headless-Start-Variablen (`NO_AT_BRIDGE=1 GTK_A11Y=none LIBGL_ALWAYS_SOFTWARE=1`), `tool/midi/virtual_port_test.sh`.
- „Project Overview": „Android app" → „Flutter app (Android, Linux desktop)".

`README.md` Zeile 3 entsprechend anpassen.

`docs/BERICHT_ETAPPE2_A.md` als Gerüst mit den Abnahmepunkten aus dem Brief (Phase A) als Checkliste, Spalten „Erwartung / Befund / Datum", Befund leer.

- [ ] **Step 3: Builds und Suite**

```bash
flutter analyze
flutter test
tool/midi/virtual_port_test.sh
flutter build linux --release
flutter build apk --debug
```

Expected: analyze ohne neue Meldungen; alle Tests grün; Integrationstest `64 of 64`; beide Builds `✓ Built`. Die Debug-APK nach `~/drum-coach-set-a.apk` kopieren (Ulis Gerätetest, S23 per OTG); den Linux-Bundle-Pfad `build/linux/x64/release/bundle/` im Bericht-Gerüst nennen.

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml docs/CLAUDE.md README.md docs/BERICHT_ETAPPE2_A.md
git commit -m "docs(Etappe 2): Phase A — Manifest USB-Host, CLAUDE.md Messquellen + Linux, Bericht-Gerüst für den Gerätetest"
```

---

## Selbstprüfung (durchgeführt beim Schreiben)

- **Spec-Abdeckung:** A.1 → Task 3/4/9; A.2 → Task 2/14; A.3 → Task 8/9/13; A.4 → Task 15; A.5 → Task 4/5/11 (Pad-Rolle in Task 7/11/13; Kopfhörer-Regel in Task 11); A.6 → Task 3/7/11/13; A.7 → Task 1/10/12/16; A.8 → Task 9 (Mapper), 16 (Manifest); A.9 → Task 6/11. Technische Festlegungen: Bibliothek Task 1, Zeitbasis Task 8/9, kein Mindestabstand Task 9, Mikrofon-Schwellen Task 4, `KitMapping`-JSON Task 2/7, Isar-Felder Task 6, `platform_support` Task 10, Tests inkl. virtuellem Port Task 9.
- **Platzhalter:** keine „TBD"; die zwei Platzhalter-Screens in Task 13 werden in Task 14/15 ersetzt und sind als solche benannt.
- **Typkonsistenz:** `StrokeEvent(timeMs, instrument, velocity, rawNote, source)` überall gleich; `analyzeStrokes(events, beatLog, sticking, source, expectedInstrument, latencyOffsetMs, analysisMode, recordingSetup)` in Task 4/5/11; `MidiPortService.inputDevices/open/setupChanges` in Task 9/13/14/15; `MeasurementPlan`/`planMeasurement` in Task 11; `SettingsService`-Namen aus Task 7 in 11/13/14/15.
- **Review Focus:** alle fünf Punkte haben ihren Test (Task 4, 9+11, 4, 2, 7).
