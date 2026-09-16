import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/error_state.dart';
import '../stats/stats_provider.dart';
import 'next_step.dart';
import 'next_step_provider.dart';

/// Start screen (K2): two doors — continue the path, or practice freely —
/// then streak and minutes, compact. Replaces the dashboard card stack.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(nextStepProvider);
    final streak = ref.watch(streakDaysProvider);
    final today = ref.watch(todayStatusProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning.'
        : hour < 18
            ? 'Good afternoon.'
            : 'Good evening.';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                const _Eyebrow('Today'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  color: AppColors.textMuted,
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            Text(greeting, style: AppTypography.display),
            const SizedBox(height: AppSpacing.xl),
            step.when(
              data: (s) => _PathDoor(step: s),
              loading: () => const SizedBox(height: 140),
              error: (e, _) => ErrorStateWidget(
                message: 'Could not load your next step.',
                onRetry: () => ref.invalidate(nextStepProvider),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            const _FreeDoor(),
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            _StatsRow(
              streak: streak.valueOrNull ?? 0,
              today: today.valueOrNull,
            ),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text, {this.color = AppColors.textMuted});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTypography.label.copyWith(color: color, letterSpacing: 1.0),
      );
}

class _PathDoor extends StatelessWidget {
  const _PathDoor({required this.step});
  final PathStep step;

  String? get _buttonLabel => switch (step.kind) {
        PathStepKind.exercise =>
          step.minutes > 0 ? 'Start · ${step.minutes} min' : 'Start',
        PathStepKind.setup => 'Set up your path',
        PathStepKind.dayDone || PathStepKind.programComplete => 'Open program',
        PathStepKind.restDay => null,
      };

  @override
  Widget build(BuildContext context) {
    final label = _buttonLabel;
    final route = step.route;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Continue the path', color: AppColors.paperAccent),
        const SizedBox(height: AppSpacing.xs),
        Text(step.title, style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          step.detail,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        if (label != null && route != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => context.push(route),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: Text(label),
          ),
        ],
      ],
    );
  }
}

class _FreeDoor extends StatelessWidget {
  const _FreeDoor();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Practice freely'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Rudiments, etudes and technique studies.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => context.go('/library'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Open library'),
              SizedBox(width: AppSpacing.sm),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.streak, required this.today});
  final int streak;
  final TodayStatus? today;

  @override
  Widget build(BuildContext context) {
    final number = GoogleFonts.ibmPlexMono(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      height: 1.05,
      color: AppColors.textPrimary,
    );
    final faint = number.copyWith(color: AppColors.textMuted);
    final label =
        AppTypography.body.copyWith(fontSize: 13, color: AppColors.textMuted);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streak', style: number),
              Text('day streak', style: label),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${today?.minutes ?? 0}', style: number),
                  Text('/${today?.goalMinutes ?? 0}', style: faint),
                ],
              ),
              Text('min today', style: label),
            ],
          ),
        ),
      ],
    );
  }
}
