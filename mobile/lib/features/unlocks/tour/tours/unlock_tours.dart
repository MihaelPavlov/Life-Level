import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../models/unlock_catalog.dart';
import '../tour_step.dart';

/// Tour target ids. Each is placed on the real widget with a `TourTarget`.
abstract final class TourIds {
  static const homeHero = 'home.hero';
  static const homeHub = 'home.hub';
  static const homeBanked = 'home.banked';

  static const mapOrb = 'shell.mapOrb';
  static const journeyCard = 'journey.card';
  static const journeyViewMap = 'journey.viewOnMap';

  static const achContinue = 'achievements.continue';
  static const achRoads = 'achievements.roads';
  static const achClaimAll = 'achievements.claimAll';

  static const gearSlots = 'gear.slots';
  static const gearStats = 'gear.stats';
  static const gearFirstItem = 'gear.firstItem';

  static const chestsCurrent = 'chests.current';
  static const chestsRewards = 'chests.rewards';
  static const chestsNext = 'chests.next';

  static const talentsCurrency = 'talents.currency';
  static const talentsGrid = 'talents.grid';
  static const talentsDraw = 'talents.draw';

  static const streakHeader = 'streak.header';
  static const streakShields = 'streak.shields';
  static const streakClaim = 'streak.claim';

  static const bossTop = 'boss.activeTop';
  static const bossHp = 'boss.hp';
  static const bossEnter = 'boss.enter';

  static const titlesRank = 'titles.rank';
  static const titlesLocked = 'titles.locked';
  static const titlesEquip = 'titles.equip';

  static const leaderboardScopes = 'leaderboard.scopes';
  static const leaderboardMetrics = 'leaderboard.metrics';
  static const leaderboardYou = 'leaderboard.you';

  static const guildInfo = 'guild.info';
  static const guildCreate = 'guild.create';
  static const guildFind = 'guild.find';

  static const modesBurn = 'modes.burn';
  static const modesDelve = 'modes.delve';
}

/// The stops each unlock's tour makes, ending on the feature's main action
/// (copy from the Guided Unlocks and Unlock Path designs). Home has 3 and
/// Map 4 (it starts on banked km); every other feature has 3.
List<TourStep> tourStepsFor(String key) => switch (key) {
      UnlockKeys.home => const [
          TourStep(
            targetId: TourIds.homeHero,
            icon: AppIcons.homePowerIcon,
            eyebrow: 'YOUR HERO',
            title: 'This is you · Level 1',
            body:
                'Workouts raise your **XP, stats and Power**. **Pull Home down** to import new ones.',
            color: AppColors.orange,
            pad: 4,
            radius: 22,
          ),
          TourStep(
            targetId: TourIds.homeHub,
            icon: AppIcons.rankChampion,
            eyebrow: 'WHAT’S NEXT',
            title: 'Features open as you level',
            body:
                'Each level opens **one or two** of these. Locked tiles keep their names so you know what’s coming.',
            color: AppColors.orange,
            pad: 2,
          ),
          TourStep(
            targetId: TourIds.mapOrb,
            icon: AppIcons.mapDestination,
            eyebrow: 'YOUR FIRST UNLOCK',
            title: 'Your first workout opens the Map',
            body:
                'Run, ride or walk. The km you log are **banked** and carry you across the world.',
            circular: true,
            pad: 4,
          ),
        ],
      UnlockKeys.map => const [
          TourStep(
            targetId: TourIds.homeBanked,
            icon: AppIcons.mapCurrentLocation,
            eyebrow: 'BANKED KM',
            title: 'Your km land here first',
            body:
                'Every km you run, ride or walk is **banked**. Banked km never expire. You spend them to travel.',
            pad: 6,
            radius: 14,
          ),
          TourStep(
            targetId: TourIds.mapOrb,
            icon: AppIcons.mapDestination,
            eyebrow: 'THE MAP BUTTON',
            title: 'Spend them on your journey',
            body:
                'The ring shows how close your next stop is. The label says what’s next: **km to go, a boss, a chest or a dungeon**.',
            tapLabel: 'TAP THE MAP BUTTON',
            circular: true,
            pad: 4,
          ),
          TourStep(
            targetId: TourIds.journeyCard,
            icon: AppIcons.mapDestination,
            eyebrow: 'YOUR JOURNEY',
            title: 'Where you’re heading',
            body:
                'The next stop and how far it is. If your **banked km** cover it, you can go now. **Sync** pulls in new workouts.',
            pad: 4,
            radius: 20,
          ),
          TourStep(
            targetId: TourIds.journeyViewMap,
            icon: AppIcons.ringWorld,
            eyebrow: 'TRAVEL',
            title: 'Use banked km to move',
            body:
                'Travel walks your hero down the trail and takes the km out of your bank. Whatever is left stays banked.',
            tapLabel: 'TAP THE BUTTON',
            pad: 4,
            radius: 14,
          ),
        ],
      UnlockKeys.achievements => const [
          TourStep(
            targetId: TourIds.achContinue,
            icon: AppIcons.rewardTreasureChest,
            eyebrow: 'CONTINUE',
            title: 'Your nearest chest',
            body:
                'Each road has **5 stages**. Finish every badge in a stage and its chest opens.',
          ),
          TourStep(
            targetId: TourIds.achRoads,
            icon: AppIcons.rankChampion,
            eyebrow: 'ALL ROADS',
            title: 'One road per way you train',
            body:
                'Running, strength, streaks and raids. Every workout moves the roads it counts for.',
          ),
          TourStep(
            targetId: TourIds.achClaimAll,
            icon: AppIcons.rewardTreasureChest,
            eyebrow: 'YOUR FIRST BADGE',
            title: 'Claim what you earned',
            body: 'Badges you’ve earned wait here. Tap **Claim all**.',
            tapLabel: 'TAP CLAIM ALL',
            radius: 14,
          ),
        ],
      UnlockKeys.gear => const [
          TourStep(
            targetId: TourIds.gearSlots,
            icon: AppIcons.navGear,
            eyebrow: 'SIX SLOTS',
            title: 'Wear what you find',
            body:
                'Head, chest, accessory, hands, legs and feet. **Equipped items glow in their rarity color.**',
            radius: 16,
          ),
          TourStep(
            targetId: TourIds.gearStats,
            icon: AppIcons.homePowerIcon,
            eyebrow: 'COMBAT STATS',
            title: 'Gear makes you stronger',
            body:
                '**Power, Attack, Health and Defense** decide how hard you hit bosses.',
            pad: 4,
            radius: 16,
          ),
          TourStep(
            targetId: TourIds.gearFirstItem,
            icon: AppIcons.itemCarbonX3,
            eyebrow: 'YOUR FIRST ITEM',
            title: 'Tap your new item',
            body: 'Every item shows its bonuses when you tap it.',
            tapLabel: 'TAP THE ITEM',
            radius: 12,
          ),
        ],
      UnlockKeys.chests => const [
          TourStep(
            targetId: TourIds.chestsCurrent,
            icon: AppIcons.regionChestsHubIcon,
            eyebrow: 'ONE CHEST PER REGION',
            title: 'Clear the region, claim the chest',
            body: 'Every zone you reach counts toward **this region’s chest**.',
            pad: 4,
            radius: 20,
          ),
          TourStep(
            targetId: TourIds.chestsRewards,
            icon: AppIcons.homeGemIcon,
            eyebrow: 'WHAT’S INSIDE',
            title: 'Gems and coins',
            body: 'Later regions hold bigger chests.',
          ),
          TourStep(
            targetId: TourIds.chestsNext,
            icon: AppIcons.mapDestination,
            eyebrow: 'WHAT’S NEXT',
            title: 'The next region waits',
            body: 'Clear this one to open the next region.',
            tapLabel: 'TAP THE NEXT REGION',
            pad: 4,
            radius: 16,
          ),
        ],
      UnlockKeys.talents => const [
          TourStep(
            targetId: TourIds.talentsCurrency,
            icon: AppIcons.talentCrystalIcon,
            eyebrow: 'CRYSTALS',
            title: 'You earn crystals by leveling',
            body: 'A draw costs **1 crystal and coins**.',
            pad: 4,
            radius: 22,
          ),
          TourStep(
            targetId: TourIds.talentsGrid,
            icon: AppIcons.talentCrystalIcon,
            eyebrow: 'TALENTS',
            title: 'Passive bonuses',
            body:
                'Faded tiles are ones you don’t own yet. Drawing one you own levels it up.',
            radius: 16,
          ),
          TourStep(
            targetId: TourIds.talentsDraw,
            icon: AppIcons.talentCrystalIcon,
            eyebrow: 'FIRST DRAW',
            title: 'Draw your first talent',
            body: 'Spend your crystal and see what you get.',
            tapLabel: 'TAP CARD DRAW',
            radius: 14,
          ),
        ],
      UnlockKeys.shields => const [
          TourStep(
            targetId: TourIds.streakHeader,
            icon: AppIcons.rewardStreakFire,
            eyebrow: 'YOUR STREAK',
            title: 'Days in a row',
            body:
                'Any activity keeps it going. **Miss a day** and it starts over.',
            pad: 8,
            radius: 14,
          ),
          TourStep(
            targetId: TourIds.streakShields,
            icon: AppIcons.rewardStreakShield,
            eyebrow: 'SHIELDS',
            title: 'A shield saves your streak',
            body:
                'You earn one every 7 active days. Spend it to cover a missed day.',
            radius: 14,
          ),
          TourStep(
            targetId: TourIds.streakClaim,
            icon: AppIcons.homeCoinIcon,
            eyebrow: 'EVERY DAY',
            title: 'Collect your streak coins',
            body: 'Each streak day adds more. Day 7 also gives ×1.5 XP.',
            tapLabel: 'TAP CLAIM REWARD',
            pad: 4,
            radius: 12,
          ),
        ],
      UnlockKeys.bosses => const [
          TourStep(
            targetId: TourIds.bossTop,
            icon: AppIcons.ringBoss,
            eyebrow: 'YOUR FIRST BOSS',
            title: 'A boss on a timer',
            body: 'Bring its HP to zero **before the timer runs out**.',
            pad: 2,
          ),
          TourStep(
            targetId: TourIds.bossHp,
            icon: AppIcons.homePowerIcon,
            eyebrow: 'HOW YOU FIGHT',
            title: 'Workouts deal damage',
            body:
                'Every workout hits the boss. **Your damage** is counted here.',
            radius: 14,
          ),
          TourStep(
            targetId: TourIds.bossEnter,
            icon: AppIcons.ringBoss,
            eyebrow: 'START THE FIGHT',
            title: 'Enter the battle',
            body: 'See how each workout turns into damage.',
            tapLabel: 'TAP ENTER BATTLE',
            pad: 4,
            radius: 16,
          ),
        ],
      UnlockKeys.ranks => const [
          TourStep(
            targetId: TourIds.titlesRank,
            icon: AppIcons.rankChampion,
            eyebrow: 'YOUR RANK',
            title: 'Ranks climb with bosses',
            body:
                'Novice, Warrior, Veteran, Champion, Legend. **Every boss you beat** moves you up.',
            radius: 16,
          ),
          TourStep(
            targetId: TourIds.titlesLocked,
            icon: AppIcons.ringTitles,
            eyebrow: 'TITLES',
            title: 'Earned by playing',
            body:
                'Quests, streaks, bosses and ranks each unlock a title. Locked ones show **what they need**.',
            radius: 14,
          ),
          TourStep(
            targetId: TourIds.titlesEquip,
            icon: AppIcons.ringTitles,
            eyebrow: 'WEAR IT',
            title: 'Equip your title',
            body: 'It shows next to your name on Profile and the leaderboard.',
            tapLabel: 'TAP EQUIP',
            radius: 14,
          ),
        ],
      UnlockKeys.leaderboard => const [
          TourStep(
            targetId: TourIds.leaderboardScopes,
            icon: AppIcons.ringLeaderboard,
            eyebrow: 'THREE BOARDS',
            title: 'Global, region and guild',
            body:
                'Compare yourself with **everyone**, the players in your region, or your guild.',
            radius: 14,
          ),
          TourStep(
            targetId: TourIds.leaderboardYou,
            icon: AppIcons.rewardTreasureChest,
            eyebrow: 'YOUR SPOT',
            title: 'Pass players, fill your chest',
            body:
                'Every player you pass adds a reward to your **rank-up chest**. Open it from your row.',
            radius: 16,
          ),
          TourStep(
            targetId: TourIds.leaderboardMetrics,
            icon: AppIcons.ringLeaderboard,
            eyebrow: 'MORE WAYS TO WIN',
            title: 'Pick what you’re ranked by',
            body:
                'Power is all-time. **XP, km and boss damage** reset every week, so anyone can climb.',
            tapLabel: 'TAP A BOARD',
            radius: 14,
          ),
        ],
      UnlockKeys.guild => const [
          TourStep(
            targetId: TourIds.guildInfo,
            icon: AppIcons.ringGuild,
            eyebrow: 'SMALL TEAMS',
            title: 'Up to 5 members',
            body:
                'Everyone’s workouts hit the **same raid boss**. The top damage dealer earns bonus XP.',
          ),
          TourStep(
            targetId: TourIds.guildCreate,
            icon: AppIcons.ringTitles,
            eyebrow: 'OR LEAD ONE',
            title: 'Found your own',
            body: 'Pick a crest and a motto, then invite up to 4 friends.',
            radius: 14,
          ),
          TourStep(
            targetId: TourIds.guildFind,
            icon: AppIcons.ringGuild,
            eyebrow: 'START HERE',
            title: 'Find a guild',
            body: 'Search open guilds and join one in a tap.',
            tapLabel: 'TAP FIND A GUILD',
            radius: 14,
          ),
        ],
      UnlockKeys.modes => const [
          TourStep(
            targetId: TourIds.modesBurn,
            icon: AppIcons.rewardStreakFire,
            eyebrow: 'FIRST MODE',
            title: 'Burn Chain',
            body:
                'For 24 hours, every workout that burns **more calories than the last** pays calories × 2 in coins.',
            pad: 4,
          ),
          TourStep(
            targetId: TourIds.modesDelve,
            icon: AppIcons.rewardTreasureChest,
            eyebrow: 'NEXT MODE',
            title: 'Treasure Delve at Level 15',
            body:
                'New modes open as you level up. Locked banners show what’s next.',
            pad: 4,
          ),
          TourStep(
            targetId: TourIds.modesBurn,
            icon: AppIcons.rewardStreakFire,
            eyebrow: 'START HERE',
            title: 'Start your first chain',
            body: 'Your next workout sets the bar.',
            tapLabel: 'TAP BURN CHAIN',
            pad: 4,
          ),
        ],
      UnlockKeys.delve => const [
          TourStep(
            targetId: TourIds.modesDelve,
            icon: AppIcons.rewardTreasureChest,
            eyebrow: 'NEW MODE',
            title: 'Treasure Delve',
            body:
                'Short 5-chamber runs. Pick a path, pass a stat check, then **bank your coins or go deeper**.',
            pad: 4,
          ),
          TourStep(
            targetId: TourIds.modesDelve,
            icon: AppIcons.itemEnergyGel,
            eyebrow: 'RUNS',
            title: 'Workouts earn runs',
            body: '20 min earns 1 run, 45 min earns 2. Up to 3 a day.',
            pad: 4,
          ),
          TourStep(
            targetId: TourIds.modesDelve,
            icon: AppIcons.rewardTreasureChest,
            eyebrow: 'FIRST RUN',
            title: 'Enter the vault',
            body: 'Your runs come from today’s workouts.',
            tapLabel: 'TAP TREASURE DELVE',
            pad: 4,
          ),
        ],
      _ => const [],
    };
