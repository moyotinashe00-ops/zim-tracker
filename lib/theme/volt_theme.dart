import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoltTheme {
  /// Source of truth for dark/light. Mutated by ThemeController, read by
  /// every getter below. This is deliberately a plain static field (not a
  /// stream/notifier itself) so VoltTheme can be used without a
  /// BuildContext anywhere in the app, same as before this refactor --
  /// ThemeController.toggle() is what triggers the actual UI rebuild via
  /// Provider.
  static bool isDark = true;

  // Volt Color Palette - Deep Obsidian & Cyber Accents (dark) /
  // Clean Grid Ops on White (light)
  static Color get obsidian => isDark ? const Color(0xFF050505) : const Color(0xFFF5F5F7);
  static Color get slate => isDark ? const Color(0xFF0D0D0F) : const Color(0xFFFFFFFF);
  static Color get carbon => isDark ? const Color(0xFF16161A) : const Color(0xFFEAEAEE);

  // Accent colors stay recognizably "Volt" in both modes, just deepened
  // slightly in light mode so they hold contrast against a white background.
  static Color get cyberBlue => isDark ? const Color(0xFF00D1FF) : const Color(0xFF0091B3);
  static Color get neonGreen => isDark ? const Color(0xFF00FF94) : const Color(0xFF00A85C);
  static Color get neonRed => isDark ? const Color(0xFFFF2D55) : const Color(0xFFD6003D);
  static Color get amber => isDark ? const Color(0xFFFFB800) : const Color(0xFFB37D00);

  static Color get textMain => isDark ? Colors.white : const Color(0xFF141416);
  static Color get textMuted => isDark ? const Color(0xFF6E6E73) : const Color(0xFF5B5B60);
  static Color get textDim => isDark ? const Color(0xFF3A3A3C) : const Color(0xFFB0B0B5);

  /// Centralized replacement for the many one-off `Colors.white10` /
  /// `Colors.white.withValues(alpha: 0.0X)` overlay borders and subtle
  /// fills used throughout the app. In dark mode these were always a thin
  /// wash of white over a black background; in light mode the same effect
  /// needs a wash of black over a white background instead, or borders
  /// become invisible.
  static Color overlay(double alpha) => (isDark ? Colors.white : Colors.black).withValues(alpha: alpha);

  static ThemeData get theme {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: obsidian,
      cardColor: slate,
      primaryColor: cyberBlue,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.w800, letterSpacing: -1.5),
        displayMedium: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.w700, letterSpacing: -1.0),
        titleLarge: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: textMain, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textMuted, fontSize: 14),
      ),
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: cyberBlue,
        onPrimary: Colors.black,
        secondary: neonGreen,
        onSecondary: Colors.black,
        surface: slate,
        onSurface: textMain,
        error: neonRed,
        onError: Colors.white,
      ),
      dividerColor: textDim.withValues(alpha: 0.3),
    );
  }

  // Volt UI Accents
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: carbon.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: overlay(0.05)),
  );

  static TextStyle get dataStyle => GoogleFonts.robotoMono(
    color: cyberBlue,
    fontWeight: FontWeight.bold,
  );

  static InputDecoration voltInputDecoration({
    String? hintText,
    IconData? prefixIcon,
  }) => InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: textDim, fontSize: 14),
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: cyberBlue, size: 18) : null,
    filled: true,
    fillColor: overlay(0.02),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: overlay(0.05)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: overlay(0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cyberBlue, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  );
}
