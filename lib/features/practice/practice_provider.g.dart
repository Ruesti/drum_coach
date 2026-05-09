// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recentSessionsHash() => r'bc6a5934d5b645761fd5f584a296467bf3af579b';

/// See also [recentSessions].
@ProviderFor(recentSessions)
final recentSessionsProvider =
    AutoDisposeFutureProvider<List<PracticeSession>>.internal(
  recentSessions,
  name: r'recentSessionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentSessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RecentSessionsRef = AutoDisposeFutureProviderRef<List<PracticeSession>>;
String _$practiceNotifierHash() => r'2e3c0556569a80849f5bc968300c50098498e4ad';

/// See also [PracticeNotifier].
@ProviderFor(PracticeNotifier)
final practiceNotifierProvider =
    AutoDisposeNotifierProvider<PracticeNotifier, void>.internal(
  PracticeNotifier.new,
  name: r'practiceNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PracticeNotifier = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
