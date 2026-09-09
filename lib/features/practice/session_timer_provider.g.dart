// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_timer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionTimerNotifierHash() =>
    r'baea1c9b2fb81a3e5f0f3f70ac58e8d5ead0cf44';

/// Elapsed seconds of actual playing time for the whole training session
/// (may span several exercises back-to-back), shown alongside the
/// per-exercise lesson timer. Mirrors the lesson timer's own play/pause
/// behavior — [resume]/[pause] are called in lockstep with the metronome's
/// isPlaying transitions, so this only counts while an exercise is actually
/// being played, not time spent paused or browsing between exercises.
/// [reset] is called when the user returns to the Dashboard.
///
/// Copied from [SessionTimerNotifier].
@ProviderFor(SessionTimerNotifier)
final sessionTimerNotifierProvider =
    NotifierProvider<SessionTimerNotifier, int>.internal(
  SessionTimerNotifier.new,
  name: r'sessionTimerNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sessionTimerNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SessionTimerNotifier = Notifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
