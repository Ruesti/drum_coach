import '../../coaching/midi/kit_instrument.dart';
import '../../lessons/data/etude_dsl.dart';
import '../../lessons/models/rudiment.dart';
import '../models/guided_exercise.dart';

// Two hand-written guided exercises for the hidden listening page (Plan 1,
// Task 7). The real catalog comes in Plan 2 (tool/katalog/gefuehrt.py).
// Texts are the sentences of tool/stimme/saetze.py, verbatim.

const _e = NoteValue.eighth;
const _s = NoteValue.sixteenth;
const _q = NoteValue.quarter;

/// Section lengths (bars): groove 12, variation 24 → about 5 min at the
/// default tempo (Spec §3.1: 5 min ± 1).
const _grooveBars = 12;
const _variationBars = 24;

List<GuidedSection> _sections({
  required ExerciseLine groove,
  required List<({ExerciseLine line, String clip, String text, String title})>
      variations,
}) {
  final out = <GuidedSection>[
    GuidedSection(
        kind: SectionKind.intro, line: const ExerciseLine([]), bars: 0),
  ];
  for (var i = 0; i < variations.length; i++) {
    final v = variations[i];
    out
      ..add(GuidedSection(
          kind: SectionKind.groove, line: groove, bars: _grooveBars))
      ..add(GuidedSection(
        kind: SectionKind.variation,
        line: v.line,
        bars: _variationBars,
        textEn: v.text,
        titleEn: v.title,
        speechClipId: v.clip,
        // "Nice — back to the groove." after every variation but the last.
        afterClipId: i < variations.length - 1 ? 'after_good' : null,
      ));
  }
  out
    ..add(GuidedSection(
        kind: SectionKind.groove, line: groove, bars: _grooveBars))
    ..add(GuidedSection(kind: SectionKind.outro, line: groove, bars: 1));
  return out;
}

// ── Kit: rock eighths ─────────────────────────────────────────────────

Voice _hihat({bool openOn4and = false}) => voice(KitInstrument.hiHatClosed, [
      for (var i = 0; i < 7; i++) note(R, _e),
      openOn4and ? rest(_e) : note(R, _e),
    ]);

Voice get _openHihat => voice(KitInstrument.hiHatOpen, [
      rest(NoteValue.half),
      rest(_q),
      rest(_e),
      note(R, _e),
    ]);

Voice _snare({bool ghostOn2e = false}) => voice(KitInstrument.snare, [
      rest(_q),
      if (ghostOn2e) ...[
        note(L, _s, accent: true),
        note(L, _s, ghost: true),
        rest(_e),
      ] else
        note(L, _q, accent: true),
      rest(_q),
      note(L, _q, accent: true),
    ]);

Voice _kick({bool on3and = false}) => voice(KitInstrument.kick, [
      foot(_q),
      rest(_q),
      if (on3and) ...[foot(_e), foot(_e)] else foot(_q),
      rest(_q),
    ]);

final demoKitExercise = GuidedExercise(
  id: 'demo_kit_rock8',
  name: 'Rock 8ths — guided demo',
  description: 'Rock eighths with three building variations.',
  package: GuidedPackage.kit,
  difficulty: Difficulty.intermediate,
  defaultBpm: 100,
  minBpm: 60,
  maxBpm: 140,
  gridUnit: NoteGrid.sixteenth,
  sections: _sections(
    groove: kitLine([_hihat(), _snare(), _kick()]),
    variations: [
      (
        line: kitLine([_hihat(), _snare(), _kick(on3and: true)]),
        clip: 'demo_kit_v1',
        text: 'Next up: add the bass drum on the and of three.',
        title: 'Kick on and of three',
      ),
      (
        line: kitLine([_hihat(), _snare(ghostOn2e: true), _kick(on3and: true)]),
        clip: 'demo_kit_v2',
        text: 'Now add a soft ghost note on the snare, on the e of two.',
        title: 'Ghost note on two',
      ),
      (
        line: kitLine([
          _hihat(openOn4and: true),
          _openHihat,
          _snare(ghostOn2e: true),
          _kick(on3and: true),
        ]),
        clip: 'demo_kit_v3',
        text: 'Last one: open the hi-hat on the and of four.',
        title: 'Open hat on four',
      ),
    ],
  ),
);

// ── Pad: eighths ──────────────────────────────────────────────────────

final demoPadExercise = GuidedExercise(
  id: 'demo_pad_eighths',
  name: 'Eighths — guided demo',
  description: 'Alternating eighths with accents, doubles and paradiddles.',
  package: GuidedPackage.pad,
  difficulty: Difficulty.beginner,
  defaultBpm: 90,
  minBpm: 60,
  maxBpm: 130,
  gridUnit: NoteGrid.eighth,
  sections: _sections(
    groove: line(eighths([R, L, R, L, R, L, R, L])),
    variations: [
      (
        line: line(eighths([R, L, R, L, R, L, R, L], accents: {0, 2, 4, 6})),
        clip: 'demo_pad_v1',
        text: 'Next up: accent the first note of every beat.',
        title: 'Accent on every beat',
      ),
      (
        line: line(eighths([R, R, L, L, R, R, L, L])),
        clip: 'demo_pad_v2',
        text: 'Now switch to doubles: right right, left left.',
        title: 'Switch to doubles',
      ),
      (
        line: line(eighths([R, L, R, R, L, R, L, L], accents: {0, 4})),
        clip: 'demo_pad_v3',
        text: 'Last one: play paradiddles. '
            'Right left right right, left right left left.',
        title: 'Paradiddles with accents',
      ),
    ],
  ),
);
