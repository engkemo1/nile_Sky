import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_colors.dart';

class AdminTheme {
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AdminColors.bgDark,
      primaryColor: AdminColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AdminColors.primary,
        secondary: AdminColors.secondary,
        surface: AdminColors.cardDark,
        error: AdminColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: AdminColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.outfit(
          color: AdminColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AdminColors.textPrimary,
          fontSize: 14,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AdminColors.textSecondary,
          fontSize: 13,
        ),
      ),
      cardTheme: CardThemeData(
        color: AdminColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AdminColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      dividerColor: AdminColors.border,
      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.inter(
          color: AdminColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        dataTextStyle: GoogleFonts.inter(
          color: AdminColors.textPrimary,
          fontSize: 13,
        ),
        headingRowColor: WidgetStatePropertyAll(AdminColors.surfaceDark),
        decoration: const BoxDecoration(color: AdminColors.cardDark),
      ),
    );
  }
}
