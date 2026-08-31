import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design-token system for the "60cm" redesign.
///
/// The app is read at arm's length next to a practice pad, in the corner of
/// the eye — legibility at distance beats subtlety. Everything here mirrors
/// the token values from `docs/design/60-cm-kontext-und-startpunkt`.
class AppColors {
  AppColors._();

  // Surface scale (replaces the ad-hoc 0xFF1E1E1E / 0xFF1A1A1A hex litter).
  static const base = Color(0xFF101010);
  static const surface = Color(0xFF191919);
  static const raised = Color(0xFF212121);
  static const inset = Color(0xFF0B0B0B);
  static const coach = Color(0xFF151726);

  // Accent / semantic.
  static const accent = Color(0xFFFF6A2B);
  static const live = Color(0xFFFFC42E);
  static const solidStreak = Color(0xFF57C97A);
  static const ok = Color(0xFFFFC107);
  static const struggled = Color(0xFFE5484D);
  static const info = Color(0xFF6AA9FF);

  // Notation "paper" palette — only the staff itself breaks dark-only.
  static const paper = Color(0xFFFAF8F3);
  static const ink = Color(0xFF17181A);
  static const paperAccent = Color(0xFFC0451A);
  static const paperCursorLine = Color(0xFFB87700);

  // Text on dark surfaces.
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textMuted = Colors.white54;
  static const textFaint = Colors.white24;
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

/// Layout limits. On large (desktop) windows the phone-first UI is capped to
/// this width and centered, so it never stretches into an unreadable column.
class AppLayout {
  AppLayout._();

  static const maxContentWidth = 560.0;
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
/// labels and meta-text. Nothing goes below [label] (12).
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
