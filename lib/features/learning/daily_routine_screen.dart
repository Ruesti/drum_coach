import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/error_state.dart';
import '../lessons/lessons_provider.dart';
import '../lessons/models/rudiment.dart';
import 'models/daily_routine.dart';
import 'routine_provider.dart';

class DailyRoutineScreen extends ConsumerWidget {
  const DailyRoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(dailyRoutineProvider);
    final rudiments = ref.watch(rudimentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Routine')),
      body: routineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ErrorStateWidget(
            message: 'Error: $e',
            onRetry: () => ref.invalidate(dailyRoutineProvider),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyRoutine(onFreePractice: () => context.push('/lessons'));
          }
          final totalMin =
              items.fold(0, (sum, i) => sum + i.suggestedDurationMinutes);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RoutineHeader(itemCount: items.length, totalMin: totalMin),
              const SizedBox(height: 16),
              for (final item in items) ...[
                _RoutineCard(
                  item: item,
                  rudiment: rudiments.firstWhere((r) => r.id == item.rudimentId),
                  onStart: () => context
                      .push('/routine/${item.rudimentId}?bpm=${item.suggestedBpm}'),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RoutineHeader extends StatelessWidget {
  final int itemCount;
  final int totalMin;
  const _RoutineHeader({required this.itemCount, required this.totalMin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.today, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Routine",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$itemCount rudiments · ~$totalMin min',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final DailyRoutineItem item;
  final Rudiment rudiment;
  final VoidCallback onStart;

  const _RoutineCard({
    required this.item,
    required this.rudiment,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeBadge(type: item.type),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        rudiment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.suggestedBpm} BPM · ~${item.suggestedDurationMinutes} min',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(70, 38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.chip)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final RoutineItemType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      RoutineItemType.review => ('Review', AppColors.ok),
      RoutineItemType.progression => ('Progress', AppColors.info),
      RoutineItemType.newRudiment => ('New', AppColors.solidStreak),
    };
    return AppBadge(label: label, color: color);
  }
}

class _EmptyRoutine extends StatelessWidget {
  final VoidCallback onFreePractice;
  const _EmptyRoutine({required this.onFreePractice});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text("You're all caught up!",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('No reviews due today. Great work!',
                style: TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onFreePractice,
              icon: const Icon(Icons.library_books_outlined),
              label: const Text('Browse Lessons'),
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
