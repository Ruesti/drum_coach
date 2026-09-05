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
import '../program/program_provider.dart';
import 'ladder_plan.dart';
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
  /// ladder gate). Null presets the exercise's own suggested tempo instead.
  final int? targetBpm;

  /// Suggested session length (e.g. a program block's duration). Presets the
  /// countdown; the user can still pick another length before starting.
  final int? targetMinutes;

  /// True when launched as a program tempo-ladder block: the session climbs
  /// through [buildLadderPlan]'s steps and ends with the clean-pass question.
  final bool isLadder;

  const PracticeSessionScreen({
    super.key,
    required this.rudimentId,
    required this.isFromRoutine,
    this.targetBpm,
    this.targetMinutes,
    this.isLadder = false,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState
    extends ConsumerState<PracticeSessionScreen> with WidgetsBindingObserver {
  int _elapsedSeconds = 0;
  int? _goalSeconds;
  Timer? _ticker;
  bool _sessionFinished = false;

  // Tempo ladder (program block): plan + current step.
  LadderPlan? _ladderPlan;
  int _ladderStepIndex = 0;

  bool get _ladderActive => widget.isLadder && widget.targetBpm != null;

  // Beat log for mic correlation: recorded in build via ref.listen
  final List<BeatRecord> _beatLog = [];

  // Mic analysis
  MicAnalysisService? _micService;
  bool _micRecording = false;

  final _aiService = AICoachingService();

  /// Captured in [initState] because `ref` is unsafe to read fresh inside
  /// [dispose] — by then the widget's Element may already be torn down.
  late final MetronomeNotifier _metronomeNotifier;
  late final SessionTimerNotifier _sessionTimerNotifier;

  /// Fine-grid (24 ticks/quarter) expansion of the exercise, used to drive the
  /// metronome's per-tick volumes and map the playback cursor to a note.
  late PatternPlayback _playback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _metronomeNotifier = ref.read(metronomeNotifierProvider.notifier);
    _sessionTimerNotifier = ref.read(sessionTimerNotifierProvider.notifier);
    _playback = PatternPlayback.forRudiment(
        ref.read(rudimentByIdProvider(widget.rudimentId)));

    if (widget.targetMinutes != null) {
      _goalSeconds = widget.targetMinutes! * 60;
    }
    if (_ladderActive) {
      _ladderPlan = buildLadderPlan(
          startBpm: widget.targetBpm!, totalSeconds: _goalSeconds ?? 240);
    }

    // Restore a session interrupted by the app going to background (e.g. a
    // phone call killed the process mid-practice).
    final snap = SettingsService.practiceSnapshotFor(widget.rudimentId);
    if (snap != null) {
      _elapsedSeconds = snap.elapsedSeconds;
      _goalSeconds = snap.goalSeconds ?? _goalSeconds;
      SettingsService.clearPracticeSnapshot();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final metronome = _metronomeNotifier
        ..setPatternClock(_playback.ticksPerQuarter)
        ..setPatternVolumes(_playback.tickVolumes);
      if (_ladderActive) {
        metronome.setBpm(_ladderPlan!.bpmAt(_elapsedSeconds));
      } else if (widget.targetBpm != null) {
        metronome.setBpm(widget.targetBpm!);
      } else {
        _presetExerciseBpm();
      }
      _initMicIfEnabled();
      if (snap != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Unterbrochene Session fortgesetzt (${_formatDuration(snap.elapsedSeconds)})'),
        ));
      }
    });
  }

  /// Presets the metronome to this exercise's own suggested tempo (its BPM
  /// progression, else its minimum) so tempo from a previously played
  /// exercise never leaks over. Skipped once the user is already playing.
  Future<void> _presetExerciseBpm() async {
    final stored =
        await ref.read(exerciseStartBpmProvider(widget.rudimentId).future);
    if (!mounted || _sessionFinished) return;
    final met = ref.read(metronomeNotifierProvider);
    if (met.isPlaying || _elapsedSeconds > 0) return;
    final minBpm = ref.read(rudimentByIdProvider(widget.rudimentId)).minBpm;
    _metronomeNotifier.setBpm(stored ?? minBpm);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save as soon as the app loses focus (a phone call passes through
    // `inactive` before `paused`, and the process can be killed any time
    // after) — the snapshot is cleared again on normal completion.
    if (state != AppLifecycleState.resumed &&
        _elapsedSeconds > 0 &&
        !_sessionFinished) {
      SettingsService.savePracticeSnapshot(
        rudimentId: widget.rudimentId,
        elapsedSeconds: _elapsedSeconds,
        goalSeconds: _goalSeconds,
      );
    }
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
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _ticker?.cancel();
    // Leaving the screen while playing (e.g. backing out mid-exercise) never
    // fires the ref.listen isPlaying transition below — that listener is
    // gone the moment this widget is disposed — so the session timer would
    // otherwise keep ticking forever with nothing left to pause it.
    _sessionTimerNotifier.pause();
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
    if (_ladderActive) {
      // Rebuild against the actually chosen session length and (re)apply the
      // step tempo — covers both a changed goal chip and a restored session.
      _ladderPlan = buildLadderPlan(
          startBpm: widget.targetBpm!,
          totalSeconds: _goalSeconds ?? widget.targetMinutes ?? 240);
      _ladderStepIndex = _ladderPlan!.stepIndexAt(_elapsedSeconds);
      _metronomeNotifier.setBpm(_ladderPlan!.bpms[_ladderStepIndex]);
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      final plan = _ladderPlan;
      if (plan != null) {
        final step = plan.stepIndexAt(_elapsedSeconds);
        if (step != _ladderStepIndex) {
          _ladderStepIndex = step;
          _metronomeNotifier.setBpm(plan.bpms[step]);
        }
      }
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
    await SettingsService.clearPracticeSnapshot();

    String? ladderResult;
    if (_ladderActive && mounted) ladderResult = await _askCleanPass();

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
        ladderResult: ladderResult,
        aiService: _aiService,
        onClose: () => Navigator.pop(context),
      ),
    );

    if (mounted) context.pop();
  }

  /// §6 gate, asked right after a ladder session: a clean pass lifts the
  /// stored clean tempo to gate + 4 and may unlock the next stage. Returns
  /// the result line for the feedback sheet (null when dismissed).
  Future<String?> _askCleanPass() async {
    final gate = widget.targetBpm!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sauber & locker?'),
        content: Text(
          'Lief die Tempo-Leiter bis ${gate + 4} BPM gleichmäßig und locker '
          'durch? Ja macht ${gate + 4} BPM zu deinem neuen sauberen Tempo.',
          style: const TextStyle(color: AppColors.textSecondary),
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
    if (ok == null) return null;
    if (!ok) return 'Sauberes Tempo bleibt bei $gate BPM — morgen wieder.';
    await ref
        .read(cleanTempoNotifierProvider.notifier)
        .recordCleanPass(widget.rudimentId, gate);
    final advanced =
        await ref.read(programControllerProvider.notifier).advanceStageIfReady();
    return advanced
        ? 'Sauberes Tempo jetzt ${gate + 4} BPM · Level up: neue Stufe!'
        : 'Sauberes Tempo jetzt ${gate + 4} BPM.';
  }

  @override
  Widget build(BuildContext context) {
    final rudiment = ref.watch(rudimentByIdProvider(widget.rudimentId));
    final metState = ref.watch(metronomeNotifierProvider);
    final notifier = ref.read(metronomeNotifierProvider.notifier);
    final sessionSeconds = ref.watch(sessionTimerNotifierProvider);

    ref.listen<MetronomeState>(metronomeNotifierProvider, (prev, next) {
      // Record beat timestamps for mic correlation — only pattern ticks that
      // carry a note onset (silent grid ticks are not expected strokes), and
      // logged as note index so the sticking pattern maps hits to hands.
      if (_micRecording &&
          next.isPlaying &&
          next.currentBeatIndex >= 0 &&
          next.currentBeatIndex != (prev?.currentBeatIndex ?? -2)) {
        final tick = next.currentBeatIndex % _playback.totalTicks;
        if (_playback.tickVolumes[tick] > 0) {
          _beatLog.add((
            beatIndex: _playback.noteIndexAtTick(tick),
            timestamp: DateTime.now(),
          ));
        }
      }

      // Start/stop ticker and mic with metronome
      if (next.isPlaying && !(prev?.isPlaying ?? false)) {
        _startTicker();
        _startMicRecording();
        _sessionTimerNotifier.resume();
      } else if (!next.isPlaying && (prev?.isPlaying ?? false)) {
        _stopTicker();
        _sessionTimerNotifier.pause();
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
              // Single row, not stacked — a two-line Column here silently
              // clipped against the AppBar's fixed toolbar height, making
              // the session timer invisible on-device.
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCountdown)
                    const Icon(Icons.timer_outlined,
                        size: 16, color: AppColors.textMuted),
                  if (isCountdown) const SizedBox(width: 4),
                  Text(
                    _timerLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: timerColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.timelapse,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(sessionSeconds),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
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
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
          child: Column(
            children: [
              // Sheet bleeds to the screen edges (minus a tiny 4px margin) —
              // every pixel of width matters for note spacing, unlike the
              // controls below which read fine with normal 20px insets.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: NotationStaffWidget(
                    rudiment: rudiment,
                    activeIndex: activeBeat,
                    autoScroll: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_ladderActive && _ladderPlan != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _LadderStepRow(
                    bpms: _ladderPlan!.bpms,
                    currentStep: _ladderPlan!.stepIndexAt(_elapsedSeconds),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CompactMetronome(
                  bpm: metState.bpm,
                  isPlaying: metState.isPlaying,
                  isAccent: metState.isAccent,
                  currentBeatIndex: metState.currentBeatIndex,
                  soundType: metState.soundType,
                  onBpmChanged: notifier.setBpm,
                  onToggle: notifier.toggle,
                  onSoundTypeChanged: notifier.setSoundType,
                ),
              ),
              const SizedBox(height: 10),
              if (!metState.isPlaying && _elapsedSeconds == 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _TimerGoalRow(
                    selected: _goalSeconds,
                    suggestedMinutes: widget.targetMinutes,
                    onSelected: (s) => setState(() => _goalSeconds = s),
                  ),
                ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: _showRatingSheet,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Finish Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ladder step row ────────────────────────────────────────────────────────────

/// Read-only view of the tempo-ladder steps with the active one highlighted.
class _LadderStepRow extends StatelessWidget {
  final List<int> bpms;
  final int currentStep;

  const _LadderStepRow({required this.bpms, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.stairs_outlined, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        const Text('Tempo-Leiter',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(width: 8),
        for (var i = 0; i < bpms.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AppSelectableChip(
              label: '${bpms[i]}',
              selected: i == currentStep,
              onTap: () {},
            ),
          ),
      ],
    );
  }
}

// ── Timer goal row ─────────────────────────────────────────────────────────────

class _TimerGoalRow extends StatelessWidget {
  final int? selected;
  final int? suggestedMinutes;
  final ValueChanged<int?> onSelected;

  const _TimerGoalRow({
    required this.selected,
    this.suggestedMinutes,
    required this.onSelected,
  });

  static const _defaults = [
    (label: '5 min', seconds: 5 * 60),
    (label: '10 min', seconds: 10 * 60),
    (label: '15 min', seconds: 15 * 60),
    (label: '∞', seconds: 0),
  ];

  @override
  Widget build(BuildContext context) {
    final options = [
      if (suggestedMinutes != null &&
          !_defaults.any((o) => o.seconds == suggestedMinutes! * 60))
        (label: '$suggestedMinutes min ✦', seconds: suggestedMinutes! * 60),
      ..._defaults,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((opt) {
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
  final String? ladderResult;
  final AICoachingService aiService;
  final VoidCallback onClose;

  const _FeedbackSheet({
    required this.rudimentName,
    required this.achievedBpm,
    required this.targetBpm,
    required this.durationSeconds,
    required this.rating,
    required this.analysis,
    this.ladderResult,
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
          if (widget.ladderResult != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.stairs_outlined,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.ladderResult!,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
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
