import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:drum_coach/features/metronome/metronome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stops the metronome when navigating away from the screen while playing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );

    // Push MetronomeScreen — this is the "navigate to the metronome" step.
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const MetronomeScreen()),
    );
    await tester.pumpAndSettle();

    container.read(metronomeNotifierProvider.notifier).start();
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).isPlaying, isTrue,
        reason: 'precondition: metronome must be playing before we leave the screen');

    // Pop MetronomeScreen off the stack — this disposes it, exactly like
    // tapping the back button or switching bottom-nav tabs on a real device.
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.pump(); // let the deferred stop() microtask run

    expect(container.read(metronomeNotifierProvider).isPlaying, isFalse,
        reason: 'metronome keeps ticking in the background after leaving the '
            'screen unless dispose() stops it — this is what caused the '
            'repeating "defunct element" crash on a real device');
  });
}
