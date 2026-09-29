import 'package:flutter/painting.dart';

import 'app_colors.dart';
import 'app_icons.dart';

String? classIconAssetForName(String? className) {
  switch ((className ?? '').trim().toLowerCase()) {
    case 'warrior':
      return AppIcons.classWarrior;
    case 'ranger':
    case 'archer':
      return AppIcons.classArcher;
    case 'mystic':
      return AppIcons.classMystic;
    case 'sentinel':
      return AppIcons.classSentinel;
    case 'tidecaller':
      return AppIcons.activitySwimming;
    case 'cragborn':
      return AppIcons.activityRockClimbing;
    case 'wayfarer':
      return AppIcons.activityHiking;
    default:
      // Hybrids show their first parent's icon where only one fits.
      return classIconPairForName(className)?.$1;
  }
}

/// The two parent icons of a hybrid class, or null for single classes.
(String, String)? classIconPairForName(String? className) {
  switch ((className ?? '').trim().toLowerCase()) {
    case 'vanguard':
      return (AppIcons.classArcher, AppIcons.classWarrior);
    case 'spellblade':
      return (AppIcons.classWarrior, AppIcons.classMystic);
    case 'druid':
      return (AppIcons.classArcher, AppIcons.classMystic);
    case 'stormrunner':
      return (AppIcons.activitySwimming, AppIcons.activityCycling);
    default:
      return null;
  }
}

/// Accent colour for a class, matching the class selection cards.
Color classColorForName(String? className) {
  switch ((className ?? '').trim().toLowerCase()) {
    case 'warrior':
      return AppColors.red;
    case 'ranger':
      return AppColors.green;
    case 'mystic':
      return AppColors.purple;
    case 'tidecaller':
      return const Color(0xFF39C5CF);
    case 'cragborn':
      return const Color(0xFFDB6D28);
    case 'wayfarer':
      return const Color(0xFF7EE2B8);
    case 'vanguard':
      return const Color(0xFFFF9B6B);
    case 'spellblade':
      return const Color(0xFFD2A8FF);
    case 'druid':
      return const Color(0xFFB4E08C);
    case 'stormrunner':
      return const Color(0xFF79C0FF);
    case 'sentinel':
    default:
      return AppColors.blue;
  }
}

String? classIconAssetForEmoji(String? emoji) {
  switch ((emoji ?? '').trim()) {
    case '\u2694':
    case '\u2694\uFE0F':
      return AppIcons.classWarrior;
    case '\u{1F3F9}':
      return AppIcons.classArcher;
    case '\u{1F52E}':
    case '\u2726':
      return AppIcons.classMystic;
    case '\u{1F6E1}':
    case '\u{1F6E1}\uFE0F':
      return AppIcons.classSentinel;
    default:
      return null;
  }
}

String? classIconAsset({
  String? className,
  String? classEmoji,
}) {
  return classIconAssetForName(className) ?? classIconAssetForEmoji(classEmoji);
}
