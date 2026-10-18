import 'dart:io';

import 'package:drum_coach/app/app_version.dart';
import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    debugDesktopOverride = false;
  });
  tearDown(() => debugDesktopOverride = null);

  test('app version matches pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    expect(line.substring('version:'.length).trim(), appVersion);
  });

  testWidgets('long press on the version line opens /debug/guided',
      (tester) async {
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('ink splashes')) return;
      onError?.call(details);
    };
    addTearDown(() => FlutterError.onError = onError);
    final router = GoRouter(initialLocation: '/settings', routes: [
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/debug/guided',
          builder: (_, __) => const Scaffold(body: Text('GUIDED PAGE'))),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    final version = find.byKey(const ValueKey('settings-version'));
    await tester.scrollUntilVisible(version, 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Version $appVersion'), findsOneWidget);
    await tester.tap(version);
    await tester.pumpAndSettle();
    expect(find.text('GUIDED PAGE'), findsNothing);
    await tester.longPress(version);
    await tester.pumpAndSettle();
    expect(find.text('GUIDED PAGE'), findsOneWidget);
  });
}
