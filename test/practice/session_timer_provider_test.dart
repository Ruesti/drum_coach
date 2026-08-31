import 'package:drum_coach/features/practice/session_timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionTimerNotifier', () {
    test('starts at zero and ticks once started', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(sessionTimerNotifierProvider), 0);

      container.read(sessionTimerNotifierProvider.notifier).startIfNeeded();
      await Future<void>.delayed(const Duration(milliseconds: 2200));

      expect(container.read(sessionTimerNotifierProvider), greaterThanOrEqualTo(2));
    });

    test('starting twice does not double the tick rate', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sessionTimerNotifierProvider.notifier);
      notifier.startIfNeeded();
      notifier.startIfNeeded(); // no-op: a ticker is already running
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(container.read(sessionTimerNotifierProvider), 1);
    });

    test('reset stops the ticker and zeroes the count', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sessionTimerNotifierProvider.notifier);
      notifier.startIfNeeded();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(container.read(sessionTimerNotifierProvider), greaterThanOrEqualTo(1));

      notifier.reset();
      expect(container.read(sessionTimerNotifierProvider), 0);

      // Confirm the ticker really stopped, not just that state was zeroed once.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(container.read(sessionTimerNotifierProvider), 0);
    });
  });
}
