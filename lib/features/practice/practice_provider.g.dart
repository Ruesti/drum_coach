// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recentSessionsHash() => r'1d78965a8c4ea5726375813397648cebd55e722c';

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
String _$practiceNotifierHash() => r'df8d10b45d323e9837af2ff1cfa485f7167b32df';

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
