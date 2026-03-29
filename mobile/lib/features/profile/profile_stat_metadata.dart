import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../character/models/character_profile.dart';

// ── colour aliases (used across all profile files) ────────────────────────────
const kPBg       = AppColors.background;
const kPSurface  = AppColors.surface;
const kPSurface2 = AppColors.surfaceElevated;
const kPBorder   = AppColors.surfaceElevated;
const kPBorder2  = Color(0xFF30363d);
const kPTextPri  = AppColors.textPrimary;
const kPTextSec  = AppColors.textSecondary;
const kPBlue     = AppColors.blue;
const kPPurple   = AppColors.purple;
const kPGold     = AppColors.orange;

// ── tabs ──────────────────────────────────────────────────────────────────────
const kProfileTabs = ['Overview', 'Equipment', 'Inventory', 'Achievements'];

// ── XP format helper ──────────────────────────────────────────────────────────
String fmtXp(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

// ── rank → accent colour ──────────────────────────────────────────────────────
Color profileRankColor(String rank) {
  switch (rank.toLowerCase()) {
    case 'warrior':  return AppColors.blue;
    case 'veteran':  return AppColors.purple;
    case 'champion': return AppColors.orange;
    case 'legend':   return AppColors.red;
    default:         return AppColors.textSecondary; // novice
  }
}

// ── static stat metadata ──────────────────────────────────────────────────────
class StatMeta {
  final String key;
  final String label;
  final String emoji;
  final Color color;
  final String description;
  final List<String> activities;
  final List<String> perks;
  const StatMeta(
    this.key,
    this.label,
    this.emoji,
    this.color,
    this.description,
    this.activities,
    this.perks,
  );
}

const kStrMeta = StatMeta(
  'STR', 'Strength', '💪', AppColors.red,
  'Raw physical power. Determines how much damage you deal in battles and '
  'how quickly you break through boss health bars.',
  ['🏋️ Gym workouts', '🪨 Climbing', '🚵 Weighted cycling'],
  ['⚔️ +Damage vs bosses', '🪖 Equip heavy armour', '🔓 Unlock Warrior zones'],
);

const kEndMeta = StatMeta(
  'END', 'Endurance', '🏃', AppColors.blue,
  'Your ability to sustain effort over time. High endurance lets you travel '
  'further on the map and complete longer quest chains.',
  ['🏃 Running', '🚴 Cycling', '🏊 Swimming'],
  ['🗺️ +Map distance per km', '📜 Access long-distance quests', '🔓 Unlock Ocean of Balance'],
);

const kAgiMeta = StatMeta(
  'AGI', 'Agility', '⚡', Color(0xFF38d9c8),
  'Speed and reaction time. Agility boosts your dodge chance in raids and '
  'increases XP gained from pace-based activities.',
  ['🏃 Running (pace-focused)', '🚴 Cycling sprints', '⛹️ HIIT'],
  ['🎯 +Dodge chance in raids', '⚡ +XP for high-pace runs', '🔓 Unlock sprint challenges'],
);

const kFlxMeta = StatMeta(
  'FLX', 'Flexibility', '🧘', AppColors.purple,
  'Mobility and recovery. Flexibility reduces injury cooldowns and '
  'gives bonus XP on rest days when you do active recovery.',
  ['🧘 Yoga', '🤸 Stretching', '💆 Mobility sessions'],
  ['💤 -Recovery time after boss fights', '✨ +XP on rest-day workouts', '🔓 Unlock Zen titles'],
);

const kStaMeta = StatMeta(
  'STA', 'Stamina', '❤️', AppColors.orange,
  'Overall staying power across all activity types. Stamina grows from '
  'consistency — it feeds every other stat and your streak multiplier.',
  ['🏋️ Any gym session', '🧘 Any workout', '📅 Daily login streak'],
  ['🔥 +Streak XP multiplier', '❤️ +Max HP in raids', '🔓 Required for Champion rank'],
);

// ── runtime stat model (meta + live value) ────────────────────────────────────
class StatData {
  final StatMeta meta;
  final int value;
  const StatData(this.meta, this.value);

  String get key         => meta.key;
  String get label       => meta.label;
  String get emoji       => meta.emoji;
  Color  get color       => meta.color;
  String get description => meta.description;
  List<String> get activities => meta.activities;
  List<String> get perks      => meta.perks;
}

List<StatData> buildProfileStats(CharacterProfile p) => [
  StatData(kStrMeta, p.strength),
  StatData(kEndMeta, p.endurance),
  StatData(kAgiMeta, p.agility),
  StatData(kFlxMeta, p.flexibility),
  StatData(kStaMeta, p.stamina),
];
