import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/settings/sequence_repeats_row.dart';
import 'package:drum_coach/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    debugDesktopOverride = false;
  });
  tearDown(() => debugDesktopOverride = null);

  testWidgets('LINE SEQUENCES: shows the repeats, a tap saves them',
      (tester) async {
    // The screen's ListTiles sit in colored cards (pre-existing, outside
    // this test): Flutter's debug hint about hidden ink splashes is noise.
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('ink splashes')) return;
      onError?.call(details);
    };
    addTearDown(() => FlutterError.onError = onError);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();
    expect(find.text('LINE SEQUENCES'), findsOneWidget);
    expect(
        find.text(
            'Each selected line plays this many times before the next one.'),
        findsOneWidget);
    expect(
        tester
            .widget<SequenceRepeatsRow>(find.byType(SequenceRepeatsRow))
            .value,
        2);
    await tester.ensureVisible(find.byKey(const ValueKey('repeats-4')));
    await tester.tap(find.byKey(const ValueKey('repeats-4')));
    await tester.pump();
    expect(SettingsService.sequenceRepeats, 4);
    expect(
        tester
            .widget<SequenceRepeatsRow>(find.byType(SequenceRepeatsRow))
            .value,
        4);
  });

  testWidgets('Settings has a Credits entry', (tester) async {
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('ink splashes')) return;
      onError?.call(details);
    };
    addTearDown(() => FlutterError.onError = onError);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();
    final entry = find.byKey(const ValueKey('settings-credits'));
    await tester.scrollUntilVisible(entry, 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.descendant(of: entry, matching: find.text('Credits')),
        findsOneWidget);
  });
}
