import 'dart:convert';

/// Every instrument of a full kit (Brief Etappe 2, A.2) with its General
/// MIDI default note. `pad` is the microphone's "instrument": one voice,
/// no note number. `unknown` carries MIDI notes the kit mapping does not
/// know: logged with their raw note (Brief A.9), never mapped, never learnt.
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
  pad(null, 'Pad (microphone)'),
  unknown(null, 'Unknown note');

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
  /// The snare also takes 40: most modules send the rimshot as 40 (the
  /// cross-stick stays 37 on [KitInstrument.snareRim]).
  factory KitMapping.gm() => KitMapping._({
        for (final i in KitInstrument.values)
          if (i.gmNote != null) i: {i.gmNote!},
        KitInstrument.snare: {38, 40},
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
        if (i != KitInstrument.pad && i != KitInstrument.unknown) i: <int>{},
    };
    for (final e in json.entries) {
      final instrument = KitInstrument.fromName(e.key);
      final raw = e.value;
      if (instrument == null ||
          instrument == KitInstrument.pad ||
          instrument == KitInstrument.unknown ||
          raw is! List) {
        continue;
      }
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
