import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Coach-mark step identifier. Values match the server's `tutorialStep` field
/// (0 = intro modal, 1–6 = bubble steps, 7 = outro modal, -1 = skipped,
/// 99 = fully completed).
enum TutorialStep {
  intro, // 0
  xpBar, // 1
  stats, // 2
  quests, // 3
  logActivity, // 4
  mapTab, // 5
  bossFab, // 6
  outro; // 7

  /// Server-side integer for this step.
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
    }
  }

  /// Parse server integer back to an enum. Returns `null` for -1 (skipped)
  /// and 99 (completed) — those are terminal states with no active bubble.
  static TutorialStep? fromServer(int value) {
    switch (value) {
      case 0:
        return TutorialStep.intro;
      case 1:
        return TutorialStep.xpBar;
      case 2:
        return TutorialStep.stats;
      case 3:
        return TutorialStep.quests;
      case 4:
        return TutorialStep.logActivity;
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

  /// Human identifier for the GlobalKey that targets this step on Home.
  /// `null` for modals (intro/outro have no target).
  String? get targetKeyId {
    switch (this) {
      case TutorialStep.xpBar:
        return 'xpCard';
      case TutorialStep.stats:
        return 'statsRow';
      case TutorialStep.quests:
        return 'questsCard';
      case TutorialStep.logActivity:
        return 'logFab';
      case TutorialStep.mapTab:
        return 'mapTab';
      case TutorialStep.bossFab:
        return 'bossFab';
      case TutorialStep.intro:
      case TutorialStep.outro:
        return null;
    }
  }
}

/// Presentation content for a bubble step.
class TutorialStepContent {
  final String emoji;
  final String title;
  final String body;
  final Color accent;

  const TutorialStepContent({
    required this.emoji,
    required this.title,
    required this.body,
    required this.accent,
  });
}

/// Step → content map (bubble steps only).
const Map<TutorialStep, TutorialStepContent> kTutorialStepContent = {
  TutorialStep.xpBar: TutorialStepContent(
    emoji: '\u26A1',
    title: 'Your XP Bar',
    body:
        'Every workout fills this bar. Reach Level 2 to unlock new zones, items, and daily quests.',
    accent: AppColors.blue,
  ),
  TutorialStep.stats: TutorialStepContent(
    emoji: '\uD83D\uDC8E',
    title: 'Five Core Stats',
    body:
        'STR, END, AGI, FLX, STA — each activity raises different stats. Tap a gem to see what trains it.',
    accent: AppColors.purple,
  ),
  TutorialStep.quests: TutorialStepContent(
    emoji: '\uD83D\uDCDC',
    title: 'Daily Quests & Streaks',
    body:
        'Five quests refresh every day. A daily workout keeps your streak alive — shields protect you on rest days.',
    accent: AppColors.orange,
  ),
  TutorialStep.logActivity: TutorialStepContent(
    emoji: '\uD83D\uDDE1',
    title: 'Log Your First Activity',
    body:
        'Tap the sword. Any workout counts — even a 5-min walk. This step unlocks only when you log a real workout.',
    accent: AppColors.blue,
  ),
  TutorialStep.mapTab: TutorialStepContent(
    emoji: '\uD83D\uDDFA\uFE0F',
    title: 'The Adventure Map',
    body:
        'Every km you run or ride moves you across the world. Unlock zones like Forest of Endurance.',
    accent: AppColors.green,
  ),
  TutorialStep.bossFab: TutorialStepContent(
    emoji: '\uD83D\uDD25',
    title: 'Strike the Boss',
    body:
        'Every workout also damages today\u2019s boss. Defeat them before the 7-day timer for gear, XP, and a title.',
    accent: AppColors.red,
  ),
};

/// Total number of bubble steps (1..6). Used by progress-dot indicators.
const int kTutorialBubbleCount = 6;
