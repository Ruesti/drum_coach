import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../data/local/models/rudiment_progress.dart';
import '../../shared/widgets/error_state.dart';
import '../lessons/lessons_provider.dart';
import '../lessons/models/rudiment.dart';
import '../stats/stats_provider.dart';
import 'room_provider.dart';

/// The Trainingsraum session (spec 4.2): warm up, then deepen one area.
/// Replaces the training program and the daily routine; Today's "Continue"
/// opens it.
class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(roomPlanProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("Today's session")),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: 'Could not plan your session.',
          onRetry: () => ref.invalidate(allProgressProvider),
        ),
        data: (p) => p == null ? const _Empty() : _PlanView(plan: p),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Text(
            'Nothing to practice here yet.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _PlanView extends ConsumerWidget {
  const _PlanView({required this.plan});
  final RoomPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = {for (final r in ref.watch(rudimentsProvider)) r.id: r};
    final progress = ref.watch(roomProgressProvider).valueOrNull ?? const {};
    final session = plan.session;
    final now = DateTime.now();

    Future<void> start(Rudiment r, {required bool room}) async {
      final current = progress[r.id]?.currentBpm ?? 0;
      final bpm = current > 0 ? current : r.minBpm;
      await context
          .push('/practice/${r.id}?lines=all&bpm=$bpm${room ? '&room=1' : ''}');
      // Back from practice: re-plan from the fresh progress rows.
      if (context.mounted) ref.invalidate(allProgressProvider);
    }

    Widget row(String prefix, String id, {required bool room}) {
      final r = catalog[id];
      if (r == null) return const SizedBox.shrink();
      final p = progress[id];
      final due = p != null && !p.nextReviewDate.isAfter(now);
      final bpm = (p?.currentBpm ?? 0) > 0 ? p!.currentBpm : r.minBpm;
      final detail = [
        if (!room && r.area != null) r.area!.label,
        if (room && due) 'Review',
        if (p?.mastery == MasteryLevel.mastered) 'Sits',
        '$bpm BPM',
      ].join(' · ');
      return _ExerciseRow(
        key: Key('$prefix-$id'),
        name: r.name,
        detail: detail,
        primary: room,
        onStart: () => start(r, room: room),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            const _Heading('Warm-up'),
            const SizedBox(height: AppSpacing.xs),
            const _Hint('About 5 minutes, at a comfortable tempo.'),
            const SizedBox(height: AppSpacing.sm),
            for (final id in session.warmup) row('warmup', id, room: false),
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            _Heading("Today's focus: ${session.area.label}"),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final a in plan.areas)
                  ChoiceChip(
                    key: Key('area-${a.name}'),
                    label: Text(a.label),
                    avatar: a == plan.suggested
                        ? const Icon(Icons.star, size: 16)
                        : null,
                    showCheckmark: false,
                    selected: a == session.area,
                    onSelected: (_) => ref
                        .read(roomChosenAreaProvider.notifier)
                        .state = a == plan.suggested ? null : a,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // The star as an icon: the text font has no ★ glyph.
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 3, right: AppSpacing.xs),
                  child: Icon(Icons.star,
                      size: 16, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: _Hint('Suggested: due reviews first, otherwise the '
                      'area played longest ago.'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (session.deepen.isEmpty)
              const _Hint('Everything at this level sits. '
                  'The next level is always open in the Library.')
            else
              for (final id in session.deepen) row('deepen', id, room: true),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: AppTypography.title);
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      );
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    super.key,
    required this.name,
    required this.detail,
    required this.primary,
    required this.onStart,
  });

  final String name;
  final String detail;
  final bool primary;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    const button = Text('Start');
    // The theme's buttons are full-width; here they sit beside the name.
    const size = Size(96, 44);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.body),
                Text(
                  detail,
                  style: AppTypography.body
                      .copyWith(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          primary
              ? ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(minimumSize: size),
                  child: button)
              : OutlinedButton(
                  onPressed: onStart,
                  style: OutlinedButton.styleFrom(minimumSize: size),
                  child: button),
        ],
      ),
    );
  }
}
