// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allSessionsHash() => r'52ec019b1f899f368001b187c5059ddeaa040d5e';

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
String _$allProgressHash() => r'0a5ab76926af1c0277e7927492858487a73be734';

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
String _$streakDaysHash() => r'48e4f5e12a577c6380c2a0a9fb7c01c46a95ad5d';

/// Current streak with a one-day grace, skipping scheduled program rest days.
/// See [computeCurrentStreak].
///
/// Copied from [streakDays].
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
String _$longestStreakHash() => r'ee85bd5d57b208c10df5e1d2fded644361bfa8f2';

/// The longest consecutive-day run ever recorded (no grace), bridging
/// scheduled program rest days. See [computeLongestStreak].
///
/// Copied from [longestStreak].
@ProviderFor(longestStreak)
final longestStreakProvider = AutoDisposeFutureProvider<int>.internal(
  longestStreak,
  name: r'longestStreakProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$longestStreakHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LongestStreakRef = AutoDisposeFutureProviderRef<int>;
String _$todayStatusHash() => r'da0a2897529d8adb80d68ea7124263e3f4985691';

/// Today's minutes vs. the user's daily goal.
///
/// Copied from [todayStatus].
@ProviderFor(todayStatus)
final todayStatusProvider = AutoDisposeFutureProvider<TodayStatus>.internal(
  todayStatus,
  name: r'todayStatusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todayStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TodayStatusRef = AutoDisposeFutureProviderRef<TodayStatus>;
String _$practiceCalendarHash() => r'79eae58fbc3f283416a167d963cc2f654e0524f8';

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

/// Per-day practice minutes for the last [days] days (oldest first), for the
/// calendar heatmap.
///
/// Copied from [practiceCalendar].
@ProviderFor(practiceCalendar)
const practiceCalendarProvider = PracticeCalendarFamily();

/// Per-day practice minutes for the last [days] days (oldest first), for the
/// calendar heatmap.
///
/// Copied from [practiceCalendar].
class PracticeCalendarFamily extends Family<AsyncValue<List<DailyMinutes>>> {
  /// Per-day practice minutes for the last [days] days (oldest first), for the
  /// calendar heatmap.
  ///
  /// Copied from [practiceCalendar].
  const PracticeCalendarFamily();

  /// Per-day practice minutes for the last [days] days (oldest first), for the
  /// calendar heatmap.
  ///
  /// Copied from [practiceCalendar].
  PracticeCalendarProvider call({
    int days = 119,
  }) {
    return PracticeCalendarProvider(
      days: days,
    );
  }

  @override
  PracticeCalendarProvider getProviderOverride(
    covariant PracticeCalendarProvider provider,
  ) {
    return call(
      days: provider.days,
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
  String? get name => r'practiceCalendarProvider';
}

/// Per-day practice minutes for the last [days] days (oldest first), for the
/// calendar heatmap.
///
/// Copied from [practiceCalendar].
class PracticeCalendarProvider
    extends AutoDisposeFutureProvider<List<DailyMinutes>> {
  /// Per-day practice minutes for the last [days] days (oldest first), for the
  /// calendar heatmap.
  ///
  /// Copied from [practiceCalendar].
  PracticeCalendarProvider({
    int days = 119,
  }) : this._internal(
          (ref) => practiceCalendar(
            ref as PracticeCalendarRef,
            days: days,
          ),
          from: practiceCalendarProvider,
          name: r'practiceCalendarProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceCalendarHash,
          dependencies: PracticeCalendarFamily._dependencies,
          allTransitiveDependencies:
              PracticeCalendarFamily._allTransitiveDependencies,
          days: days,
        );

  PracticeCalendarProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.days,
  }) : super.internal();

  final int days;

  @override
  Override overrideWith(
    FutureOr<List<DailyMinutes>> Function(PracticeCalendarRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeCalendarProvider._internal(
        (ref) => create(ref as PracticeCalendarRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        days: days,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<DailyMinutes>> createElement() {
    return _PracticeCalendarProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeCalendarProvider && other.days == days;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, days.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeCalendarRef on AutoDisposeFutureProviderRef<List<DailyMinutes>> {
  /// The parameter `days` of this provider.
  int get days;
}

class _PracticeCalendarProviderElement
    extends AutoDisposeFutureProviderElement<List<DailyMinutes>>
    with PracticeCalendarRef {
  _PracticeCalendarProviderElement(super.provider);

  @override
  int get days => (origin as PracticeCalendarProvider).days;
}

String _$bpmHistoryForRudimentHash() =>
    r'96b03be252e41835b8c9ba1b785b30ad23944ff0';

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
