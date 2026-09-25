import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design-token system.
///
/// K2 (decision 15.09.2026): the app is light — a paper look, "leicht,
/// luftig, klar" — and only the practice screen stays dark, because it is
/// read at arm's length next to a pad, often in a dim room. [AppColors]
/// carries the light palette; [PracticeColors] the dark one; [AppPalette.of]
/// picks between them from the ambient theme for shared widgets.
class AppColors {
  AppColors._();

  // Surface scale on paper.
  static const base = Color(0xFFFAF8F3);
  static const surface = Color(0xFFFFFFFF);
  static const raised = Color(0xFFF1EDE6);
  static const inset = Color(0xFFECE7DF);
  static const coach = Color(0xFFEEF1FA);

  // Accent / semantic (tuned for light ground).
  static const accent = Color(0xFFFF6A2B);
  static const live = Color(0xFFFFC42E);
  static const solidStreak = Color(0xFF2E9E55);
  static const ok = Color(0xFFC98A00);
  static const struggled = Color(0xFFD9383E);
  static const info = Color(0xFF2F6FD6);

  // Notation "paper" palette — unchanged, the staff is light in both themes.
  static const paper = Color(0xFFFAF8F3);
  static const ink = Color(0xFF17181A);
  static const paperAccent = Color(0xFFC0451A);
  static const paperCursorLine = Color(0xFFB87700);

  // Text on paper (ink with alpha).
  static const textPrimary = Color(0xFF17181A);
  static const textSecondary = Color(0xBD17181A); // 74 %
  static const textMuted = Color(0x9E17181A); // 62 %
  static const textFaint = Color(0x3817181A); // 22 % — dividers, borders
}

/// The practice screen stays dark. Same field names as [AppColors]; used
/// only by the practice screen and, via [AppPalette.of], by shared widgets
/// rendered inside it.
class PracticeColors {
  PracticeColors._();

  static const base = Color(0xFF101010);
  static const surface = Color(0xFF191919);
  static const raised = Color(0xFF212121);
  static const inset = Color(0xFF0B0B0B);
  static const coach = Color(0xFF151726);

  static const accent = Color(0xFFFF6A2B);
  static const live = Color(0xFFFFC42E);
  static const solidStreak = Color(0xFF57C97A);
  static const ok = Color(0xFFFFC107);
  static const struggled = Color(0xFFE5484D);
  static const info = Color(0xFF6AA9FF);

  static const paper = AppColors.paper;
  static const ink = AppColors.ink;
  static const paperAccent = AppColors.paperAccent;
  static const paperCursorLine = AppColors.paperCursorLine;

  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textMuted = Colors.white54;
  static const textFaint = Colors.white24;
}

/// Palette resolved from the ambient [Theme]: dark inside the practice
/// screen's `Theme(data: drumCoachPracticeTheme)`, light everywhere else.
/// Shared widgets use this instead of the static classes so they render
/// correctly on both grounds.
class AppPalette {
  const AppPalette._({
    required this.base,
    required this.surface,
    required this.raised,
    required this.coach,
    required this.accent,
    required this.struggled,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
  });

  final Color base;
  final Color surface;
  final Color raised;
  final Color coach;
  final Color accent;
  final Color struggled;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;

  static const light = AppPalette._(
    base: AppColors.base,
    surface: AppColors.surface,
    raised: AppColors.raised,
    coach: AppColors.coach,
    accent: AppColors.accent,
    struggled: AppColors.struggled,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    textFaint: AppColors.textFaint,
  );

  static const dark = AppPalette._(
    base: PracticeColors.base,
    surface: PracticeColors.surface,
    raised: PracticeColors.raised,
    coach: PracticeColors.coach,
    accent: PracticeColors.accent,
    struggled: PracticeColors.struggled,
    textPrimary: PracticeColors.textPrimary,
    textSecondary: PracticeColors.textSecondary,
    textMuted: PracticeColors.textMuted,
    textFaint: PracticeColors.textFaint,
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  static const screenPadding = 20.0;
  static const cardPadding = 16.0;
}

class AppRadius {
  AppRadius._();

  static const badge = 6.0;
  static const chip = 10.0;
  static const card = 14.0;
  static const sheet = 20.0;
  static const pill = 999.0;
}

/// Typography scale — Space Grotesk for UI text, IBM Plex Mono for numbers,
/// labels and meta-text. Nothing goes below [label] (12). Colors are the
/// light palette; the practice screen uses [PracticeTypography].
class AppTypography {
  AppTypography._();

  static TextStyle get numericXl => GoogleFonts.ibmPlexMono(
        fontSize: 104,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.0,
      );

  static TextStyle get display => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  static TextStyle get title => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get subtitle => GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get body => GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.55,
      );

  static TextStyle get label => GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
        height: 1.3,
      );
}

/// Same scale as [AppTypography], colored for the dark practice screen.
class PracticeTypography {
  PracticeTypography._();

  static TextStyle get numericXl =>
      AppTypography.numericXl.copyWith(color: PracticeColors.textPrimary);
  static TextStyle get display =>
      AppTypography.display.copyWith(color: PracticeColors.textPrimary);
  static TextStyle get title =>
      AppTypography.title.copyWith(color: PracticeColors.textPrimary);
  static TextStyle get subtitle =>
      AppTypography.subtitle.copyWith(color: PracticeColors.textPrimary);
  static TextStyle get body =>
      AppTypography.body.copyWith(color: PracticeColors.textPrimary);
  static TextStyle get label =>
      AppTypography.label.copyWith(color: PracticeColors.textSecondary);
}
