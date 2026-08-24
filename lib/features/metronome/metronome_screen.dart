import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/beat_indicator.dart';
import 'metronome_engine.dart';
import 'metronome_provider.dart';

class MetronomeScreen extends ConsumerStatefulWidget {
  const MetronomeScreen({super.key});

  @override
  ConsumerState<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends ConsumerState<MetronomeScreen> {
  /// Captured in [initState] because `ref` is unsafe to read fresh inside
  /// [dispose] — by then the widget's Element may already be torn down.
  late final MetronomeNotifier _metronomeNotifier;

  @override
  void initState() {
    super.initState();
    _metronomeNotifier = ref.read(metronomeNotifierProvider.notifier);
  }

  @override
  void dispose() {
    // Deferred: Riverpod forbids modifying provider state synchronously
    // during a widget tree teardown (dispose runs mid-build/mid-unmount).
    Future.microtask(_metronomeNotifier.stop);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metronomeNotifierProvider);
    final notifier = ref.read(metronomeNotifierProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Metronome')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),
              BeatIndicator(
                diameter: 160,
                isPlaying: state.isPlaying,
                isAccent: state.isAccent,
                beatTrigger: state.currentBeatIndex,
                beatNumber: state.currentBeatIndex + 1,
              ),
              const SizedBox(height: 32),
              _BpmDisplay(bpm: state.bpm),
              const SizedBox(height: 16),
              _BpmSlider(
                bpm: state.bpm,
                onChanged: notifier.setBpm,
              ),
              const SizedBox(height: 32),
              _SubdivisionSelector(
                selected: state.subdivision,
                onSelected: notifier.setSubdivision,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              _SoundTypeToggle(
                selected: state.soundType,
                onSelected: notifier.setSoundType,
              ),
              const Spacer(),
              _TapTempoButton(onTap: notifier.tap),
              const SizedBox(height: 16),
              _StartStopButton(
                isPlaying: state.isPlaying,
                onTap: notifier.toggle,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BpmDisplay extends StatelessWidget {
  final int bpm;
  const _BpmDisplay({required this.bpm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$bpm', style: AppTypography.numericXl),
        Text(
          'BPM',
          style: AppTypography.label.copyWith(letterSpacing: 4),
        ),
      ],
    );
  }
}

class _BpmSlider extends StatelessWidget {
  final int bpm;
  final ValueChanged<int> onChanged;

  const _BpmSlider({required this.bpm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: bpm.toDouble(),
          min: 40,
          max: 240,
          divisions: 200,
          onChanged: (v) => onChanged(v.round()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('40', style: AppTypography.label.copyWith(color: AppColors.textFaint)),
              Text('240', style: AppTypography.label.copyWith(color: AppColors.textFaint)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubdivisionSelector extends StatelessWidget {
  final Subdivision selected;
  final ValueChanged<Subdivision> onSelected;
  final ColorScheme colorScheme;

  const _SubdivisionSelector({
    required this.selected,
    required this.onSelected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: Subdivision.values.map((s) {
        final isSelected = s == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onSelected(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.raised,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Column(
                children: [
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 18,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.name,
                    style: AppTypography.label.copyWith(
                      color: isSelected
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TapTempoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TapTempoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.touch_app_outlined),
        label: const Text('Tap Tempo'),
      ),
    );
  }
}

class _SoundTypeToggle extends StatelessWidget {
  final SoundType selected;
  final ValueChanged<SoundType> onSelected;

  const _SoundTypeToggle({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: SoundType.values.map((t) {
        final isSelected = t == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AppSelectableChip(
            label: t.label,
            selected: isSelected,
            onTap: () => onSelected(t),
          ),
        );
      }).toList(),
    );
  }
}

class _StartStopButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _StartStopButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
        label: Text(isPlaying ? 'Stop' : 'Start'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPlaying ? AppColors.struggled : AppColors.accent,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }
}
