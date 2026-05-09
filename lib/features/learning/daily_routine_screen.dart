import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        error: (e, _) => Center(child: Text('Error: $e')),
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
                  onStart: () => context.push('/routine/${item.rudimentId}'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.today, color: Colors.deepOrange),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Routine",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('$itemCount rudiments · ~$totalMin min',
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeBadge(type: item.type),
                    const SizedBox(width: 8),
                    Text(rudiment.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.suggestedBpm} BPM · ~${item.suggestedDurationMinutes} min',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              minimumSize: const Size(70, 38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
      RoutineItemType.review => ('Review', Colors.amber),
      RoutineItemType.progression => ('Progress', Colors.blue.shade300),
      RoutineItemType.newRudiment => ('New', Colors.green.shade400),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
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
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('No reviews due today. Great work!',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onFreePractice,
              icon: const Icon(Icons.library_books_outlined),
              label: const Text('Browse Lessons'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
