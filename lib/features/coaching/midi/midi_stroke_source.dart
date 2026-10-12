import 'dart:async';

import '../services/stroke_source.dart';
import 'kit_instrument.dart';
import 'midi_port_service.dart';
import 'midi_timestamp_mapper.dart';

/// Strokes from a MIDI module (Brief A.1). No minimum gap, no level
/// threshold: a Note-On is a stroke. Notes the mapping does not know become
/// [KitInstrument.unknown] events (logged with their raw note, Brief A.9)
/// and are counted in [unmappedNotes] for the learn step's hint. Raw stamps
/// are kept and converted when [events] is read, so monotonic (Android)
/// stamps use the session-wide minimum offset.
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
  final List<({MidiNoteOn note, KitInstrument instrument})> _raw = [];
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
  List<StrokeEvent> get events {
    final offset = _mapper.offsetUs;
    return List.unmodifiable([
      for (final r in _raw)
        StrokeEvent(
          timeMs: _mapper.toEpochMsWith(
              libTimestamp: r.note.libTimestamp,
              arrivalEpochUs: r.note.arrivalEpochUs,
              offsetUs: offset),
          instrument: r.instrument,
          velocity: r.note.velocity / 127.0,
          rawNote: r.note.note,
          source: StrokeSourceKind.midi,
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
