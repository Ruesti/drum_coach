import 'models/training_program.dart';

/// Route into the practice screen for a program block — one place for the
/// bpm / min / ladder query, shared by the program screen and Today.
/// [ctx] is the context line the practice header shows under the exercise
/// name (e.g. "Day 9 · Step 2 of 3 · 84 BPM").
String practiceRouteFor(ExerciseBlock block, {String? ctx}) {
  final params = [
    if (block.startBpm != null) 'bpm=${block.startBpm}',
    if (block.durationMinutes > 0) 'min=${block.durationMinutes}',
    if (block.type == BlockType.tempoLadder) 'ladder=1',
    if (ctx != null && ctx.isNotEmpty) 'ctx=${Uri.encodeQueryComponent(ctx)}',
  ].join('&');
  return '/practice/${block.exerciseKey}${params.isEmpty ? '' : '?$params'}';
}
