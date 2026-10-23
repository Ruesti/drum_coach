import 'models/guided_exercise.dart';

/// `m:ss` of [ms] milliseconds.
String guidedMmss(double ms) {
  final s = (ms / 1000).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// `~m:ss`: planned length at the default tempo, without the planner's
/// extension for long explanations.
String guidedDurationLabel(GuidedExercise ex) =>
    '~${guidedMmss(ex.barsAt(ex.defaultBpm) * guidedBeatsPerBar * 60000 / ex.defaultBpm)}';
