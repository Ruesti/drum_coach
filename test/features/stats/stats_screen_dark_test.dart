import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/features/stats/stats_provider.dart';
import 'package:drum_coach/features/stats/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Progress is dark like the practice screen', (tester) async {
    // 29.09. (Uli): "Die Stats-Seite müsste dunkel."
    await tester.pumpWidget(ProviderScope(
      overrides: [
        allSessionsProvider.overrideWith((ref) async => []),
        streakDaysProvider.overrideWith((ref) async => 0),
        longestStreakProvider.overrideWith((ref) async => 0),
        todayStatusProvider.overrideWith(
            (ref) async => const TodayStatus(minutes: 0, goalMinutes: 20)),
      ],
      child: MaterialApp(theme: drumCoachTheme, home: const StatsScreen()),
    ));
    await tester.pumpAndSettle();
    final scaffold = find.byType(Scaffold);
    expect(Theme.of(tester.element(scaffold)).brightness, Brightness.dark);
    expect(Theme.of(tester.element(scaffold)).scaffoldBackgroundColor,
        PracticeColors.base);
    // The screen's own region (the AppBar adds a second one inside).
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first);
    expect(region.value.statusBarIconBrightness, Brightness.light);
    expect(find.text('Progress'), findsOneWidget);
  });
}
