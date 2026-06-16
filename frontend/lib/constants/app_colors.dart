import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color teal = Color(0xFF14A7A0);
  static const Color accentCyan = Color(0xFF2ED1B0);

  // Background colors
  static const Color darkBg1 = Color(0xFF0B1120);
  static const Color darkBg2 = Color(0xFF0E1A20);
  static const Color darkBg3 = Color(0xFF0A1218);

  static const Color lightBg1 = Color(0xFFE8F8F5);
  static const Color lightBg2 = Color(0xFFF2F6FF);
  static const Color lightBg3 = Color(0xFFF7FBFF);

  // Accent colors
  static const Color purple = Color(0xFF4F46E5);
  static const Color lightPurple = Color(0xFF818CF8);

  // Text colors
  static const Color darkText = Color(0xFF1D232B);
  static const Color lightText = Color(0xFFE6EDF3);
  static const Color lightTextSecondary = Color(0xFFC0CDD8);
  static const Color lightTextTertiary = Color(0xFFA5B3BF);
  static const Color lightTextQuaternary = Color(0xFF8B99A6);
  static const Color darkTextSecondary = Color(0xFF4A5568);
  static const Color darkTextTertiary = Color(0xFF98A2AC);

  // UI colors
  static const Color red = Colors.red;
  static const Color redAccent = Colors.redAccent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Status colors (shared across tasks / sync / alerts)
  static const Color success = Color(0xFF1FA971);
  static const Color warning = Color(0xFFDD8A2A);
  static const Color danger = Color(0xFFD64242);
  static const Color info = Color(0xFF14A7A0);

  // ── Semantic, brightness-aware helpers ───────────────────────────────────
  // Prefer these over scattered `isDark ? A : B` ternaries so theming stays
  // consistent and a single source of truth drives light/dark surfaces.

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Primary readable text color.
  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? lightText : darkText;

  /// Muted secondary text (subtitles, captions).
  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? const Color(0xFF9EABB7) : const Color(0xFF6C7580);

  /// Faint tertiary text (hints, metadata).
  static Color textTertiary(BuildContext context) =>
      _isDark(context) ? lightTextTertiary : const Color(0xFF8B939C);

  /// Opaque card/panel surface (used where translucency isn't wanted).
  static Color surface(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A232C) : white;

  /// A slightly recessed inner surface (sections inside a card).
  static Color surfaceMuted(BuildContext context) =>
      _isDark(context) ? const Color(0xFF22303C) : const Color(0xFFF4F8FB);

  /// Hairline border for cards and dividers.
  static Color border(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2A3642) : const Color(0xFFE9EDF0);

  /// Brand accent tuned for the current brightness.
  static Color brand(BuildContext context) =>
      _isDark(context) ? accentCyan : teal;

  /// Skeleton/shimmer resting block color (opaque so the loading placeholder
  /// reads clearly against the gradient background).
  static Color shimmerBase(BuildContext context) =>
      _isDark(context) ? const Color(0xFF263441) : const Color(0xFFD6DEE6);

  /// Skeleton/shimmer moving-sweep highlight. Deliberately lighter than
  /// [shimmerBase] in both themes so the animation is clearly visible.
  static Color shimmerHighlight(BuildContext context) =>
      _isDark(context) ? const Color(0xFF3C4C5A) : const Color(0xFFF2F6FA);
}
