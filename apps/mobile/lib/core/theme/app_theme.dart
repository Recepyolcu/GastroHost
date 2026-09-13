import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Stitch Modern Epicurean Palette
  static const Color background = Color(0xFFFBF9F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE4E2E2);
  static const Color border = Color(0xFFE4E2E2);
  
  static const Color primary = Color(0xFF000000);
  static const Color secondary = Color(0xFF7B5800); // Warm Copper / Amber
  static const Color secondaryLight = Color(0xFFFDC34D);

  static const Color textDark = Color(0xFF1B1C1C);
  static const Color textMuted = Color(0xFF747878);
  static const Color accentEmerald = Color(0xFF10B981);

  // Legacy / Helper colors & gradients
  static const Color primaryGold = Color(0xFFD97706);
  static const Color primaryGoldLight = Color(0xFFF59E0B);
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textLight = Color(0xFFF8FAFC);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.libreCaslonText(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        titleLarge: GoogleFonts.libreCaslonText(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
