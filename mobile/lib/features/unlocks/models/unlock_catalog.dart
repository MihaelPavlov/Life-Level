import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';

/// Where an unlocked feature lives, so its icon can fly there.
enum UnlockSlot { none, hub, nav, orb, chip, mode }

/// Keys shared with the server's `UnlockService.Catalog`.
abstract final class UnlockKeys {
  static const home = 'home';
  static const achievements = 'achievements';
  static const map = 'map';
  static const gear = 'gear';
  static const chests = 'chests';
  static const talents = 'talents';
  static const shields = 'shields';
  static const bosses = 'bosses';
  static const ranks = 'ranks';
  static const guild = 'guild';
  static const leaderboard = 'leaderboard';
  static const modes = 'modes';
  static const delve = 'delve';
}

/// What the ceremony, the locked slot and the tour say about one feature.
class UnlockMeta {
  final String key;
  final String name;
  final String icon;
  final Color color;
  final UnlockSlot slot;

  /// One sentence: what the feature is for.
  final String line;
  final String perkIcon;
  final String perk;

  /// Shown when a locked slot is tapped: what unlocks it.
  final String lockedHint;

  /// The level this feature belongs to (server `UnlockService.Catalog`).
  /// Each level opens at most two features.
  final int tier;

  /// The action it needs besides the level, short ("Find an item").
  final String need;

  const UnlockMeta({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.slot,
    required this.line,
    required this.perkIcon,
    required this.perk,
    required this.lockedHint,
    required this.tier,
    required this.need,
  });
}

const kUnlockCatalog = <String, UnlockMeta>{
  UnlockKeys.home: UnlockMeta(
    key: UnlockKeys.home,
    name: 'Home',
    icon: AppIcons.navHome,
    color: AppColors.blue,
    slot: UnlockSlot.none,
    line: 'Your hero, your workouts and everything that opens next.',
    perkIcon: AppIcons.navHome,
    perk: 'Home',
    lockedHint: 'Finish setup',
    tier: 1,
    need: 'Finish setup',
  ),
  UnlockKeys.achievements: UnlockMeta(
    key: UnlockKeys.achievements,
    name: 'Achievements',
    icon: AppIcons.rankChampion,
    color: AppColors.orange,
    slot: UnlockSlot.hub,
    line: 'Badges for everything you do. Your first one is already waiting.',
    perkIcon: AppIcons.rankChampion,
    perk: 'Your first badge is ready to claim',
    lockedHint: 'Reach Level 2 to unlock',
    tier: 2,
    need: 'Log a workout',
  ),
  UnlockKeys.map: UnlockMeta(
    key: UnlockKeys.map,
    name: 'Map & Banked km',
    icon: AppIcons.mapDestination,
    color: AppColors.blue,
    slot: UnlockSlot.orb,
    line:
        'Every km you run lands in your bank first. Spend it on the map to travel.',
    perkIcon: AppIcons.mapCurrentLocation,
    perk: 'Your first km are banked',
    lockedHint: 'Log a workout with distance to unlock the Map',
    tier: 1,
    need: 'Log your first km',
  ),
  UnlockKeys.gear: UnlockMeta(
    key: UnlockKeys.gear,
    name: 'Gear',
    icon: AppIcons.navGear,
    color: AppColors.blue,
    slot: UnlockSlot.nav,
    line:
        'Items you find make your hero stronger. Your mount and weapon slots open too.',
    perkIcon: AppIcons.itemCarbonX3,
    perk: 'Your first item is in your bag',
    lockedHint: 'Reach Level 2 and find an item to unlock Gear',
    tier: 2,
    need: 'Find an item',
  ),
  UnlockKeys.chests: UnlockMeta(
    key: UnlockKeys.chests,
    name: 'Region Chests',
    icon: AppIcons.regionChestsHubIcon,
    color: AppColors.green,
    slot: UnlockSlot.hub,
    line: 'Every region hides a chest. Clear its zones to claim it.',
    perkIcon: AppIcons.rewardTreasureChest,
    perk: 'Your first zone counts toward it',
    lockedHint: 'Reach Level 4 and a second zone to unlock',
    tier: 4,
    need: 'Reach a second zone',
  ),
  UnlockKeys.talents: UnlockMeta(
    key: UnlockKeys.talents,
    name: 'Talents',
    icon: AppIcons.talentCrystalIcon,
    color: AppColors.purple,
    slot: UnlockSlot.hub,
    line: 'Spend crystals on talent cards that boost how you earn XP.',
    perkIcon: AppIcons.talentCrystalIcon,
    perk: 'Crystals come with every level',
    lockedHint: 'Reach Level 3 to unlock',
    tier: 3,
    need: 'Reach Level 3',
  ),
  UnlockKeys.shields: UnlockMeta(
    key: UnlockKeys.shields,
    name: 'Streak Shields',
    icon: AppIcons.rewardStreakShield,
    color: AppColors.orange,
    slot: UnlockSlot.chip,
    line: 'A shield saves your streak on a day you can’t train.',
    perkIcon: AppIcons.rewardStreakShield,
    perk: 'First shield at day 7',
    lockedHint: 'Reach Level 3 and keep a 3-day streak to unlock',
    tier: 3,
    need: 'Keep a 3-day streak',
  ),
  UnlockKeys.bosses: UnlockMeta(
    key: UnlockKeys.bosses,
    name: 'Bosses',
    icon: AppIcons.ringBoss,
    color: AppColors.red,
    slot: UnlockSlot.hub,
    line:
        'Your boss fights live in the Adventure Hub. Every workout deals damage.',
    perkIcon: AppIcons.ringBoss,
    perk: 'A boss is waiting for you',
    lockedHint: 'Reach Level 4 and a boss zone to unlock',
    tier: 4,
    need: 'Meet a boss',
  ),
  UnlockKeys.ranks: UnlockMeta(
    key: UnlockKeys.ranks,
    name: 'Titles & Ranks',
    icon: AppIcons.ringTitles,
    color: AppColors.orange,
    slot: UnlockSlot.hub,
    line:
        'Ranks climb as you beat bosses. Titles you earn go next to your name.',
    perkIcon: AppIcons.rankChampion,
    perk: 'Your first rank is in',
    lockedHint: 'Reach Level 5 and beat a boss or earn a title to unlock',
    tier: 5,
    need: 'Beat a boss or earn a title',
  ),
  UnlockKeys.guild: UnlockMeta(
    key: UnlockKeys.guild,
    name: 'Guild',
    icon: AppIcons.ringGuild,
    color: AppColors.blue,
    slot: UnlockSlot.hub,
    line: 'Team up for guild raids. Everyone’s workouts hit the same boss.',
    perkIcon: AppIcons.ringGuild,
    perk: 'Up to 5 members per guild',
    lockedHint: 'Reach Level 8 to unlock',
    tier: 8,
    need: 'Reach Level 8',
  ),
  UnlockKeys.leaderboard: UnlockMeta(
    key: UnlockKeys.leaderboard,
    name: 'Leaderboard',
    icon: AppIcons.ringLeaderboard,
    color: AppColors.blue,
    slot: UnlockSlot.hub,
    line:
        'See where you stand. Every player you pass adds to your rank-up chest.',
    perkIcon: AppIcons.ringLeaderboard,
    perk: 'Global, region and guild boards',
    lockedHint: 'Reach Level 6 to unlock',
    tier: 6,
    need: 'Reach Level 6',
  ),
  UnlockKeys.modes: UnlockMeta(
    key: UnlockKeys.modes,
    name: 'Game Modes',
    icon: AppIcons.navMode,
    color: Color(0xFFF0883E),
    slot: UnlockSlot.nav,
    line:
        'Short game modes that turn your workouts into extra coins. Burn Chain is first.',
    perkIcon: AppIcons.rewardStreakFire,
    perk: 'Burn Chain · beat your last burn for ×2',
    lockedHint: 'Reach Level 10 to unlock Modes',
    tier: 10,
    need: 'Reach Level 10',
  ),
  UnlockKeys.delve: UnlockMeta(
    key: UnlockKeys.delve,
    name: 'Treasure Delve',
    icon: AppIcons.rewardTreasureChest,
    color: AppColors.orange,
    slot: UnlockSlot.mode,
    line:
        'Five-chamber vault runs. Your stats decide which paths are safe to take.',
    perkIcon: AppIcons.itemEnergyGel,
    perk: 'Workouts earn runs',
    lockedHint: 'Unlocks at Level 15',
    tier: 15,
    need: 'Reach Level 15',
  ),
};

UnlockMeta unlockMeta(String key) => kUnlockCatalog[key]!;

/// Features that belong to [level], in catalog order (at most two).
List<UnlockMeta> unlocksAtLevel(int level) =>
    [for (final m in kUnlockCatalog.values) if (m.tier == level) m];

/// Features whose level is in `(from, to]`, for a level-up that may skip levels.
List<UnlockMeta> unlocksBetweenLevels(int from, int to) =>
    [for (final m in kUnlockCatalog.values) if (m.tier > from && m.tier <= to) m];
