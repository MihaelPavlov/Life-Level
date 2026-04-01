import 'package:flutter/material.dart';

const _kCommonColor    = Color(0xFF8b949e);
const _kUncommonColor  = Color(0xFF3fb950);
const _kRareColor      = Color(0xFF4f9eff);
const _kEpicColor      = Color(0xFFa371f7);
const _kLegendaryColor = Color(0xFFf5a623);

class AchievementDto {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category;
  final String tier;
  final Color tierColor;
  final int xpReward;
  final double targetValue;
  final String targetUnit;
  final double currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementDto({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.tier,
    required this.tierColor,
    required this.xpReward,
    required this.targetValue,
    required this.targetUnit,
    required this.currentValue,
    required this.isUnlocked,
    this.unlockedAt,
  });

  double get progressPercent =>
      targetValue <= 0 ? 0.0 : (currentValue / targetValue).clamp(0.0, 1.0);

  bool get isInProgress => !isUnlocked && currentValue > 0;

  factory AchievementDto.fromJson(Map<String, dynamic> json) {
    final tierStr = json['tier'] as String? ?? 'Common';
    return AchievementDto(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏅',
      category: json['category'] as String? ?? '',
      tier: tierStr,
      tierColor: _tierColor(tierStr),
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 1.0,
      targetUnit: json['targetUnit'] as String? ?? '',
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
    );
  }

  static Color _tierColor(String tier) {
    switch (tier) {
      case 'Uncommon':
        return _kUncommonColor;
      case 'Rare':
        return _kRareColor;
      case 'Epic':
        return _kEpicColor;
      case 'Legendary':
        return _kLegendaryColor;
      default:
        return _kCommonColor;
    }
  }
}

class CheckUnlocksResult {
  final List<String> newlyUnlockedIds;
  const CheckUnlocksResult({required this.newlyUnlockedIds});

  factory CheckUnlocksResult.fromJson(Map<String, dynamic> json) =>
      CheckUnlocksResult(
        newlyUnlockedIds: (json['newlyUnlockedIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
