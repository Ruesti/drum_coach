import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lessons/lessons_provider.dart';
import '../room/room_provider.dart';
import '../room/session_planner.dart';
import 'next_step.dart';

/// Today's "Continue": the room session, its detail naming the area the
/// planner suggests today.
final nextStepProvider = FutureProvider.autoDispose<PathStep>((ref) async {
  final catalog = ref.watch(rudimentsProvider);
  final progress = await ref.watch(roomProgressProvider.future);
  final session = planSession(
    catalog: catalog,
    progress: progress,
    now: DateTime.now(),
  );
  return computeNextStep(session: session);
});
