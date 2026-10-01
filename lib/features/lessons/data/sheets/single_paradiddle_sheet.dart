import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// Sample sheet for the sheet format (Blattform, 30.09.). Placeholder
// content: the catalog step recomposes every sheet by the rule "as varied
// and groovy as possible". Each line is two bars; the challenge is eight
// bars straight through. Freely composed — nothing copied from the PDFs.

List<StrokeBeat> _pd8() => eighths([R, L, R, R, L, R, L, L]);
List<StrokeBeat> _pd16() =>
    sixteenths([R, L, R, R, L, R, L, L, R, L, R, R, L, R, L, L]);
List<StrokeBeat> _pd16acc() => sixteenths(
    [R, L, R, R, L, R, L, L, R, L, R, R, L, R, L, L],
    accents: {0, 4, 8, 12});

final List<ExerciseLine> singleParadiddleSheet = [
  // 1 · plain eighths, two bars
  line([..._pd8(), ..._pd8()], counts: true),
  // 2 · eighths, then the pattern lands on quarters
  line([
    ..._pd8(),
    ...eighths([R, L, R, R]),
    note(L, NoteValue.quarter),
    note(R, NoteValue.quarter),
  ], counts: true),
  // 3 · sixteenth group + quarter, mirrored in bar 2
  line([
    ...sixteenths([R, L, R, R]),
    note(L, NoteValue.quarter),
    ...sixteenths([R, L, R, R]),
    note(L, NoteValue.quarter),
    ...sixteenths([L, R, L, L]),
    note(R, NoteValue.quarter),
    ...sixteenths([L, R, L, L]),
    note(R, NoteValue.quarter),
  ], counts: true),
  // 4 · sixteenths, bar 2 ends on a quarter and a rest
  line([
    ..._pd16(),
    ...sixteenths([R, L, R, R, L, R, L, L]),
    note(R, NoteValue.quarter),
    rest(NoteValue.quarter),
  ]),
  // 5 · eighths into sixteenths
  line([..._pd8(), ..._pd16()]),
  // 6 · paradiddle, then doubles
  line([..._pd8(), ...eighths([R, R, L, L, R, R, L, L])]),
  // 7 · paradiddle, then singles
  line([
    ..._pd8(),
    ...sixteenths([R, L, R, L, R, L, R, L]),
    note(R, NoteValue.quarter),
    rest(NoteValue.quarter),
  ]),
  // 8 · accent on the lead of every group
  line([
    ..._pd16acc(),
    ...sixteenths([R, L, R, R, L, R, L, L], accents: {0, 4}),
    note(R, NoteValue.eighth, accent: true),
    rest(NoteValue.eighth),
    note(L, NoteValue.quarter, accent: true),
  ]),
  // 9 · groups with rests between
  line([
    ...sixteenths([R, L, R, R]),
    rest(NoteValue.eighth),
    note(L, NoteValue.eighth),
    ...sixteenths([R, L, R, R]),
    rest(NoteValue.eighth),
    note(L, NoteValue.eighth),
    ...sixteenths([L, R, L, L]),
    rest(NoteValue.eighth),
    note(R, NoteValue.eighth),
    ...sixteenths([L, R, L, L]),
    note(R, NoteValue.quarter),
  ]),
  // 10 · inverted paradiddle
  line([
    ...eighths([R, R, L, R, L, L, R, L]),
    ...sixteenths([R, R, L, R, L, L, R, L, R, R, L, R, L, L, R, L]),
  ]),
  // Challenge · eight bars, everything mixed, no repeat
  line([
    ..._pd8(),
    ...sixteenths([R, L, R, R, L, R, L, L]),
    note(R, NoteValue.quarter),
    rest(NoteValue.quarter),
    ...sixteenths([R, L, R, R]),
    note(L, NoteValue.quarter),
    ...sixteenths([R, L, R, R]),
    note(L, NoteValue.quarter),
    ..._pd16acc(),
    ..._pd8(),
    ...eighths([R, R, L, L, R, R, L, L]),
    ...sixteenths([R, L, R, R]),
    rest(NoteValue.eighth),
    note(L, NoteValue.eighth),
    ...sixteenths([R, L, R, R]),
    rest(NoteValue.eighth),
    note(L, NoteValue.eighth),
    ...sixteenths([R, L, R, R, L, R, L, L]),
    note(R, NoteValue.quarter),
    rest(NoteValue.quarter),
  ], repeat: false, title: 'Challenge'),
];

/// Lesson sections for the info page (spec §7) — never shown on the
/// practice screen.
const List<TechniqueSection> singleParadiddleLesson = [
  TechniqueSection(
    title: 'Why it matters',
    body: 'The paradiddle joins the two building blocks, single and double '
        'strokes. Because the lead hand switches every group, it moves you '
        'freely between the hands on the kit: the base for fills, grooves '
        'between snare and toms, and everything later called "mixed".',
  ),
  TechniqueSection(
    title: 'How to play it',
    body: 'One stroke right, one left, then two right: R L R R. Then the '
        'mirror image: L R L L. Say it out loud — pa-ra-did-dle.',
  ),
  TechniqueSection(
    title: 'Practice tips',
    body: 'The double must not get quieter than the singles: play both '
        'strokes from the wrist and let the stick bounce only when the tempo '
        'demands it. First put a light accent on the first stroke of each '
        'group, then play everything even. If you tense up, drop back one '
        'tempo step.',
  ),
  TechniqueSection(
    title: 'Song examples',
    body: '• 50 Ways to Leave Your Lover — Paul Simon (Steve Gadd builds the '
        'groove from paradiddles)\n• more places later from your song analysis',
  ),
];
