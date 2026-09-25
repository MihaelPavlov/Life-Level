import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/achievement_models.dart';

/// Display data for a road (achievement category).
class RoadMeta {
  final String name;
  final String emoji;
  final Color color;
  const RoadMeta(this.name, this.emoji, this.color);

  static RoadMeta of(String category) => switch (category) {
        'Running' => const RoadMeta('Running', '🏃', AppColors.blue),
        'Strength' => const RoadMeta('Strength', '🏋️', AppColors.red),
        // The Social category holds the streak achievements.
        'Social' => const RoadMeta('Streaks', '🔥', AppColors.orange),
        'Raids' => const RoadMeta('Raids', '⚔️', AppColors.purple),
        _ => RoadMeta(category, '🏅', AppColors.textSecondary),
      };
}

/// Tier colours, shared with the rest of the achievements UI.
Color tierColor(String tier) => switch (tier) {
      'Uncommon' => AppColors.green,
      'Rare' => AppColors.blue,
      'Epic' => AppColors.purple,
      'Legendary' => AppColors.orange,
      _ => AppColors.textSecondary,
    };

/// Remaining work in plain words: "15 km to go", "3 bosses to go".
String toGoLabel(AchievementDto a) {
  final left = (a.targetValue - a.currentValue).clamp(0, double.infinity);
  final n = left == left.roundToDouble()
      ? left.toInt().toString()
      : left.toStringAsFixed(1);
  final unit = a.targetUnit.isEmpty ? '' : ' ${a.targetUnit}';
  return '$n$unit to go';
}

/// Stage copy for a road's stage card.
String stageHeadline(AchievementStage s) {
  if (s.chestOpened) return '${s.chestName} opened';
  if (s.chestReady) return '${s.chestName} is ready!';
  if (s.toGo > 0) return '${s.toGo} more to open the ${s.chestName}';
  return 'Claim ${s.ready} to open the ${s.chestName}';
}
