import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/settings_service.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(program.name)),
      body: dayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (day) {
          final configured = SettingsService.programConfig != null;
          if (!configured) {
            return _NotStarted(
              program: program,
              onSetup: () => context.push('/program/setup'),
            );
          }
          if (day == null) {
            return _Finished(
              onReset: () =>
                  ref.read(programControllerProvider.notifier).reset(),
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
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(program.description,
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 20),
        for (final phase in program.phases) ...[
          _PhaseOverviewCard(phase: phase),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onSetup,
          icon: const Icon(Icons.settings),
          label: const Text('Programm einrichten'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phase ${phase.index} · ${phase.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text('Woche ${phase.weekStart}–${phase.weekEnd} · ab ${phase.startBpm} BPM',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          Text(phase.focus,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Finished extends StatelessWidget {
  final VoidCallback onReset;
  const _Finished({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('Programm abgeschlossen',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Zwölf Wochen durch. Neue saubere Bestwerte in der Hand.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.replay),
              label: const Text('Neu starten'),
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

class _DayView extends StatelessWidget {
  final ProgramDay day;
  const _DayView({required this.day});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DayHeader(day: day),
        const SizedBox(height: 16),
        if (day.type == DayType.rest)
          const _RestDay()
        else
          for (final block in day.blocks) ...[
            _BlockCard(block: block),
            const SizedBox(height: 10),
          ],
      ],
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
          PacingStatus.ahead => 'voraus',
          PacingStatus.onTrack => 'im Plan',
          PacingStatus.behind => 'hinterher',
        };
        pacingLabel = 'Woche ${pacing.nominalWeek}/${config.durationWeeks} · '
            'Stufe: ${stages[stageIndex].label} · $statusLabel';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tag ${day.dayNumber}/$totalDays · ~${day.estimatedMinutes} min',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (pacingLabel != null) ...[
            const SizedBox(height: 2),
            Text(pacingLabel,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
          const SizedBox(height: 4),
          Text('Phase ${phase.index}: ${phase.name}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(phase.focus,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (phase.focusCue != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(phase.focusCue!,
                      style: const TextStyle(
                          color: Colors.white38,
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
          Text('Ruhetag',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Frei. Kein Block heute — der Ruhetag zählt nicht gegen deinen '
              'Streak. Erholung ist Teil des Plans.',
              style: TextStyle(color: Colors.white54),
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
  const _BlockCard({required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rudiment = ref.watch(rudimentByIdProvider(block.exerciseKey));
    final variants =
        block.variants.map(_variantLabel).join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
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
                        _BlockBadge(type: block.type),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(rudiment.name,
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
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final bpm = block.startBpm;
                  final q = bpm != null ? '?bpm=$bpm' : '';
                  context.push('/practice/${block.exerciseKey}$q');
                },
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
          // Tempo-ladder gate: self-rated clean pass lifts the stored tempo +4.
          if (block.cleanPassRequired) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _askCleanPass(context, ref),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Sauber & locker durchgelaufen?'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
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
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Sauber & locker?'),
        content: Text(
          'Lief die Tempo-Leiter gleichmäßig und locker durch? '
          'Ja hebt dein sauberes Tempo um +4 BPM auf '
          '${(block.startBpm ?? 0) + 4}.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nein'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ja'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(cleanTempoNotifierProvider.notifier)
          .recordCleanPass(block.exerciseKey, block.startBpm ?? 0);
      if (!context.mounted) return;
      final advanced =
          await ref.read(programControllerProvider.notifier).advanceStageIfReady();
      if (advanced && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Level up! Neue Stufe erreicht.')),
        );
      }
    }
  }
}

class _BlockBadge extends StatelessWidget {
  final BlockType type;
  const _BlockBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      BlockType.warmup => ('Warmup', Colors.green.shade400),
      BlockType.technique => ('Technik', Colors.blue.shade300),
      BlockType.tempoLadder => ('Tempo-Leiter', Colors.deepOrange),
      BlockType.endurance => ('Ausdauer', Colors.amber),
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

String _variantLabel(Variant v) => switch (v) {
      Variant.even => 'gleichmäßig',
      Variant.pp => 'pp (leise)',
      Variant.ff => 'ff (laut)',
      Variant.crescendo => 'Crescendo',
      Variant.fingers => 'Finger',
      Variant.rebound => 'Rebound',
      Variant.accentTap => 'Akzent/Tap',
      Variant.endurance => 'Ausdauer',
    };
