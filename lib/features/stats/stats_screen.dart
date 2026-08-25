import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/error_state.dart';
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
    final bestAsync = ref.watch(longestStreakProvider);
    final todayAsync = ref.watch(todayStatusProvider);
    final calendarAsync = ref.watch(practiceCalendarProvider());
    final sessionsAsync = ref.watch(allSessionsProvider);
    final rudiments = ref.watch(rudimentsProvider);

    _selectedRudimentId ??= rudiments.firstOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ErrorStateWidget(
            message: 'Error: $e',
            onRetry: () => ref.invalidate(allSessionsProvider),
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const _EmptyStats();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Streak
              _StreakCard(
                current: streakAsync.valueOrNull ?? 0,
                best: bestAsync.valueOrNull ?? 0,
                today: todayAsync.valueOrNull,
              ),
              const SizedBox(height: 16),
              // Calendar heatmap
              _SectionLabel('PRACTICE CALENDAR'),
              const SizedBox(height: 8),
              calendarAsync.when(
                loading: () => const SizedBox(height: 96),
                error: (e, _) => ErrorStateWidget(
                  message: 'Error: $e',
                  compact: true,
                  onRetry: () => ref.invalidate(practiceCalendarProvider()),
                ),
                data: (days) => _CalendarHeatmap(days: days),
              ),
              const SizedBox(height: 20),
              // Bar chart
              _SectionLabel('DAILY PRACTICE (last 14 days)'),
              const SizedBox(height: 8),
              dailyAsync.when(
                loading: () => const SizedBox(
                    height: 160, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => ErrorStateWidget(
                  message: 'Error: $e',
                  compact: true,
                  onRetry: () => ref.invalidate(last14DaysMinutesProvider),
                ),
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
                    .where((r) => r.id == s.exerciseId)
                    .firstOrNull
                    ?.name ?? s.exerciseId;
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
  final int current;
  final int best;
  final TodayStatus? today;
  const _StreakCard({required this.current, required this.best, this.today});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$current day streak',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Best: $best ${best == 1 ? "day" : "days"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          if (today != null) _TodayBadge(status: today!),
        ],
      ),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  final TodayStatus status;
  const _TodayBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final done = status.goalMet;
    final practiced = status.practiced;
    final color = done
        ? AppColors.solidStreak
        : practiced
            ? AppColors.ok
            : AppColors.textFaint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color, size: 24),
        const SizedBox(height: 4),
        Text('Heute', style: TextStyle(color: color, fontSize: 11)),
        Text('${status.minutes}/${status.goalMinutes}m',
            style: const TextStyle(color: AppColors.textFaint, fontSize: 10)),
      ],
    );
  }
}

class _CalendarHeatmap extends StatelessWidget {
  final List<DailyMinutes> days;
  const _CalendarHeatmap({required this.days});

  static const _cell = 13.0;
  static const _gap = 3.0;

  Color _colorFor(int minutes) {
    if (minutes <= 0) return AppColors.textPrimary.withValues(alpha: 0.06);
    if (minutes < 10) return AppColors.accent.withValues(alpha: 0.30);
    if (minutes < 20) return AppColors.accent.withValues(alpha: 0.55);
    if (minutes < 40) return AppColors.accent.withValues(alpha: 0.80);
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    // Pad with leading blanks so each column is a Mon→Sun week.
    final leading = days.first.date.weekday - 1; // Mon=1 → 0 blanks
    final cells = <DailyMinutes?>[
      ...List.filled(leading, null),
      ...days,
    ];
    final weeks = (cells.length / 7).ceil();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(weeks, (w) {
            return Padding(
              padding: const EdgeInsets.only(right: _gap),
              child: Column(
                children: List.generate(7, (d) {
                  final idx = w * 7 + d;
                  final cell = idx < cells.length ? cells[idx] : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: _gap),
                    child: Container(
                      width: _cell,
                      height: _cell,
                      decoration: BoxDecoration(
                        color: cell == null
                            ? Colors.transparent
                            : _colorFor(cell.minutes),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.accent,
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
    return SizedBox(
      height: 160,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
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
                    color: isToday ? AppColors.accent : AppColors.textFaint,
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
                      style: const TextStyle(color: AppColors.textFaint, fontSize: 10),
                    );
                  },
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: DropdownButton<String>(
        value: selected,
        isExpanded: true,
        dropdownColor: AppColors.raised,
        underline: const SizedBox.shrink(),
        items: rudiments
            .map((r) => DropdownMenuItem(
                  value: r.$1,
                  child: Text(
                    r.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
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
      error: (e, _) => ErrorStateWidget(
        message: 'Error: $e',
        compact: true,
        onRetry: () => ref.invalidate(bpmHistoryForRudimentProvider(rudimentId)),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return SizedBox(
            height: 80,
            child: AppCard(
              child: Center(
                child: Text('No sessions yet for this rudiment',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textFaint)),
              ),
            ),
          );
        }
        final spots = sessions.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.achievedBpm.toDouble()))
            .toList();
        return SizedBox(
          height: 140,
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: LineChart(LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.accent,
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.accent.withValues(alpha: 0.08),
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
                        style: const TextStyle(color: AppColors.textFaint, fontSize: 10)),
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            )),
          ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(
        DateFormat('dd MMM yyyy').format(session.date as DateTime),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textFaint, fontSize: 12),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$emoji  ${session.achievedBpm} BPM',
              style: const TextStyle(fontSize: 13)),
          Text('${m}m ${s}s',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
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
                style: TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
