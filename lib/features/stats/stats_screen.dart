import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../lessons/lessons_provider.dart';
import 'stats_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String? _selectedRudimentId;

  @override
  Widget build(BuildContext context) {
    final dailyAsync = ref.watch(last14DaysMinutesProvider);
    final streakAsync = ref.watch(streakDaysProvider);
    final sessionsAsync = ref.watch(allSessionsProvider);
    final rudiments = ref.watch(rudimentsProvider);

    _selectedRudimentId ??= rudiments.firstOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const _EmptyStats();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Streak
              streakAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (streak) => _StreakCard(streak: streak),
              ),
              const SizedBox(height: 16),
              // Bar chart
              _SectionLabel('DAILY PRACTICE (last 14 days)'),
              const SizedBox(height: 8),
              dailyAsync.when(
                loading: () => const SizedBox(
                    height: 160, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) => _BarChartCard(data: data),
              ),
              const SizedBox(height: 20),
              // BPM progress
              _SectionLabel('BPM PROGRESS'),
              const SizedBox(height: 8),
              _RudimentPicker(
                rudiments: rudiments.map((r) => (r.id, r.name)).toList(),
                selected: _selectedRudimentId,
                onChanged: (id) => setState(() => _selectedRudimentId = id),
              ),
              const SizedBox(height: 8),
              if (_selectedRudimentId != null)
                _BpmLineChart(rudimentId: _selectedRudimentId!),
              const SizedBox(height: 20),
              // Recent sessions
              _SectionLabel('RECENT SESSIONS'),
              const SizedBox(height: 8),
              ...sessions.take(10).map((s) {
                final name = rudiments
                    .where((r) => r.id == s.rudimentId)
                    .firstOrNull
                    ?.name ?? s.rudimentId;
                return _SessionTile(session: s, rudimentName: name);
              }),
            ],
          );
        },
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

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
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streak day streak',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Keep it going!',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.deepOrange,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _BarChartCard extends ConsumerWidget {
  final List<DailyMinutes> data;
  const _BarChartCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          maxY: data.map((d) => d.minutes.toDouble()).fold<double>(10, (a, b) => a > b ? a : b) + 5,
          barGroups: data.asMap().entries.map((e) {
            final isToday = e.value.date.day == today.day &&
                e.value.date.month == today.month &&
                e.value.date.year == today.year;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.minutes.toDouble(),
                  width: 14,
                  color: isToday ? Colors.deepOrange : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 7,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  return Text(
                    DateFormat('d/M').format(data[idx].date),
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RudimentPicker extends StatelessWidget {
  final List<(String, String)> rudiments;
  final String? selected;
  final ValueChanged<String> onChanged;

  const _RudimentPicker({
    required this.rudiments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: selected,
        isExpanded: true,
        dropdownColor: const Color(0xFF2A2A2A),
        underline: const SizedBox.shrink(),
        items: rudiments
            .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _BpmLineChart extends ConsumerWidget {
  final String rudimentId;
  const _BpmLineChart({required this.rudimentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(bpmHistoryForRudimentProvider(rudimentId));

    return historyAsync.when(
      loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No sessions yet for this rudiment',
                style: TextStyle(color: Colors.white38)),
          );
        }
        final spots = sessions.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.achievedBpm.toDouble()))
            .toList();
        return Container(
          height: 140,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.deepOrange,
                barWidth: 2,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.deepOrange.withValues(alpha: 0.08),
                ),
              ),
            ],
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          )),
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  final dynamic session;
  final String rudimentName;
  const _SessionTile({required this.session, required this.rudimentName});

  @override
  Widget build(BuildContext context) {
    final emoji = switch (session.rating as int) {
      1 => '😓',
      2 => '😐',
      _ => '💪',
    };
    final dur = session.durationSeconds as int;
    final m = dur ~/ 60;
    final s = dur % 60;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      title: Text(rudimentName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(
        DateFormat('dd MMM yyyy').format(session.date as DateTime),
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$emoji  ${session.achievedBpm} BPM',
              style: const TextStyle(fontSize: 13)),
          Text('${m}m ${s}s',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥁', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text('No sessions yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Complete your first practice session\nto see stats here.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
