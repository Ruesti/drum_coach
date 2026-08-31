import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/design_tokens.dart';
import '../../data/local/settings_service.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/beat_indicator.dart';
import '../../shared/widgets/bpm_control.dart';
import '../../shared/widgets/notation_staff_widget.dart';
import '../coaching/models/session_analysis.dart';
import '../coaching/services/ai_coaching_service.dart';
import '../coaching/services/mic_analysis_service.dart';
import '../coaching/widgets/coach_feedback_card.dart';
import '../lessons/lesson_detail_screen.dart';
import '../lessons/lessons_provider.dart';
import '../lessons/models/pattern_playback.dart';
import '../metronome/metronome_engine.dart';
import '../metronome/metronome_provider.dart';
import 'practice_provider.dart';
import 'session_timer_provider.dart';

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class PracticeSessionScreen extends ConsumerStatefulWidget {
  final String rudimentId;
  final bool isFromRoutine;

  /// Optional target tempo to preset the metronome to (e.g. a program's tempo
  /// ladder start). Null keeps the metronome's current BPM.
  final int? targetBpm;

  const PracticeSessionScreen({
    super.key,
    required this.rudimentId,
    required this.isFromRoutine,
    this.targetBpm,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState
    extends ConsumerState<PracticeSessionScreen> {
  int _elapsedSeconds = 0;
  int? _goalSeconds;
  Timer? _ticker;
  bool _sessionFinished = false;

  // Beat log for mic correlation: recorded in build via ref.listen
  final List<BeatRecord> _beatLog = [];

  // Mic analysis
  MicAnalysisService? _micService;
  bool _micRecording = false;

  final _aiService = AICoachingService();

  /// Captured in [initState] because `ref` is unsafe to read fresh inside
  /// [dispose] — by then the widget's Element may already be torn down.
  late final MetronomeNotifier _metronomeNotifier;

  /// Fine-grid (24 ticks/quarter) expansion of the exercise, used to drive the
  /// metronome's per-tick volumes and map the playback cursor to a note.
  late PatternPlayback _playback;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    ref.read(sessionTimerNotifierProvider.notifier).startIfNeeded();
    _metronomeNotifier = ref.read(metronomeNotifierProvider.notifier);
    _playback = PatternPlayback.forRudiment(
        ref.read(rudimentByIdProvider(widget.rudimentId)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final metronome = _metronomeNotifier
        ..setPatternClock(_playback.ticksPerQuarter)
        ..setPatternVolumes(_playback.tickVolumes);
      if (widget.targetBpm != null) {
        metronome.setBpm(widget.targetBpm!);
      }
      _initMicIfEnabled();
    });
  }

  Future<void> _initMicIfEnabled() async {
    if (!SettingsService.micAnalysisEnabled) return;
    final status = await Permission.microphone.request();
    if (status.isGranted && mounted) {
      _micService = MicAnalysisService();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _ticker?.cancel();
    // Deferred: Riverpod forbids modifying provider state synchronously
    // during a widget tree teardown (dispose runs mid-build/mid-unmount).
    Future.microtask(() {
      _metronomeNotifier
        ..stop()
        ..setPatternVolumes(null)
        ..setSubdivision(Subdivision.quarter);
    });
    _micService?.stopRecording();
    _micService?.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_goalSeconds != null && _elapsedSeconds >= _goalSeconds!) {
        _showRatingSheet();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _startMicRecording() async {
    if (_micService == null || _micRecording) return;
    try {
      await _micService!.startRecording();
      if (mounted) setState(() => _micRecording = true);
    } catch (_) {}
  }

  Future<void> _stopMicRecording() async {
    if (!_micRecording) return;
    try {
      await _micService!.stopRecording();
      _micRecording = false;
    } catch (_) {}
  }

  String get _timerLabel {
    final remaining = _goalSeconds != null
        ? (_goalSeconds! - _elapsedSeconds).clamp(0, _goalSeconds!)
        : null;
    return _formatDuration(remaining ?? _elapsedSeconds);
  }

  Future<void> _showRatingSheet() async {
    if (_sessionFinished) return;
    final metronome = ref.read(metronomeNotifierProvider.notifier);
    metronome.stop();
    _stopTicker();
    await _stopMicRecording();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => _RatingSheet(onRating: _saveAndShowFeedback),
    );
  }

  Future<void> _saveAndShowFeedback(int rating) async {
    if (_sessionFinished) return;
    _sessionFinished = true;

    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final metState = ref.read(metronomeNotifierProvider);

    await ref.read(practiceNotifierProvider.notifier).saveSession(
          rudimentId: widget.rudimentId,
          durationSeconds: _elapsedSeconds,
          achievedBpm: metState.bpm,
          rating: rating,
          targetBpm: rudiment.targetBpm,
        );

    // Analyse mic data if available
    SessionAnalysis? analysis;
    if (_micService != null && _beatLog.isNotEmpty) {
      analysis = _micService!.analyze(
        beatLog: _beatLog,
        sticking: rudiment.sticking,
        bpm: metState.bpm,
      );
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => _FeedbackSheet(
        rudimentName: rudiment.name,
        achievedBpm: metState.bpm,
        targetBpm: rudiment.targetBpm,
        durationSeconds: _elapsedSeconds,
        rating: rating,
        analysis: analysis,
        aiService: _aiService,
        onClose: () => Navigator.pop(context),
      ),
    );

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final rudiment = ref.watch(rudimentByIdProvider(widget.rudimentId));
    final metState = ref.watch(metronomeNotifierProvider);
    final notifier = ref.read(metronomeNotifierProvider.notifier);
    final sessionSeconds = ref.watch(sessionTimerNotifierProvider);

    ref.listen<MetronomeState>(metronomeNotifierProvider, (prev, next) {
      // Record beat timestamps for mic correlation
      if (_micRecording &&
          next.isPlaying &&
          next.currentBeatIndex >= 0 &&
          next.currentBeatIndex != (prev?.currentBeatIndex ?? -2)) {
        _beatLog.add((
          beatIndex: next.currentBeatIndex,
          timestamp: DateTime.now(),
        ));
      }

      // Start/stop ticker and mic with metronome
      if (next.isPlaying && !(prev?.isPlaying ?? false)) {
        _startTicker();
        _startMicRecording();
      } else if (!next.isPlaying && (prev?.isPlaying ?? false)) {
        _stopTicker();
      }
    });

    final activeBeat = metState.isPlaying && metState.currentBeatIndex >= 0
        ? _playback.noteIndexAtTick(
            metState.currentBeatIndex % _playback.totalTicks)
        : null;

    final isCountdown = _goalSeconds != null;
    final timerColor = isCountdown && (_goalSeconds! - _elapsedSeconds) <= 30
        ? AppColors.accent
        : AppColors.textPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Text(rudiment.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Erklärung anzeigen',
            // A plain Navigator push, not context.push('/lessons/...') — this
            // screen lives on the top-level /practice route (outside the
            // bottom-nav shell, see router.dart), and pushing a shell-branch
            // route from there previously caused a duplicate-page-key crash.
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LessonDetailScreen(rudimentId: widget.rudimentId),
            )),
          ),
          if (SettingsService.micAnalysisEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                _micRecording ? Icons.mic : Icons.mic_off,
                size: 18,
                color: _micRecording ? AppColors.accent : AppColors.textFaint,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCountdown)
                        const Icon(Icons.timer_outlined,
                            size: 16, color: AppColors.textMuted),
                      if (isCountdown) const SizedBox(width: 4),
                      Text(
                        _timerLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: timerColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Session ${_formatDuration(sessionSeconds)}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textFaint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: NotationStaffWidget(
                    rudiment: rudiment,
                    activeIndex: activeBeat,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _CompactMetronome(
                bpm: metState.bpm,
                isPlaying: metState.isPlaying,
                isAccent: metState.isAccent,
                currentBeatIndex: metState.currentBeatIndex,
                soundType: metState.soundType,
                onBpmChanged: notifier.setBpm,
                onToggle: notifier.toggle,
                onSoundTypeChanged: notifier.setSoundType,
              ),
              const SizedBox(height: 10),
              if (!metState.isPlaying && _elapsedSeconds == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TimerGoalRow(
                    selected: _goalSeconds,
                    onSelected: (s) => setState(() => _goalSeconds = s),
                  ),
                ),
              const SizedBox(height: 4),
              ElevatedButton.icon(
                onPressed: _showRatingSheet,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Finish Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timer goal row ─────────────────────────────────────────────────────────────

class _TimerGoalRow extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onSelected;

  const _TimerGoalRow({required this.selected, required this.onSelected});

  static const _options = [
    (label: '5 min', seconds: 5 * 60),
    (label: '10 min', seconds: 10 * 60),
    (label: '15 min', seconds: 15 * 60),
    (label: '∞', seconds: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _options.map((opt) {
        final sec = opt.seconds == 0 ? null : opt.seconds;
        final isSelected = selected == sec;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AppSelectableChip(
            label: opt.label,
            selected: isSelected,
            onTap: () => onSelected(sec),
          ),
        );
      }).toList(),
    );
  }
}

// ── Compact metronome ──────────────────────────────────────────────────────────

class _CompactMetronome extends StatelessWidget {
  final int bpm;
  final bool isPlaying;
  final bool isAccent;
  final int currentBeatIndex;
  final SoundType soundType;
  final ValueChanged<int> onBpmChanged;
  final VoidCallback onToggle;
  final ValueChanged<SoundType> onSoundTypeChanged;

  const _CompactMetronome({
    required this.bpm,
    required this.isPlaying,
    required this.isAccent,
    required this.currentBeatIndex,
    required this.soundType,
    required this.onBpmChanged,
    required this.onToggle,
    required this.onSoundTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.raised,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Row(
            children: [
              BeatIndicator(
                diameter: 64,
                isPlaying: isPlaying,
                isAccent: isAccent,
                beatTrigger: currentBeatIndex,
                onTap: onToggle,
                child: Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: AppColors.textPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final value = await editBpmDialog(context, current: bpm);
                    if (value != null) onBpmChanged(value);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$bpm', style: AppTypography.display),
                      const SizedBox(width: 4),
                      Text('BPM',
                          style: AppTypography.label
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              BpmStepButtons(
                bpm: bpm,
                onChanged: onBpmChanged,
                alignment: MainAxisAlignment.start,
              ),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: SoundType.values.map((t) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppSelectableChip(
                  label: t.label,
                  selected: t == soundType,
                  onTap: () => onSoundTypeChanged(t),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Rating sheet ───────────────────────────────────────────────────────────────

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
              color: AppColors.textFaint,
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
            color: AppColors.struggled,
            onTap: () {
              Navigator.pop(context);
              onRating(1);
            },
          ),
          const SizedBox(height: 10),
          _RatingButton(
            emoji: '😐',
            label: 'OK',
            subtitle: '+2 BPM next time',
            color: AppColors.ok,
            onTap: () {
              Navigator.pop(context);
              onRating(2);
            },
          ),
          const SizedBox(height: 10),
          _RatingButton(
            emoji: '💪',
            label: 'Solid',
            subtitle: '+5 BPM next time',
            color: AppColors.solidStreak,
            onTap: () {
              Navigator.pop(context);
              onRating(3);
            },
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
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feedback sheet ─────────────────────────────────────────────────────────────

class _FeedbackSheet extends StatefulWidget {
  final String rudimentName;
  final int achievedBpm;
  final int targetBpm;
  final int durationSeconds;
  final int rating;
  final SessionAnalysis? analysis;
  final AICoachingService aiService;
  final VoidCallback onClose;

  const _FeedbackSheet({
    required this.rudimentName,
    required this.achievedBpm,
    required this.targetBpm,
    required this.durationSeconds,
    required this.rating,
    required this.analysis,
    required this.aiService,
    required this.onClose,
  });

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  String? _feedback;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final apiKey = SettingsService.claudeApiKey;
    if (apiKey.isNotEmpty) _fetchFeedback(apiKey);
  }

  Future<void> _fetchFeedback(String apiKey) async {
    setState(() => _loading = true);
    final result = await widget.aiService.getCoachingFeedback(
      apiKey: apiKey,
      rudimentName: widget.rudimentName,
      achievedBpm: widget.achievedBpm,
      targetBpm: widget.targetBpm,
      durationSeconds: widget.durationSeconds,
      rating: widget.rating,
      analysis: widget.analysis,
    );
    if (mounted) {
      setState(() {
        _feedback = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMicData = widget.analysis?.hasData ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textFaint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Session complete',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '${widget.achievedBpm} BPM  ·  '
            '${widget.durationSeconds ~/ 60}min ${widget.durationSeconds % 60}s',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          if (hasMicData && widget.analysis?.timing != null) ...[
            const SizedBox(height: 16),
            _AnalysisSummary(analysis: widget.analysis!),
          ],
          CoachFeedbackCard(
            feedback: _feedback,
            isLoading: _loading,
            hasAnalysis: hasMicData,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onClose,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisSummary extends StatelessWidget {
  final SessionAnalysis analysis;
  const _AnalysisSummary({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final t = analysis.timing!;
    final d = analysis.dynamics;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.raised,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mic Analysis',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          _Row(
            label: 'Overall timing',
            value:
                '${t.overallDeviationMs > 0 ? '+' : ''}${t.overallDeviationMs.toStringAsFixed(1)} ms '
                '(${t.overallDeviationMs > 0 ? 'late' : 'early'})',
          ),
          _Row(
            label: 'R hand',
            value:
                '${t.rightHandDeviationMs > 0 ? '+' : ''}${t.rightHandDeviationMs.toStringAsFixed(1)} ms',
          ),
          _Row(
            label: 'L hand',
            value:
                '${t.leftHandDeviationMs > 0 ? '+' : ''}${t.leftHandDeviationMs.toStringAsFixed(1)} ms',
          ),
          _Row(
            label: 'Consistency',
            value: '±${t.jitterMs.toStringAsFixed(1)} ms jitter',
          ),
          if (d != null)
            _Row(
              label: 'Dynamics R / L',
              value:
                  '${(d.rightHandLevel * 100).round()}% / ${(d.leftHandLevel * 100).round()}%',
            ),
          _Row(
            label: 'Hits detected',
            value:
                '${analysis.detectedHits} / ${analysis.expectedHits} expected',
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
