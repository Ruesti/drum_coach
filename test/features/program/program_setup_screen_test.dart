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

    // Duration chips (4 / 8 / 12 weeks).
    expect(find.text('4 Wochen'), findsOneWidget);
    expect(find.text('8 Wochen'), findsOneWidget);
    expect(find.text('12 Wochen'), findsOneWidget);

    // Start-difficulty options.
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);

    // Pool options.
    expect(find.text('Klassische Schlagübungen'), findsOneWidget);
    expect(find.text('Neue Übungen'), findsOneWidget);
    expect(find.text('Gemischt'), findsOneWidget);

    // Start button.
    expect(find.text('Programm starten'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
