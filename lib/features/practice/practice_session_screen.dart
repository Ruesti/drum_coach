import 'dart:async';

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
import 'package:share_plus/share_plus.dart';

import '../../data/local/models/session_log.dart';
import '../../data/local/session_log_service.dart';
import '../coaching/models/session_analysis.dart';
import 'analysis_announcement.dart';
import 'auto_backing.dart';
import 'kit_backing.dart';
import 'backdrop.dart';
import '../coaching/services/recording_setup.dart';
import '../coaching/services/ai_coaching_service.dart';
import '../../app/platform_support.dart';
import '../coaching/midi/kit_instrument.dart';
import '../coaching/midi/midi_port_service.dart';
import '../coaching/midi/midi_stroke_source.dart';
import '../coaching/midi/midi_timestamp_mapper.dart';
import '../coaching/services/mic_analysis_service.dart' show BeatRecord;
import '../coaching/services/mic_stroke_source.dart';
import '../coaching/services/stroke_analysis.dart';
import '../coaching/services/stroke_source.dart';
import 'measurement_plan.dart';
import '../lessons/lesson_detail_screen.dart';
import '../lessons/lessons_provider.dart';
import '../lessons/models/pattern_playback.dart';
import '../lessons/models/rudiment.dart';
import '../lessons/models/sheet_plan.dart';
import '../metronome/backing_styles.dart';
import '../metronome/loop_voices.dart' show KitSoundTrack;
import '../metronome/metronome_engine.dart';
import '../metronome/metronome_provider.dart';
import '../room/lesson_voice.dart';
import '../room/room_progress_service.dart';
import '../room/round_tracker.dart';
import '../room/round_verdict.dart';
import '../room/tempo_ladder.dart';
import 'line_selection.dart';
import 'practice_provider.dart';
import 'practice_shortcuts.dart';
import 'session_timer_provider.dart';
import 'widgets/pulse_bar.dart';
import 'widgets/result_sheet.dart';
import 'widgets/line_view.dart';
import 'widgets/tempo_row.dart';

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class PracticeSessionScreen extends ConsumerStatefulWidget {
  final String rudimentId;
  final bool isFromRoutine;

  /// Optional tempo to preset the metronome to. Null presets the exercise's
  /// own suggested tempo instead.
  final int? targetBpm;

  /// Suggested session length (e.g. a program block's duration). Presets the
  /// countdown; the user can still pick another length before starting.
  final int? targetMinutes;

  /// Trainingsraum mode (`?room=1`): one round = once through the selected
  /// lines; each measured round steps the tempo +4 / 0 / −4, two clean
  /// rounds at the target tempo "sit". Without measurement the rating at
  /// the end decides one round. "How to play" explains on request only.
  final bool room;

  /// Second header line under the exercise name, e.g. the path position
  /// "Day 9 · Step 2 of 3 · 84 BPM". Null shows the exercise's difficulty.
  final String? contextLine;

  /// Program phase 1–4 handed over by Today. Since 28.09. the backdrop photo
  /// is random (`backdrop.dart`), so this only travels with the route.
  /// Null (free practice) picks it by the exercise's difficulty.
  final int? phase;

  /// Lines to play, raw from `?lines=` (`all` or 1-based `1,3,5`; see
  /// [initialLineSelection]) and the single-line alias `?line=` (1-based).
  /// Null both: the remembered line of this exercise, else line 1.
  final String? lines;
  final int? line;

  /// MIDI port access; null = the real plugin (test seam).
  final MidiPortService? ports;

  /// Opens this stroke source instead of the planned one (test seam).
  final StrokeSource Function()? strokeSource;

  /// Spoken lesson behind "How to play"; null = the voice assets (seam).
  final LessonVoice? lessonVoice;

  const PracticeSessionScreen({
    super.key,
    required this.rudimentId,
    required this.isFromRoutine,
    this.targetBpm,
    this.targetMinutes,
    this.room = false,
    this.contextLine,
    this.phase,
    this.lines,
    this.line,
    this.ports,
    this.strokeSource,
    this.lessonVoice,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

/// Click track rule (27.09., Brief A.5): silent only while the *microphone*
/// analyses without headphones — MIDI cannot hear the speaker.
bool extrasAllowed({
  required bool analysisMode,
  required bool headphones,
  required bool micListens,
}) =>
    !analysisMode || headphones || !micListens;

/// Visible source line under the header (Brief A.3/A.4/A.6): which source
/// measures, which device, whether its latency is calibrated — or that the
/// run cannot be measured. Null while the source is still being opened.
String? measurementStatusText({
  required bool opening,
  required StrokeSourceKind? source,
  required String? midiDeviceName,
  required bool lost,
  required bool latencyCalibrated,
}) {
  if (opening) return null;
  if (source == null || lost) return 'NOT MEASURABLE';
  if (source == StrokeSourceKind.mic) return 'MIC';
  final name = midiDeviceName ?? 'device';
  return latencyCalibrated ? 'MIDI · $name' : 'MIDI · $name · not calibrated';
}

/// The engine's loop-rebuild debounce (`metronome_engine.dart`).
const int engineRebuildMs = 150;

/// Whether a tick still belongs to the loop of the unit played before a
/// line/mode change: everything until the first downbeat ([tick] 0 of the
/// new unit) planned at least [engineRebuildMs] after the change. Pure.
bool staleTickAfterUnitChange({
  required int tick,
  required DateTime changedAt,
  required DateTime plannedAt,
}) =>
    !(tick == 0 &&
        plannedAt.difference(changedAt).inMilliseconds >= engineRebuildMs);

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen>
    with WidgetsBindingObserver {
  int _elapsedSeconds = 0;
  int? _goalSeconds;
  Timer? _ticker;
  bool _sessionFinished = false;
  bool _finishing = false; // result sheet is opening or open

  // Trainingsraum rounds (room mode): boundaries from the beat stream, the
  // judged rounds of this session, where the running round starts in the
  // beat log, and the short hint after each round.
  late RoundTracker _roundTracker;
  final List<LadderRound> _rounds = [];
  int _roundLogStart = 0;
  int? _roundOfLogStart;
  bool _nailed = false;
  String? _roundChip;
  Timer? _roundChipTimer;
  LessonVoice? _voice;
  LessonVoice get _lessonVoice =>
      _voice ??= widget.lessonVoice ?? AssetLessonVoice();

  // Beat log for mic correlation: recorded in build via ref.listen
  final List<BeatRecord> _beatLog = [];

  // Measurement (Brief Etappe 2, A.1): one stroke source, mic or MIDI.
  StrokeSource? _source;
  bool _measuring = false;
  String? _midiDeviceName;
  StreamSubscription<StrokeSourceStatus>? _sourceStatusSub;
  bool _sourceLost = false;

  /// True until [_openSource] has finished (the status line waits).
  bool _sourceOpening = true;

  /// The kit mapping the MIDI source was opened with — logged as is, even
  /// if the settings change before the session is saved.
  KitMapping? _openedMapping;

  bool get _midiLatencyCalibrated =>
      SettingsService.midiLatencyOffsetMsFor(_midiDeviceName ?? '') != null;

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

  /// Click track: rule of 27.09. — silent while the mic analyses without
  /// headphones (in learn mode the short, quiet pulse is tolerated).
  bool get _extrasAllowed => extrasAllowed(
      analysisMode: _analysisMode,
      headphones: _headphones,
      micListens: _micListens);

  /// Backing: silent whenever the *microphone* listens without headphones.
  /// MIDI cannot hear the speaker (Brief A.5). Kit exercises open no source
  /// yet (B.3), so nothing listens there.
  bool get _micListens =>
      !_kitExercise &&
      (_source?.kind == StrokeSourceKind.mic ||
          (_source == null &&
              planMeasurement(
                    preference: SettingsService.measurementSource,
                    midiDeviceAvailable: false,
                    isDesktop: isDesktopPlatform,
                  ) ==
                  MeasurementPlan.mic));
  bool get _backingAllowed => !_micListens || _headphones;

  /// Overlapping headphone queries (start + route change): only the newest
  /// answer counts.
  int _headphoneQuerySeq = 0;
  late final SessionTimerNotifier _sessionTimerNotifier;

  /// Fine-grid (24 ticks/quarter) expansion of the played unit, used to drive
  /// the metronome's per-tick volumes and map the playback cursor to a note.
  late PatternPlayback _playback;

  // Lines (16.10.): the selected sheet lines (0-based, play order), the
  // selection index the loop starts at, and the resulting unit.
  late List<int> _selection;
  late int _start;
  late SheetPlan _plan;

  /// Selection step the cursor is on (0 before the start); set in [build]
  /// without setState, read by ‹ ›.
  int _shownStep = 0;

  /// The exercise is a kit sheet: no measurement in Teil 1.
  bool _kitExercise = false;

  /// Kit unit: its own kick/hi-hat voices, played by the band when Backing
  /// is on (S23 test 16.10.). Built once per unit, so the engine sees the
  /// same list until the unit changes.
  List<KitSoundTrack> _kitTracks = const [];
  List<double>? _kitPatternSound;

  /// The played unit as an ordinary exercise: playback, backing choice and
  /// analysis see only this (spec §2).
  late Rudiment _unit;

  void _buildUnit(Rudiment rudiment) {
    _kitExercise = rudiment.isKit;
    // A room round is ONE pass through the selected lines.
    _plan = SheetPlan.sequence(rudiment, _selection,
        repeats: widget.room ? 1 : SettingsService.sequenceRepeats,
        start: _start);
    _unit = rudiment.withSticking(_plan.beats);
    // A kit unit mixes its voices; the cursor then steps per column.
    _playback = _plan.isKit
        ? buildVoicesPlayback(_plan.voices, rudiment.gridUnit)
        : PatternPlayback.forRudiment(_unit);
    _kitTracks = _plan.isKit
        ? kitBackingTracks(_plan.voices, rudiment.gridUnit)
        : const [];
    _kitPatternSound =
        _plan.isKit ? kitPatternSound(_plan.voices, rudiment.gridUnit) : null;
    _freshRounds();
  }

  /// Round counting starts over: a new unit, or playback (re)started.
  void _freshRounds() {
    _roundTracker = RoundTracker(beatsPerRound: _playback.totalTicks);
    _roundLogStart = _beatLog.length;
    _roundOfLogStart = null;
  }

  /// Line or start change: new unit, new loop, fresh beat log, line
  /// remembered. While playing the engine rebuilds and the new unit starts
  /// on its "1" (spec §5).
  void _applyUnitChange() {
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final playing = ref.read(metronomeNotifierProvider).isPlaying;
    setState(() => _buildUnit(rudiment));
    _beatLog.clear();
    _roundLogStart = 0;
    // Until the new loop's first downbeat ([_consumeStaleTick]) nothing
    // counts as a round.
    if (playing) _roundTracker.reset();
    _metronomeNotifier.setPatternVolumes(_playback.tickVolumes);
    _applyExtras();
    if (playing) {
      // The old loop keeps ticking until the engine has rebuilt; those
      // ticks mean nothing to the new unit (review 01.10.).
      _unitChangedAt = DateTime.now();
      // Re-anchor the mic (spec §5): onsets before the switch belong to the
      // old unit and would count as extra strokes against the new one.
      if (_measuring) unawaited(_restartMeasuring());
    }
    // Only a single line is remembered; moving within a sequence is not.
    if (!_plan.isSequence) {
      SettingsService.setLastLine(widget.rudimentId, _plan.lineIndex);
    }
  }

  /// Set by [_applyUnitChange] while playing; cleared by the first tick of
  /// the new unit's loop (see [_consumeStaleTick]) or by a stop.
  DateTime? _unitChangedAt;

  /// Whether this tick still comes from the previous unit's loop. The first
  /// downbeat planned after the engine's rebuild is the new start: from
  /// then on ticks count again (and the beat log starts clean).
  bool _consumeStaleTick(int globalTick, DateTime? plannedAt) {
    final changedAt = _unitChangedAt;
    if (changedAt == null) return false;
    if (staleTickAfterUnitChange(
        tick: globalTick % _playback.totalTicks,
        changedAt: changedAt,
        plannedAt: plannedAt ?? DateTime.now())) {
      return true;
    }
    _unitChangedAt = null;
    _beatLog.clear();
    // The new unit's loop starts here, on its "1": a fresh first round.
    _freshRounds();
    return false;
  }

  Future<void> _restartMeasuring() async {
    await _stopMeasuring();
    await _startMeasuring();
  }

  /// ‹ › — one line: the neighbouring line (nothing at the ends); a
  /// sequence: the loop restarts at the previous/next selected line from
  /// the one the cursor is on, wrapping round.
  void _step(int delta) {
    if (_plan.isSequence) {
      _start = (_shownStep + delta) % _selection.length;
    } else {
      final count =
          ref.read(rudimentByIdProvider(widget.rudimentId)).sheet.length;
      final i = _plan.lineIndex + delta;
      if (i < 0 || i >= count) return;
      _selection = [i];
    }
    _applyUnitChange();
  }

  // Result sheet inputs that arrive after it opened (K2 step 3); the
  // first carries the room's round summary.
  final _roomResult = ValueNotifier<String?>(null);
  final _sessionLogN = ValueNotifier<SessionLog?>(null);
  final _coachFeedback = ValueNotifier<String?>(null);
  final _coachLoading = ValueNotifier<bool>(false);
  SessionAnalysis? _pendingAnalysis;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _metronomeNotifier = ref.read(metronomeNotifierProvider.notifier);
    _sessionTimerNotifier = ref.read(sessionTimerNotifierProvider.notifier);
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    _selection = initialLineSelection(
        lineCount: rudiment.sheet.length,
        linesParam: widget.lines,
        lineParam: widget.line,
        rememberedLine: SettingsService.lastLineFor(widget.rudimentId));
    _start = 0;
    _buildUnit(rudiment);

    if (widget.targetMinutes != null) {
      _goalSeconds = widget.targetMinutes! * 60;
    }

    // Restore a session interrupted by the app going to background (e.g. a
    // phone call killed the process mid-practice).
    final snap = SettingsService.practiceSnapshotFor(widget.rudimentId);
    if (snap != null) {
      _elapsedSeconds = snap.elapsedSeconds;
      _goalSeconds = snap.goalSeconds ?? _goalSeconds;
      // Resume with the same lines and start (lines outside the sheet are
      // dropped by SheetPlan.sequence).
      _selection = snap.lines;
      _start = snap.start;
      _buildUnit(rudiment);
      _selection = _plan.selection;
      _start = _plan.start;
      SettingsService.clearPracticeSnapshot();
    }
    // A single line is remembered as soon as it opens (the line list marks
    // the line actually practised); a sequence stores nothing.
    if (!_plan.isSequence && rudiment.sheet.length > 1) {
      SettingsService.setLastLine(widget.rudimentId, _plan.lineIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final metronome = _metronomeNotifier
        ..setPatternClock(_playback.ticksPerQuarter)
        ..setPatternVolumes(_playback.tickVolumes)
        ..setBackingLevel(SettingsService.backingLevel);
      _applyExtras();
      unawaited(_refreshHeadphones());
      if (widget.targetBpm != null) {
        metronome.setBpm(widget.targetBpm!);
      } else {
        _presetExerciseBpm();
      }
      _initMeasurement();
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
        lines: _selection,
        start: _start,
      );
    }
  }

  /// Opens the stroke source, then re-applies the backing rule: it ran at
  /// init while no source was known, and MIDI may lift the mic mute.
  Future<void> _initMeasurement() async {
    await _openSource();
    _sourceOpening = false;
    if (!mounted) return;
    setState(() {});
    _applyExtras();
  }

  /// Opens the stroke source; any failure counts as "no source" (the
  /// session runs without numbers instead of breaking).
  Future<void> _openSource() async {
    try {
      await _openSourceOrThrow();
    } catch (e) {
      debugPrint('measurement: opening the source failed: $e');
      await _sourceStatusSub?.cancel();
      _sourceStatusSub = null;
      _source?.dispose();
      _source = null;
      _midiDeviceName = null;
      _openedMapping = null;
    }
  }

  Future<void> _openSourceOrThrow() async {
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    // Kit exercises are measured per voice (Brief B.3) — not in this step:
    // no source, no number; sheet, click and cursor run (Leitprinzip: no
    // number is better than a wrong one).
    if (rudiment.isKit) return;
    final injected = widget.strokeSource;
    if (injected != null) {
      _source = injected();
    } else {
      await _openPlannedSource();
    }
    final src = _source;
    if (src == null) return;
    if (!mounted) {
      // dispose() already ran and missed this source.
      src.dispose();
      _source = null;
      _midiDeviceName = null;
      _openedMapping = null;
      return;
    }
    // Sensor level (Brief A.6): an exercise above the source's level is
    // played without numbers.
    if (!rudiment.requiredSensor.satisfiedBy(src.kind)) {
      src.dispose();
      _source = null;
      _midiDeviceName = null;
      _openedMapping = null;
      return;
    }
    _sourceStatusSub = src.statusChanges.listen((s) {
      if (s == StrokeSourceStatus.notMeasurable && mounted) {
        setState(() => _sourceLost = true);
      }
    });
  }

  /// The source the settings and devices call for (MIDI, mic or none).
  Future<void> _openPlannedSource() async {
    final ports = widget.ports ?? MidiPortService();
    final devices = await ports.inputDevices();
    final chosen =
        chooseMidiDevice(devices, lastId: SettingsService.midiLastDeviceId);
    final plan = planMeasurement(
      preference: SettingsService.measurementSource,
      midiDeviceAvailable: chosen != null,
      isDesktop: isDesktopPlatform,
    );
    if (!mounted) return;
    switch (plan) {
      case MeasurementPlan.midi:
        final port = await ports.open(chosen!);
        if (port == null) return;
        if (!mounted) {
          // Screen left while the port was opening: release it again.
          await port.close();
          return;
        }
        _midiDeviceName = port.deviceName;
        _openedMapping = SettingsService.kitMappingFor(port.deviceName);
        _source = MidiStrokeSource(
          port: port,
          mapping: _openedMapping!,
          mapper: MidiTimestampMapper(midiTimestampUnitForPlatform(
              isAndroid: isAndroidPlatform, isLinux: isLinuxPlatform)),
        );
        await SettingsService.setMidiLastDeviceId(chosen);
      case MeasurementPlan.mic:
        // The desktop has no permission plugin (MissingPluginException);
        // the user chose the microphone explicitly there.
        if (isDesktopPlatform) {
          _source = MicStrokeSource();
        } else {
          final status = await Permission.microphone.request();
          if (status.isGranted && mounted) _source = MicStrokeSource();
        }
      case MeasurementPlan.none:
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _ticker?.cancel();
    _roomResult.dispose();
    _roundChipTimer?.cancel();
    final voice = _voice;
    if (voice != null) unawaited(voice.stop());
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
    _sourceStatusSub?.cancel();
    _source?.stop();
    _source?.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
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
  /// In room mode the round in progress then does not count.
  void _onUserBpmChanged(int bpm) {
    final changed = bpm != ref.read(metronomeNotifierProvider).bpm;
    _metronomeNotifier.setBpm(bpm);
    if (widget.room && changed) _roundTracker.reset();
  }

  /// Room mode, one beat of the running loop: at a round boundary the
  /// finished round is judged from its own window and the tempo steps.
  void _onRoomBeat(int globalTick, DateTime plannedAt) {
    final ended = _roundTracker.onBeat(globalTick);
    final round = _roundTracker.currentRound;
    if (round == _roundOfLogStart) return;
    final from = _roundLogStart.clamp(0, _beatLog.length);
    final roundLog = _beatLog.sublist(from);
    _roundLogStart = _beatLog.length;
    final first = _roundOfLogStart == null;
    _roundOfLogStart = round;
    if (ended == null || first) return;
    final verdict = verdictOf(_analyzeRound(roundLog, plannedAt));
    if (verdict == null) return; // not measurable: no verdict, no step
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final bpm = ref.read(metronomeNotifierProvider).bpm;
    _rounds.add(LadderRound(bpm: bpm, verdict: verdict));
    final nailedNow = !_nailed && sitsAt(_rounds, rudiment.targetBpm);
    if (nailedNow) _nailed = true;
    final next = nextLadderBpm(bpm, verdict, minBpm: rudiment.minBpm);
    if (next != bpm) {
      _metronomeNotifier.setBpm(next);
      // The engine restarts the loop on its next "1" at the new tempo; the
      // round begun meanwhile is cut short and does not count.
      _roundTracker.reset();
    }
    _showRoundChip(nailedNow ? 'Nailed it' : roundChipText(verdict, bpm, next));
  }

  void _showRoundChip(String text) {
    _roundChipTimer?.cancel();
    setState(() => _roundChip = text);
    _roundChipTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _roundChip = null);
    });
  }

  /// One round's analysis: the strokes inside its window, against the beat
  /// log entries of that round. Null = nothing measurable.
  SessionAnalysis? _analyzeRound(List<BeatRecord> log, DateTime endAt) {
    final src = _source;
    if (src == null || !_measuring || log.isEmpty) return null;
    if (_sourceLost || src.status == StrokeSourceStatus.notMeasurable) {
      return null;
    }
    // Window: half a note before the round's first note up to half a note
    // before the next round's "1", shifted by the latency the strokes
    // carry (the analysis subtracts it again).
    final firstMs = log.first.timestamp.microsecondsSinceEpoch / 1000.0;
    final lastMs = log.last.timestamp.microsecondsSinceEpoch / 1000.0;
    final gap =
        log.length >= 2 ? (lastMs - firstMs) / (log.length - 1) : 200.0;
    final latency = _latencyOffsetMs(src);
    final lo = firstMs - gap / 2 + latency;
    final hi = endAt.microsecondsSinceEpoch / 1000.0 - gap / 2 + latency;
    final events = [
      for (final e in src.events)
        if (e.timeMs >= lo && e.timeMs < hi) e,
    ];
    try {
      return _analyze(src, events, log);
    } catch (e) {
      debugPrint('round analysis failed: $e');
      return null;
    }
  }

  double _latencyOffsetMs(StrokeSource src) =>
      src.kind == StrokeSourceKind.midi
          ? (SettingsService.midiLatencyOffsetMsFor(_midiDeviceName ?? '') ??
              0)
          : (SettingsService.latencyOffsetMs ?? 0);

  /// [analyzeStrokes] with this session's source settings.
  SessionAnalysis _analyze(
      StrokeSource src, List<StrokeEvent> events, List<BeatRecord> log) {
    final isMidi = src.kind == StrokeSourceKind.midi;
    final midiOffset = isMidi
        ? SettingsService.midiLatencyOffsetMsFor(_midiDeviceName ?? '')
        : null;
    final analysis = analyzeStrokes(
      events: events,
      beatLog: log,
      sticking: _unit.sticking,
      source: src.kind,
      expectedInstrument:
          isMidi ? SettingsService.padRoleInstrument : KitInstrument.pad,
      latencyOffsetMs: _latencyOffsetMs(src),
      analysisMode: _analysisMode,
      recordingSetup: src.describeSetup(),
    );
    // Brief A.4: warn, do not withhold — numbers stay.
    return isMidi && midiOffset == null
        ? analysis.withLatencyUncalibrated()
        : analysis;
  }

  Future<void> _startMeasuring() async {
    final src = _source;
    if (src == null || _measuring) return;
    try {
      await src.start();
      if (mounted) setState(() => _measuring = true);
    } catch (_) {}
  }

  Future<void> _stopMeasuring() async {
    if (!_measuring) return;
    try {
      await _source!.stop();
      _measuring = false;
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
    // The style follows the played unit (a triplet line gets shuffle).
    final bpm = ref.read(metronomeNotifierProvider).bpm;
    _backingStyleId = autoBackingStyle(_unit, bpm: bpm);
    final backingOn = SettingsService.backingEnabled && _backingAllowed;
    _metronomeNotifier
        .setClickTrack(SettingsService.clickTrackEnabled && _extrasAllowed);
    final b = backingFor(
        isKit: _plan.isKit,
        backingOn: backingOn,
        styleId: _backingStyleId,
        playsKick: _plan.playsKick,
        playsHihat: _plan.playsHihat,
        kitTracks: _kitTracks,
        kitPatternSound: _kitPatternSound);
    _metronomeNotifier.setBacking(b.styleId,
        beatsPerBar: _unit.beatsPerBar,
        backingKick: b.kick,
        backingHihat: b.hihat,
        kitTracks: b.kitTracks,
        patternSound: b.patternSound);
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
            final soundType =
                ref.watch(metronomeNotifierProvider.select((s) => s.soundType));
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
              backingKit: _plan.isKit,
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
              showSticking: SettingsService.showSticking,
              showCounts: SettingsService.showCounts,
              onShowSticking: (on) async {
                await SettingsService.setShowSticking(on);
                if (mounted) setState(() {});
              },
              onShowCounts: (on) async {
                await SettingsService.setShowCounts(on);
                if (mounted) setState(() {});
              },
              onAbout: () {
                Navigator.of(sheetContext).pop();
                // A plain Navigator push, not context.push('/library/...') —
                // this screen lives on the top-level /practice route (outside
                // the bottom-nav shell), and pushing a shell-branch route from
                // there caused a duplicate-page-key crash.
                Navigator.of(screenContext).push(
                  MaterialPageRoute(
                    builder: (_) => LessonDetailScreen(
                      rudimentId: widget.rudimentId,
                      showStart: false,
                    ),
                  ),
                );
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
    await _stopMeasuring();
    if (!mounted) return;

    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final metState = ref.read(metronomeNotifierProvider);
    SessionAnalysis? analysis;
    final src = _source;
    if (src != null && _beatLog.isNotEmpty) {
      try {
        if (_sourceLost || src.status == StrokeSourceStatus.notMeasurable) {
          analysis = SessionAnalysis(
            detectedHits: src.events.length,
            expectedHits: _beatLog.length,
            notMeasurable: true,
            source: src.kind,
            recordingSetup: src.describeSetup(),
            events: [
              for (final e in src.events)
                OnsetEventData(
                  timeMs: e.timeMs,
                  peakLevel: e.velocity,
                  instrument: e.instrument.name,
                  rawNote: e.rawNote,
                ),
            ],
          );
        } else {
          analysis = _analyze(src, src.events, _beatLog);
        }
      } catch (e) {
        // A broken analysis must not block saving the session.
        debugPrint('analysis failed: $e');
      }
    }
    _pendingAnalysis = analysis;
    if (widget.room) {
      _roundChipTimer?.cancel();
      setState(() => _roundChip = null);
      if (_rounds.isNotEmpty) _roomResult.value = _roomSummary(_rounds);
    }
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
              ladderResult: _roomResult,
              sessionLog: _sessionLogN,
              coachFeedback: _coachFeedback,
              coachLoading: _coachLoading,
              coachEnabled: SettingsService.claudeApiKey.isNotEmpty,
              onRate: _onRated,
              onDone: () => Navigator.of(sheetContext).pop(),
              onExport: () async {
                final log = _sessionLogN.value;
                if (log == null) return null;
                final out = await SessionLogService.deliverExport(
                  write: (dir) =>
                      SessionLogService.exportSession(log, dir: dir),
                  shareAvailable: fileShareAvailable,
                  share: (f) => SharePlus.instance
                      .share(ShareParams(files: [XFile(f.path)])),
                );
                return SessionLogService.exportMessage(out);
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
    // Room: the measured rounds decide; without any, the rating is one
    // round at the tempo played.
    final rounds = !widget.room
        ? null
        : _rounds.isNotEmpty
            ? List<LadderRound>.of(_rounds)
            : [
                LadderRound(
                    bpm: metState.bpm, verdict: verdictOfRating(rating)),
              ];
    try {
      final practice = ref.read(practiceNotifierProvider.notifier);
      if (rounds != null) {
        await practice.saveRoomSession(
          rudimentId: widget.rudimentId,
          durationSeconds: _elapsedSeconds,
          achievedBpm: metState.bpm,
          rating: rating,
          rounds: rounds,
          targetBpm: rudiment.targetBpm,
          minBpm: rudiment.minBpm,
        );
      } else {
        await practice.saveSession(
          rudimentId: widget.rudimentId,
          durationSeconds: _elapsedSeconds,
          achievedBpm: metState.bpm,
          rating: rating,
          targetBpm: rudiment.targetBpm,
        );
      }
    } catch (e) {
      _sessionFinished = false;
      if (mounted) _coachLoading.value = false;
      rethrow;
    }
    await SettingsService.clearPracticeSnapshot();
    if (!mounted) return;

    if (rounds != null && _rounds.isEmpty) {
      _roomResult.value = _roomSummary(rounds);
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
        latencyOffsetMs: _source?.kind == StrokeSourceKind.midi
            ? SettingsService.midiLatencyOffsetMsFor(_midiDeviceName ?? '')
            : SettingsService.latencyOffsetMs,
        source: _source?.kind.name ?? 'off',
        midiDevice: _midiDeviceName,
        kitMapping: _openedMapping?.encode(),
        mode: _analysisMode ? 'analysis' : 'learn',
        sheetLine: sessionLogSheetFields(_plan).line,
        sheetMode: sessionLogSheetFields(_plan).mode,
        sheetLines: sessionLogSheetFields(_plan).lines,
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

  /// The room's line on the result sheet.
  String _roomSummary(List<LadderRound> rounds) {
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    if (sitsInSession(rounds, rudiment.targetBpm)) {
      return 'Nailed it · two clean rounds at ${rudiment.targetBpm} BPM';
    }
    final last = rounds.last;
    final next =
        nextLadderBpm(last.bpm, last.verdict, minBpm: rudiment.minBpm);
    final n = rounds.length;
    return '$n ${n == 1 ? 'round' : 'rounds'} · next time from $next BPM';
  }

  /// "How to play": the lesson text and, if recorded, its voice — only
  /// ever on this button, never by itself.
  Future<void> _showHowTo() async {
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final voice = _lessonVoice;
    final clipId = lessonClipId(rudiment.id);
    final hasClip = voice.has(clipId);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PracticeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) => Theme(
        data: drumCoachPracticeTheme,
        child: _HowToSheet(
          rudiment: rudiment,
          hasClip: hasClip,
          onPlay: () => voice.play(clipId),
        ),
      ),
    );
    unawaited(voice.stop());
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
      final newTick = next.isPlaying &&
          next.currentBeatIndex >= 0 &&
          next.currentBeatIndex != (prev?.currentBeatIndex ?? -2);
      // Ticks of the previous unit's loop after a line change count for
      // nothing — neither the beat log nor (via _unitChangedAt) the cursor.
      final stale = newTick &&
          _consumeStaleTick(next.currentBeatIndex, next.lastBeatPlannedAt);
      // Room rounds: the boundary beat closes the round before it joins
      // the log of the next one.
      if (widget.room && newTick && !stale) {
        _onRoomBeat(
            next.currentBeatIndex, next.lastBeatPlannedAt ?? DateTime.now());
      }
      // Record beat timestamps for mic correlation — only main-note onsets
      // (silent grid ticks and flam/drag grace ticks are not expected
      // strokes), logged as note index so the sticking maps hits to hands.
      if (_measuring && newTick && !stale) {
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
        // A (re)start plays the loop from its "1": rounds count afresh.
        _freshRounds();
        _startTicker();
        _startMeasuring();
        _sessionTimerNotifier.resume();
      } else if (!next.isPlaying && (prev?.isPlaying ?? false)) {
        _unitChangedAt = null;
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
        s.isPlaying && s.currentBeatIndex >= 0 && _unitChangedAt == null
            ? _playback
                .noteIndexAtTick(s.currentBeatIndex % _playback.totalTicks)
            : null));
    // Which sheet line and note (pad) or tick (kit) the cursor is on (null
    // before the start).
    final loc =
        activeBeat == null || _plan.isKit ? null : _plan.locate(activeBeat);
    final tickLoc =
        activeBeat == null || !_plan.isKit || _playback.onsetTicks.isEmpty
            ? null
            : _plan.locateTick(_playback.onsetTicks[activeBeat]);
    // Slot, line and selection step under the cursor (slot 0 before the
    // start) — for the line bar and for ‹ › in a sequence.
    final cursorSlot = tickLoc?.slot ?? loc?.slot ?? 0;
    final cursorLine = _plan.lines[cursorSlot];
    final cursorStep = _plan.stepOf(cursorSlot);
    _shownStep = cursorStep.step;
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

    final scaffold = Scaffold(
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
                  statusLine:
                      SettingsService.measurementSource != MeasurementSource.off
                          ? measurementStatusText(
                              opening: _sourceOpening,
                              source: _source?.kind,
                              midiDeviceName: _midiDeviceName,
                              lost: _sourceLost,
                              latencyCalibrated: _midiLatencyCalibrated,
                            )
                          : null,
                  modeChip:
                      SettingsService.measurementSource != MeasurementSource.off
                          ? _ModeChip(
                              analysis: _analysisMode,
                              source: _source?.kind,
                              active: _measuring && !_sourceLost,
                              unavailable: _source == null || _sourceLost,
                              kit: rudiment.isKit,
                              // No measurement for kit yet: nothing to switch.
                              onTap: rudiment.isKit
                                  ? null
                                  : () {
                                      setState(
                                          () => _analysisMode = !_analysisMode);
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
                // Center: a short line (one row) must not leave the card
                // glued to the top with a hole under it.
                // Translucent while configuring so the backdrop photo reads
                // (Uli 28.09.: the sheet hid it), solid once the session has
                // started and the notes are what matters.
                // The one-line view (Zeilen statt Blatt, 16.10.): only the
                // line being played, the card as high as its rows.
                // 6 px at the sides (was 16): the notes need the width
                // more than the card needs a margin (Uli, 10.10.).
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 14, 6, 0),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: isPlaying || _elapsedSeconds > 0 ? 1.0 : 0.6,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        child: LineView(
                          rudiment: rudiment,
                          line: cursorLine,
                          activeIndex: loc?.index,
                          activeTick: tickLoc?.tick,
                          showSticking: SettingsService.showSticking,
                          showCounts: SettingsService.showCounts,
                        ),
                      ),
                    ),
                  ),
                ),
                if (rudiment.sheet.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _LineBar(
                      label: lineNavLabel(
                          line: cursorLine,
                          lineCount: rudiment.sheet.length,
                          step: cursorStep.step,
                          steps: _plan.selection.length,
                          pass: cursorStep.pass,
                          repeats: _plan.repeats),
                      canPrev: _plan.isSequence || _plan.lineIndex > 0,
                      canNext: _plan.isSequence ||
                          _plan.lineIndex < rudiment.sheet.length - 1,
                      onPrev: () => _step(-1),
                      onNext: () => _step(1),
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
                      if (widget.room) ...[
                        _RoomBar(chip: _roundChip, onHowTo: _showHowTo),
                        const SizedBox(height: 10),
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
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // No AppBar on this screen, so nothing else sets the status-bar icons;
      // the screen is dark, the icons must be light.
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: drumCoachPracticeTheme,
        child: isDesktopPlatform
            ? CallbackShortcuts(
                bindings: practiceShortcuts(
                  toggle: notifier.toggle,
                  bumpBpm: (d) => _onUserBpmChanged(
                      (ref.read(metronomeNotifierProvider).bpm + d)
                          .clamp(40, 240)),
                  leave: () {
                    if (ref.read(metronomeNotifierProvider).isPlaying) {
                      notifier.toggle();
                    } else {
                      context.pop();
                    }
                  },
                ),
                child: Focus(autofocus: true, child: scaffold),
              )
            : scaffold,
      ),
    );
  }

  /// Backdrop: a random photo from the pool each time the screen opens
  /// (28.09., Uli), never the one shown last on any screen. The program
  /// phase from Today no longer picks it.
  late final String _backdrop = nextBackdrop();
}

// ── Line bar ───────────────────────────────────────────────────────────────────

/// Under the one-line view: ‹ label › — "Line 3 of 8" or "Line 5 · 2 of 4 ·
/// 1/2" (see [lineNavLabel]).
class _LineBar extends StatelessWidget {
  final String label;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _LineBar({
    required this.label,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('line-bar'),
      height: 44,
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('line-prev'),
            icon: const Icon(Icons.chevron_left),
            color: PracticeColors.textPrimary,
            disabledColor: PracticeColors.textFaint,
            onPressed: canPrev ? onPrev : null,
          ),
          Expanded(
            child: Center(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PracticeTypography.label
                      .copyWith(color: PracticeColors.textPrimary)),
            ),
          ),
          IconButton(
            key: const ValueKey('line-next'),
            icon: const Icon(Icons.chevron_right),
            color: PracticeColors.textPrimary,
            disabledColor: PracticeColors.textFaint,
            onPressed: canNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// ── Room bar ────────────────────────────────────────────────────────────────────

/// The hint after a room round: what the verdict did to the tempo.
String roundChipText(RoundVerdict verdict, int bpm, int nextBpm) {
  if (nextBpm > bpm) return 'Clean · +${nextBpm - bpm}';
  if (nextBpm < bpm) return 'Slower · −${bpm - nextBpm}';
  return verdict == RoundVerdict.clean ? 'Clean' : 'Hold';
}

/// Room mode, above the tempo row: "How to play" and the round hint.
class _RoomBar extends StatelessWidget {
  final String? chip;
  final VoidCallback onHowTo;

  const _RoomBar({required this.chip, required this.onHowTo});

  @override
  Widget build(BuildContext context) {
    final text = chip;
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          TextButton.icon(
            key: const Key('room-how-to'),
            onPressed: onHowTo,
            style: TextButton.styleFrom(
                foregroundColor: PracticeColors.textSecondary),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text('How to play'),
          ),
          const Spacer(),
          if (text != null)
            Container(
              key: const Key('room-round-chip'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: text == 'Nailed it'
                    ? PracticeColors.solidStreak
                    : PracticeColors.raised,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(text,
                  style: PracticeTypography.label.copyWith(
                      color: PracticeColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

/// "How to play": the exercise's lesson sections, and a play button when
/// a spoken version exists.
class _HowToSheet extends StatelessWidget {
  final Rudiment rudiment;
  final Future<bool> hasClip;
  final VoidCallback onPlay;

  const _HowToSheet({
    required this.rudiment,
    required this.hasClip,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final sections = rudiment.technique;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('How to play',
                        style: PracticeTypography.title
                            .copyWith(color: PracticeColors.textPrimary)),
                  ),
                  FutureBuilder<bool>(
                    future: hasClip,
                    builder: (_, snap) => snap.data == true
                        ? IconButton(
                            key: const Key('room-how-to-play'),
                            tooltip: 'Listen',
                            color: PracticeColors.accent,
                            icon: const Icon(Icons.volume_up_rounded),
                            onPressed: onPlay,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (sections.isEmpty)
                Text(rudiment.description,
                    style: PracticeTypography.body
                        .copyWith(color: PracticeColors.textSecondary)),
              for (final s in sections) ...[
                Text(s.title,
                    style: PracticeTypography.subtitle
                        .copyWith(color: PracticeColors.textPrimary)),
                const SizedBox(height: 6),
                Text(s.body,
                    style: PracticeTypography.body
                        .copyWith(color: PracticeColors.textSecondary)),
                const SizedBox(height: 16),
              ],
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
  const _Header({
    required this.title,
    required this.subtitle,
    this.statusLine,
    this.modeChip,
  });

  final String title;
  final String subtitle;

  /// Measurement source and device ("MIDI · TD-17", "MIC", "NOT
  /// MEASURABLE") — visible text, readable from the kit.
  final String? statusLine;
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
                if (statusLine != null) ...[
                  const SizedBox(height: 2),
                  Text(statusLine!,
                      key: const ValueKey('measurement-status'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PracticeTypography.label.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.66,
                          color: statusLine == 'NOT MEASURABLE' ||
                                  statusLine!.endsWith('not calibrated')
                              ? PracticeColors.accent
                              : PracticeColors.textSecondary,
                          shadows: _headerShadow)),
                ],
              ],
            ),
          ),
          if (modeChip != null) ...[const SizedBox(width: 10), modeChip!],
        ],
      ),
    );
  }
}

/// "ANALYSIS" / "LEARN" pill with the source state (mic or MIDI); tap
/// switches the mode.
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.analysis,
    required this.source,
    required this.active,
    required this.unavailable,
    required this.kit,
    required this.onTap,
  });

  final bool analysis;

  /// The open stroke source, or null when none could be opened.
  final StrokeSourceKind? source;

  /// The source is recording right now.
  final bool active;

  /// No source, or the source was lost mid-session.
  final bool unavailable;

  /// Kit exercise: measured per voice from B.3 on — not yet.
  final bool kit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: kit
          ? 'Full-kit measurement is not available yet'
          : unavailable
              ? 'Not measurable with this setup'
              : analysis
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
                  Icon(
                      unavailable
                          ? Icons.mic_off
                          : source == StrokeSourceKind.midi
                              ? Icons.piano
                              : Icons.mic,
                      size: 16,
                      color: active
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
    required this.backingKit,
    required this.backingLevel,
    required this.extrasAllowed,
    required this.backingAllowed,
    required this.onBackingEnabled,
    required this.onBackingLevel,
    required this.onClickTrack,
    required this.showSticking,
    required this.showCounts,
    required this.onShowSticking,
    required this.onShowCounts,
    required this.onAbout,
  });

  /// Sheet switches (Blattform): sticking letters and count hints, global.
  final bool showSticking;
  final bool showCounts;
  final ValueChanged<bool> onShowSticking;
  final ValueChanged<bool> onShowCounts;

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

  /// Kit unit: the band plays the unit's own kick and hi-hat (on) or
  /// nothing (off), never a style.
  final bool backingKit;
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
  late bool _sticking = widget.showSticking;
  late bool _counts = widget.showCounts;

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
                    : widget.backingKit
                        ? (_backingOn
                            ? 'Band plays kick and hi-hat with you'
                            : 'Click only')
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
              key: const ValueKey('opt-click'),
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
            const SizedBox(height: 12),
            const _SectionLabel('SHEET'),
            SwitchListTile(
              key: const ValueKey('opt-sticking'),
              contentPadding: EdgeInsets.zero,
              title: Text('Sticking letters', style: PracticeTypography.body),
              subtitle: Text('R and L under every note',
                  style: PracticeTypography.body
                      .copyWith(fontSize: 13, color: PracticeColors.textMuted)),
              value: _sticking,
              onChanged: (on) {
                setState(() => _sticking = on);
                widget.onShowSticking(on);
              },
            ),
            SwitchListTile(
              key: const ValueKey('opt-counts'),
              contentPadding: EdgeInsets.zero,
              title: Text('Count hints', style: PracticeTypography.body),
              subtitle: Text('1 e + a under lines that carry them',
                  style: PracticeTypography.body
                      .copyWith(fontSize: 13, color: PracticeColors.textMuted)),
              value: _counts,
              onChanged: (on) {
                setState(() => _counts = on);
                widget.onShowCounts(on);
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
