// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$exerciseStartBpmHash() => r'c2a238d06c4af5b822ffaaecdabd26c3a10bbc24';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// The suggested start tempo for an exercise: the BPM progression's current
/// value (lifted +2/+5 by session ratings), or null if never practiced or
/// the store is unavailable. Practice sessions preset the metronome with
/// this so tempo never leaks over from a previously played exercise.
///
/// Copied from [exerciseStartBpm].
@ProviderFor(exerciseStartBpm)
const exerciseStartBpmProvider = ExerciseStartBpmFamily();

/// The suggested start tempo for an exercise: the BPM progression's current
/// value (lifted +2/+5 by session ratings), or null if never practiced or
/// the store is unavailable. Practice sessions preset the metronome with
/// this so tempo never leaks over from a previously played exercise.
///
/// Copied from [exerciseStartBpm].
class ExerciseStartBpmFamily extends Family<AsyncValue<int?>> {
  /// The suggested start tempo for an exercise: the BPM progression's current
  /// value (lifted +2/+5 by session ratings), or null if never practiced or
  /// the store is unavailable. Practice sessions preset the metronome with
  /// this so tempo never leaks over from a previously played exercise.
  ///
  /// Copied from [exerciseStartBpm].
  const ExerciseStartBpmFamily();

  /// The suggested start tempo for an exercise: the BPM progression's current
  /// value (lifted +2/+5 by session ratings), or null if never practiced or
  /// the store is unavailable. Practice sessions preset the metronome with
  /// this so tempo never leaks over from a previously played exercise.
  ///
  /// Copied from [exerciseStartBpm].
  ExerciseStartBpmProvider call(
    String rudimentId,
  ) {
    return ExerciseStartBpmProvider(
      rudimentId,
    );
  }

  @override
  ExerciseStartBpmProvider getProviderOverride(
    covariant ExerciseStartBpmProvider provider,
  ) {
    return call(
      provider.rudimentId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'exerciseStartBpmProvider';
}

/// The suggested start tempo for an exercise: the BPM progression's current
/// value (lifted +2/+5 by session ratings), or null if never practiced or
/// the store is unavailable. Practice sessions preset the metronome with
/// this so tempo never leaks over from a previously played exercise.
///
/// Copied from [exerciseStartBpm].
class ExerciseStartBpmProvider extends AutoDisposeFutureProvider<int?> {
  /// The suggested start tempo for an exercise: the BPM progression's current
  /// value (lifted +2/+5 by session ratings), or null if never practiced or
  /// the store is unavailable. Practice sessions preset the metronome with
  /// this so tempo never leaks over from a previously played exercise.
  ///
  /// Copied from [exerciseStartBpm].
  ExerciseStartBpmProvider(
    String rudimentId,
  ) : this._internal(
          (ref) => exerciseStartBpm(
            ref as ExerciseStartBpmRef,
            rudimentId,
          ),
          from: exerciseStartBpmProvider,
          name: r'exerciseStartBpmProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$exerciseStartBpmHash,
          dependencies: ExerciseStartBpmFamily._dependencies,
          allTransitiveDependencies:
              ExerciseStartBpmFamily._allTransitiveDependencies,
          rudimentId: rudimentId,
        );

  ExerciseStartBpmProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rudimentId,
  }) : super.internal();

  final String rudimentId;

  @override
  Override overrideWith(
    FutureOr<int?> Function(ExerciseStartBpmRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExerciseStartBpmProvider._internal(
        (ref) => create(ref as ExerciseStartBpmRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rudimentId: rudimentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int?> createElement() {
    return _ExerciseStartBpmProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseStartBpmProvider && other.rudimentId == rudimentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rudimentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ExerciseStartBpmRef on AutoDisposeFutureProviderRef<int?> {
  /// The parameter `rudimentId` of this provider.
  String get rudimentId;
}

class _ExerciseStartBpmProviderElement
    extends AutoDisposeFutureProviderElement<int?> with ExerciseStartBpmRef {
  _ExerciseStartBpmProviderElement(super.provider);

  @override
  String get rudimentId => (origin as ExerciseStartBpmProvider).rudimentId;
}

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
String _$practiceNotifierHash() => r'd137557a4124b3da88cd7a877068a52e9ebaad8b';

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
