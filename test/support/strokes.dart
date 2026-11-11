import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:drum_coach/measure/targets.dart';

const _gmNote = {Voice.hiHat: 42, Voice.snare: 38, Voice.kick: 36};
const _gmInstrument = {
  Voice.hiHat: KitInstrument.hiHatClosed,
  Voice.snare: KitInstrument.snare,
  Voice.kick: KitInstrument.kick,
};

/// A stroke for [t] on its own voice, or on voice [as] when given.
Stroke strokeFor(TargetTime t,
        {double shiftMs = 0, int velocity = 100, Voice? as}) =>
    Stroke(
      timeMs: t.timeMs + shiftMs,
      note: _gmNote[as ?? t.voice]!,
      velocity: velocity,
      instrument: _gmInstrument[as ?? t.voice]!,
    );
