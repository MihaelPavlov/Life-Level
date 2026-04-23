import 'package:flutter/material.dart';

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
  const RingItem(this.id, this.emoji, this.label, this.color);
}

const kAllRingItems = [
  RingItem('world',       '🌍', 'World',       Color(0xFF4f9eff)),
  RingItem('guild',       '🛡️', 'Guild',       Color(0xFFb08ce8)),
  RingItem('stats',       '📊', 'Stats',       Color(0xFF38d9c8)),
  RingItem('battle',      '⚔️', 'Battle',      Color(0xFFff8060)),
  RingItem('titles',      '🏅', 'Titles',      Color(0xFFe8b86d)),
  RingItem('boss',        '🐉', 'Boss',        Color(0xFFf85149)),
  RingItem('profile',     '👤', 'Profile',     Color(0xFF9e9e9e)),
  RingItem('leaderboard', '🏆', 'Leaderboard', Color(0xFFf5a623)),
  RingItem('map',         '🗺️', 'Map',         Color(0xFF52e0a0)),
  RingItem('quests',      '📜', 'Quests',      Color(0xFF8b949e)),
];

const kDefaultRingIds = ['world', 'guild', 'stats', 'battle', 'titles', 'boss'];

// ── nav tab data ──────────────────────────────────────────────────────────────
class NavTab {
  final String id;
  final String emoji;
  final String label;
  const NavTab(this.id, this.emoji, this.label);
}

const kAllNavItems = [
  NavTab('home',        '🏠', 'Home'),
  NavTab('quests',      '📜', 'Quests'),
  NavTab('map',         '🗺️', 'Map'),
  NavTab('profile',     '👤', 'Profile'),
  NavTab('stats',       '📊', 'Stats'),
  NavTab('boss',        '⚔️', 'Bosses'),
  NavTab('guild',       '🛡️', 'Guild'),
  NavTab('leaderboard', '🏆', 'Rankings'),
  NavTab('world',       '🗺️', 'Map'),
];

const kDefaultNavIds = ['home', 'quests', 'world', 'profile'];
