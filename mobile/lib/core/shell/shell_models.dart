import 'package:flutter/material.dart';
import '../constants/app_icons.dart';

/// Evenly-spaced angles for n items, starting at 30°.
/// For n=6: [30, 90, 150, 210, 270, 330] — matches the original layout.
List<double> anglesFor(int n) {
  if (n == 0) return [];
  final step = 360.0 / n;
  return List.generate(n, (i) => (30.0 + step * i) % 360);
}

// ── radial item data ──────────────────────────────────────────────────────────
class RingItem {
  final String id;
  final String emoji;
  final String label;
  final Color color;
  final String? iconAsset;
  const RingItem(this.id, this.emoji, this.label, this.color, {this.iconAsset});
}

const kAllRingItems = [
  RingItem('world',       '🌍', 'World',       Color(0xFF4f9eff), iconAsset: AppIcons.ringWorld),
  RingItem('guild',       '🛡️', 'Guild',       Color(0xFFb08ce8), iconAsset: AppIcons.ringGuild),
  RingItem('stats',       '📊', 'Stats',       Color(0xFF38d9c8)),
RingItem('titles',      '🏅', 'Titles',      Color(0xFFe8b86d), iconAsset: AppIcons.ringTitles),
  RingItem('boss',        '🐉', 'Boss',        Color(0xFFf85149), iconAsset: AppIcons.ringBoss),
  RingItem('profile',     '👤', 'Profile',     Color(0xFF9e9e9e)),
  RingItem('leaderboard', '🏆', 'Leaderboard', Color(0xFFf5a623), iconAsset: AppIcons.ringLeaderboard),
  RingItem('quests',      '📜', 'Quests',      Color(0xFF8b949e)),
];

const kDefaultRingIds = ['world', 'guild', 'stats', 'titles', 'boss'];

// ── nav tab data ──────────────────────────────────────────────────────────────
class NavTab {
  final String id;
  final String emoji;
  final String label;
  final String? iconAsset;
  const NavTab(this.id, this.emoji, this.label, {this.iconAsset});
}

const kAllNavItems = [
  NavTab('home',        '🏠', 'Home',     iconAsset: AppIcons.navHome),
  NavTab('quests',      '📜', 'Quests',   iconAsset: AppIcons.navQuests),
  NavTab('profile',     '👤', 'Profile',  iconAsset: AppIcons.navProfile),
  NavTab('stats',       '📊', 'Stats',    iconAsset: AppIcons.navStats),
  NavTab('boss',        '⚔️', 'Bosses'),
  NavTab('guild',       '🛡️', 'Guild'),
  NavTab('leaderboard', '🏆', 'Rankings'),
  NavTab('world',       '🗺️', 'Map',      iconAsset: AppIcons.navMap),
];

const kDefaultNavIds = ['home', 'quests', 'world', 'profile'];
