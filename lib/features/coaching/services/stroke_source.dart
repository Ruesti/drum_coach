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
