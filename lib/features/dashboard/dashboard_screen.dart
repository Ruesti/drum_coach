import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../learning/routine_provider.dart';
import '../stats/stats_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakDaysProvider);
    final routineAsync = ref.watch(dailyRoutineProvider);
    final sessionsAsync = ref.watch(allSessionsProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      appBar: AppBar(title: const Text('DrumCoach')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting + streak
          streakAsync.when(
            loading: () => _GreetingCard(greeting: greeting, streak: 0),
            error: (_, __) => _GreetingCard(greeting: greeting, streak: 0),
            data: (streak) => _GreetingCard(greeting: greeting, streak: streak),
          ),
          const SizedBox(height: 16),

          // Today's routine card
          routineAsync.when(
            loading: () => const _LoadingCard(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => _RoutineSummaryCard(
              itemCount: items.length,
              totalMin: items.fold(0, (s, i) => s + i.suggestedDurationMinutes),
              reviewCount: items.where((i) =>
                      i.type.name == 'review').length,
              onTap: () => context.go('/routine'),
            ),
          ),
          const SizedBox(height: 12),

          // Last session card
          sessionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (sessions) {
              if (sessions.isEmpty) return const _NoSessionsCard();
              final last = sessions.first;
              return _LastSessionCard(
                rudimentId: last.rudimentId,
                bpm: last.achievedBpm,
              );
            },
          ),
          const SizedBox(height: 12),

          // Quick-start metronome
          OutlinedButton.icon(
            onPressed: () => context.push('/metronome'),
            icon: const Icon(Icons.music_note_outlined),
            label: const Text('Open Metronome'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String greeting;
  final int streak;
  const _GreetingCard({required this.greeting, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (streak > 0) ...[
          const SizedBox(height: 4),
          Text('🔥 $streak day streak',
              style: const TextStyle(color: Colors.deepOrange, fontSize: 14)),
        ],
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
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
      return _DashCard(
        onTap: onTap,
        child: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("All caught up!",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("No reviews due today",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
    }
    return _DashCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.today, color: Colors.deepOrange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$itemCount rudiments · ~$totalMin min",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  reviewCount > 0
                      ? "$reviewCount due for review"
                      : "Practice session ready",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
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
    return _DashCard(
      onTap: () {},
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.white38, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Last practiced",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(rudimentId.replaceAll('_', ' '),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        textBaseline: TextBaseline.alphabetic)),
              ],
            ),
          ),
          Text('$bpm BPM',
              style: const TextStyle(
                  color: Colors.deepOrange, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _NoSessionsCard extends StatelessWidget {
  const _NoSessionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "Start your first practice session to see your progress here.",
        style: TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _DashCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
