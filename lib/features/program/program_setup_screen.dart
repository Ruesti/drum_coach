import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../data/local/settings_service.dart';
import '../../shared/widgets/app_badge.dart';
import '../lessons/models/rudiment.dart';
import 'models/program_config.dart';
import 'program_provider.dart';

/// Setup screen for the adaptive training program: pick duration, start
/// difficulty, and exercise pool, then hand the choice to
/// [ProgramController.startWithConfig].
class ProgramSetupScreen extends ConsumerStatefulWidget {
  const ProgramSetupScreen({super.key});

  @override
  ConsumerState<ProgramSetupScreen> createState() =>
      _ProgramSetupScreenState();
}

class _ProgramSetupScreenState extends ConsumerState<ProgramSetupScreen> {
  static const _minWeeks = 1;
  static const _maxWeeks = 24;
  static const _difficultyOptions = [
    Difficulty.beginner,
    Difficulty.intermediate,
    Difficulty.advanced,
  ];

  late int _durationWeeks;
  late Difficulty _startDifficulty;
  late ProgramPool _pool;

  @override
  void initState() {
    super.initState();
    // Pre-fill from an existing config (re-visiting setup), else sane
    // defaults.
    final existing = SettingsService.programConfig;
    _durationWeeks =
        existing?.durationWeeks.clamp(_minWeeks, _maxWeeks) ?? 8;
    _startDifficulty = existing != null &&
            _difficultyOptions.contains(existing.startDifficulty)
        ? existing.startDifficulty
        : Difficulty.beginner;
    _pool = existing?.pool ?? ProgramPool.mixed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programm einrichten')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(
            title: 'Dauer',
            subtitle: 'Wie viele Wochen soll dein Programm laufen?',
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_durationWeeks', style: AppTypography.display),
              const SizedBox(width: AppSpacing.sm),
              Text('Wochen',
                  style: AppTypography.label.copyWith(color: AppColors.textMuted)),
            ],
          ),
          Slider(
            value: _durationWeeks.toDouble(),
            min: _minWeeks.toDouble(),
            max: _maxWeeks.toDouble(),
            divisions: _maxWeeks - _minWeeks,
            label: '$_durationWeeks Wochen',
            onChanged: (v) => setState(() => _durationWeeks = v.round()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_minWeeks',
                    style: AppTypography.label.copyWith(color: AppColors.textFaint)),
                Text('$_maxWeeks',
                    style: AppTypography.label.copyWith(color: AppColors.textFaint)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Startniveau',
            subtitle: 'Wo steigst du ein?',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in _difficultyOptions)
                AppSelectableChip(
                  label: d.label,
                  selected: _startDifficulty == d,
                  onTap: () => setState(() => _startDifficulty = d),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Übungspool',
            subtitle: 'Woraus soll dein Programm schöpfen?',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in ProgramPool.values)
                AppSelectableChip(
                  label: p.label,
                  selected: _pool == p,
                  onTap: () => setState(() => _pool = p),
                ),
            ],
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Programm starten'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size(double.infinity, 54),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _start() async {
    await ref.read(programControllerProvider.notifier).startWithConfig(
          ProgramConfig(
            durationWeeks: _durationWeeks,
            startDifficulty: _startDifficulty,
            pool: _pool,
          ),
        );
    if (!mounted) return;
    context.go('/program');
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
