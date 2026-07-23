// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$trainingProgramHash() => r'a699fa1b0e4135c1d83bbd81ccc7c9841a8a22bb';

/// See also [trainingProgram].
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
String _$programDayHash() => r'b2be4961703b783f683b36cd3bad883f6d536566';

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

/// A single expanded program day, with the stored clean tempo folded in.
///
/// Copied from [programDay].
@ProviderFor(programDay)
const programDayProvider = ProgramDayFamily();

/// A single expanded program day, with the stored clean tempo folded in.
///
/// Copied from [programDay].
class ProgramDayFamily extends Family<AsyncValue<ProgramDay>> {
  /// A single expanded program day, with the stored clean tempo folded in.
  ///
  /// Copied from [programDay].
  const ProgramDayFamily();

  /// A single expanded program day, with the stored clean tempo folded in.
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

/// A single expanded program day, with the stored clean tempo folded in.
///
/// Copied from [programDay].
class ProgramDayProvider extends AutoDisposeFutureProvider<ProgramDay> {
  /// A single expanded program day, with the stored clean tempo folded in.
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

String _$currentProgramDayHash() => r'ef41f142018a5f49580668e54f177999f862fc89';

/// The current program day derived from the stored start date, or null if the
/// program has not been started (or has run past its final day).
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
String _$cleanTempoNotifierHash() =>
    r'd7aa3ea7b962beb26a5cf6033b85e8afc3e0ee97';

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
String _$programControllerHash() => r'45258b13d8f502f05a210e562a42f9d89d0ae497';

/// Controls program lifecycle (start / reset).
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
