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
/// arrival delay: arrival is always later than the true event, and the
/// smallest delay is the closest to the truth (§0: never trust a single
/// arrival time, the main isolate may be busy). Events are converted after
/// the fact with the session-wide minimum ([offsetUs] + [toEpochMsWith]), so
/// an early event that arrived late is corrected once a later event shows
/// the smaller delay.
class MidiTimestampMapper {
  MidiTimestampMapper(this.unit);

  final MidiTimestampUnit unit;
  int? _offsetUs; // arrivalEpochUs - libTimestampUs, minimum so far

  /// Smallest arrival delay seen so far (monotonic stamps only), µs.
  int? get offsetUs => _offsetUs;

  /// Learns from one event's arrival (monotonic stamps only).
  void observe({required int libTimestamp, required int arrivalEpochUs}) {
    if (unit != MidiTimestampUnit.monotonicNanos || libTimestamp == 0) return;
    final delay = arrivalEpochUs - libTimestamp ~/ 1000;
    if (_offsetUs == null || delay < _offsetUs!) _offsetUs = delay;
  }

  /// Pure conversion with a given offset (the session's final [offsetUs]).
  double toEpochMsWith({
    required int libTimestamp,
    required int arrivalEpochUs,
    required int? offsetUs,
  }) {
    if (libTimestamp == 0) return arrivalEpochUs / 1000.0;
    switch (unit) {
      case MidiTimestampUnit.epochMicros:
        return libTimestamp / 1000.0;
      case MidiTimestampUnit.monotonicNanos:
        if (offsetUs == null) return arrivalEpochUs / 1000.0;
        return (libTimestamp ~/ 1000 + offsetUs) / 1000.0;
      case MidiTimestampUnit.none:
        return arrivalEpochUs / 1000.0;
    }
  }

  /// Running conversion: learn from this event, convert with the minimum
  /// so far (good for live use; the logged events use [toEpochMsWith]).
  double toEpochMs({required int libTimestamp, required int arrivalEpochUs}) {
    observe(libTimestamp: libTimestamp, arrivalEpochUs: arrivalEpochUs);
    return toEpochMsWith(
        libTimestamp: libTimestamp,
        arrivalEpochUs: arrivalEpochUs,
        offsetUs: _offsetUs);
  }
}
