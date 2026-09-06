// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$trainingProgramHash() => r'23c9d465321c21f56b7de40699814fe3bf7df993';

/// A lightweight description of the current adaptive program run, built from
/// the persisted [ProgramConfig]. `phases` is intentionally empty — the
/// adaptive program has no fixed phase list; per-day content comes from
/// [currentProgramDay] instead.
///
/// Copied from [trainingProgram].
@ProviderFor(trainingProgram)
final trainingProgramProvider = AutoDisposeProvider<TrainingProgram>.internal(
  trainingProgram,
  name: r'trainingProgramProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trainingProgramHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TrainingProgramRef = AutoDisposeProviderRef<TrainingProgram>;
String _$programDayHash() => r'238c9096ae8db92a4641ba565c58c2e1ba8a09dd';

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

/// A single expanded program day for the current adaptive stage, with the
/// stored clean tempo folded in. Kept only for its generated provider
/// signature (family, non-nullable `Future<ProgramDay>`) — [currentProgramDay]
/// builds the day directly now and no longer routes through this provider,
/// so it throws if invoked with no config/stages rather than returning a
/// meaningless day for an arbitrary [dayNumber].
///
/// Copied from [programDay].
@ProviderFor(programDay)
const programDayProvider = ProgramDayFamily();

/// A single expanded program day for the current adaptive stage, with the
/// stored clean tempo folded in. Kept only for its generated provider
/// signature (family, non-nullable `Future<ProgramDay>`) — [currentProgramDay]
/// builds the day directly now and no longer routes through this provider,
/// so it throws if invoked with no config/stages rather than returning a
/// meaningless day for an arbitrary [dayNumber].
///
/// Copied from [programDay].
class ProgramDayFamily extends Family<AsyncValue<ProgramDay>> {
  /// A single expanded program day for the current adaptive stage, with the
  /// stored clean tempo folded in. Kept only for its generated provider
  /// signature (family, non-nullable `Future<ProgramDay>`) — [currentProgramDay]
  /// builds the day directly now and no longer routes through this provider,
  /// so it throws if invoked with no config/stages rather than returning a
  /// meaningless day for an arbitrary [dayNumber].
  ///
  /// Copied from [programDay].
  const ProgramDayFamily();

  /// A single expanded program day for the current adaptive stage, with the
  /// stored clean tempo folded in. Kept only for its generated provider
  /// signature (family, non-nullable `Future<ProgramDay>`) — [currentProgramDay]
  /// builds the day directly now and no longer routes through this provider,
  /// so it throws if invoked with no config/stages rather than returning a
  /// meaningless day for an arbitrary [dayNumber].
  ///
  /// Copied from [programDay].
  ProgramDayProvider call(
    int dayNumber,
  ) {
    return ProgramDayProvider(
      dayNumber,
    );
  }

  @override
  ProgramDayProvider getProviderOverride(
    covariant ProgramDayProvider provider,
  ) {
    return call(
      provider.dayNumber,
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
  String? get name => r'programDayProvider';
}

/// A single expanded program day for the current adaptive stage, with the
/// stored clean tempo folded in. Kept only for its generated provider
/// signature (family, non-nullable `Future<ProgramDay>`) — [currentProgramDay]
/// builds the day directly now and no longer routes through this provider,
/// so it throws if invoked with no config/stages rather than returning a
/// meaningless day for an arbitrary [dayNumber].
///
/// Copied from [programDay].
class ProgramDayProvider extends AutoDisposeFutureProvider<ProgramDay> {
  /// A single expanded program day for the current adaptive stage, with the
  /// stored clean tempo folded in. Kept only for its generated provider
  /// signature (family, non-nullable `Future<ProgramDay>`) — [currentProgramDay]
  /// builds the day directly now and no longer routes through this provider,
  /// so it throws if invoked with no config/stages rather than returning a
  /// meaningless day for an arbitrary [dayNumber].
  ///
  /// Copied from [programDay].
  ProgramDayProvider(
    int dayNumber,
  ) : this._internal(
          (ref) => programDay(
            ref as ProgramDayRef,
            dayNumber,
          ),
          from: programDayProvider,
          name: r'programDayProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$programDayHash,
          dependencies: ProgramDayFamily._dependencies,
          allTransitiveDependencies:
              ProgramDayFamily._allTransitiveDependencies,
          dayNumber: dayNumber,
        );

  ProgramDayProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dayNumber,
  }) : super.internal();

  final int dayNumber;

  @override
  Override overrideWith(
    FutureOr<ProgramDay> Function(ProgramDayRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProgramDayProvider._internal(
        (ref) => create(ref as ProgramDayRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dayNumber: dayNumber,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ProgramDay> createElement() {
    return _ProgramDayProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramDayProvider && other.dayNumber == dayNumber;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dayNumber.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ProgramDayRef on AutoDisposeFutureProviderRef<ProgramDay> {
  /// The parameter `dayNumber` of this provider.
  int get dayNumber;
}

class _ProgramDayProviderElement
    extends AutoDisposeFutureProviderElement<ProgramDay> with ProgramDayRef {
  _ProgramDayProviderElement(super.provider);

  @override
  int get dayNumber => (origin as ProgramDayProvider).dayNumber;
}

String _$currentProgramDayHash() => r'e04cd8cff6be77e0acf5796d01314822fa2e8706';

/// The current program day derived from the stored config + start date, or
/// null if the program has not been started, has no config, has no exercises
/// for the configured pool/difficulty, or has run past its final day.
///
/// Copied from [currentProgramDay].
@ProviderFor(currentProgramDay)
final currentProgramDayProvider =
    AutoDisposeFutureProvider<ProgramDay?>.internal(
  currentProgramDay,
  name: r'currentProgramDayProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentProgramDayHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentProgramDayRef = AutoDisposeFutureProviderRef<ProgramDay?>;
String _$programDayCompletionHash() =>
    r'658d0b9ba3327ab6191f53a3ad7685b6b4430d27';

/// Which of today's program-day blocks already count as done, derived from
/// today's finished practice sessions (ordinal per exercise key — see
/// [completedBlockIndices]). Empty when no program day is active.
///
/// Copied from [programDayCompletion].
@ProviderFor(programDayCompletion)
final programDayCompletionProvider =
    AutoDisposeFutureProvider<Set<int>>.internal(
  programDayCompletion,
  name: r'programDayCompletionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$programDayCompletionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProgramDayCompletionRef = AutoDisposeFutureProviderRef<Set<int>>;
String _$cleanTempoNotifierHash() =>
    r'93a2942f9d03e4270d9246110175258327d467fd';

/// Stored clean tempos keyed by exercise key (the last clean tempo per line).
///
/// Copied from [CleanTempoNotifier].
@ProviderFor(CleanTempoNotifier)
final cleanTempoNotifierProvider = AutoDisposeAsyncNotifierProvider<
    CleanTempoNotifier, Map<String, int>>.internal(
  CleanTempoNotifier.new,
  name: r'cleanTempoNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cleanTempoNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CleanTempoNotifier = AutoDisposeAsyncNotifier<Map<String, int>>;
String _$programControllerHash() => r'0ae3bf79df077a6c852a42ad8ab8cacdf71f2333';

/// Controls program lifecycle (start / reset / stage advance).
///
/// Copied from [ProgramController].
@ProviderFor(ProgramController)
final programControllerProvider =
    AutoDisposeNotifierProvider<ProgramController, void>.internal(
  ProgramController.new,
  name: r'programControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$programControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProgramController = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
