import 'package:drum_coach/features/room/round_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tracker reports round end at beatsPerRound', () {
    final t = RoundTracker(beatsPerRound: 96);
    expect(t.onBeat(0), isNull);
    expect(t.onBeat(48), isNull);
    expect(t.onBeat(95), isNull);
    // The first beat of the next round closes round 0 …
    expect(t.onBeat(96), 0);
    expect(t.onBeat(100), isNull);
    // … and a jump (silent ticks emit no beat) still closes round 1.
    expect(t.onBeat(200), 1);
  });

  test('tracker reset drops the started round', () {
    final t = RoundTracker(beatsPerRound: 96);
    t.onBeat(0);
    t.onBeat(40);
    t.reset(); // tempo changed by hand mid-round
    expect(t.onBeat(60), isNull);
    expect(t.onBeat(96), isNull, reason: 'the started round does not count');
    expect(t.onBeat(150), isNull);
    expect(t.onBeat(192), 1, reason: 'the next full round counts again');
  });

  test('tracker reset before the first beat drops that round', () {
    final t = RoundTracker(beatsPerRound: 10);
    t.reset();
    expect(t.onBeat(3), isNull);
    expect(t.onBeat(10), isNull);
    expect(t.onBeat(20), 1);
  });

  test('a backwards jump (restart) starts afresh without reporting', () {
    final t = RoundTracker(beatsPerRound: 10);
    t.onBeat(25);
    expect(t.onBeat(0), isNull);
    expect(t.onBeat(10), 0);
  });

  test('currentRound follows the beats', () {
    final t = RoundTracker(beatsPerRound: 10);
    expect(t.currentRound, isNull);
    t.onBeat(12);
    expect(t.currentRound, 1);
  });
}
