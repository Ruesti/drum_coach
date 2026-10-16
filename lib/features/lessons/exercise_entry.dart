import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../learning/suggested_bpm_provider.dart';
import 'models/rudiment.dart';

/// Sheets (more than one line) open their line list; a list with a single
/// card would be an empty extra step.
bool opensLineList(Rudiment r) => r.sheet.length > 1;

/// The library/collection entry: sheets → line list, one-line exercises
/// straight into practice at the suggested tempo.
Future<void> openExercise(
    BuildContext context, WidgetRef ref, Rudiment r) async {
  if (opensLineList(r)) {
    await context.push('/exercise/${r.id}');
    return;
  }
  final bpm = await ref.read(suggestedBpmProvider(r.id).future);
  if (context.mounted) await context.push('/practice/${r.id}?bpm=$bpm');
}
