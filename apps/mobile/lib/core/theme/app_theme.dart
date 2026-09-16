import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Stitch Modern Epicurean Palette (Light)
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

  // Elite Luxury Obsidian Palette (Dark)
  static const Color bgDark = Color(0xFF0B0D11);
  static const Color cardDark = Color(0xFF13171F);
  static const Color surfaceDarkElevated = Color(0xFF1B202A);
  static const Color borderDark = Color(0xFF242B38);
  static const Color borderDarkSubtle = Color(0xFF1B202A);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color goldAccentDark = Color(0xFFF59E0B);
  static const Color goldLightDark = Color(0xFFFDC34D);

  // Legacy / Helper colors & gradients
  static const Color primaryGold = Color(0xFFD97706);
  static const Color primaryGoldLight = Color(0xFFF59E0B);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppThemePalette {
  final bool isDark;
  const AppThemePalette(this.isDark);

  Color get bg => isDark ? AppColors.bgDark : AppColors.background;
  Color get surface => isDark ? AppColors.cardDark : AppColors.surface;
  Color get surfaceElevated => isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF5F4F3);
  Color get border => isDark ? AppColors.borderDark : AppColors.border;
  Color get borderSubtle => isDark ? AppColors.borderDarkSubtle : const Color(0xFFEFEDED);
  Color get textPrimary => isDark ? AppColors.textLight : AppColors.textDark;
  Color get textMuted => isDark ? AppColors.textMutedDark : AppColors.textMuted;
  Color get goldAccent => isDark ? AppColors.goldAccentDark : AppColors.secondary;
  Color get goldLight => isDark ? AppColors.goldLightDark : AppColors.secondaryLight;
  Color get goldGlow => isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.18) : const Color(0xFF7B5800).withValues(alpha: 0.10);
  Color get emerald => AppColors.accentEmerald;
  Color get emeraldGlow => isDark ? const Color(0xFF10B981).withValues(alpha: 0.20) : const Color(0xFF10B981).withValues(alpha: 0.12);
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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.goldAccentDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.goldAccentDark,
        secondary: AppColors.goldLightDark,
        surface: AppColors.cardDark,
        onSurface: AppColors.textLight,
        surfaceContainerHighest: AppColors.surfaceDarkElevated,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.libreCaslonText(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
        titleLarge: GoogleFonts.libreCaslonText(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          color: AppColors.textLight,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          color: AppColors.textMutedDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
    );
  }
}

