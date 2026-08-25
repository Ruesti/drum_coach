import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/error_state.dart';
import '../learning/routine_provider.dart';
import '../stats/stats_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakDaysProvider);
    final bestAsync = ref.watch(longestStreakProvider);
    final todayAsync = ref.watch(todayStatusProvider);
    final routineAsync = ref.watch(dailyRoutineProvider);
    final sessionsAsync = ref.watch(allSessionsProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      appBar: AppBar(
        title: const Text('DrumCoach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Greeting + streak
          _GreetingCard(
            greeting: greeting,
            streak: streakAsync.valueOrNull ?? 0,
            best: bestAsync.valueOrNull ?? 0,
            today: todayAsync.valueOrNull,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Training program entry
          AppCard(
            onTap: () => context.push('/program'),
            child: const _DashRow(
              icon: Icons.fitness_center,
              title: 'Trainingsprogramm',
              subtitle: 'Stick Control · 12 Wochen',
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Étude/technique-collection browse entry
          AppCard(
            onTap: () => context.push('/collection/rudimentEtudes'),
            child: const _DashRow(
              icon: Icons.library_music_outlined,
              title: 'Übungs-Sammlung',
              subtitle: 'Rudiment-Étüden & Technik-Studien',
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Technique-studies collection entry
          AppCard(
            onTap: () => context.push('/collection/techniqueStudies'),
            child: const _DashRow(
              icon: Icons.school_outlined,
              title: 'Technik-Studien',
              subtitle: 'Gezielte Technik-Übungen',
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Pad-workout collection entry
          AppCard(
            onTap: () => context.push('/collection/padWorkouts'),
            child: const _DashRow(
              icon: Icons.dashboard_customize_outlined,
              title: 'Pad-Workouts',
              subtitle: 'Sticking-Patterns, Warm-Up, Akzent-Workout & mehr',
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Today's routine card
          routineAsync.when(
            loading: () => const _LoadingCard(),
            error: (_, __) => ErrorStateWidget(
              message: 'Tagesroutine konnte nicht geladen werden.',
              compact: true,
              onRetry: () => ref.invalidate(dailyRoutineProvider),
            ),
            data: (items) => _RoutineSummaryCard(
              itemCount: items.length,
              totalMin: items.fold(0, (s, i) => s + i.suggestedDurationMinutes),
              reviewCount: items.where((i) =>
                      i.type.name == 'review').length,
              onTap: () => context.go('/routine'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Last session card
          sessionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => ErrorStateWidget(
              message: 'Letzte Sessions konnten nicht geladen werden.',
              compact: true,
              onRetry: () => ref.invalidate(allSessionsProvider),
            ),
            data: (sessions) {
              if (sessions.isEmpty) return const _NoSessionsCard();
              final last = sessions.first;
              return _LastSessionCard(
                rudimentId: last.exerciseId,
                bpm: last.achievedBpm,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick-start metronome
          OutlinedButton.icon(
            onPressed: () => context.push('/metronome'),
            icon: const Icon(Icons.music_note_outlined),
            label: const Text('Open Metronome'),
          ),
        ],
      ),
    );
  }
}

/// Shared icon + title/subtitle row used by the simple navigation cards.
class _DashRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _DashRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 28),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textFaint),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String greeting;
  final int streak;
  final int best;
  final TodayStatus? today;
  const _GreetingCard({
    required this.greeting,
    required this.streak,
    this.best = 0,
    this.today,
  });

  @override
  Widget build(BuildContext context) {
    final today = this.today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (streak > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text('🔥 $streak day streak',
                  style:
                      const TextStyle(color: AppColors.accent, fontSize: 14)),
              if (best > streak) ...[
                const SizedBox(width: 10),
                Text('Best $best',
                    style:
                        const TextStyle(color: AppColors.textFaint, fontSize: 13)),
              ],
            ],
          ),
        ],
        if (today != null && today.practiced) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(today.goalMet ? Icons.check_circle : Icons.timelapse_outlined,
                  size: 14,
                  color: today.goalMet ? AppColors.solidStreak : AppColors.ok),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  today.goalMet
                      ? 'Tagesziel erreicht'
                      : 'Heute ${today.minutes}/${today.goalMinutes} min',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _RoutineSummaryCard extends StatelessWidget {
  final int itemCount;
  final int totalMin;
  final int reviewCount;
  final VoidCallback onTap;

  const _RoutineSummaryCard({
    required this.itemCount,
    required this.totalMin,
    required this.reviewCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return AppCard(
        onTap: onTap,
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "All caught up!",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "No reviews due today",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.today, color: AppColors.accent, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$itemCount rudiments · ~$totalMin min",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  reviewCount > 0
                      ? "$reviewCount due for review"
                      : "Practice session ready",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textFaint),
        ],
      ),
    );
  }
}

class _LastSessionCard extends StatelessWidget {
  final String rudimentId;
  final int bpm;
  const _LastSessionCard({required this.rudimentId, required this.bpm});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {},
      child: Row(
        children: [
          const Icon(Icons.history, color: AppColors.textFaint, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Last practiced",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                Text(
                  rudimentId.replaceAll('_', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      textBaseline: TextBaseline.alphabetic),
                ),
              ],
            ),
          ),
          Text('$bpm BPM',
              style: const TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _NoSessionsCard extends StatelessWidget {
  const _NoSessionsCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Text(
        "Start your first practice session to see your progress here.",
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}
