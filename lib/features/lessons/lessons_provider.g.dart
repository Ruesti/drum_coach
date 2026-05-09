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
String _$groupedRudimentsHash() => r'60eced3bd6c1e2f0946872070e65f90f0fdead66';

/// See also [groupedRudiments].
@ProviderFor(groupedRudiments)
final groupedRudimentsProvider =
    AutoDisposeProvider<Map<String, List<Rudiment>>>.internal(
  groupedRudiments,
  name: r'groupedRudimentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupedRudimentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GroupedRudimentsRef
    = AutoDisposeProviderRef<Map<String, List<Rudiment>>>;
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
