import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app theme is light on paper, practice theme stays dark', () {
    expect(drumCoachTheme.brightness, Brightness.light);
    expect(drumCoachTheme.scaffoldBackgroundColor, AppColors.base);
    expect(AppColors.base, const Color(0xFFFAF8F3));
    expect(drumCoachPracticeTheme.brightness, Brightness.dark);
    expect(drumCoachPracticeTheme.scaffoldBackgroundColor, PracticeColors.base);
    expect(PracticeColors.base, const Color(0xFF101010));
    // Paper tokens untouched.
    expect(AppColors.paper, const Color(0xFFFAF8F3));
    expect(AppColors.ink, const Color(0xFF17181A));
  });

  testWidgets('AppPalette.of follows the ambient theme brightness',
      (tester) async {
    late AppPalette inLight;
    late AppPalette inDark;
    await tester.pumpWidget(MaterialApp(
      theme: drumCoachTheme,
      home: Builder(builder: (context) {
        inLight = AppPalette.of(context);
        return Theme(
          data: drumCoachPracticeTheme,
          child: Builder(builder: (context) {
            inDark = AppPalette.of(context);
            return const SizedBox();
          }),
        );
      }),
    ));
    expect(inLight.surface, AppColors.surface);
    expect(inDark.surface, PracticeColors.surface);
    expect(inDark.textPrimary, Colors.white);
  });
}
