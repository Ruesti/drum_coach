import 'dart:async';

import '../measure/kit.dart';
import '../measure/stroke.dart';
import '../measure/timestamp_mapper.dart';
import 'midi_port_service.dart';
import 'stroke_source.dart';

/// Strokes from a MIDI module. No minimum gap, no level threshold: a
/// Note-On is a stroke. Notes the mapping does not know become
/// [KitInstrument.unknown] strokes (kept with their raw note) and are
/// counted in [unmappedNotes] for the learn step's hint. Raw stamps are kept
/// and converted when [strokes] is read, with the session-wide offset of the
/// mapper, so early late-arriving monotonic (Android) events are corrected.
class MidiStrokeSource implements StrokeSource {
  MidiStrokeSource({
    required MidiPort port,
    required KitMapping mapping,
    required MidiTimestampMapper mapper,
  })  : _port = port,
        _mapping = mapping,
        _mapper = mapper;

  final MidiPort _port;
  final KitMapping _mapping;
  final MidiTimestampMapper _mapper;
  final List<({MidiNoteOn note, KitInstrument instrument})> _raw = [];
  final Set<int> unmappedNotes = {};
  StreamSubscription<MidiNoteOn>? _noteSub;

  @override
  String get deviceName => _port.deviceName;

  @override
  Stream<bool> get connection => _port.connection;

  @override
  List<Stroke> get strokes {
    final offset = _mapper.offsetUs;
    return List.unmodifiable([
      for (final r in _raw)
        Stroke(
          timeMs: _mapper.toEpochMsWith(
              libTimestamp: r.note.libTimestamp,
              arrivalEpochUs: r.note.arrivalEpochUs,
              offsetUs: offset),
          note: r.note.note,
          velocity: r.note.velocity,
          instrument: r.instrument,
        ),
    ]);
  }

  @override
  Future<void> start() async {
    _raw.clear();
    unmappedNotes.clear();
    _noteSub ??= _port.noteOns.listen((n) {
      final instrument = _mapping.instrumentFor(n.note);
      if (instrument == null) unmappedNotes.add(n.note);
      _mapper.observe(
          libTimestamp: n.libTimestamp, arrivalEpochUs: n.arrivalEpochUs);
      _raw.add((note: n, instrument: instrument ?? KitInstrument.unknown));
    });
  }

  @override
  Future<void> stop() async {
    await _noteSub?.cancel();
    _noteSub = null;
  }

  @override
  void dispose() {
    _noteSub?.cancel();
    _port.close();
  }
}
