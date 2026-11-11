import 'kit.dart';

/// One detected drum hit. [instrument] is [KitInstrument.unknown] when the
/// kit mapping has no entry for [note].
class Stroke {
  const Stroke({
    required this.timeMs,
    required this.note,
    required this.velocity,
    required this.instrument,
  });

  final double timeMs;
  final int note;
  final int velocity;
  final KitInstrument instrument;

  @override
  bool operator ==(Object other) =>
      other is Stroke &&
      other.timeMs == timeMs &&
      other.note == note &&
      other.velocity == velocity &&
      other.instrument == instrument;

  @override
  int get hashCode => Object.hash(timeMs, note, velocity, instrument);

  @override
  String toString() =>
      'Stroke($timeMs ms, note $note, vel $velocity, ${instrument.name})';
}
