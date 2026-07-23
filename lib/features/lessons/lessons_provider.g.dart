// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lessons_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$rudimentsHash() => r'd2549f377d40c632ac2c37641824e6941610badb';

/// See also [rudiments].
@ProviderFor(rudiments)
final rudimentsProvider = AutoDisposeProvider<List<Rudiment>>.internal(
  rudiments,
  name: r'rudimentsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$rudimentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RudimentsRef = AutoDisposeProviderRef<List<Rudiment>>;
String _$rudimentByIdHash() => r'bbc3e6a6c61a389a406561b782fa62c50f0200ed';

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

/// See also [rudimentById].
@ProviderFor(rudimentById)
const rudimentByIdProvider = RudimentByIdFamily();

/// See also [rudimentById].
class RudimentByIdFamily extends Family<Rudiment> {
  /// See also [rudimentById].
  const RudimentByIdFamily();

  /// See also [rudimentById].
  RudimentByIdProvider call(
    String id,
  ) {
    return RudimentByIdProvider(
      id,
    );
  }

  @override
  RudimentByIdProvider getProviderOverride(
    covariant RudimentByIdProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'rudimentByIdProvider';
}

/// See also [rudimentById].
class RudimentByIdProvider extends AutoDisposeProvider<Rudiment> {
  /// See also [rudimentById].
  RudimentByIdProvider(
    String id,
  ) : this._internal(
          (ref) => rudimentById(
            ref as RudimentByIdRef,
            id,
          ),
          from: rudimentByIdProvider,
          name: r'rudimentByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$rudimentByIdHash,
          dependencies: RudimentByIdFamily._dependencies,
          allTransitiveDependencies:
              RudimentByIdFamily._allTransitiveDependencies,
          id: id,
        );

  RudimentByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    Rudiment Function(RudimentByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RudimentByIdProvider._internal(
        (ref) => create(ref as RudimentByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Rudiment> createElement() {
    return _RudimentByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RudimentByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RudimentByIdRef on AutoDisposeProviderRef<Rudiment> {
  /// The parameter `id` of this provider.
  String get id;
}

class _RudimentByIdProviderElement extends AutoDisposeProviderElement<Rudiment>
    with RudimentByIdRef {
  _RudimentByIdProviderElement(super.provider);

  @override
  String get id => (origin as RudimentByIdProvider).id;
}

String _$availableSkillsHash() => r'9908e7093b80267c4a7faf7bd7b9e36daf8eae72';

/// Skills actually present on at least one seed rudiment, in [Skill] enum
/// order. Used to drive the skill filter chip row so chips that would
/// always dead-end on an empty result (e.g. no rudiment is tagged
/// `Skill.groove` or `Skill.fill` today) aren't rendered.
///
/// Copied from [availableSkills].
@ProviderFor(availableSkills)
final availableSkillsProvider = AutoDisposeProvider<List<Skill>>.internal(
  availableSkills,
  name: r'availableSkillsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableSkillsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AvailableSkillsRef = AutoDisposeProviderRef<List<Skill>>;
String _$filteredRudimentsHash() => r'c6232dd82b421c53ee11342091bb06d8ab58bff2';

/// See also [filteredRudiments].
@ProviderFor(filteredRudiments)
final filteredRudimentsProvider = AutoDisposeProvider<List<Rudiment>>.internal(
  filteredRudiments,
  name: r'filteredRudimentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredRudimentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredRudimentsRef = AutoDisposeProviderRef<List<Rudiment>>;
String _$lessonsFilterHash() => r'd3710f75d6167680cb2244965d81672565b38f60';

/// See also [LessonsFilter].
@ProviderFor(LessonsFilter)
final lessonsFilterProvider =
    AutoDisposeNotifierProvider<LessonsFilter, LessonsFilterState>.internal(
  LessonsFilter.new,
  name: r'lessonsFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonsFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LessonsFilter = AutoDisposeNotifier<LessonsFilterState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
