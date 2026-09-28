import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/design_tokens.dart';
import '../../app/theme.dart';
import '../../data/local/settings_service.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/notation_staff_widget.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/models/session_log.dart';
import '../../data/local/session_log_service.dart';
import '../coaching/models/session_analysis.dart';
import 'analysis_announcement.dart';
import 'auto_backing.dart';
import 'backdrop.dart';
import '../coaching/services/recording_setup.dart';
import '../coaching/services/ai_coaching_service.dart';
import '../coaching/services/mic_analysis_service.dart';
import '../lessons/lesson_detail_screen.dart';
import '../lessons/lessons_provider.dart';
import '../lessons/models/pattern_playback.dart';
import '../metronome/backing_styles.dart';
import '../metronome/metronome_engine.dart';
import '../metronome/metronome_provider.dart';
import '../program/program_provider.dart';
import 'ladder_plan.dart';
import 'practice_provider.dart';
import 'session_timer_provider.dart';
import 'widgets/pulse_bar.dart';
import 'widgets/result_sheet.dart';
import 'widgets/tempo_row.dart';

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

  /// Second header line under the exercise name, e.g. the path position
  /// "Day 9 · Step 2 of 3 · 84 BPM". Null shows the exercise's difficulty.
  final String? contextLine;

  /// Program phase 1–4 handed over by Today. Since 28.09. the backdrop photo
  /// is random (`backdrop.dart`), so this only travels with the route.
  /// Null (free practice) picks it by the exercise's difficulty.
  final int? phase;

  const PracticeSessionScreen({
    super.key,
    required this.rudimentId,
    required this.isFromRoutine,
    this.targetBpm,
    this.targetMinutes,
    this.isLadder = false,
    this.contextLine,
    this.phase,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen>
    with WidgetsBindingObserver {
  int _elapsedSeconds = 0;
  int? _goalSeconds;
  Timer? _ticker;
  bool _sessionFinished = false;
  bool _finishing = false; // result sheet is opening or open

  // Tempo ladder (program block): plan + current step. The gate is the
  // clean-pass tempo the ladder climbs to (+4 above it is the top step);
  // it starts at the program's target and follows manual BPM changes.
  LadderPlan? _ladderPlan;
  int _ladderStepIndex = 0;
  int? _gateBpm;

  bool get _ladderActive => widget.isLadder && _gateBpm != null;

  // Beat log for mic correlation: recorded in build via ref.listen
  final List<BeatRecord> _beatLog = [];

  // Mic analysis
  MicAnalysisService? _micService;
  bool _micRecording = false;

  final _aiService = AICoachingService();

  /// Captured in [initState] because `ref` is unsafe to read fresh inside
  /// [dispose] — by then the widget's Element may already be torn down.
  late final MetronomeNotifier _metronomeNotifier;

  /// Analysis mode (Brief Phase 3): remembered per exercise, learn is the
  /// default. Only the analysis mode may show per-hand values.
  late bool _analysisMode = SettingsService.analysisModeFor(widget.rudimentId);

  /// Backing loop (Engine part 1; 28.09.: never picked by the user): the
  /// style follows the exercise and the tempo via [autoBackingStyle].
  /// Refreshed in [_applyExtras].
  String? _backingStyleId;

  /// Headphones detected — the extras may sound next to the mic only when
  /// they cannot reach it.
  bool _headphones = false;

  /// Click track: rule of 27.09. — silent while analysing without headphones
  /// (in learn mode the short, quiet pulse is tolerated).
  bool get _extrasAllowed => !_analysisMode || _headphones;

  /// Backing: silent whenever the mic listens at all (mic analysis on, learn
  /// or analysis mode) without headphones — a kick at 70 % and hi-hat noise
  /// through the speaker register as strokes and wreck the result.
  bool get _backingAllowed =>
      !SettingsService.micAnalysisEnabled || _headphones;

  /// Overlapping headphone queries (start + route change): only the newest
  /// answer counts.
  int _headphoneQuerySeq = 0;
  late final SessionTimerNotifier _sessionTimerNotifier;

  /// Fine-grid (24 ticks/quarter) expansion of the exercise, used to drive the
  /// metronome's per-tick volumes and map the playback cursor to a note.
  late PatternPlayback _playback;

  // Result sheet inputs that arrive after it opened (K2 step 3).
  final _ladderResult = ValueNotifier<String?>(null);
  final _sessionLogN = ValueNotifier<SessionLog?>(null);
  final _coachFeedback = ValueNotifier<String?>(null);
  final _coachLoading = ValueNotifier<bool>(false);
  SessionAnalysis? _pendingAnalysis;

  @override
  void initState() {
    super.initState();
    // Draw this screen's photo now and remember it, so the next exercise
    // gets a different one.
    _lastBackdrop = _backdrop;
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _metronomeNotifier = ref.read(metronomeNotifierProvider.notifier);
    _sessionTimerNotifier = ref.read(sessionTimerNotifierProvider.notifier);
    _playback = PatternPlayback.forRudiment(
        ref.read(rudimentByIdProvider(widget.rudimentId)));

    if (widget.targetMinutes != null) {
      _goalSeconds = widget.targetMinutes! * 60;
    }
    _gateBpm = widget.targetBpm;
    if (_ladderActive) {
      _ladderPlan = buildLadderPlan(
          startBpm: _gateBpm!, totalSeconds: _goalSeconds ?? 240);
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
        ..setPatternVolumes(_playback.tickVolumes)
        ..setBackingLevel(SettingsService.backingLevel);
      _applyExtras();
      unawaited(_refreshHeadphones());
      if (_ladderActive) {
        metronome.setBpm(_ladderPlan!.bpmAt(_elapsedSeconds));
      } else if (widget.targetBpm != null) {
        metronome.setBpm(widget.targetBpm!);
      } else {
        _presetExerciseBpm();
      }
      _initMicIfEnabled();
      if (snap != null && mounted) {
        _sessionTimerNotifier.restore(snap.sessionSeconds);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Resumed interrupted session (${_formatDuration(snap.elapsedSeconds)})'),
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
        sessionSeconds: ref.read(sessionTimerNotifierProvider),
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
    _ladderResult.dispose();
    _sessionLogN.dispose();
    _coachFeedback.dispose();
    _coachLoading.dispose();
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
          startBpm: _gateBpm!,
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
        _finishSession();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// All manual tempo input (slider, ±buttons, dialog) funnels through here.
  /// In ladder mode a manual choice rebases the whole ladder: the current
  /// step becomes the chosen tempo, later steps keep the same +4 spacing,
  /// and the clean-pass gate shifts along with it — the program's stored
  /// tempo never overrides what the player actually dialed in.
  void _onUserBpmChanged(int bpm) {
    _metronomeNotifier.setBpm(bpm);
    final plan = _ladderPlan;
    if (!_ladderActive || plan == null) return;
    final step = plan.stepIndexAt(_elapsedSeconds);
    if (plan.bpms[step] == bpm) return;
    setState(() {
      _gateBpm = _gateBpm! + (bpm - plan.bpms[step]);
      _ladderPlan =
          buildLadderPlan(startBpm: _gateBpm!, totalSeconds: plan.totalSeconds);
      _ladderStepIndex = _ladderPlan!.stepIndexAt(_elapsedSeconds);
    });
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

  /// The pulse follows the setting but never runs in analysis mode: the mic
  /// would hear it as strokes (decided 27.09.).
  /// Click track and backing follow the settings, the exercise and the
  /// analysis-mode rule (spec §6): both silent while analysing without
  /// headphones, the mic would hear them.
  void _applyExtras() {
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final bpm = ref.read(metronomeNotifierProvider).bpm;
    _backingStyleId = autoBackingStyle(rudiment, bpm: bpm);
    final backingOn = SettingsService.backingEnabled && _backingAllowed;
    _metronomeNotifier
      ..setClickTrack(SettingsService.clickTrackEnabled && _extrasAllowed)
      ..setBacking(backingOn ? _backingStyleId : null,
          beatsPerBar: rudiment.beatsPerBar);
  }

  /// Ask the platform for headphones, then re-apply the extras. Failure
  /// counts as "no headphones" (the safe side while the mic listens).
  Future<void> _refreshHeadphones() async {
    final seq = ++_headphoneQuerySeq;
    var type = 'none';
    try {
      type = await AudioCapabilities.headphonesType();
    } catch (_) {}
    if (!mounted || seq != _headphoneQuerySeq) return;
    _headphones = type != 'none';
    _applyExtras();
  }

  /// Label of the primary button: Stop while playing, Resume once time has
  /// elapsed, Start before the first note.
  String _primaryLabel(bool isPlaying) {
    if (isPlaying) return 'Stop';
    return _elapsedSeconds > 0 ? 'Resume' : 'Start';
  }

  /// Time next to the label: the chosen length ("8 min") before the first
  /// start, otherwise remaining time with a goal / elapsed time without.
  String? _primaryTime(bool isPlaying) {
    if (!isPlaying && _elapsedSeconds == 0) {
      return _goalSeconds == null ? null : '${_goalSeconds! ~/ 60} min';
    }
    return _timerLabel;
  }

  /// Duration, sound and the exercise explanation live behind "⋯" — rarely
  /// touched while playing, so they leave the main controls alone.
  /// True while the "⋯" sheet is up, so an auto-finish can close it first.
  bool _optionsOpen = false;

  Future<void> _showOptionsSheet() async {
    final screenContext = context;
    // Headphone state is current here: queried at start and on every route
    // change (plug/unplug) via the metronome's audioRouteChanges counter.
    _optionsOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: PracticeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) => Theme(
        data: drumCoachPracticeTheme,
        child: Consumer(
          builder: (context, ref, _) {
            final soundType = ref.watch(
                metronomeNotifierProvider.select((s) => s.soundType));
            return _OptionsSheet(
              goalSeconds: _goalSeconds,
              suggestedMinutes: widget.targetMinutes,
              durationLocked: _elapsedSeconds > 0,
              onGoalSelected: (s) => setState(() => _goalSeconds = s),
              soundType: soundType,
              onSoundSelected:
                  ref.read(metronomeNotifierProvider.notifier).setSoundType,
              clickTrack: SettingsService.clickTrackEnabled,
              analysisMode: _analysisMode,
              backingEnabled: SettingsService.backingEnabled,
              backingStyleLabel: backingStyleById(_backingStyleId)?.label,
              backingLevel: SettingsService.backingLevel,
              extrasAllowed: _extrasAllowed,
              backingAllowed: _backingAllowed,
              onBackingEnabled: (on) async {
                await SettingsService.setBackingEnabled(on);
                _applyExtras();
              },
              onBackingLevel: (level) async {
                await SettingsService.setBackingLevel(level);
                _metronomeNotifier.setBackingLevel(level);
              },
              onClickTrack: (on) async {
                await SettingsService.setClickTrackEnabled(on);
                _applyExtras();
              },
              onAbout: () {
                Navigator.of(sheetContext).pop();
                // A plain Navigator push, not context.push('/library/...') —
                // this screen lives on the top-level /practice route (outside
                // the bottom-nav shell), and pushing a shell-branch route from
                // there caused a duplicate-page-key crash.
                Navigator.of(screenContext).push(MaterialPageRoute(
                  builder: (_) =>
                      LessonDetailScreen(rudimentId: widget.rudimentId),
                ));
              },
            );
          },
        ),
      ),
    );
    _optionsOpen = false;
  }

  /// Session end (Finish or the goal expiring): stop everything, analyse,
  /// and open the ONE result sheet. Saving happens on the rating tap.
  Future<void> _finishSession() async {
    // A second Finish tap while the mic is still stopping must not open a
    // second sheet on top of the first.
    if (_sessionFinished || _finishing) return;
    _finishing = true;
    // The goal can expire while the "⋯" sheet is open; the result sheet must
    // not stack on it, or the final pop leaves a finished screen behind.
    if (_optionsOpen && mounted) Navigator.of(context).pop();
    final metronome = ref.read(metronomeNotifierProvider.notifier);
    metronome.stop();
    _stopTicker();
    await _stopMicRecording();
    if (!mounted) return;

    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final metState = ref.read(metronomeNotifierProvider);
    SessionAnalysis? analysis;
    if (_micService != null && _beatLog.isNotEmpty) {
      try {
        analysis = _micService!.analyze(
          beatLog: _beatLog,
          sticking: rudiment.sticking,
          latencyOffsetMs: SettingsService.latencyOffsetMs ?? 0,
          analysisMode: _analysisMode,
        );
      } catch (e) {
        // A broken analysis must not block saving the session.
        debugPrint('analysis failed: $e');
      }
    }
    _pendingAnalysis = analysis;
    final announcement = analysis == null
        ? null
        : analysisAnnouncement(analysis, analysisMode: _analysisMode);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      // isDismissible only covers the barrier; the back button and the
      // back gesture would still close the sheet before anything is saved.
      builder: (sheetContext) => PopScope(
        canPop: false,
        child: Theme(
          data: drumCoachTheme,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: ResultSheet(
              rudimentName: rudiment.name,
              bpm: metState.bpm,
              durationSeconds: _elapsedSeconds,
              analysisMode: _analysisMode,
              analysis: analysis,
              announcement: announcement,
              ladderResult: _ladderResult,
              sessionLog: _sessionLogN,
              coachFeedback: _coachFeedback,
              coachLoading: _coachLoading,
              coachEnabled: SettingsService.claudeApiKey.isNotEmpty,
              onRate: _onRated,
              onDone: () => Navigator.of(sheetContext).pop(),
              onExport: () async {
                final log = _sessionLogN.value;
                if (log == null) return;
                final file = await SessionLogService.exportSession(log);
                await SharePlus.instance
                    .share(ShareParams(files: [XFile(file.path)]));
              },
            ),
          ),
        ),
      ),
    );
    _finishing = false;
    // The sheet only closes through Done, i.e. after a saved rating. Should
    // it ever close otherwise, stay on the paused screen with Finish live.
    if (mounted && _sessionFinished) context.pop();
  }

  /// Rating tapped on the result sheet: save (once), clear the snapshot,
  /// ladder dialog — Done unlocks when this returns. Session log and coach
  /// answer follow on their own and fill the sheet in when they arrive.
  /// Throws when saving fails so the sheet can release the rating.
  Future<void> _onRated(int rating) async {
    if (_sessionFinished) return;
    _sessionFinished = true;
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final metState = ref.read(metronomeNotifierProvider);
    // Without an API key the coach card only ever showed an error for an
    // expected condition — so it stays hidden entirely.
    final apiKey = SettingsService.claudeApiKey;
    // Flag "loading" before the first await so the card never shows an
    // error for a request that has not been sent yet.
    if (apiKey.isNotEmpty) _coachLoading.value = true;
    try {
      await ref.read(practiceNotifierProvider.notifier).saveSession(
            rudimentId: widget.rudimentId,
            durationSeconds: _elapsedSeconds,
            achievedBpm: metState.bpm,
            rating: rating,
            targetBpm: rudiment.targetBpm,
          );
    } catch (e) {
      _sessionFinished = false;
      if (mounted) _coachLoading.value = false;
      rethrow;
    }
    await SettingsService.clearPracticeSnapshot();
    if (!mounted) return;

    if (_ladderActive) {
      final line = await _askCleanPass();
      if (!mounted) return;
      _ladderResult.value = line;
    }
    unawaited(_afterSave(
      rating: rating,
      rudimentName: rudiment.name,
      targetBpm: rudiment.targetBpm,
      achievedBpm: metState.bpm,
      apiKey: apiKey,
    ));
  }

  /// Session log and coach call after the rating is saved. The notifiers
  /// may be gone by the time these finish (Done pressed meanwhile), so every
  /// write checks `mounted`.
  Future<void> _afterSave({
    required int rating,
    required String rudimentName,
    required int targetBpm,
    required int achievedBpm,
    required String apiKey,
  }) async {
    // Raw session log (Brief Phase 2) — every session, mic or not.
    try {
      final log = buildSessionLog(
        analysis: _pendingAnalysis,
        beatLog: _beatLog,
        exerciseId: widget.rudimentId,
        bpm: achievedBpm,
        durationSeconds: _elapsedSeconds,
        rating: rating,
        startedAt: DateTime.now().subtract(Duration(seconds: _elapsedSeconds)),
        headphones: await AudioCapabilities.headphonesType(),
        device: await AudioCapabilities.deviceInfo(),
        latencyOffsetMs: SettingsService.latencyOffsetMs,
        mode: _analysisMode ? 'analysis' : 'learn',
      );
      await SessionLogService.save(log);
      if (!mounted) return;
      _sessionLogN.value = log;
    } catch (e) {
      debugPrint('session log failed: $e');
    }

    if (apiKey.isEmpty) return;
    String? text;
    try {
      text = await _aiService.getCoachingFeedback(
        apiKey: apiKey,
        rudimentName: rudimentName,
        achievedBpm: achievedBpm,
        targetBpm: targetBpm,
        durationSeconds: _elapsedSeconds,
        rating: rating,
        analysis: _pendingAnalysis,
      );
    } catch (e) {
      debugPrint('coach failed: $e');
    }
    if (!mounted) return;
    _coachFeedback.value = text;
    _coachLoading.value = false;
  }

  /// §6 gate, asked right after a ladder session: a clean pass lifts the
  /// stored clean tempo to gate + 4 and may unlock the next stage. Returns
  /// the result line for the feedback sheet (null when dismissed).
  Future<String?> _askCleanPass() async {
    final gate = _gateBpm!;
    final ok = await showDialog<bool>(
      context: context,
      // Shown over the light result sheet with the light app theme (the
      // dialog uses the screen's context, above the dark practice theme).
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clean & relaxed?'),
        content: Text(
          'Did the tempo ladder run evenly and relaxed all the way to '
          '${gate + 4} BPM? Yes makes ${gate + 4} BPM your new clean tempo.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (ok == null) return null;
    if (!ok) return 'Clean tempo stays at $gate BPM — try again tomorrow.';
    await ref
        .read(cleanTempoNotifierProvider.notifier)
        .recordCleanPass(widget.rudimentId, gate);
    final advanced = await ref
        .read(programControllerProvider.notifier)
        .advanceStageIfReady();
    return advanced
        ? 'Clean tempo now ${gate + 4} BPM · Level up: new stage!'
        : 'Clean tempo now ${gate + 4} BPM.';
  }

  @override
  Widget build(BuildContext context) {
    final rudiment = ref.watch(rudimentByIdProvider(widget.rudimentId));
    final notifier = ref.read(metronomeNotifierProvider.notifier);

    ref.listen<int>(metronomeNotifierProvider.select((s) => s.bpm),
        (prev, next) {
      // The automatic style follows the tempo (sixteenths relax to eighths
      // from 140 BPM).
      if (prev != null && next != prev) _applyExtras();
    });

    ref.listen<int>(
        metronomeNotifierProvider.select((s) => s.audioRouteChanges),
        (prev, next) {
      // Headphones plugged or unplugged: assume they are gone until the
      // query says otherwise — the running loop keeps sounding until it is
      // re-rendered, so every millisecond counts while the mic listens.
      if (prev != null && next != prev) {
        _headphones = false;
        _applyExtras();
        unawaited(_refreshHeadphones());
      }
    });

    ref.listen<MetronomeState>(metronomeNotifierProvider, (prev, next) {
      // Record beat timestamps for mic correlation — only main-note onsets
      // (silent grid ticks and flam/drag grace ticks are not expected
      // strokes), logged as note index so the sticking maps hits to hands.
      if (_micRecording &&
          next.isPlaying &&
          next.currentBeatIndex >= 0 &&
          next.currentBeatIndex != (prev?.currentBeatIndex ?? -2)) {
        final tick = next.currentBeatIndex % _playback.totalTicks;
        if (_playback.isOnsetTick(tick)) {
          _beatLog.add((
            beatIndex: _playback.noteIndexAtTick(tick),
            // Scheduled instant from the timing isolate (§1.3) — not the
            // arrival time of this state update in the UI.
            timestamp: next.lastBeatPlannedAt ?? DateTime.now(),
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

    // Selective watches: the pattern clock updates currentBeatIndex up to
    // ~80×/s, but everything visible here changes only per NOTE or per BEAT.
    // Watching the whole state rebuilt the screen on every tick and clogged
    // the main-isolate queue the click playback runs through (measured
    // 20-30 ms click-fire spikes every few seconds, §Wiedergabe-Diagnose).
    final activeBeat = ref.watch(metronomeNotifierProvider.select((s) =>
        s.isPlaying && s.currentBeatIndex >= 0
            ? _playback
                .noteIndexAtTick(s.currentBeatIndex % _playback.totalTicks)
            : null));
    final isPlaying =
        ref.watch(metronomeNotifierProvider.select((s) => s.isPlaying));
    final bpm = ref.watch(metronomeNotifierProvider.select((s) => s.bpm));

    // Pulse bar input: changes once per onset (the engine only reports
    // audible ticks), so this select never rebuilds per silent grid tick.
    final onset = ref.watch(metronomeNotifierProvider.select((s) =>
        s.isPlaying && s.currentBeatIndex >= 0
            ? (tick: s.currentBeatIndex, at: s.lastBeatPlannedAt)
            : null));
    final onsetTick = onset?.tick ?? -1;
    final pulseVolume = onsetTick >= 0
        ? _playback.tickVolumes[onsetTick % _playback.totalTicks]
        : 0.0;

    final paused = !isPlaying && _elapsedSeconds > 0;
    final showLadder = _ladderActive && _ladderPlan != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // No AppBar on this screen, so nothing else sets the status-bar icons;
      // the screen is dark, the icons must be light.
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: drumCoachPracticeTheme,
        child: Scaffold(
          backgroundColor: PracticeColors.base,
          // A dimmed photo behind the whole screen, like a stage (decided
          // 27.09.): Today's phase picture continues here; free practice
          // picks one by difficulty. The gradient keeps sheet, tempo and
          // buttons readable from the pad.
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _backdrop,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              AnimatedContainer(
                key: const ValueKey('backdrop-scrim'),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Lighter while configuring — the sheet is translucent
                    // then and the photo should read (Uli 28.09.) — darker
                    // once the session runs; the bottom stays dark for the
                    // controls either way.
                    colors: isPlaying || _elapsedSeconds > 0
                        ? const [
                            Color(0x4D101010),
                            Color(0x99101010),
                            Color(0xE0101010),
                          ]
                        : const [
                            Color(0x26101010),
                            Color(0x66101010),
                            Color(0xD9101010),
                          ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              SafeArea(
            child: Column(
              children: [
                _Header(
                  title: rudiment.name,
                  subtitle: widget.contextLine ?? rudiment.difficulty.label,
                  modeChip: SettingsService.micAnalysisEnabled
                      ? _ModeChip(
                          analysis: _analysisMode,
                          micOn: _micRecording,
                          onTap: () {
                            setState(() => _analysisMode = !_analysisMode);
                            SettingsService.setAnalysisModeFor(
                                widget.rudimentId, _analysisMode);
                            _applyExtras();
                          },
                        )
                      : null,
                ),
                // The sheet draws its own paper card; only the margins are
                // ours. 16 px at the sides costs a little note spacing versus
                // the old 4 px, in exchange for the card reading as a card.
                // Center: a short exercise (one row) must not leave the card
                // glued to the top with a hole under it — the scroll view
                // shrinks to the card here and still scrolls long sheets.
                // Translucent while configuring so the backdrop photo reads
                // (Uli 28.09.: the sheet hid it), solid once the session has
                // started and the notes are what matters.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: isPlaying || _elapsedSeconds > 0 ? 1.0 : 0.6,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        child: NotationStaffWidget(
                          rudiment: rudiment,
                          activeIndex: activeBeat,
                          autoScroll: true,
                        ),
                      ),
                    ),
                  ),
                ),
                // The pulse bar (decided 27.09., instead of the digit
                // counter): the marker runs through the loop, each onset
                // flashes a pulse sized by its volume.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: PulseBar(
                    playing: isPlaying,
                    anchorTick: onsetTick,
                    anchorAt: onset?.at,
                    tickDurMs: 60000.0 / bpm / _playback.ticksPerQuarter,
                    totalTicks: _playback.totalTicks,
                    ticksPerQuarter: _playback.ticksPerQuarter,
                    pulseVolume: pulseVolume,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Column(
                    children: [
                      if (showLadder) ...[
                        _LadderStepRow(
                          bpms: _ladderPlan!.bpms,
                          currentStep:
                              _ladderPlan!.stepIndexAt(_elapsedSeconds),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TempoRow(bpm: bpm, onChanged: _onUserBpmChanged),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryButton(
                              icon: isPlaying
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              label: _primaryLabel(isPlaying),
                              time: _primaryTime(isPlaying),
                              onPressed: notifier.toggle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _MoreButton(onPressed: _showOptionsSheet),
                        ],
                      ),
                      // Finish gets its own row: "Resume 03:20", "Finish"
                      // and "⋯" side by side overflow a 360 dp phone.
                      if (paused) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _GhostButton(
                            icon: Icons.check_circle_outline,
                            label: 'Finish',
                            onPressed: _finishSession,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  /// Backdrop: a random photo from the practice pool each time the screen
  /// opens (28.09., Uli), never the one shown last time. The program phase
  /// from Today no longer picks it.
  static String? _lastBackdrop;
  late final String _backdrop =
      pickBackdrop(Random(), avoid: _lastBackdrop);
}

// ── Ladder step row ────────────────────────────────────────────────────────────

/// Read-only view of the tempo-ladder steps with the active one highlighted.
class _LadderStepRow extends StatelessWidget {
  final List<int> bpms;
  final int currentStep;

  const _LadderStepRow({required this.bpms, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    // Wrap, not Row — on narrow phones the label plus four chips can exceed
    // the line and must break instead of overflowing.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        const Text('LADDER',
            style: TextStyle(
                color: PracticeColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w600)),
        for (var i = 0; i < bpms.length; i++)
          AppSelectableChip(
            label: '${bpms[i]}',
            selected: i == currentStep,
            onTap: () {},
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
    // Wrap, not Row — with a suggested-duration chip there are five options,
    // which don't always fit one line on a phone.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: options.map((opt) {
        final sec = opt.seconds == 0 ? null : opt.seconds;
        final isSelected = selected == sec;
        return AppSelectableChip(
          label: opt.label,
          selected: isSelected,
          onTap: () => onSelected(sec),
        );
      }).toList(),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

/// Light shadow behind the header texts so they read on bright backdrop
/// photos too (Uli 28.09.: "bitte leichter Schatten").
const _headerShadow = [
  Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 1)),
];

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.modeChip});

  final String title;
  final String subtitle;
  final Widget? modeChip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            color: PracticeColors.textPrimary,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PracticeTypography.subtitle
                        .copyWith(shadows: _headerShadow)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PracticeTypography.body.copyWith(
                        fontSize: 13,
                        color: PracticeColors.textMuted,
                        shadows: _headerShadow)),
              ],
            ),
          ),
          if (modeChip != null) ...[const SizedBox(width: 10), modeChip!],
        ],
      ),
    );
  }
}

/// "ANALYSIS" / "LEARN" pill with the mic state; tap switches the mode.
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.analysis,
    required this.micOn,
    required this.onTap,
  });

  final bool analysis;
  final bool micOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: analysis
          ? 'Analysis mode (per-hand values) — tap for Learn mode'
          : 'Learn mode — tap for hand analysis',
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(
            side: BorderSide(color: PracticeColors.textFaint)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(micOn ? Icons.mic : Icons.mic_off,
                      size: 16,
                      color: micOn
                          ? PracticeColors.accent
                          : PracticeColors.textFaint),
                  const SizedBox(width: 6),
                  Text(analysis ? 'ANALYSIS' : 'LEARN',
                      style: PracticeTypography.label.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.66,
                          color: PracticeColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Footer buttons ────────────────────────────────────────────────────────────

/// The orange main action: icon, label and (optionally) a time.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.time,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String? time;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: PracticeColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style:
                    PracticeTypography.subtitle.copyWith(color: Colors.white)),
            if (time != null) ...[
              const SizedBox(width: 10),
              Text(time!,
                  style: PracticeTypography.label.copyWith(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: PracticeColors.textPrimary,
          side: const BorderSide(color: PracticeColors.textFaint),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: PracticeTypography.subtitle),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: PracticeColors.textSecondary,
          side: const BorderSide(color: PracticeColors.textFaint),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card)),
        ),
        onPressed: onPressed,
        child: const Tooltip(
            message: 'Options', child: Icon(Icons.more_horiz, size: 22)),
      ),
    );
  }
}


// ── Options sheet ─────────────────────────────────────────────────────────────

class _OptionsSheet extends StatefulWidget {
  const _OptionsSheet({
    required this.goalSeconds,
    required this.suggestedMinutes,
    required this.durationLocked,
    required this.onGoalSelected,
    required this.soundType,
    required this.onSoundSelected,
    required this.clickTrack,
    required this.analysisMode,
    required this.backingEnabled,
    required this.backingStyleLabel,
    required this.backingLevel,
    required this.extrasAllowed,
    required this.backingAllowed,
    required this.onBackingEnabled,
    required this.onBackingLevel,
    required this.onClickTrack,
    required this.onAbout,
  });

  final int? goalSeconds;
  final int? suggestedMinutes;
  final bool durationLocked;
  final ValueChanged<int?> onGoalSelected;
  final SoundType soundType;
  final ValueChanged<SoundType> onSoundSelected;
  final bool clickTrack;
  final bool analysisMode;
  final bool backingEnabled;

  /// Label of the automatically chosen style, shown under the switch.
  final String? backingStyleLabel;
  final double backingLevel;

  /// False while analysing without headphones: click track and backing are
  /// muted and their controls disabled with a hint.
  final bool extrasAllowed;

  /// False while the mic listens without headphones: the band is muted,
  /// switch and level slider are disabled with a hint.
  final bool backingAllowed;
  final ValueChanged<bool> onBackingEnabled;
  final ValueChanged<double> onBackingLevel;
  final ValueChanged<bool> onClickTrack;
  final VoidCallback onAbout;

  @override
  State<_OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<_OptionsSheet> {
  // Local copy so the chips update while the sheet is open — the screen's
  // setState does not rebuild a modal sheet's builder.
  late int? _goal = widget.goalSeconds;
  late bool _clickTrack = widget.clickTrack;
  late bool _backingOn = widget.backingEnabled;
  late double _level = widget.backingLevel;

  @override
  Widget build(BuildContext context) {
    // Scrollable: with the click-track switch the sheet outgrows the 9/16
    // screen share a bottom sheet gets on a 780 dp phone (and any phone with
    // a larger system font).
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Options', style: PracticeTypography.title),
            const SizedBox(height: 18),
            const _SectionLabel('DURATION'),
            const SizedBox(height: 8),
            if (widget.durationLocked)
              Text('Duration is set once the session runs',
                  style: PracticeTypography.body
                      .copyWith(color: PracticeColors.textMuted))
            else
              _TimerGoalRow(
                selected: _goal,
                suggestedMinutes: widget.suggestedMinutes,
                onSelected: (s) {
                  setState(() => _goal = s);
                  widget.onGoalSelected(s);
                },
              ),
            const SizedBox(height: 18),
            const _SectionLabel('SOUND'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: SoundType.values
                  .map((t) => AppSelectableChip(
                        label: t.label,
                        selected: t == widget.soundType,
                        onTap: () => widget.onSoundSelected(t),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            // Backing (Engine part 1): a band that fits the exercise by
            // itself — no picking (28.09.); only on/off and its level.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Backing', style: PracticeTypography.body),
              subtitle: Text(
                !widget.backingAllowed
                    ? 'Off while the mic listens without headphones — it would hear the band'
                    : '${widget.backingStyleLabel ?? 'Off'} · automatic',
                style: PracticeTypography.body
                    .copyWith(fontSize: 13, color: PracticeColors.textMuted),
              ),
              value: _backingOn,
              onChanged: !widget.backingAllowed
                  ? null
                  : (on) {
                      setState(() => _backingOn = on);
                      widget.onBackingEnabled(on);
                    },
            ),
            Row(
              children: [
                Text('Level', style: PracticeTypography.body),
                Expanded(
                  child: Slider(
                    value: _level,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: '${(_level * 100).round()} %',
                    onChanged: !_backingOn || !widget.backingAllowed
                        ? null
                        : (v) {
                            setState(() => _level = v);
                            widget.onBackingLevel(v);
                          },
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Click track', style: PracticeTypography.body),
              subtitle: Text(
                !widget.extrasAllowed
                    ? 'Off while analysing without headphones — the mic would hear it'
                    : 'A quarter-note pulse next to the exercise',
                style: PracticeTypography.body
                    .copyWith(fontSize: 13, color: PracticeColors.textMuted),
              ),
              value: _clickTrack,
              onChanged: !widget.extrasAllowed
                  ? null
                  : (on) {
                      setState(() => _clickTrack = on);
                      widget.onClickTrack(on);
                    },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline,
                  color: PracticeColors.textSecondary),
              title:
                  Text('About this exercise', style: PracticeTypography.body),
              trailing: const Icon(Icons.chevron_right,
                  color: PracticeColors.textMuted),
              onTap: widget.onAbout,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: PracticeColors.textPrimary,
                  side: const BorderSide(color: PracticeColors.textFaint),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: PracticeTypography.label.copyWith(
            fontSize: 11, letterSpacing: 0.9, color: PracticeColors.textMuted),
      );
}
