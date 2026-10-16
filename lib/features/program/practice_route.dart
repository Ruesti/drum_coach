import 'models/training_program.dart';

/// Route into the practice screen for a program block — one place for the
/// lines / bpm / min / ladder query, shared by the program screen and Today.
/// A block always plays every line of its sheet (`lines=all`).
/// [ctx] is the context line the practice header shows under the exercise
/// name (e.g. "Day 9 · Step 2 of 3 · 84 BPM"); [phase] (1–4) picks the
/// practice backdrop so it continues Today's phase picture.
String practiceRouteFor(ExerciseBlock block, {String? ctx, int? phase}) {
  final params = [
    'lines=all',
    if (block.startBpm != null) 'bpm=${block.startBpm}',
    if (block.durationMinutes > 0) 'min=${block.durationMinutes}',
    if (block.type == BlockType.tempoLadder) 'ladder=1',
    if (ctx != null && ctx.isNotEmpty) 'ctx=${Uri.encodeQueryComponent(ctx)}',
    if (phase != null) 'phase=$phase',
  ].join('&');
  return '/practice/${block.exerciseKey}?$params';
}
