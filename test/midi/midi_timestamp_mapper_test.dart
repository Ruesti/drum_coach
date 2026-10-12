import 'package:drum_coach/features/coaching/midi/midi_timestamp_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('epochMicros: library stamp is the time, arrival ignored', () {
    final m = MidiTimestampMapper(MidiTimestampUnit.epochMicros);
    expect(m.toEpochMs(libTimestamp: 1700000000123456, arrivalEpochUs: 0),
        closeTo(1700000000123.456, 1e-6));
  });

  test('none or zero stamp: arrival time is used', () {
    final m = MidiTimestampMapper(MidiTimestampUnit.none);
    expect(m.toEpochMs(libTimestamp: 42, arrivalEpochUs: 1700000000000500),
        closeTo(1700000000000.5, 1e-6));
    final e = MidiTimestampMapper(MidiTimestampUnit.epochMicros);
    expect(e.toEpochMs(libTimestamp: 0, arrivalEpochUs: 1700000000000500),
        closeTo(1700000000000.5, 1e-6));
  });

  test('monotonicNanos: offset learned as the minimum arrival delay', () {
    final m = MidiTimestampMapper(MidiTimestampUnit.monotonicNanos);
    const base = 1700000000000000; // µs epoch
    // Event 1: true time base, arrived 9 ms late (main isolate busy).
    final t1 = m.toEpochMs(
        libTimestamp: 5000000000, arrivalEpochUs: base + 9000);
    // Event 2: true time base+500 ms, arrived 1 ms late → offset shrinks.
    final t2 = m.toEpochMs(
        libTimestamp: 5500000000, arrivalEpochUs: base + 500000 + 1000);
    // Event 3: true time base+1000 ms, arrived 12 ms late → uses the learned
    // 1 ms offset, not its own late arrival.
    final t3 = m.toEpochMs(
        libTimestamp: 6000000000, arrivalEpochUs: base + 1000000 + 12000);
    expect(t2 - t1, closeTo(500 - 8, 1e-6)); // first event carried 8 ms extra
    expect(t3 - t2, closeTo(500, 1e-6));
  });

  test('monotonicNanos after the fact: an early late-arriving event is '
      'corrected once a later event lowers the offset', () {
    final m = MidiTimestampMapper(MidiTimestampUnit.monotonicNanos);
    const base = 1700000000000000;
    // Event 1 arrived 9 ms late, event 2 only 1 ms.
    m.observe(libTimestamp: 5000000000, arrivalEpochUs: base + 9000);
    expect(m.offsetUs, base - 5000000 + 9000);
    m.observe(libTimestamp: 5500000000, arrivalEpochUs: base + 501000);
    expect(m.offsetUs, base - 5000000 + 1000);
    final t1 = m.toEpochMsWith(
        libTimestamp: 5000000000,
        arrivalEpochUs: base + 9000,
        offsetUs: m.offsetUs);
    final t2 = m.toEpochMsWith(
        libTimestamp: 5500000000,
        arrivalEpochUs: base + 501000,
        offsetUs: m.offsetUs);
    expect(t2 - t1, closeTo(500, 1e-6));
    expect(t1, closeTo((base + 1000) / 1000.0, 1e-6));
  });

  test('epochMicros ignores the offset; no offset yet falls back to arrival',
      () {
    final e = MidiTimestampMapper(MidiTimestampUnit.epochMicros);
    e.observe(libTimestamp: 1700000000123456, arrivalEpochUs: 1);
    expect(e.offsetUs, isNull);
    expect(
        e.toEpochMsWith(
            libTimestamp: 1700000000123456, arrivalEpochUs: 0, offsetUs: 5),
        closeTo(1700000000123.456, 1e-6));
    final m = MidiTimestampMapper(MidiTimestampUnit.monotonicNanos);
    expect(
        m.toEpochMsWith(
            libTimestamp: 7, arrivalEpochUs: 1700000000000500, offsetUs: null),
        closeTo(1700000000000.5, 1e-6));
  });
}
