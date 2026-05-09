import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'metronome_engine.dart';
import 'metronome_provider.dart';

class MetronomeScreen extends ConsumerStatefulWidget {
  const MetronomeScreen({super.key});

  @override
  ConsumerState<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends ConsumerState<MetronomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.45)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.45, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_pulseController);
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.5),
        weight: 70,
      ),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metronomeNotifierProvider);
    final notifier = ref.read(metronomeNotifierProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<MetronomeState>(metronomeNotifierProvider, (prev, next) {
      if (next.currentBeatIndex != (prev?.currentBeatIndex ?? -1) &&
          next.currentBeatIndex >= 0) {
        _pulseController.forward(from: 0);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Metronome')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),
              _BeatIndicator(
                scaleAnim: _scaleAnim,
                opacityAnim: _opacityAnim,
                isAccent: state.isAccent,
                isPlaying: state.isPlaying,
                colorScheme: colorScheme,
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

class _BeatIndicator extends StatelessWidget {
  final Animation<double> scaleAnim;
  final Animation<double> opacityAnim;
  final bool isAccent;
  final bool isPlaying;
  final ColorScheme colorScheme;

  const _BeatIndicator({
    required this.scaleAnim,
    required this.opacityAnim,
    required this.isAccent,
    required this.isPlaying,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor =
        isAccent ? Colors.deepOrange : colorScheme.onSurface.withValues(alpha: 0.7);
    final idleColor = colorScheme.onSurface.withValues(alpha: 0.15);

    return AnimatedBuilder(
      animation: scaleAnim,
      builder: (_, __) => Transform.scale(
        scale: isPlaying ? scaleAnim.value : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPlaying ? baseColor : idleColor,
            boxShadow: isPlaying && isAccent
                ? [
                    BoxShadow(
                      color: Colors.deepOrange.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    )
                  ]
                : null,
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
        Text(
          '$bpm',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 96,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
        ),
        Text(
          'BPM',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white54,
                letterSpacing: 4,
              ),
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
              Text('40', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white38)),
              Text('240', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white38)),
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
                color: isSelected
                    ? Colors.deepOrange
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 18,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : Colors.white38,
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
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white24),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
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
          backgroundColor: isPlaying ? Colors.red.shade700 : Colors.deepOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
