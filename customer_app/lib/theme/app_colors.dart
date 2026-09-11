import 'package:flutter/material.dart';

class AppColors {
  // -------------------------------------------------------------
  // Premium Brand Colors - Luxor Sunrise Gold, Azure Nile & Coral
  // -------------------------------------------------------------
  static const Color primary = Color(0xFFFFB800); // Electric Luxor Amber Gold
  static const Color primaryLight = Color(0xFFFFFBEB); // Soft Sun Gold Tint
  static const Color primaryDark = Color(0xFFD97706); // Burnished Bronze Gold
  static const Color primaryGlow = Color(0xFFFF9500); // Radiant Sunset Orange

  static const Color secondary = Color(0xFF0284C7); // Nile Sky Azure Blue
  static const Color secondaryLight = Color(0xFFE0F2FE); // Morning Sky Mist
  static const Color secondaryDark = Color(0xFF0369A1); // Deep River Blue

  static const Color accent = Color(0xFFFF5E36); // Sunrise Coral / Rose
  static const Color accentWarm = Color(0xFFFFF1EE); // Soft Coral Glow
  static const Color accentRose = Color(0xFFFF2A6D); // Pharaonic Rose

  static const Color nileBlue = Color(0xFF0F172A); // Deep Slate Navy
  static const Color nileNavy = Color(0xFF1E293B);

  // -------------------------------------------------------------
  // Backgrounds & Surfaces (Bright, Crisp, Luxury White Theme)
  // -------------------------------------------------------------
  static const Color bgDark = Color(0xFFF8FAFC); // Main App Canvas (Pearl White Slate)
  static const Color surfaceDark = Color(0xFFFFFFFF); // Pure White Surface
  static const Color cardDark = Color(0xFFFFFFFF); // Pure White Card Surface
  static const Color cardHighlight = Color(0xFFFFFBEB); // Active / Highlighted Card Surface

  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // -------------------------------------------------------------
  // Status Colors (Vibrant & High-Contrast)
  // -------------------------------------------------------------
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successLight = Color(0xFFECFDF5); // Soft Emerald Tint
  static const Color warning = Color(0xFFF59E0B); // Vivid Amber
  static const Color warningLight = Color(0xFFFFFBEB); // Soft Amber Tint
  static const Color error = Color(0xFFEF4444); // Coral Red
  static const Color errorLight = Color(0xFFFEF2F2); // Soft Red Tint
  static const Color info = Color(0xFF0EA5E9); // Sky Info Cyan

  // -------------------------------------------------------------
  // Typography & Borders (High-Contrast Charcoal & Light Slate)
  // -------------------------------------------------------------
  static const Color textPrimary = Color(0xFF0F172A); // Deep Charcoal Slate (Crisp & High Contrast)
  static const Color textSecondary = Color(0xFF475569); // Refined Slate Gray
  static const Color textTertiary = Color(0xFF94A3B8); // Light Slate
  static const Color textMuted = Color(0xFF64748B); // Muted Slate

  static const Color border = Color(0xFFE2E8F0); // Sleek Light Border
  static const Color borderLight = Color(0xFFF1F5F9); // Very Subtle Border
  static const Color borderGlow = Color(0x4DFFB800); // Amber Glow Border

  // -------------------------------------------------------------
  // Luxurious Signature Gradients
  // -------------------------------------------------------------
  static const LinearGradient sunriseGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF5E36), Color(0xFFFF2A6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldenGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFB800), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient nileGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x88FFFFFF), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient skyGradient = LinearGradient(
    colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFFFFFBEB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
