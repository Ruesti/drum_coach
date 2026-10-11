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
