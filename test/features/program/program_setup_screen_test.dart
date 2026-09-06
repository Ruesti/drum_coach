import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/program/program_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });

  testWidgets(
      'renders duration, difficulty and pool choice groups plus a start '
      'button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProgramSetupScreen()),
      ),
    );

    // Duration is a free-form slider (default 8 weeks), not preset chips.
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Wochen'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    // Start-difficulty options.
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);

    // Pool options — one per exercise source plus "mixed".
    expect(find.text('Klassische Schlagübungen'), findsOneWidget);
    expect(find.text('Rudiment-Étüden'), findsOneWidget);
    expect(find.text('Technik-Studien'), findsOneWidget);
    expect(find.text('Pad-Workouts'), findsOneWidget);
    expect(find.text('Gemischt'), findsOneWidget);

    // Start button.
    expect(find.text('Programm starten'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('duration slider allows free week selection, not just presets',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProgramSetupScreen()),
      ),
    );
    expect(find.text('8'), findsOneWidget);

    // Drag the slider to its maximum — any week count should be reachable,
    // not just the old 4/8/12 presets.
    await tester.drag(find.byType(Slider), const Offset(1000, 0));
    await tester.pumpAndSettle();

    expect(find.text('8'), findsNothing);
    // "24" now appears twice: the big current-value display and the
    // slider's static max-range label below it.
    expect(find.text('24'), findsNWidgets(2));
  });

  testWidgets(
      'starting a program pops back to /program instead of collapsing the '
      'whole nav stack', (tester) async {
    // /program lives outside the bottom-nav shell (see router.dart), so
    // context.go('/program') after starting would replace the *entire*
    // stack with just /program — nothing left below it to pop to (no
    // AppBar back button, system back exits the app instead of navigating).
    // _start() must context.pop() back to the existing /program screen
    // instead, leaving whatever was under it (here: '/') intact.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('root'))),
        GoRoute(path: '/program', builder: (_, __) => const Scaffold(body: Text('program'))),
        GoRoute(path: '/program/setup', builder: (_, __) => const ProgramSetupScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    router.push('/program');
    await tester.pumpAndSettle();
    router.push('/program/setup');
    await tester.pumpAndSettle();
    expect(find.byType(ProgramSetupScreen), findsOneWidget);

    await tester.tap(find.text('Programm starten'));
    await tester.pumpAndSettle();

    expect(find.text('program'), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigator.canPop(), isTrue,
        reason: 'root ("/") must still be reachable by popping once more');
  });
}
