import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';

/// Maps a talent's stable `key` slug to its bundled painted icon. Every seeded
/// talent has bespoke art under `assets/Talents/`; an unrecognised key (e.g. a
/// future talent added without art yet) falls back to the sparkle icon.
const Map<String, String> _talentKeyIcons = {
  'iron-grip': AppIcons.talentIronGrip,
  'deep-lungs': AppIcons.talentDeepLungs,
  'fast-twitch': AppIcons.talentFastTwitch,
  'loose-joints': AppIcons.talentLooseJoints,
  'second-engine': AppIcons.talentSecondEngine,
  'focused-training': AppIcons.talentFocusedTraining,
  'morning-momentum': AppIcons.talentMorningMomentum,
  'runners-high': AppIcons.talentRunnersHigh,
  'iron-discipline': AppIcons.talentIronDiscipline,
  'quest-zeal': AppIcons.talentQuestZeal,
  'second-wind': AppIcons.talentSecondWind,
  'steel-resolve': AppIcons.talentSteelResolve,
  'shield-craft': AppIcons.talentShieldCraft,
  'direct-hit': AppIcons.talentDirectHit,
  'boss-instinct': AppIcons.talentBossInstinct,
  'fair-exchange': AppIcons.talentFairExchange,
};

String talentIconAsset(String key) {
  return _talentKeyIcons[key] ?? 'assets/icons/reward_xp_sparkle.png';
}

/// Rarity → accent colour (Common green / Rare blue / Epic orange).
Color talentRarityColor(String rarity) {
  switch (rarity) {
    case 'Epic':
      return AppColors.orange;
    case 'Rare':
      return AppColors.blue;
    case 'Common':
    default:
      return AppColors.green;
  }
}
