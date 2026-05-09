// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allSessionsHash() => r'3561c477faabe83d749b04357923b78642273ce2';

/// See also [allSessions].
@ProviderFor(allSessions)
final allSessionsProvider =
    AutoDisposeFutureProvider<List<PracticeSession>>.internal(
  allSessions,
  name: r'allSessionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allSessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllSessionsRef = AutoDisposeFutureProviderRef<List<PracticeSession>>;
String _$allProgressHash() => r'dc665154fca0f401183105b21789f0d63d33013e';

/// See also [allProgress].
@ProviderFor(allProgress)
final allProgressProvider =
    AutoDisposeFutureProvider<List<RudimentProgress>>.internal(
  allProgress,
  name: r'allProgressProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllProgressRef = AutoDisposeFutureProviderRef<List<RudimentProgress>>;
String _$last14DaysMinutesHash() => r'6a53017e5a03d5f0d646533ec8162da325164e6d';

/// See also [last14DaysMinutes].
@ProviderFor(last14DaysMinutes)
final last14DaysMinutesProvider =
    AutoDisposeFutureProvider<List<DailyMinutes>>.internal(
  last14DaysMinutes,
  name: r'last14DaysMinutesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$last14DaysMinutesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef Last14DaysMinutesRef = AutoDisposeFutureProviderRef<List<DailyMinutes>>;
String _$streakDaysHash() => r'286e6c3c9848c1115a299ea16eb22b28e4597a21';

/// See also [streakDays].
@ProviderFor(streakDays)
final streakDaysProvider = AutoDisposeFutureProvider<int>.internal(
  streakDays,
  name: r'streakDaysProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$streakDaysHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StreakDaysRef = AutoDisposeFutureProviderRef<int>;
String _$bpmHistoryForRudimentHash() =>
    r'96b03be252e41835b8c9ba1b785b30ad23944ff0';

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

/// See also [bpmHistoryForRudiment].
@ProviderFor(bpmHistoryForRudiment)
const bpmHistoryForRudimentProvider = BpmHistoryForRudimentFamily();

/// See also [bpmHistoryForRudiment].
class BpmHistoryForRudimentFamily
    extends Family<AsyncValue<List<PracticeSession>>> {
  /// See also [bpmHistoryForRudiment].
  const BpmHistoryForRudimentFamily();

  /// See also [bpmHistoryForRudiment].
  BpmHistoryForRudimentProvider call(
    String rudimentId,
  ) {
    return BpmHistoryForRudimentProvider(
      rudimentId,
    );
  }

  @override
  BpmHistoryForRudimentProvider getProviderOverride(
    covariant BpmHistoryForRudimentProvider provider,
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
  String? get name => r'bpmHistoryForRudimentProvider';
}

/// See also [bpmHistoryForRudiment].
class BpmHistoryForRudimentProvider
    extends AutoDisposeFutureProvider<List<PracticeSession>> {
  /// See also [bpmHistoryForRudiment].
  BpmHistoryForRudimentProvider(
    String rudimentId,
  ) : this._internal(
          (ref) => bpmHistoryForRudiment(
            ref as BpmHistoryForRudimentRef,
            rudimentId,
          ),
          from: bpmHistoryForRudimentProvider,
          name: r'bpmHistoryForRudimentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bpmHistoryForRudimentHash,
          dependencies: BpmHistoryForRudimentFamily._dependencies,
          allTransitiveDependencies:
              BpmHistoryForRudimentFamily._allTransitiveDependencies,
          rudimentId: rudimentId,
        );

  BpmHistoryForRudimentProvider._internal(
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
    FutureOr<List<PracticeSession>> Function(BpmHistoryForRudimentRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BpmHistoryForRudimentProvider._internal(
        (ref) => create(ref as BpmHistoryForRudimentRef),
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
  AutoDisposeFutureProviderElement<List<PracticeSession>> createElement() {
    return _BpmHistoryForRudimentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BpmHistoryForRudimentProvider &&
        other.rudimentId == rudimentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rudimentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BpmHistoryForRudimentRef
    on AutoDisposeFutureProviderRef<List<PracticeSession>> {
  /// The parameter `rudimentId` of this provider.
  String get rudimentId;
}

class _BpmHistoryForRudimentProviderElement
    extends AutoDisposeFutureProviderElement<List<PracticeSession>>
    with BpmHistoryForRudimentRef {
  _BpmHistoryForRudimentProviderElement(super.provider);

  @override
  String get rudimentId => (origin as BpmHistoryForRudimentProvider).rudimentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
