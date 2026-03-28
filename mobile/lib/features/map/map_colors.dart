import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

const kMapSurface2 = Color(0xFF1e2632);
const kMapBorder   = Color(0xFF30363d);
const kMapGold     = Color(0xFFf5dc3c);

Color mapNodeColor(String type) {
  switch (type) {
    case 'Boss':       return AppColors.red;
    case 'Crossroads': return AppColors.orange;
    case 'Dungeon':    return AppColors.purple;
    case 'Chest':      return kMapGold;
    case 'Event':      return AppColors.green;
    default:           return AppColors.blue;
  }
}

Color mapRarityColor(String rarity) {
  switch (rarity.toLowerCase()) {
    case 'uncommon':  return AppColors.green;
    case 'rare':      return AppColors.blue;
    case 'epic':      return AppColors.purple;
    case 'legendary': return AppColors.orange;
    default:          return AppColors.textSecondary;
  }
}

Color mapDifficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':  return AppColors.green;
    case 'hard':  return AppColors.red;
    default:      return AppColors.orange;
  }
}
