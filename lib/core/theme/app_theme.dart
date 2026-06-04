import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();

    final interTextTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    final textTheme = interTextTheme.copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
        surface: AppColors.surface,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 0,
      ),
    );
  }
}
