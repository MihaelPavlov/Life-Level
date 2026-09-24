import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../motion/app_motion.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.blue,
          secondary: AppColors.purple,
          error: AppColors.red,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
          labelSmall: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: AppPageTransitionsBuilder(),
            TargetPlatform.iOS: AppPageTransitionsBuilder(),
            TargetPlatform.macOS: AppPageTransitionsBuilder(),
            TargetPlatform.windows: AppPageTransitionsBuilder(),
            TargetPlatform.linux: AppPageTransitionsBuilder(),
            TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
          },
        ),
      );
}
