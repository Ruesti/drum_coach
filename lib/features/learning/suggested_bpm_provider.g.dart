// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggested_bpm_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$suggestedBpmHash() => r'567165a149382accd683780ac12474c248339db8';

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

/// The BPM to start an exercise at: the tempo left off at last session
/// (already rating-adjusted by [BpmProgressionService] — struggled keeps it,
/// OK adds 2, solid adds 5), or the exercise's minimum tempo if it's never
/// been practiced. Used so starting any exercise picks up where that
/// exercise left off instead of carrying over whatever tempo another
/// exercise happened to be left at.
///
/// Copied from [suggestedBpm].
@ProviderFor(suggestedBpm)
const suggestedBpmProvider = SuggestedBpmFamily();

/// The BPM to start an exercise at: the tempo left off at last session
/// (already rating-adjusted by [BpmProgressionService] — struggled keeps it,
/// OK adds 2, solid adds 5), or the exercise's minimum tempo if it's never
/// been practiced. Used so starting any exercise picks up where that
/// exercise left off instead of carrying over whatever tempo another
/// exercise happened to be left at.
///
/// Copied from [suggestedBpm].
class SuggestedBpmFamily extends Family<AsyncValue<int>> {
  /// The BPM to start an exercise at: the tempo left off at last session
  /// (already rating-adjusted by [BpmProgressionService] — struggled keeps it,
  /// OK adds 2, solid adds 5), or the exercise's minimum tempo if it's never
  /// been practiced. Used so starting any exercise picks up where that
  /// exercise left off instead of carrying over whatever tempo another
  /// exercise happened to be left at.
  ///
  /// Copied from [suggestedBpm].
  const SuggestedBpmFamily();

  /// The BPM to start an exercise at: the tempo left off at last session
  /// (already rating-adjusted by [BpmProgressionService] — struggled keeps it,
  /// OK adds 2, solid adds 5), or the exercise's minimum tempo if it's never
  /// been practiced. Used so starting any exercise picks up where that
  /// exercise left off instead of carrying over whatever tempo another
  /// exercise happened to be left at.
  ///
  /// Copied from [suggestedBpm].
  SuggestedBpmProvider call(
    String rudimentId,
  ) {
    return SuggestedBpmProvider(
      rudimentId,
    );
  }

  @override
  SuggestedBpmProvider getProviderOverride(
    covariant SuggestedBpmProvider provider,
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
  String? get name => r'suggestedBpmProvider';
}

/// The BPM to start an exercise at: the tempo left off at last session
/// (already rating-adjusted by [BpmProgressionService] — struggled keeps it,
/// OK adds 2, solid adds 5), or the exercise's minimum tempo if it's never
/// been practiced. Used so starting any exercise picks up where that
/// exercise left off instead of carrying over whatever tempo another
/// exercise happened to be left at.
///
/// Copied from [suggestedBpm].
class SuggestedBpmProvider extends AutoDisposeFutureProvider<int> {
  /// The BPM to start an exercise at: the tempo left off at last session
  /// (already rating-adjusted by [BpmProgressionService] — struggled keeps it,
  /// OK adds 2, solid adds 5), or the exercise's minimum tempo if it's never
  /// been practiced. Used so starting any exercise picks up where that
  /// exercise left off instead of carrying over whatever tempo another
  /// exercise happened to be left at.
  ///
  /// Copied from [suggestedBpm].
  SuggestedBpmProvider(
    String rudimentId,
  ) : this._internal(
          (ref) => suggestedBpm(
            ref as SuggestedBpmRef,
            rudimentId,
          ),
          from: suggestedBpmProvider,
          name: r'suggestedBpmProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$suggestedBpmHash,
          dependencies: SuggestedBpmFamily._dependencies,
          allTransitiveDependencies:
              SuggestedBpmFamily._allTransitiveDependencies,
          rudimentId: rudimentId,
        );

  SuggestedBpmProvider._internal(
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
    FutureOr<int> Function(SuggestedBpmRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SuggestedBpmProvider._internal(
        (ref) => create(ref as SuggestedBpmRef),
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
  AutoDisposeFutureProviderElement<int> createElement() {
    return _SuggestedBpmProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SuggestedBpmProvider && other.rudimentId == rudimentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rudimentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SuggestedBpmRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `rudimentId` of this provider.
  String get rudimentId;
}

class _SuggestedBpmProviderElement extends AutoDisposeFutureProviderElement<int>
    with SuggestedBpmRef {
  _SuggestedBpmProviderElement(super.provider);

  @override
  String get rudimentId => (origin as SuggestedBpmProvider).rudimentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
