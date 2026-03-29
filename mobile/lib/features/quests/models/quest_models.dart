import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// ── Quest category string constants ────────────────────────────────────────────
class QuestCategory {
  QuestCategory._();

  static const duration = 'duration';
  static const calories = 'calories';
  static const distance = 'distance';
  static const workouts = 'workouts';
  static const streak = 'streak';
  static const login = 'login';
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
    case QuestCategory.streak:
      return '🔥';
    case QuestCategory.login:
      return '📅';
    default:
      return '🎯';
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
    case QuestCategory.streak:
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
  final String? requiredActivity;
  final double targetValue;
  final double currentValue;
  final String targetUnit;
  final int rewardXp;
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
    required this.requiredActivity,
    required this.targetValue,
    required this.currentValue,
    required this.targetUnit,
    required this.rewardXp,
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
        requiredActivity: json['requiredActivity'] as String?,
        targetValue: (json['targetValue'] as num).toDouble(),
        currentValue: (json['currentValue'] as num).toDouble(),
        targetUnit: json['targetUnit'] as String,
        rewardXp: json['rewardXp'] as int,
        isCompleted: json['isCompleted'] as bool,
        rewardClaimed: json['rewardClaimed'] as bool,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}
