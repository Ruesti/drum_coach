import 'models/guided_exercise.dart';

/// `m:ss` of [ms] milliseconds.
String guidedMmss(double ms) {
  final s = (ms / 1000).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// `~m:ss`: planned length at [bpm] (default: the exercise's default
/// tempo), without the planner's extension for long explanations.
String guidedDurationLabel(GuidedExercise ex, {int? bpm}) {
  final b = bpm ?? ex.defaultBpm;
  return '~${guidedMmss(ex.barsAt(b) * guidedBeatsPerBar * 60000 / b)}';
}
