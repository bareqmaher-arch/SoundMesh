import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppRadii {
  AppRadii._();
  static const double sm = 14;
  static const double md = 20;
  static const double lg = 28;
  static const double xl = 36;
  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get field => BorderRadius.circular(md);
}

class AppShadows {
  AppShadows._();
  static List<BoxShadow> soft(bool dark) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.45)
              : const Color(0xFF101935).withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double strength = 0.5}) => [
        BoxShadow(
          color: color.withValues(alpha: strength),
          blurRadius: 36,
          spreadRadius: 1,
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData _base(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.violet,
        brightness: brightness,
        primary: AppColors.violet,
        secondary: AppColors.cyan,
        surface: p.bgElevated,
      ),
    );

    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: p.text,
      displayColor: p.text,
    );

    return base.copyWith(
      textTheme: textTheme,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: p.text),
        titleTextStyle: textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, color: p.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.dGlass : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.textDim),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide(color: p.border),
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.6),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.bgElevated,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1C1F33) : const Color(0xFF1A1D33),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get dark => _base(Brightness.dark, AppPalette.dark);
  static ThemeData get light => _base(Brightness.light, AppPalette.light);
}
