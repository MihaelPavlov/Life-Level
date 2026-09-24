import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';

// ── Quest category string constants ────────────────────────────────────────────
class QuestCategory {
  QuestCategory._();

  static const duration = 'duration';
  static const calories = 'calories';
  static const distance = 'distance';
  static const workouts = 'workouts';
  static const zonesCompleted = 'zonescompleted';
  static const chestsOpened = 'chestsopened';
  static const bossContributions = 'bosscontributions';
  static const bossesDefeated = 'bossesdefeated';
  static const guildRaidContributions = 'guildraidcontributions';
  static const guildRaidsWon = 'guildraidswon';
  static const regionsCompleted = 'regionscompleted';
}

// ── Category display helpers ────────────────────────────────────────────────────
String questCategoryEmoji(String category) {
  switch (category.toLowerCase()) {
    case QuestCategory.duration:
      return '⏱️';
    case QuestCategory.calories:
      return '🔥';
    case QuestCategory.distance:
      return '📍';
    case QuestCategory.workouts:
      return '🏋️';
    case QuestCategory.zonesCompleted:
      return '🗺️';
    case QuestCategory.chestsOpened:
      return '🎁';
    case QuestCategory.bossContributions:
    case QuestCategory.bossesDefeated:
      return '⚔️';
    case QuestCategory.guildRaidContributions:
    case QuestCategory.guildRaidsWon:
      return '🛡️';
    case QuestCategory.regionsCompleted:
      return '🏔️';
    default:
      return '🎯';
  }
}

String questCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case QuestCategory.duration:
      return AppIcons.questDuration;
    case QuestCategory.calories:
      return AppIcons.questCalories;
    case QuestCategory.distance:
      return AppIcons.questDistance;
    case QuestCategory.workouts:
      return AppIcons.questWorkoutCount;
    case QuestCategory.zonesCompleted:
    case QuestCategory.regionsCompleted:
      return AppIcons.questDistance;
    case QuestCategory.chestsOpened:
      return AppIcons.regionChestsHubIcon;
    case QuestCategory.bossContributions:
    case QuestCategory.bossesDefeated:
    case QuestCategory.guildRaidContributions:
    case QuestCategory.guildRaidsWon:
      return AppIcons.questWorkoutCount;
    default:
      return AppIcons.questGeneral;
  }
}

Color questCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case QuestCategory.duration:
      return AppColors.blue;
    case QuestCategory.calories:
      return AppColors.orange;
    case QuestCategory.distance:
      return AppColors.green;
    case QuestCategory.workouts:
      return AppColors.red;
    case QuestCategory.zonesCompleted:
    case QuestCategory.regionsCompleted:
      return AppColors.green;
    case QuestCategory.chestsOpened:
      return AppColors.orange;
    default:
      return AppColors.purple;
  }
}

enum QuestType { daily, weekly, special }

class UserQuestProgress {
  final String id;
  final String questId;
  final String title;
  final String description;
  final String category;
  final String progressMode;
  final String difficultyTier;
  final String? requiredActivity;
  final double targetValue;
  final double currentValue;
  final String targetUnit;
  final int rewardXp;
  final int rewardCoins;
  final int rewardCrystals;
  final int rewardPoints;
  final bool isCompleted;
  final bool rewardClaimed;
  final DateTime expiresAt;
  final DateTime? completedAt;

  const UserQuestProgress({
    required this.id,
    required this.questId,
    required this.title,
    required this.description,
    required this.category,
    this.progressMode = 'Cumulative',
    this.difficultyTier = 'Standard',
    required this.requiredActivity,
    required this.targetValue,
    required this.currentValue,
    required this.targetUnit,
    required this.rewardXp,
    this.rewardCoins = 0,
    this.rewardCrystals = 0,
    this.rewardPoints = 0,
    required this.isCompleted,
    required this.rewardClaimed,
    required this.expiresAt,
    required this.completedAt,
  });

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory UserQuestProgress.fromJson(Map<String, dynamic> json) =>
      UserQuestProgress(
        id: json['id'] as String,
        questId: json['questId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        progressMode: json['progressMode'] as String? ?? 'Cumulative',
        difficultyTier: json['difficultyTier'] as String? ?? 'Standard',
        requiredActivity: json['requiredActivity'] as String?,
        targetValue: (json['targetValue'] as num).toDouble(),
        currentValue: (json['currentValue'] as num).toDouble(),
        targetUnit: json['targetUnit'] as String,
        rewardXp: json['rewardXp'] as int,
        rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 0,
        rewardCrystals: (json['rewardCrystals'] as num?)?.toInt() ?? 0,
        rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
        isCompleted: json['isCompleted'] as bool,
        rewardClaimed: json['rewardClaimed'] as bool,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}
