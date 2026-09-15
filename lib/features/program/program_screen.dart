import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../data/local/settings_service.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/error_state.dart';
import '../lessons/lessons_provider.dart';
import 'models/training_program.dart';
import 'program_generator.dart';
import 'program_provider.dart';

/// The training-program screen: current day, phase focus, exercise blocks with
/// target tempo, and a distinct Ruhetag (rest day) state.
class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(trainingProgramProvider);
    final dayAsync = ref.watch(currentProgramDayProvider);
    final configured = SettingsService.programConfig != null;

    Future<void> resetProgram() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Reset program?'),
          content: const Text(
              'Your current progress and settings (duration, start level, '
              'exercise pool) will be lost. Afterwards you can set up a '
              'new program with a custom duration.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(programControllerProvider.notifier).reset();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
        actions: [
          if (configured)
            IconButton(
              icon: const Icon(Icons.replay),
              tooltip: 'Reset program',
              onPressed: resetProgram,
            ),
        ],
      ),
      body: dayAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ErrorStateWidget(
            message: 'Error: $e',
            onRetry: () => ref.invalidate(currentProgramDayProvider),
          ),
        ),
        data: (day) {
          if (!configured) {
            return _NotStarted(
              program: program,
              onSetup: () => context.push('/program/setup'),
            );
          }
          if (day == null) {
            return _Finished(
              weeks: SettingsService.programConfig?.durationWeeks,
              onReset: resetProgram,
            );
          }
          return _DayView(day: day);
        },
      ),
    );
  }
}

class _NotStarted extends StatelessWidget {
  final TrainingProgram program;
  final VoidCallback onSetup;
  const _NotStarted({required this.program, required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Text(program.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(program.description,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        const SizedBox(height: 20),
        for (final phase in program.phases) ...[
          _PhaseOverviewCard(phase: phase),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onSetup,
          icon: const Icon(Icons.settings),
          label: const Text('Set up program'),
        ),
      ],
    );
  }
}

class _PhaseOverviewCard extends StatelessWidget {
  final ProgramPhase phase;
  const _PhaseOverviewCard({required this.phase});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phase ${phase.index} · ${phase.name}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text('Week ${phase.weekStart}–${phase.weekEnd} · from ${phase.startBpm} BPM',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(phase.focus,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Finished extends StatelessWidget {
  final int? weeks;
  final VoidCallback onReset;
  const _Finished({required this.weeks, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final weeksLabel = weeks != null ? '$weeks weeks' : 'The program';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('Program complete',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$weeksLabel done. New clean personal bests in your hands.',
                style: const TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.replay),
              label: const Text('Start over'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.textFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayView extends ConsumerWidget {
  final ProgramDay day;
  const _DayView({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done =
        ref.watch(programDayCompletionProvider).valueOrNull ?? const <int>{};
    final allDone = day.blocks.isNotEmpty && done.length >= day.blocks.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DayHeader(day: day),
        const SizedBox(height: 16),
        if (day.type == DayType.rest)
          const _RestDay()
        else ...[
          if (allDone) ...[
            _DayDoneBanner(day: day),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < day.blocks.length; i++) ...[
            _BlockCard(block: day.blocks[i], done: done.contains(i)),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

/// Shown once every block of the day has a finished session: confirms the
/// day is complete and says what tomorrow brings.
class _DayDoneBanner extends StatelessWidget {
  final ProgramDay day;
  const _DayDoneBanner({required this.day});

  @override
  Widget build(BuildContext context) {
    final totalDays =
        SettingsService.programConfig?.totalDays ?? programTotalDays;
    final String tomorrow;
    if (day.dayNumber >= totalDays) {
      tomorrow = 'That was the last day — program complete!';
    } else {
      tomorrow = switch (dayTypeForDayNumber(day.dayNumber + 1)) {
        DayType.practice =>
          'Day ${day.dayNumber + 1} with fresh exercises awaits tomorrow.',
        DayType.light => 'Tomorrow: easy day with a short technique review.',
        DayType.rest => 'Tomorrow: rest day — recovery is part of the plan.',
      };
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.ok.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.ok.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 26)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day ${day.dayNumber} done!',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(tomorrow,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends ConsumerWidget {
  final ProgramDay day;
  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = day.phase;
    final config = SettingsService.programConfig;
    final totalDays = config?.totalDays ?? programTotalDays;

    String? pacingLabel;
    if (config != null) {
      final pool =
          programPoolExercises(ref.watch(rudimentsProvider), config.pool);
      final stages = effectiveStages(pool, config.startDifficulty);
      if (stages.isNotEmpty) {
        final stageIndex =
            SettingsService.programStageIndex.clamp(0, stages.length - 1);
        final pacing = programPacing(
          durationWeeks: config.durationWeeks,
          totalStages: stages.length,
          stageIndex: stageIndex,
          dayNumber: day.dayNumber,
        );
        final statusLabel = switch (pacing.status) {
          PacingStatus.ahead => 'ahead',
          PacingStatus.onTrack => 'on track',
          PacingStatus.behind => 'behind',
        };
        pacingLabel = 'Week ${pacing.nominalWeek}/${config.durationWeeks} · '
            'Stage: ${stages[stageIndex].label} · $statusLabel';
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Day ${day.dayNumber}/$totalDays · ~${day.estimatedMinutes} min',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          if (pacingLabel != null) ...[
            const SizedBox(height: 2),
            Text(pacingLabel,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
          const SizedBox(height: 4),
          Text('Phase ${phase.index}: ${phase.name}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(phase.focus,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          if (phase.focusCue != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(phase.focusCue!,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RestDay extends StatelessWidget {
  const _RestDay();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Text('😴', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text('Rest day',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Day off. No blocks today — the rest day doesn't count against "
              'your streak. Recovery is part of the plan.',
              style: TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockCard extends ConsumerWidget {
  final ExerciseBlock block;
  final bool done;
  const _BlockCard({required this.block, this.done = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rudiment = ref.watch(rudimentByIdProvider(block.exerciseKey));
    final variants =
        block.variants.map(_variantLabel).join(' · ');
    final (badgeLabel, badgeColor) = _blockBadgeInfo(block.type);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppBadge(label: badgeLabel, color: badgeColor),
                        const SizedBox(width: 8),
                        if (done) ...[
                          const Icon(Icons.check_circle,
                              size: 16, color: AppColors.ok),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(rudiment.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (block.startBpm != null) '${block.startBpm} BPM',
                        '~${block.durationMinutes} min',
                        if (variants.isNotEmpty) variants,
                      ].join(' · '),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final params = [
                    if (block.startBpm != null) 'bpm=${block.startBpm}',
                    if (block.durationMinutes > 0)
                      'min=${block.durationMinutes}',
                    if (block.type == BlockType.tempoLadder) 'ladder=1',
                  ].join('&');
                  final q = params.isEmpty ? '' : '?$params';
                  context.push('/practice/${block.exerciseKey}$q');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: done ? AppColors.raised : AppColors.accent,
                  foregroundColor:
                      done ? AppColors.textSecondary : AppColors.textPrimary,
                  minimumSize: const Size(70, 38),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Text(done ? 'Again' : 'Start'),
              ),
            ],
          ),
          // Tempo-ladder gate: self-rated clean pass lifts the stored tempo +4.
          if (block.cleanPassRequired) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.textFaint, height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _askCleanPass(context, ref),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Ran clean & relaxed?'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: EdgeInsets.zero),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _askCleanPass(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clean & relaxed?'),
        content: Text(
          'Did the tempo ladder run evenly and relaxed? '
          'Yes raises your clean tempo by +4 BPM to '
          '${(block.startBpm ?? 0) + 4}.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return; // guards this context use only — safe here
    // Capture the messenger before any further await: recordCleanPass
    // invalidates currentProgramDay, which reloads the screen and disposes
    // this widget, so a later context.mounted check would be false by the
    // time advanceStageIfReady resolves. The messenger itself outlives the
    // widget, so no further mounted check is needed below.
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(cleanTempoNotifierProvider.notifier)
        .recordCleanPass(block.exerciseKey, block.startBpm ?? 0);
    final advanced =
        await ref.read(programControllerProvider.notifier).advanceStageIfReady();
    if (advanced) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Level up! New stage reached.')),
      );
    }
  }
}

(String, Color) _blockBadgeInfo(BlockType type) => switch (type) {
      BlockType.warmup => ('Warmup', AppColors.solidStreak),
      BlockType.technique => ('Technique', AppColors.info),
      BlockType.tempoLadder => ('Tempo ladder', AppColors.accent),
      BlockType.endurance => ('Endurance', AppColors.ok),
    };

String _variantLabel(Variant v) => switch (v) {
      Variant.even => 'even',
      Variant.pp => 'pp (soft)',
      Variant.ff => 'ff (loud)',
      Variant.crescendo => 'Crescendo',
      Variant.fingers => 'Fingers',
      Variant.rebound => 'Rebound',
      Variant.accentTap => 'Accent/tap',
      Variant.endurance => 'Endurance',
    };
