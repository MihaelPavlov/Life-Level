import '../../../core/constants/app_colors.dart';

// ─── local palette aliases (thin wrappers around AppColors) ──────────────────
// Keep these even though the repo has `AppColors` because the home feature
// matches design-mockup/home/home-v3.html where the tokens are expressed as
// CSS custom properties like `--bg-base`, `--surface-1`, etc. Aliasing them
// once keeps the card widgets readable and 1:1 with the mockup.
const kHBgBase      = AppColors.backgroundAlt;
const kHSurface1    = AppColors.surface;
const kHSurface2    = AppColors.surfaceElevated;
const kHBorderColor = AppColors.border;
const kHBorderSoft  = AppColors.surfaceElevated;
const kHTextMuted   = AppColors.textMuted;
