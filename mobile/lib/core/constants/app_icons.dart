/// Central registry of every icon asset path in the app.
///
/// All icons are full-colour RPG-style PNGs on transparent backgrounds.
/// Do NOT apply colour tinting (BlendMode.srcIn) — render them as-is.
class AppIcons {
  AppIcons._();

  // ── Navigation ──────────────────────────────────────────────────────────────
  static const String navHome    = 'assets/icons/nav_home.png';
  static const String navMap     = 'assets/icons/nav_map.png';
  static const String navProfile = 'assets/icons/nav_profile.png';
  static const String navQuests  = 'assets/icons/nav_quests.png';
  static const String navStats   = 'assets/icons/nav_stats.png';
  static const String menuIcon   = 'assets/menu_icon.png';

  // ── Ring Menu ───────────────────────────────────────────────────────────────
static const String ringBoss        = 'assets/icons/ring_boss.png';
  static const String ringGuild       = 'assets/icons/ring_guild.png';
  static const String ringLeaderboard = 'assets/icons/ring_leaderboard.png';
  static const String ringTitles      = 'assets/icons/ring_titles.png';
  static const String ringWorld       = 'assets/icons/ring_world.png';

  // Titles & Ranks
  static const String rankChampion = 'assets/Titles&Ranks/rank_champion.png';
  static const String rankLegend   = 'assets/Titles&Ranks/rank_legend.png';
  static const String rankNovice   = 'assets/Titles&Ranks/rank_novice.png';
  static const String rankVeteran  = 'assets/Titles&Ranks/rank_veteran.png';
  static const String rankWarrior  = 'assets/Titles&Ranks/rank_warrior.png';

  static const String title5amClub          = 'assets/Titles&Ranks/title_5am_club.png';
  static const String titleChampion         = 'assets/Titles&Ranks/title_champion.png';
  static const String titleMarathoner       = 'assets/Titles&Ranks/title_marathoner.png';
  static const String titleNoviceAdventurer = 'assets/Titles&Ranks/title_novice_adventurer.png';
  static const String titleRaidVeteran      = 'assets/Titles&Ranks/title_raid_veteran.png';
  static const String titleStreakMaster     = 'assets/Titles&Ranks/title_streak_master.png';
  static const String titleUnstoppable      = 'assets/Titles&Ranks/title_unstoppable.png';

  // ── Activity Types ──────────────────────────────────────────────────────────
  static const String activityClimbing      = 'assets/icons/activity_climbing.png';
  static const String activityCycling       = 'assets/icons/activity_cycling.png';
  static const String activityGym           = 'assets/icons/activity_gym.png';
  static const String activityHiit          = 'assets/icons/activity_hiit.png';
  static const String activityHiking        = 'assets/icons/activity_hiking.png';
  static const String activityMobility      = 'assets/icons/activity_mobility.png';
  static const String activityMtbCycling    = 'assets/icons/activity_mtb_cycling.png';
  static const String activityRockClimbing  = 'assets/icons/activity_rock_climbing.png';
  static const String activityRunning       = 'assets/icons/activity_running.png';
  static const String activityStretching    = 'assets/icons/activity_stretching.png';
  static const String activitySwimming      = 'assets/icons/activity_swimming.png';
  static const String activityWeightlifting = 'assets/icons/activity_weightlifting.png';
  static const String activityYoga          = 'assets/icons/activity_yoga.png';

  // ── Character Stats ─────────────────────────────────────────────────────────
  static const String statAgility    = 'assets/icons/stat_agility.png';
  static const String statEndurance  = 'assets/icons/stat_endurance.png';
  static const String statFlexibility = 'assets/icons/stat_flexibility.png';
  static const String statStamina    = 'assets/icons/stat_stamina.png';
  static const String statStrength   = 'assets/icons/stat_strength.png';

  // ── Map Zones & Nodes ───────────────────────────────────────────────────────
  static const String mapCurrentLocation = 'assets/icons/map_current_location.png';
  static const String mapDestination     = 'assets/icons/map_destination.png';
  static const String mapXpReward        = 'assets/icons/map_xp_reward.png';
  static const String zoneAshfieldPlains  = 'assets/icons/zone_ashfield_plains.png';
  static const String zoneCoralCoast      = 'assets/icons/zone_coral_coast.png';
  static const String zoneDesertOfTrials  = 'assets/icons/zone_desert_of_trials.png';
  static const String zoneFinalApproach   = 'assets/icons/zone_final_approach.png';
  static const String zoneFirstFork       = 'assets/icons/zone_first_fork.png';
  static const String zoneFrostboundPeaks = 'assets/icons/zone_frostbound_peaks.png';
  static const String zoneIronPeaks       = 'assets/icons/zone_iron_peaks.png';
  static const String zoneTheConvergence  = 'assets/icons/zone_the_convergence.png';
  static const String zoneThornwoodForest = 'assets/icons/zone_thornwood_forest.png';

  // ── Quest Categories ────────────────────────────────────────────────────────
  static const String questCalories     = 'assets/icons/quest_calories.png';
  static const String questDailyLogin   = 'assets/icons/quest_daily_login.png';
  static const String questDistance     = 'assets/icons/quest_distance.png';
  static const String questDuration     = 'assets/icons/quest_duration.png';
  static const String questGeneral      = 'assets/icons/quest_general.png';
  static const String questWorkoutCount = 'assets/icons/quest_workout_count.png';

  // ── Rewards & Progression ───────────────────────────────────────────────────
  static const String rewardDailyBonus    = 'assets/icons/reward_daily_bonus.png';
  static const String questFirst          = 'assets/icons/icon_first_quest.png';
  static const String rewardGrantItem     = 'assets/icons/reward_grant_item.png';
  static const String rewardStreakFire    = 'assets/icons/reward_streak_fire.png';
  static const String rewardStreakShield  = 'assets/icons/reward_streak_shield.png';
  static const String rewardTreasureChest = 'assets/icons/reward_treasure_chest.png';
  static const String rewardXpSparkle    = 'assets/icons/reward_xp_sparkle.png';
  static const String rewardXpStorm      = 'assets/icons/reward_xp_storm.png';
  static const String uiNewItem          = 'assets/icons/ui_new_item.png';

  // ── Avatars ─────────────────────────────────────────────────────────────────
  static const String avatarArcher    = 'assets/icons/avatar_archer.png';
  static const String avatarCrown     = 'assets/icons/avatar_crown.png';
  static const String avatarDiamond   = 'assets/icons/avatar_diamond.png';
  static const String avatarElf       = 'assets/icons/avatar_elf.png';
  static const String avatarFox       = 'assets/icons/avatar_fox.png';
  static const String avatarLightning = 'assets/icons/avatar_lightning.png';
  static const String avatarMonk      = 'assets/icons/avatar_monk.png';
  static const String avatarMoon      = 'assets/icons/avatar_moon.png';
  static const String avatarMystic    = 'assets/icons/avatar_mystic.png';
  static const String avatarNinja     = 'assets/icons/avatar_ninja.png';
  static const String avatarPaladin   = 'assets/icons/avatar_paladin.png';
  static const String avatarStar      = 'assets/icons/avatar_star.png';
  static const String avatarSuperhero = 'assets/icons/avatar_superhero.png';
  static const String avatarWarrior   = 'assets/icons/avatar_warrior.png';
  static const String avatarWizard    = 'assets/icons/avatar_wizard.png';
  static const String avatarWolf      = 'assets/icons/avatar_wolf.png';

  // —— Classes ———————————————————————————————————————————————————————————————
  static const String classWarrior = 'assets/Classes/warrior_icon.png';
  static const String classArcher = 'assets/Classes/archer_icon.png';
  static const String classMystic = 'assets/Classes/mystic_icon.png';
  static const String classSentinel = 'assets/Classes/sentinel_icon.png';
  static const String setupUnfinished = 'assets/Classes/icon_setup_unfinished.png';
  static const String classSelectBurst = 'assets/Classes/class_select_burst.png';
  static const String classSelectRuneRing = 'assets/Classes/class_select_rune_ring.png';
}
