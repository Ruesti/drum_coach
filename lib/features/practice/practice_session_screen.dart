import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/sticking_pattern_widget.dart';
import '../lessons/lessons_provider.dart';
import '../metronome/metronome_provider.dart';
import 'practice_provider.dart';

class PracticeSessionScreen extends ConsumerStatefulWidget {
  final String rudimentId;
  final bool isFromRoutine;

  const PracticeSessionScreen({
    super.key,
    required this.rudimentId,
    required this.isFromRoutine,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState
    extends ConsumerState<PracticeSessionScreen> {
  int _elapsedSeconds = 0;
  Timer? _ticker;
  bool _sessionFinished = false;

  @override
  void dispose() {
    _ticker?.cancel();
    // Stop metronome when leaving screen
    ref.read(metronomeNotifierProvider.notifier).stop();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  String get _timerLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _showRatingSheet() async {
    final metronome = ref.read(metronomeNotifierProvider.notifier);
    metronome.stop();
    _stopTicker();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RatingSheet(
        onRating: _saveAndPop,
      ),
    );
  }

  Future<void> _saveAndPop(int rating) async {
    if (_sessionFinished) return;
    _sessionFinished = true;

    final rudiment =
        ref.read(rudimentByIdProvider(widget.rudimentId));
    final metState = ref.read(metronomeNotifierProvider);

    await ref.read(practiceNotifierProvider.notifier).saveSession(
          rudimentId: widget.rudimentId,
          durationSeconds: _elapsedSeconds,
          achievedBpm: metState.bpm,
          rating: rating,
          targetBpm: rudiment.targetBpm,
        );

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final rudiment = ref.watch(rudimentByIdProvider(widget.rudimentId));
    final metState = ref.watch(metronomeNotifierProvider);
    final notifier = ref.read(metronomeNotifierProvider.notifier);

    // Sync ticker with metronome play state
    ref.listen<MetronomeState>(metronomeNotifierProvider, (prev, next) {
      if (next.isPlaying && !(prev?.isPlaying ?? false)) {
        _startTicker();
      } else if (!next.isPlaying && (prev?.isPlaying ?? false)) {
        _stopTicker();
      }
    });

    final activeBeat = metState.isPlaying
        ? metState.currentBeatIndex % rudiment.sticking.length
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(rudiment.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _timerLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Live sticking pattern
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StickingPatternWidget(
                  pattern: rudiment.sticking,
                  activeBeatIndex: activeBeat,
                  beatBoxSize: 44,
                ),
              ),
              const SizedBox(height: 28),
              // Compact BPM control
              _CompactMetronome(
                bpm: metState.bpm,
                isPlaying: metState.isPlaying,
                onBpmChanged: notifier.setBpm,
                onToggle: notifier.toggle,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showRatingSheet,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Finish Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactMetronome extends StatelessWidget {
  final int bpm;
  final bool isPlaying;
  final ValueChanged<int> onBpmChanged;
  final VoidCallback onToggle;

  const _CompactMetronome({
    required this.bpm,
    required this.isPlaying,
    required this.onBpmChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPlaying ? Colors.red.shade700 : Colors.deepOrange,
              ),
              child: Icon(
                isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$bpm',
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Text('BPM',
              style: TextStyle(fontSize: 12, color: Colors.white38)),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: bpm.toDouble(),
              min: 40,
              max: 240,
              divisions: 200,
              onChanged: (v) => onBpmChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSheet extends StatelessWidget {
  final void Function(int rating) onRating;
  const _RatingSheet({required this.onRating});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'How did it feel?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _RatingButton(
            emoji: '😓',
            label: 'Struggled',
            subtitle: 'Keep the same BPM',
            color: Colors.red.shade400,
            onTap: () { Navigator.pop(context); onRating(1); },
          ),
          const SizedBox(height: 10),
          _RatingButton(
            emoji: '😐',
            label: 'OK',
            subtitle: '+2 BPM next time',
            color: Colors.amber,
            onTap: () { Navigator.pop(context); onRating(2); },
          ),
          const SizedBox(height: 10),
          _RatingButton(
            emoji: '💪',
            label: 'Solid',
            subtitle: '+5 BPM next time',
            color: Colors.green.shade400,
            onTap: () { Navigator.pop(context); onRating(3); },
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white54)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
