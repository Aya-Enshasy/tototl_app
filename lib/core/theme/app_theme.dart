import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.white,
      error: AppColors.red,
      onPrimary: AppColors.white,
      onSecondary: AppColors.navy,
      onSurface: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: AppColors.cardBorder,
    textTheme: GoogleFonts.poppinsTextTheme(),
  );
}
