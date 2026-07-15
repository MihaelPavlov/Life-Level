import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';

/// Coach-mark step identifier. Values match the server's `tutorialStep` field
/// (0 = intro modal, 1-6 = backend bubble steps, 7 = outro modal, -1 = skipped,
/// 99 = fully completed).
enum TutorialStep {
  intro, // 0
  xpBar, // 1
  stats, // 2
  quests, // 3
  logActivity, // 4
  mapTab, // 5
  bossFab, // 6
  outro, // 7
  mapWorldBack,
  mapRegions,
  mapZoneTrail,
  mapNormalZone,
  mapChestZone,
  mapSpecialZone,
  mapDungeonZone,
  mapBossZone;

  int get serverValue {
    switch (this) {
      case TutorialStep.intro:
        return 0;
      case TutorialStep.xpBar:
        return 1;
      case TutorialStep.stats:
        return 2;
      case TutorialStep.quests:
        return 3;
      case TutorialStep.logActivity:
        return 4;
      case TutorialStep.mapTab:
        return 5;
      case TutorialStep.bossFab:
        return 6;
      case TutorialStep.outro:
        return 7;
      case TutorialStep.mapWorldBack:
      case TutorialStep.mapRegions:
      case TutorialStep.mapZoneTrail:
      case TutorialStep.mapNormalZone:
      case TutorialStep.mapChestZone:
      case TutorialStep.mapSpecialZone:
      case TutorialStep.mapDungeonZone:
      case TutorialStep.mapBossZone:
        return -99;
    }
  }

  static TutorialStep? fromServer(int value) {
    switch (value) {
      case 0:
        return TutorialStep.intro;
      case 1:
        return TutorialStep.logActivity;
      case 2:
        return TutorialStep.xpBar;
      case 3:
        return TutorialStep.stats;
      case 4:
        return TutorialStep.quests;
      case 5:
        return TutorialStep.mapTab;
      case 6:
        return TutorialStep.bossFab;
      case 7:
        return TutorialStep.outro;
      default:
        return null;
    }
  }

  String? get targetKeyId {
    switch (this) {
      case TutorialStep.xpBar:
        return 'xpCard';
      case TutorialStep.stats:
        return 'statsRow';
      case TutorialStep.quests:
        return 'questsCard';
      case TutorialStep.logActivity:
        return 'streakStrip';
      case TutorialStep.mapTab:
        return 'mapTab';
      case TutorialStep.bossFab:
        return 'bossFab';
      case TutorialStep.intro:
      case TutorialStep.outro:
        return null;
      case TutorialStep.mapWorldBack:
        return 'mapWorldBack';
      case TutorialStep.mapRegions:
        return 'mapRegions';
      case TutorialStep.mapZoneTrail:
        return 'mapZoneTrail';
      case TutorialStep.mapNormalZone:
        return 'mapNormalZone';
      case TutorialStep.mapChestZone:
        return 'mapChestZone';
      case TutorialStep.mapSpecialZone:
        return 'mapSpecialZone';
      case TutorialStep.mapDungeonZone:
        return 'mapDungeonZone';
      case TutorialStep.mapBossZone:
        return 'mapBossZone';
    }
  }
}

class TutorialStepContent {
  final String iconAsset;
  final String title;
  final String body;
  final Color accent;

  const TutorialStepContent({
    required this.iconAsset,
    required this.title,
    required this.body,
    required this.accent,
  });
}

const Map<TutorialStep, TutorialStepContent> kTutorialStepContent = {
  TutorialStep.xpBar: TutorialStepContent(
    iconAsset: AppIcons.mapDestination,
    title: 'Your Next Stop',
    body:
        'This card shows your current map route and the next stop ahead. Distance from your workouts moves you forward through the world.',
    accent: AppColors.blue,
  ),
  TutorialStep.stats: TutorialStepContent(
    iconAsset: AppIcons.rewardXpSparkle,
    title: 'Banked Km, XP, Shields',
    body:
        'Banked km is the distance you have already earned and can use to progress on the route. This strip also shows your today XP and how many shields you currently hold.',
    accent: AppColors.purple,
  ),
  TutorialStep.quests: TutorialStepContent(
    iconAsset: AppIcons.questGeneral,
    title: 'Daily Quests',
    body:
        'Your active quests live here. Complete them for extra rewards and use them as your short-term checklist each day.',
    accent: AppColors.orange,
  ),
  TutorialStep.logActivity: TutorialStepContent(
    iconAsset: AppIcons.rewardStreakShield,
    title: 'Streak Tracker',
    body:
        'This strip shows your current streak and your weekly rhythm. Come back consistently to keep the chain alive and build momentum day by day.',
    accent: AppColors.orange,
  ),
  TutorialStep.mapTab: TutorialStepContent(
    iconAsset: AppIcons.mapDestination,
    title: 'The Adventure Map',
    body:
        'Every km you run or ride moves you across the world. Unlock zones like Forest of Endurance.',
    accent: AppColors.green,
  ),
  TutorialStep.bossFab: TutorialStepContent(
    iconAsset: AppIcons.ringTitles,
    title: 'Quick Menu',
    body:
        'This center button opens the quick menu. From here you can jump to bosses, world, titles, stats, guild, and the rest of the extra navigation.',
    accent: AppColors.blue,
  ),
  TutorialStep.mapWorldBack: TutorialStepContent(
    iconAsset: AppIcons.mapDestination,
    title: 'Back To World',
    body:
        'This button returns from a region to the world view so you can move between bigger areas.',
    accent: AppColors.blue,
  ),
  TutorialStep.mapRegions: TutorialStepContent(
    iconAsset: AppIcons.mapDestination,
    title: 'Regions',
    body:
        'The world is split into regions. Each card is a chapter with its own route, rewards, and boss.',
    accent: AppColors.green,
  ),
  TutorialStep.mapZoneTrail: TutorialStepContent(
    iconAsset: AppIcons.mapDestination,
    title: 'Zones',
    body:
        'Inside a region, your route is made of zones. Your workouts move you node by node along this trail.',
    accent: AppColors.orange,
  ),
  TutorialStep.mapNormalZone: TutorialStepContent(
    iconAsset: AppIcons.mapDestination,
    title: 'Normal Zone',
    body:
        'A normal zone is a standard stop on the path. Reach it to collect its reward and continue forward.',
    accent: AppColors.blue,
  ),
  TutorialStep.mapChestZone: TutorialStepContent(
    iconAsset: AppIcons.rewardXpSparkle,
    title: 'Chest Zone',
    body:
        'Chest zones give one-time rewards when you arrive there. Open them as soon as you stand on the node.',
    accent: AppColors.orange,
  ),
  TutorialStep.mapSpecialZone: TutorialStepContent(
    iconAsset: AppIcons.ringTitles,
    title: 'Special Zone',
    body:
        'Special zones change the route. Crossroads let you choose which branch of the adventure you will follow.',
    accent: AppColors.purple,
  ),
  TutorialStep.mapDungeonZone: TutorialStepContent(
    iconAsset: AppIcons.ringTitles,
    title: 'Dungeon Zone',
    body:
        'Dungeon zones contain multiple floors. Once you enter, your next activities clear the floors one by one.',
    accent: AppColors.purple,
  ),
  TutorialStep.mapBossZone: TutorialStepContent(
    iconAsset: AppIcons.ringTitles,
    title: 'Boss Zone',
    body:
        'Boss zones are region gates. Beat the boss here to finish the chapter and unlock the next region.',
    accent: AppColors.red,
  ),
};

const int kTutorialBubbleCount = 6;
