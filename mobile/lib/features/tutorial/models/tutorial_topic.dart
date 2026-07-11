import '../../../core/constants/app_icons.dart';
import 'tutorial_step.dart';

enum TutorialTopic {
  streakSystem('activity-logging'),
  xpStats('xp-stats'),
  dailyQuests('quests-streaks'),
  worldMap('world-map'),
  bossSystem('boss-system');

  final String apiValue;
  const TutorialTopic(this.apiValue);

  int get bitIndex {
    switch (this) {
      case TutorialTopic.xpStats:
        return 0;
      case TutorialTopic.dailyQuests:
        return 1;
      case TutorialTopic.streakSystem:
        return 2;
      case TutorialTopic.worldMap:
        return 3;
      case TutorialTopic.bossSystem:
        return 4;
    }
  }

  String get label {
    switch (this) {
      case TutorialTopic.xpStats:
        return 'Next Stop & Stats';
      case TutorialTopic.dailyQuests:
        return 'Daily Quests';
      case TutorialTopic.streakSystem:
        return 'Streak System';
      case TutorialTopic.worldMap:
        return 'World Map';
      case TutorialTopic.bossSystem:
        return 'Quick Menu';
    }
  }

  String get iconAsset {
    switch (this) {
      case TutorialTopic.xpStats:
        return AppIcons.rewardXpSparkle;
      case TutorialTopic.dailyQuests:
        return AppIcons.questGeneral;
      case TutorialTopic.streakSystem:
        return AppIcons.rewardStreakShield;
      case TutorialTopic.worldMap:
        return AppIcons.mapDestination;
      case TutorialTopic.bossSystem:
        return AppIcons.ringTitles;
    }
  }

  List<TutorialStep> get steps {
    switch (this) {
      case TutorialTopic.xpStats:
        return const [TutorialStep.xpBar, TutorialStep.stats];
      case TutorialTopic.dailyQuests:
        return const [TutorialStep.quests];
      case TutorialTopic.streakSystem:
        return const [TutorialStep.logActivity];
      case TutorialTopic.worldMap:
        return const [TutorialStep.mapTab];
      case TutorialTopic.bossSystem:
        return const [TutorialStep.bossFab];
    }
  }
}

bool tutorialTopicSeen(int bitmask, TutorialTopic topic) {
  return (bitmask & (1 << topic.bitIndex)) != 0;
}
