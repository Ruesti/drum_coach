import '../models/rudiment.dart';
import 'etudes/accent_workout_etudes.dart';
import 'etudes/beginner_count_etudes.dart';
import 'etudes/double_paradiddle_etudes.dart';
import 'etudes/double_stroke_roll_etudes.dart';
import 'etudes/drag_etudes.dart';
import 'etudes/five_stroke_roll_etudes.dart';
import 'etudes/flam_accent_etudes.dart';
import 'etudes/flam_etudes.dart';
import 'etudes/pad_solo_etudes.dart';
import 'etudes/paradiddle_diddle_etudes.dart';
import 'etudes/single_paradiddle_etudes.dart';
import 'etudes/single_stroke_roll_etudes.dart';
import 'etudes/sticking_pattern_etudes.dart';
import 'etudes/swiss_army_triplet_etudes.dart';
import 'etudes/technique_studies.dart';
import 'etudes/warmup_etudes.dart';

/// All curated étude/study content, appended to the base catalog by
/// `rudimentsProvider`. One file per rudiment/group keeps authoring focused.
final List<Rudiment> allEtudes = <Rudiment>[
  ...singleStrokeRollEtudes,
  ...doubleStrokeRollEtudes,
  ...singleParadiddleEtudes,
  ...doubleParadiddleEtudes,
  ...paradiddleDiddleEtudes,
  ...flamEtudes,
  ...dragEtudes,
  ...flamAccentEtudes,
  ...fiveStrokeRollEtudes,
  ...swissArmyTripletEtudes,
  ...techniqueStudies,
  // Pad-Workouts collection — inspired by (not copied from) teaching PDFs the
  // user provided under docs/Übungen; freshly composed, same pedagogical
  // spirit. See docs/Übungen/README.md for provenance.
  ...stickingPatternEtudes,
  ...warmupEtudes,
  ...beginnerCountEtudes,
  ...accentWorkoutEtudes,
  ...padSoloEtudes,
];
