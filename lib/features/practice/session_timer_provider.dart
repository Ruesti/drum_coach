import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_timer_provider.g.dart';

/// Elapsed seconds for the whole training session (may span several
/// exercises back-to-back), shown alongside the per-exercise lesson timer.
/// Ticks continuously once started; [reset] is called when the user returns
/// to the Dashboard.
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

  void startIfNeeded() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => state++);
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    state = 0;
  }
}
