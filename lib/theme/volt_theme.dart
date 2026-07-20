import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoltTheme {
  // Volt Color Palette - Deep Obsidian & Cyber Accents
  static const Color obsidian = Color(0xFF050505);
  static const Color slate = Color(0xFF0D0D0F);
  static const Color carbon = Color(0xFF16161A);
  
  static const Color cyberBlue = Color(0xFF00D1FF);
  static const Color neonGreen = Color(0xFF00FF94);
  static const Color neonRed = Color(0xFFFF2D55);
  static const Color amber = Color(0xFFFFB800);
  
  static const Color textMain = Colors.white;
  static const Color textMuted = Color(0xFF6E6E73);
  static const Color textDim = Color(0xFF3A3A3C);

  static ThemeData get theme {
    final base = ThemeData.dark();
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
      colorScheme: const ColorScheme.dark(
        primary: cyberBlue,
        secondary: neonGreen,
        surface: slate,
        error: neonRed,
      ),
      dividerColor: textDim.withValues(alpha: 0.3),
    );
  }

  // Volt UI Accents
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: carbon.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
    hintStyle: const TextStyle(color: textDim, fontSize: 14),
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: cyberBlue, size: 18) : null,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.02),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: cyberBlue, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  );
}
