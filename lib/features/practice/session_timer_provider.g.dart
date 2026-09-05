// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_timer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionTimerNotifierHash() =>
    r'8052a01cb7ca910c699f57d19372342495899c27';

/// Elapsed seconds for the whole training session (may span several
/// exercises back-to-back), shown alongside the per-exercise lesson timer.
/// Ticks continuously once started; [reset] is called when the user returns
/// to the Dashboard.
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
