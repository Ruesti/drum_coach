import 'package:flutter/material.dart';

import 'design_tokens.dart';

final drumCoachTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.base,
  colorScheme: const ColorScheme.dark(
    surface: AppColors.base,
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
    titleTextStyle: AppTypography.title,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.accent,
    unselectedItemColor: AppColors.textMuted,
    type: BottomNavigationBarType.fixed,
  ),
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
    selectedColor: AppColors.accent.withValues(alpha: 0.3),
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
);
