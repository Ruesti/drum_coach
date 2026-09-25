import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/settings_service.dart';
import '../learning/routine_provider.dart';
import '../lessons/lessons_provider.dart';
import '../program/program_provider.dart';
import 'next_step.dart';

/// Today's "Continue the path" step, from the program (first open block of
/// the current day) or, without a program, from the daily routine.
final nextStepProvider = FutureProvider<PathStep>((ref) async {
  final rudiments = ref.watch(rudimentsProvider);
  String nameOf(String id) {
    for (final r in rudiments) {
      if (r.id == id) return r.name;
    }
    return id.replaceAll('_', ' ');
  }

  final hasProgram = SettingsService.programConfig != null;
  if (!hasProgram) {
    final routine = await ref.watch(dailyRoutineProvider.future);
    return computeNextStep(
      hasProgram: false,
      day: null,
      done: const {},
      routine: routine,
      nameOf: nameOf,
    );
  }
  final day = await ref.watch(currentProgramDayProvider.future);
  final done = day == null
      ? <int>{}
      : await ref.watch(programDayCompletionProvider.future);
  return computeNextStep(
    hasProgram: true,
    day: day,
    done: done,
    routine: const [],
    nameOf: nameOf,
  );
});
