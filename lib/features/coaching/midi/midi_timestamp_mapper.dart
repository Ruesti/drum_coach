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
