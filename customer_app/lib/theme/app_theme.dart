import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme({bool isArabic = false}) {
    return lightTheme(isArabic: isArabic);
  }

  static ThemeData lightTheme({bool isArabic = false}) {
    final baseTextTheme = isArabic
        ? GoogleFonts.cairoTextTheme(ThemeData.light().textTheme)
        : GoogleFonts.outfitTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgDark,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: (isArabic ? GoogleFonts.cairo : GoogleFonts.outfit)(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: (isArabic ? GoogleFonts.cairo : GoogleFonts.outfit)(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: isArabic ? 0 : -0.5,
        ),
        headlineMedium: (isArabic ? GoogleFonts.cairo : GoogleFonts.outfit)(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: (isArabic ? GoogleFonts.cairo : GoogleFonts.outfit)(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        bodyMedium: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          elevation: 1.5,
          shadowColor: AppColors.primary.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: (isArabic ? GoogleFonts.cairo : GoogleFonts.outfit)(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
          color: AppColors.textTertiary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
    );
  }
}
