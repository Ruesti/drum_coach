import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_timer_provider.g.dart';

/// Elapsed seconds of actual playing time for the whole training session
/// (may span several exercises back-to-back), shown alongside the
/// per-exercise lesson timer. Mirrors the lesson timer's own play/pause
/// behavior — [resume]/[pause] are called in lockstep with the metronome's
/// isPlaying transitions, so this only counts while an exercise is actually
/// being played, not time spent paused or browsing between exercises.
/// [reset] is called when the user returns to the Dashboard.
@Riverpod(keepAlive: true)
class SessionTimerNotifier extends _$SessionTimerNotifier {
  Timer? _ticker;

  @override
  int build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _ticker = null;
    });
    return 0;
  }

  void resume() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => state++);
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
  }

  void reset() {
    pause();
    state = 0;
  }
}
