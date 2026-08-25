import '../models/rudiment.dart';

const Hand R = Hand.right;
const Hand L = Hand.left;

Hand _opposite(Hand h) => h == Hand.right ? Hand.left : Hand.right;

StrokeBeat note(Hand h, NoteValue v,
        {bool accent = false,
        bool ghost = false,
        bool dotted = false,
        Tuplet tuplet = Tuplet.none,
        List<Hand> graces = const []}) =>
    StrokeBeat(
        hand: h,
        value: v,
        isAccent: accent,
        isGhost: ghost,
        dotted: dotted,
        tuplet: tuplet,
        graces: graces);

StrokeBeat rest(NoteValue v, {bool dotted = false, Tuplet tuplet = Tuplet.none}) =>
    StrokeBeat.rest(value: v, dotted: dotted, tuplet: tuplet);

StrokeBeat flam(Hand h, NoteValue v, {bool accent = false}) =>
    note(h, v, accent: accent, graces: [_opposite(h)]);

StrokeBeat drag(Hand h, NoteValue v, {bool accent = false}) =>
    note(h, v, accent: accent, graces: [_opposite(h), _opposite(h)]);

List<StrokeBeat> run(List<Hand> hands, NoteValue v,
        {Tuplet tuplet = Tuplet.none, Set<int> accents = const {}}) =>
    [
      for (var i = 0; i < hands.length; i++)
        note(hands[i], v, tuplet: tuplet, accent: accents.contains(i)),
    ];

List<StrokeBeat> eighths(List<Hand> h, {Set<int> accents = const {}}) =>
    run(h, NoteValue.eighth, accents: accents);
List<StrokeBeat> sixteenths(List<Hand> h, {Set<int> accents = const {}}) =>
    run(h, NoteValue.sixteenth, accents: accents);
List<StrokeBeat> triplet8(List<Hand> h, {Set<int> accents = const {}}) =>
    run(h, NoteValue.eighth, tuplet: Tuplet.triplet, accents: accents);
List<StrokeBeat> sextuplet16(List<Hand> h, {Set<int> accents = const {}}) =>
    run(h, NoteValue.sixteenth, tuplet: Tuplet.sextuplet, accents: accents);

/// Sum note durations; throw if not a positive whole number of [beatsPerBar]
/// bars, else return the bar count. Guards new étude content.
int barCountOrThrow(List<StrokeBeat> beats,
    {required int beatsPerBar, required NoteGrid grid}) {
  var quarters = 0.0;
  for (final b in beats) {
    quarters += resolveNote(b, grid).quarters;
  }
  final bars = quarters / beatsPerBar;
  final rounded = bars.round();
  if (rounded < 1 || (bars - rounded).abs() > 1e-6) {
    throw ArgumentError(
        '$quarters quarters is not a whole number of $beatsPerBar/4 bars');
  }
  return rounded;
}
