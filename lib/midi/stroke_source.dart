import '../measure/stroke.dart';

/// Where strokes come from. Etappe 1 has one implementation (MIDI); the
/// interface stays lean so the measurement core never sees the platform.
abstract class StrokeSource {
  /// Begins collecting strokes (clears earlier ones).
  Future<void> start();

  /// Stops collecting; [strokes] is final afterwards.
  Future<void> stop();

  /// All strokes collected since [start], in arrival order.
  List<Stroke> get strokes;

  /// false when the device disappears (unplugged / client exit).
  Stream<bool> get connection;

  String get deviceName;

  void dispose();
}
