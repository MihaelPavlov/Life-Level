import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/world_map_models.dart';

/// Bundled artwork for every world region. Server-provided URLs remain the
/// primary source so admin overrides still work; these assets are the complete
/// offline/default set used by the world hub and each region trail.
class RegionArtwork {
  static const _root = 'assets/Regions/world';

  static const Map<String, String> _slugs = {
    'Forest of Endurance': 'forest_of_endurance',
    'Ocean of Balance': 'ocean_of_balance',
    'Mountains of Strength': 'mountains_of_strength',
    'Ashen Caldera': 'ashen_caldera',
    'Frostspire Tundra': 'frostspire_tundra',
    'Sunscorch Dunes': 'sunscorch_dunes',
    'Shadewood Deep': 'shadewood_deep',
    'Moonlit Reef': 'moonlit_reef',
    'Thunderpeak Range': 'thunderpeak_range',
    'Emberfall Crater': 'emberfall_crater',
    'Glacier Abyss': 'glacier_abyss',
    'Mirage Wastes': 'mirage_wastes',
    'Verdant Spine': 'verdant_spine',
    'Abyssal Trench': 'abyssal_trench',
    'Apex Caldera': 'apex_caldera',
  };

  static String? bannerFor(String regionName) {
    final slug = _slugs[regionName];
    return slug == null ? null : '$_root/${slug}_banner.png';
  }

  static String? backgroundFor(String regionName) {
    final slug = _slugs[regionName];
    return slug == null ? null : '$_root/${slug}_background.png';
  }
}

/// Per-region palette + gradient helpers. Mirrors the CSS `.wv3-region--forest`,
/// `--ocean`, etc. themes from `design-mockup/map/WORLD-MAP-FINAL-MOCKUP.html`.
class RegionThemeColors {
  final Color accent;
  final List<Color> bannerGradient;
  final String? bannerAsset;
  final String? trailBackgroundAsset;

  const RegionThemeColors({
    required this.accent,
    required this.bannerGradient,
    this.bannerAsset,
    this.trailBackgroundAsset,
  });

  static RegionThemeColors of(RegionTheme theme) {
    switch (theme) {
      case RegionTheme.forest:
        return const RegionThemeColors(
          accent: AppColors.green,
          bannerGradient: [Color(0x473fb950), Color(0x1a4f9eff)],
          bannerAsset: 'assets/Regions/world/forest_of_endurance_banner.png',
          trailBackgroundAsset:
              'assets/Regions/world/forest_of_endurance_background.png',
        );
      case RegionTheme.ocean:
        return const RegionThemeColors(
          accent: AppColors.blue,
          bannerGradient: [Color(0x404f9eff), Color(0x33000000)],
        );
      case RegionTheme.mountain:
        return const RegionThemeColors(
          accent: AppColors.purple,
          bannerGradient: [Color(0x38a371f7), Color(0x294f9eff)],
        );
      case RegionTheme.volcano:
        return const RegionThemeColors(
          accent: AppColors.red,
          bannerGradient: [Color(0x33f85149), Color(0x2df5a623)],
        );
      case RegionTheme.frost:
        return const RegionThemeColors(
          accent: Color(0xFF6dd3ff),
          bannerGradient: [Color(0x406dd3ff), Color(0x1a4f9eff)],
        );
      case RegionTheme.desert:
        return const RegionThemeColors(
          accent: AppColors.orange,
          bannerGradient: [Color(0x40f5a623), Color(0x1fc97b2a)],
        );
    }
  }
}

/// Status → palette for [ZoneNodeStatus]. Used by both the trail bubble and
/// the zone detail sheet so the colour language stays consistent.
class ZoneNodeColors {
  final Color accent;
  final Color accentSoft;

  const ZoneNodeColors({required this.accent, required this.accentSoft});

  static ZoneNodeColors of(ZoneNodeStatus status) {
    switch (status) {
      case ZoneNodeStatus.completed:
        return const ZoneNodeColors(
          accent: AppColors.green,
          accentSoft: Color(0x263fb950),
        );
      case ZoneNodeStatus.active:
        return const ZoneNodeColors(
          accent: AppColors.blue,
          accentSoft: Color(0x264f9eff),
        );
      case ZoneNodeStatus.next:
        return const ZoneNodeColors(
          accent: AppColors.orange,
          accentSoft: Color(0x26f5a623),
        );
      case ZoneNodeStatus.available:
        return const ZoneNodeColors(
          accent: AppColors.textSecondary,
          accentSoft: Color(0x1F8b949e),
        );
      case ZoneNodeStatus.locked:
        return const ZoneNodeColors(
          accent: AppColors.textMuted,
          accentSoft: Color(0x1A4d5b6b),
        );
    }
  }
}
