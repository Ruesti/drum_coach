import 'dart:typed_data';

import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/models/voice_clip.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

/// [n] eighth-note cells (grid eighth): 8 cells = one 4/4 bar.
ExerciseLine _line(int n) => ExerciseLine([
      for (var i = 0; i < n; i++) const StrokeBeat(hand: Hand.right),
    ]);

GuidedSection _s(SectionKind k, int bars,
        {int cells = 8, String? text, String? clip, String? title}) =>
    GuidedSection(
        kind: k,
        line: _line(cells),
        bars: bars,
        textEn: text,
        titleEn: title,
        speechClipId: clip);

GuidedExercise _ex(List<GuidedSection> sections) => GuidedExercise(
      id: 'x',
      name: 'X',
      description: 'd',
      package: GuidedPackage.kit,
      difficulty: Difficulty.beginner,
      defaultBpm: 80,
      minBpm: 60,
      maxBpm: 120,
      gridUnit: NoteGrid.eighth,
      sections: sections,
    );

GuidedSection _var() => _s(SectionKind.variation, 8,
    text: 'Now the kick moves.', clip: 'v1', title: 'Kick moves');

GuidedSection _var16() =>
    _s(SectionKind.variation, 16, text: 'Now.', clip: 'v', title: 'Next step');

void main() {
  test('validate accepts groove/variation alternation', () {
    final e = _ex([
      _s(SectionKind.intro, 0, cells: 0),
      _s(SectionKind.groove, 8),
      _var(),
      _s(SectionKind.groove, 8),
      _var(),
      _s(SectionKind.groove, 8),
      _s(SectionKind.outro, 1),
    ]);
    e.validate();
    expect(e.variationCount, 2);
  });

  test('validate rejects two variations in a row', () {
    final e = _ex([
      _s(SectionKind.intro, 0, cells: 0),
      _s(SectionKind.groove, 8),
      _var(),
      _var(),
      _s(SectionKind.groove, 8),
      _s(SectionKind.outro, 1),
    ]);
    expect(e.validate, throwsArgumentError);
  });

  test('validate rejects variation directly after intro', () {
    final e = _ex([
      _s(SectionKind.intro, 0, cells: 0),
      _var(),
      _s(SectionKind.groove, 8),
      _s(SectionKind.outro, 1),
    ]);
    expect(e.validate, throwsArgumentError);
  });

  test('validate rejects variation directly before outro', () {
    final e = _ex([
      _s(SectionKind.intro, 0, cells: 0),
      _s(SectionKind.groove, 8),
      _var(),
      _s(SectionKind.outro, 1),
    ]);
    expect(e.validate, throwsArgumentError);
  });

  test('validate rejects variation without speechClipId or textEn', () {
    for (final v in [
      _s(SectionKind.variation, 8, text: 'Hi', title: 'Say hi'),
      _s(SectionKind.variation, 8, clip: 'v1', title: 'Say hi'),
    ]) {
      final e = _ex([
        _s(SectionKind.intro, 0, cells: 0),
        _s(SectionKind.groove, 8),
        v,
        _s(SectionKind.groove, 8),
        _s(SectionKind.outro, 1),
      ]);
      expect(e.validate, throwsArgumentError);
    }
  });

  test('validate rejects groove bars not multiple of 4', () {
    final e = _ex([
      _s(SectionKind.intro, 0, cells: 0),
      _s(SectionKind.groove, 6),
      _s(SectionKind.outro, 1),
    ]);
    expect(e.validate, throwsArgumentError);
    final v = _ex([
      _s(SectionKind.intro, 0, cells: 0),
      _s(SectionKind.groove, 8),
      _s(SectionKind.variation, 10,
          text: 'Now.', clip: 'v', title: 'Next step'),
      _s(SectionKind.groove, 8),
      _s(SectionKind.outro, 1),
    ]);
    expect(v.validate, throwsArgumentError);
  });

  test('validate rejects variation without titleEn', () {
    for (final title in [null, '', '  ']) {
      final e = _ex([
        _s(SectionKind.intro, 0, cells: 0),
        _s(SectionKind.groove, 8),
        _s(SectionKind.variation, 8, text: 'Now.', clip: 'v', title: title),
        _s(SectionKind.groove, 8),
        _s(SectionKind.outro, 1),
      ]);
      expect(e.validate, throwsArgumentError, reason: '$title');
    }
  });

  test('validate rejects a 3-bar line', () {
    final e = _ex([
      _s(SectionKind.intro, 0, cells: 0),
      _s(SectionKind.groove, 12, cells: 24),
      _s(SectionKind.outro, 1),
    ]);
    expect(e.validate, throwsArgumentError);
  });

  test('validate accepts a 4-bar line', () {
    final e = _ex([
      _s(SectionKind.intro, 0, cells: 0),
      _s(SectionKind.groove, 8, cells: 32),
      _s(SectionKind.outro, 1, cells: 32),
    ]);
    e.validate();
  });

  test('validate rejects non-whole-bar lines', () {
    final e = _ex([
      _s(SectionKind.intro, 0, cells: 0),
      _s(SectionKind.groove, 8, cells: 6),
      _s(SectionKind.outro, 1),
    ]);
    expect(e.validate, throwsArgumentError);
  });

  test('validate requires intro first and outro last', () {
    expect(_ex([_s(SectionKind.groove, 8), _s(SectionKind.outro, 1)]).validate,
        throwsArgumentError);
    expect(
        _ex([_s(SectionKind.intro, 0, cells: 0), _s(SectionKind.groove, 8)])
            .validate,
        throwsArgumentError);
  });

  test('barsAt counts count-in bar', () {
    final e = _ex([
      _s(SectionKind.intro, 0, cells: 0),
      _s(SectionKind.groove, 8),
      _var16(),
      _s(SectionKind.groove, 8),
      _var16(),
      _s(SectionKind.groove, 8),
      _s(SectionKind.outro, 1),
    ]);
    expect(e.barsAt(100), 58);
  });

  test('manifest parses durations', () {
    final m = ClipManifest.fromJson({
      'clips': [
        {'id': 'cd_three', 'ms': 420}
      ]
    });
    expect(m.durationMs('cd_three'), 420);
    expect(m.ids, ['cd_three']);
    expect(() => m.durationMs('nope'), throwsStateError);
  });

  test('VoiceClip duration assumes 44.1 kHz mono', () {
    expect(VoiceClip('a', Float32List(44100)).durationMs, closeTo(1000, 1e-9));
  });
}
