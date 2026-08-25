import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/program/program_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
