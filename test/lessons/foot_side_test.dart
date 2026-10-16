import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foot() may carry a side; without one it stays null', () {
    expect(foot(NoteValue.sixteenth, side: R).hand, Hand.right);
    expect(foot(NoteValue.sixteenth, side: L).hand, Hand.left);
    expect(foot(NoteValue.sixteenth).hand, isNull);
    expect(foot(NoteValue.eighth, side: R, accent: true).isAccent, isTrue);
  });

  test('voicesHaveFootSides: true only when a foot voice note carries a side',
      () {
    final hh =
        voice(KitInstrument.hiHatClosed, eighths([R, R, R, R, R, R, R, R]));
    final kickPlain = voice(KitInstrument.kick, [
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
    ]);
    final kickSided = voice(KitInstrument.kick, [
      for (var i = 0; i < 4; i++) ...[
        foot(NoteValue.eighth, side: R),
        foot(NoteValue.eighth, side: L),
      ],
    ]);
    expect(voicesHaveFootSides([hh, kickPlain]), isFalse);
    expect(voicesHaveFootSides([hh, kickSided]), isTrue);
    // A hand voice with hands is not a foot side.
    expect(voicesHaveFootSides([hh]), isFalse);
  });

  test('Rudiment.hasFootSides looks at the sheet and the pattern voices', () {
    final hh =
        voice(KitInstrument.hiHatClosed, eighths([R, R, R, R, R, R, R, R]));
    final db = voice(KitInstrument.kick, [
      for (var i = 0; i < 4; i++) ...[
        foot(NoteValue.eighth, side: R),
        foot(NoteValue.eighth, side: L),
      ],
    ]);
    final plain = voice(KitInstrument.kick, [foot(NoteValue.whole)]);
    Rudiment make({required List<Voice> pattern, required List<Voice> line}) =>
        Rudiment(
            id: 'x',
            name: 'X',
            description: '',
            minBpm: 60,
            targetBpm: 120,
            difficulty: Difficulty.beginner,
            sticking: pattern.first.beats,
            voicing: ExerciseVoicing.kit,
            requiredSensor: SensorLevel.midi,
            patternVoices: pattern,
            lines: [kitLine(line)]);
    expect(make(pattern: [hh, plain], line: [hh, plain]).hasFootSides, isFalse);
    expect(make(pattern: [hh, plain], line: [hh, db]).hasFootSides, isTrue);
    expect(make(pattern: [hh, db], line: [hh, plain]).hasFootSides, isTrue);
  });
}
