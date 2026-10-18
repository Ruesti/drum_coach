import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/platform_support.dart';
import '../../app/theme.dart';
import '../practice/practice_shortcuts.dart';
import 'data/demo_exercise.dart';
import 'guided_player.dart';
import 'guided_rig_provider.dart';
import 'models/guided_exercise.dart';
import 'models/voice_clip.dart';
import 'run_clock.dart';
import 'run_plan.dart';

/// Tempo step of the ± buttons and keys.
const int guidedBpmStep = 4;

/// `Section 3 of 9 · Variation 1 · bar 5 · beat 2` (count-in: `Count-in ·
/// beat 2`).
String guidedStatusLine(GuidedExercise ex, RunPosition p) {
  if (p.sectionIndex < 0) return 'Count-in · beat ${p.beat}';
  final s = ex.sections[p.sectionIndex];
  final label = switch (s.kind) {
    SectionKind.intro => 'Intro',
    SectionKind.groove => 'Groove',
    SectionKind.outro => 'Outro',
    SectionKind.variation =>
      'Variation ${ex.sections.take(p.sectionIndex + 1).where((x) => x.kind == SectionKind.variation).length}',
  };
  return 'Section ${p.sectionIndex + 1} of ${ex.sections.length} · $label'
      ' · bar ${p.barInSection + 1} · beat ${p.beat}';
}

/// The explanation of the variation that is playing ([coming] false) or of
/// the one that comes next ([coming] true); null when none is left.
({bool coming, String text})? guidedVariationText(
    GuidedExercise ex, int sectionIndex) {
  if (sectionIndex >= 0 &&
      ex.sections[sectionIndex].kind == SectionKind.variation) {
    return (coming: false, text: ex.sections[sectionIndex].textEn!);
  }
  for (var i = math.max(0, sectionIndex + 1); i < ex.sections.length; i++) {
    if (ex.sections[i].kind == SectionKind.variation) {
      return (coming: true, text: ex.sections[i].textEn!);
    }
  }
  return null;
}

String _mmss(double ms) {
  final s = (ms / 1000).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Hidden listening page (`/debug/guided`, long press on the version line
/// in Settings): plays a whole guided demo exercise — count-in, crash,
/// groove, explanation, countdown, variations, outro crash.
class DebugGuidedScreen extends ConsumerWidget {
  const DebugGuidedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rig = ref.watch(guidedRigProvider);
    return Theme(
      data: drumCoachPracticeTheme,
      child: rig.when(
        data: (r) => _GuidedPage(rig: r),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Guided demo')),
          body: Center(
            child: Text('Could not load the player: $e',
                style: const TextStyle(color: PracticeColors.struggled)),
          ),
        ),
      ),
    );
  }
}

class _GuidedPage extends StatefulWidget {
  const _GuidedPage({required this.rig});
  final GuidedRig rig;

  @override
  State<_GuidedPage> createState() => _GuidedPageState();
}

class _GuidedPageState extends State<_GuidedPage> {
  GuidedPlayer get _player => widget.rig.player;
  ClipManifest get _clips => widget.rig.clips;

  GuidedExercise _ex = demoKitExercise;
  late int _bpm = _ex.defaultBpm;
  RunOptions _options = const RunOptions();
  bool _running = false;
  bool _paused = false;

  /// start() is in flight: Start/Pause taps are ignored meanwhile.
  bool _starting = false;
  RunPosition? _pos;
  String? _error;

  /// Planned bar lengths at the current tempo/options (time estimate).
  List<double> _barMs = const [];

  final _subs = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    assert(() {
      GuidedPlayer.debugLogRenderTimes = true;
      return true;
    }());
    _subs
      ..add(_player.positions.listen((p) => setState(() => _pos = p)))
      // A failed run stops appending; reset the page to stopped.
      ..add(_player.errors.listen((e) {
        setState(() {
          _error = '$e';
          _running = false;
          _paused = false;
        });
        unawaited(_player.stop());
      }))
      // A frozen position paused the run on its own: show Resume.
      ..add(_player.stateChanges.listen((_) => setState(() {})))
      ..add(_player.finished.listen((_) => setState(() {
            _running = false;
            _paused = false;
          })));
    _replanTime();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    // The provider disposes the player; stop now so the run does not
    // outlive the page while the provider winds down.
    unawaited(_player.stop());
    assert(() {
      GuidedPlayer.debugLogRenderTimes = false;
      return true;
    }());
    super.dispose();
  }

  void _replanTime() {
    _barMs = [
      for (final b
          in buildRun(_ex, bpm: _bpm, options: _options, clips: _clips))
        guidedBeatsPerBar * 60000 / b.bpm
    ];
  }

  double get _totalMs => _barMs.fold(0.0, (a, b) => a + b);

  double get _elapsedMs {
    final p = _pos;
    if (p == null) return 0;
    final before = _barMs.take(p.bar).fold(0.0, (a, b) => a + b);
    final bar = p.bar < _barMs.length ? _barMs[p.bar] : 0.0;
    return math.min(_totalMs, before + bar * p.tick / runTicksPerBar);
  }

  void _choose(GuidedExercise ex) {
    if (_running || identical(ex, _ex)) return;
    setState(() {
      _ex = ex;
      _bpm = ex.defaultBpm;
      _pos = null;
      _replanTime();
    });
  }

  /// Paused by the user or by a frozen position.
  bool get _showResume => _paused || _player.isFrozen;

  Future<void> _toggle() async {
    if (_starting) return;
    if (!_running) {
      setState(() {
        _running = true;
        _paused = false;
        _starting = true;
        _error = null;
        _pos = null;
      });
      try {
        await _player.start(_ex, bpm: _bpm, options: _options);
      } finally {
        if (mounted) setState(() => _starting = false);
      }
    } else if (_showResume) {
      _player.resume();
      setState(() => _paused = false);
    } else {
      _player.pause();
      setState(() => _paused = true);
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _running = false;
      _paused = false;
      _pos = null;
    });
  }

  void _bump(int delta) {
    final next = (_bpm + delta)
        .clamp(math.max(guidedMinBpm, _ex.minBpm),
            math.min(guidedMaxBpm, _ex.maxBpm))
        .toInt();
    if (next == _bpm) return;
    _player.setBpm(next);
    setState(() {
      _bpm = next;
      _replanTime();
    });
  }

  void _setOptions(RunOptions o) {
    _player.setOptions(o);
    setState(() {
      _options = o;
      _replanTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pos = _pos;
    final text = guidedVariationText(_ex, pos?.sectionIndex ?? -1);
    final total = _totalMs;
    final elapsed = _elapsedMs;
    final scaffold = Scaffold(
      appBar: AppBar(title: const Text('Guided demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            Text('Error: $_error',
                key: const ValueKey('guided-error'),
                style: const TextStyle(color: PracticeColors.struggled)),
            const SizedBox(height: 12),
          ],
          SegmentedButton<GuidedExercise>(
            segments: [
              ButtonSegment(
                  value: demoKitExercise, label: const Text('Kit demo')),
              ButtonSegment(
                  value: demoPadExercise, label: const Text('Pad demo')),
            ],
            selected: {_ex},
            onSelectionChanged: _running ? null : (s) => _choose(s.first),
          ),
          const SizedBox(height: 8),
          Text(_ex.description,
              style: const TextStyle(color: PracticeColors.textMuted)),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton.filledTonal(
                key: const ValueKey('guided-bpm-down'),
                tooltip: 'Slower',
                onPressed: () => _bump(-guidedBpmStep),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('$_bpm',
                        style: const TextStyle(
                            fontSize: 40, fontWeight: FontWeight.w600)),
                    Text('BPM · ${_ex.minBpm}–${_ex.maxBpm}',
                        style:
                            const TextStyle(color: PracticeColors.textMuted)),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey('guided-bpm-up'),
                tooltip: 'Faster',
                onPressed: () => _bump(guidedBpmStep),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('guided-start'),
                  style: FilledButton.styleFrom(
                      backgroundColor: PracticeColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _toggle,
                  icon: Icon(!_running || _showResume
                      ? Icons.play_arrow
                      : Icons.pause),
                  label: Text(!_running
                      ? 'Start'
                      : _showResume
                          ? 'Resume'
                          : 'Pause'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('guided-stop'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _running ? _stop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey('guided-teacher'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Teacher'),
            subtitle: const Text('Voice: count-in, explanations, countdown'),
            value: _options.teacher,
            onChanged: (v) => _setOptions(
                RunOptions(teacher: v, playAlong: _options.playAlong)),
          ),
          SwitchListTile(
            key: const ValueKey('guided-playalong'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Play along'),
            subtitle: const Text('Off: only a quarter click'),
            value: _options.playAlong,
            onChanged: (v) => _setOptions(
                RunOptions(teacher: _options.teacher, playAlong: v)),
          ),
          const Divider(height: 32),
          Text(
              pos == null
                  ? (_running ? 'Starting…' : 'Stopped')
                  : guidedStatusLine(_ex, pos),
              key: const ValueKey('guided-status'),
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          if (text != null) ...[
            Text(text.coming ? 'COMING UP' : 'NOW',
                style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: PracticeColors.textMuted)),
            const SizedBox(height: 4),
            Text(text.text,
                key: const ValueKey('guided-text'),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: text.coming
                        ? PracticeColors.textSecondary
                        : PracticeColors.live)),
          ],
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: total > 0 ? elapsed / total : 0,
            minHeight: 6,
            color: PracticeColors.accent,
            backgroundColor: PracticeColors.raised,
          ),
          const SizedBox(height: 6),
          Text('${_mmss(elapsed)} / ~${_mmss(total)}',
              style: const TextStyle(color: PracticeColors.textMuted)),
          if (isDesktopPlatform) ...[
            const SizedBox(height: 24),
            const Text('Keys: Space start/pause · ↑↓ or +/− tempo · Esc stop',
                style: TextStyle(color: PracticeColors.textFaint)),
          ],
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: isDesktopPlatform
          ? CallbackShortcuts(
              bindings: practiceShortcuts(
                toggle: () => unawaited(_toggle()),
                bumpBpm: (d) => _bump(d.sign * guidedBpmStep),
                leave: () {
                  if (_running) {
                    unawaited(_stop());
                  } else {
                    unawaited(Navigator.maybePop(context));
                  }
                },
              ),
              child: Focus(autofocus: true, child: scaffold),
            )
          : scaffold,
    );
  }
}
