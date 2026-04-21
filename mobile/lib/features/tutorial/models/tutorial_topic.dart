import 'tutorial_step.dart';

/// Replayable topic tutorials available from the Tutorials Hub.
/// The string values MUST match the backend contract for
/// `POST /api/tutorial/replay-topic { topic: "..." }`.
enum TutorialTopic {
  xpStats('xp-stats'),
  questsStreaks('quests-streaks'),
  activityLogging('activity-logging'),
  worldMap('world-map'),
  bossSystem('boss-system');

  final String apiValue;
  const TutorialTopic(this.apiValue);

  /// Bitmask bit index for `tutorialTopicsSeen`.
  int get bitIndex {
    switch (this) {
      case TutorialTopic.xpStats:
        return 0;
      case TutorialTopic.questsStreaks:
        return 1;
      case TutorialTopic.activityLogging:
        return 2;
      case TutorialTopic.worldMap:
        return 3;
      case TutorialTopic.bossSystem:
        return 4;
    }
  }

  /// Human-readable row title.
  String get label {
    switch (this) {
      case TutorialTopic.xpStats:
        return 'XP & Stats';
      case TutorialTopic.questsStreaks:
        return 'Quests & Streaks';
      case TutorialTopic.activityLogging:
        return 'Activity Logging';
      case TutorialTopic.worldMap:
        return 'World Map';
      case TutorialTopic.bossSystem:
        return 'Boss System';
    }
  }

  /// Leading emoji used in the hub list.
  String get emoji {
    switch (this) {
      case TutorialTopic.xpStats:
        return '\u26A1';
      case TutorialTopic.questsStreaks:
        return '\uD83D\uDCDC';
      case TutorialTopic.activityLogging:
        return '\uD83D\uDDE1';
      case TutorialTopic.worldMap:
        return '\uD83D\uDDFA\uFE0F';
      case TutorialTopic.bossSystem:
        return '\uD83D\uDD25';
    }
  }

  /// Ordered list of bubble steps this topic replays on Home.
  List<TutorialStep> get steps {
    switch (this) {
      case TutorialTopic.xpStats:
        return const [TutorialStep.xpBar, TutorialStep.stats];
      case TutorialTopic.questsStreaks:
        return const [TutorialStep.quests];
      case TutorialTopic.activityLogging:
        return const [TutorialStep.logActivity];
      case TutorialTopic.worldMap:
        return const [TutorialStep.mapTab];
      case TutorialTopic.bossSystem:
        return const [TutorialStep.bossFab];
    }
  }
}

/// Returns true if `topic` has been seen at least once in `bitmask`.
bool tutorialTopicSeen(int bitmask, TutorialTopic topic) {
  return (bitmask & (1 << topic.bitIndex)) != 0;
}
