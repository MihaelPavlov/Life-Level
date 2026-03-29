import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF040810);
  // Slightly lighter background used as the home feed base
  static const backgroundAlt = Color(0xFF080e14);
  static const surface = Color(0xFF161b22);
  static const surfaceElevated = Color(0xFF1e2632);
  // Completed-quest tinted surface
  static const surfaceSuccess = Color(0xFF1a2d1a);
  // Expired/disabled tinted surface
  static const surfaceDisabled = Color(0xFF1a1a1a);
  // Shell/scaffold background (slightly bluer than pure background)
  static const shellBackground = Color(0xFF090d1a);
  static const textPrimary = Color(0xFFe6edf3);
  static const textSecondary = Color(0xFF8b949e);
  // Muted text, used for de-emphasised numbers
  static const textMuted = Color(0xFF4d5b6b);
  static const blue = Color(0xFF4f9eff);
  static const purple = Color(0xFFa371f7);
  static const orange = Color(0xFFf5a623);
  static const red = Color(0xFFf85149);
  // Darker red used as a gradient end on boss HP bars
  static const redDark = Color(0xFFc0392b);
  static const green = Color(0xFF3fb950);
  // Default border colour used across cards and inputs
  static const border = Color(0xFF30363d);
}
