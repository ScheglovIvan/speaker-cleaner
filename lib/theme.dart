import 'package:flutter/material.dart';

/// Design tokens captured from the native Speaker Cleaner UI
/// (app_spec.json -> design_tokens.color). Real #RRGGBBAA values.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF007AFF); // iOS system blue
  static const Color primaryLight = Color(0xFF369FFF);
  static const Color accentCyan = Color(0xFFA4EEFF);
  static const Color gradientTeal = Color(0xFF1FC7D8);
  static const Color surfaceTint = Color(0xFFEBF6FF); // light-blue card panel
  static const Color background = Color(0xFFF5F7FA); // cool near-white
  static const Color warning = Color(0xFFFF9500);
  static const Color successBg = Color(0xFFDFFDEB);
  static const Color dangerBg = Color(0xFFFFEAE9);
  static const Color danger = Color(0xFFFF3B30);
  static const Color textPrimary = Color(0xFF010101);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color neutralBorder = Color(0xFFD1D3DB);
  static const Color surface = Color(0xFFFFFFFF);

  /// Blue -> teal gradient used on primary CTAs and the active tab pill.
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, gradientTeal],
  );
}

/// Corner-radius tokens (design_tokens.dimension).
class AppRadii {
  AppRadii._();
  static const double sm = 12;
  static const double md = 20;
  static const double pill = 26;
  static const double gutter = 16;
}

ThemeData buildAppTheme() {
  const family = 'Poppins';

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.gradientTeal,
    surface: AppColors.surface,
    error: AppColors.danger,
    onPrimary: Colors.white,
    onSurface: AppColors.textPrimary,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: family,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerColor: AppColors.neutralBorder,
    splashFactory: InkRipple.splashFactory,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: family,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    textTheme: _poppinsTextTheme(base.textTheme),
  );
}

TextTheme _poppinsTextTheme(TextTheme base) {
  const primary = AppColors.textPrimary;
  const secondary = AppColors.textSecondary;
  TextStyle s(double size, FontWeight w, Color c) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        fontWeight: w,
        color: c,
      );
  return base.copyWith(
    displayLarge: s(34, FontWeight.w700, primary),
    headlineMedium: s(22, FontWeight.w700, primary), // font_title
    titleLarge: s(20, FontWeight.w600, primary),
    titleMedium: s(16, FontWeight.w600, primary),
    bodyLarge: s(16, FontWeight.w400, primary),
    bodyMedium: s(14, FontWeight.w400, primary), // font_body
    bodySmall: s(11, FontWeight.w400, secondary), // font_caption
    labelLarge: s(16, FontWeight.w600, primary),
  );
}
