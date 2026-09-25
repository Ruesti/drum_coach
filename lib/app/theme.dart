import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// App theme (K2): light paper look. See [drumCoachPracticeTheme] for the
/// one screen that stays dark.
final drumCoachTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.base,
  colorScheme: const ColorScheme.light(
    surface: AppColors.surface,
    primary: AppColors.accent,
    secondary: AppColors.live,
    error: AppColors.struggled,
    onSurface: AppColors.textPrimary,
  ),
  textTheme: TextTheme(
    displayLarge: AppTypography.numericXl,
    headlineLarge: AppTypography.display,
    titleLarge: AppTypography.title,
    titleMedium: AppTypography.subtitle,
    bodyMedium: AppTypography.body,
    labelLarge: AppTypography.label,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.base,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: AppTypography.title,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.base,
    selectedItemColor: AppColors.textPrimary,
    unselectedItemColor: AppColors.textMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  dividerTheme: const DividerThemeData(color: AppColors.textFaint, space: 1),
  sliderTheme: const SliderThemeData(
    activeTrackColor: AppColors.accent,
    thumbColor: AppColors.accent,
    inactiveTrackColor: AppColors.textFaint,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.raised,
      disabledForegroundColor: AppColors.textMuted,
      minimumSize: const Size(double.infinity, 52),
      textStyle: AppTypography.subtitle,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.textFaint),
      minimumSize: const Size(double.infinity, 52),
      textStyle: AppTypography.subtitle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.raised,
    selectedColor: AppColors.accent.withValues(alpha: 0.2),
    labelStyle: AppTypography.label.copyWith(color: AppColors.textPrimary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.chip),
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
  ),
  dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
);

/// Dark theme for the practice screen only (K2 "Mischung": the app is light,
/// practicing stays dark). Same shape as [drumCoachTheme] with the
/// [PracticeColors] / [PracticeTypography] values.
final drumCoachPracticeTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: PracticeColors.base,
  colorScheme: const ColorScheme.dark(
    surface: PracticeColors.base,
    primary: PracticeColors.accent,
    secondary: PracticeColors.live,
    error: PracticeColors.struggled,
    onSurface: PracticeColors.textPrimary,
  ),
  textTheme: TextTheme(
    displayLarge: PracticeTypography.numericXl,
    headlineLarge: PracticeTypography.display,
    titleLarge: PracticeTypography.title,
    titleMedium: PracticeTypography.subtitle,
    bodyMedium: PracticeTypography.body,
    labelLarge: PracticeTypography.label,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: PracticeColors.base,
    foregroundColor: PracticeColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: PracticeTypography.title,
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: PracticeColors.accent,
    thumbColor: PracticeColors.accent,
    inactiveTrackColor: PracticeColors.textFaint,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: PracticeColors.accent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: PracticeColors.raised,
      disabledForegroundColor: PracticeColors.textMuted,
      minimumSize: const Size(double.infinity, 52),
      textStyle: PracticeTypography.subtitle,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: PracticeColors.textPrimary,
      side: const BorderSide(color: PracticeColors.textFaint),
      minimumSize: const Size(double.infinity, 52),
      textStyle: PracticeTypography.subtitle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: PracticeColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: PracticeColors.raised,
    selectedColor: PracticeColors.accent.withValues(alpha: 0.3),
    labelStyle:
        PracticeTypography.label.copyWith(color: PracticeColors.textPrimary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.chip),
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: PracticeColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
  ),
  dialogTheme: const DialogThemeData(backgroundColor: PracticeColors.surface),
);
