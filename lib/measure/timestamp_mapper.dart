/// What `MidiPacket.timestamp` means per platform (docs/BERICHT_ETAPPE2_§0.md):
/// Linux (vendored patch) = epoch microseconds from the receive isolate;
/// Android = `android.media.midi` nanoseconds on the system's monotonic
/// clock; Windows = WinMM `dwParam2` of `MM_MIM_DATA`, milliseconds since
/// `midiInStart` (1 ms resolution); anything else = unknown, use the
/// arrival time.
enum MidiTimestampUnit { epochMicros, monotonicNanos, relativeMillis, none }

MidiTimestampUnit midiTimestampUnitForPlatform({
  required bool isAndroid,
  required bool isLinux,
  required bool isWindows,
}) {
  if (isLinux) return MidiTimestampUnit.epochMicros;
  if (isAndroid) return MidiTimestampUnit.monotonicNanos;
  if (isWindows) return MidiTimestampUnit.relativeMillis;
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

  /// Smallest arrival delay seen so far (monotonic/relative stamps only), µs.
  int? get offsetUs => _offsetUs;

  /// Library stamp in µs on its own (non-epoch) clock; null for units that
  /// need no offset.
  int? _libMicros(int libTimestamp) {
    switch (unit) {
      case MidiTimestampUnit.monotonicNanos:
        return libTimestamp ~/ 1000;
      case MidiTimestampUnit.relativeMillis:
        return libTimestamp * 1000;
      case MidiTimestampUnit.epochMicros:
      case MidiTimestampUnit.none:
        return null;
    }
  }

  /// Learns from one event's arrival (monotonic/relative stamps only).
  void observe({required int libTimestamp, required int arrivalEpochUs}) {
    final libUs = _libMicros(libTimestamp);
    if (libUs == null || libTimestamp == 0) return;
    final delay = arrivalEpochUs - libUs;
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
      case MidiTimestampUnit.relativeMillis:
        if (offsetUs == null) return arrivalEpochUs / 1000.0;
        return (libTimestamp * 1000 + offsetUs) / 1000.0;
      case MidiTimestampUnit.none:
        return arrivalEpochUs / 1000.0;
    }
  }
}
