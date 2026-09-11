import '../../items/models/item_models.dart';

/// Always-active talent bonuses + wallet, enriched onto `GET /character/me`.
class TalentSummary {
  final int ownedCount;
  final int catalogCount;
  final int totalLevels;
  final int coins;
  final int tokens;
  final int strBonus;
  final int endBonus;
  final int agiBonus;
  final int flxBonus;
  final int staBonus;
  final List<String> effectLines;

  const TalentSummary({
    required this.ownedCount,
    required this.catalogCount,
    required this.totalLevels,
    required this.coins,
    required this.tokens,
    required this.strBonus,
    required this.endBonus,
    required this.agiBonus,
    required this.flxBonus,
    required this.staBonus,
    required this.effectLines,
  });

  factory TalentSummary.fromJson(Map<String, dynamic> j) => TalentSummary(
        ownedCount: (j['ownedCount'] as num?)?.toInt() ?? 0,
        catalogCount: (j['catalogCount'] as num?)?.toInt() ?? 0,
        totalLevels: (j['totalLevels'] as num?)?.toInt() ?? 0,
        coins: (j['coins'] as num?)?.toInt() ?? 0,
        tokens: (j['tokens'] as num?)?.toInt() ?? 0,
        strBonus: (j['strBonus'] as num?)?.toInt() ?? 0,
        endBonus: (j['endBonus'] as num?)?.toInt() ?? 0,
        agiBonus: (j['agiBonus'] as num?)?.toInt() ?? 0,
        flxBonus: (j['flxBonus'] as num?)?.toInt() ?? 0,
        staBonus: (j['staBonus'] as num?)?.toInt() ?? 0,
        effectLines: ((j['effectLines'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  bool get hasAny => ownedCount > 0;
}

class CharacterProfile {
  final String username;
  final String? avatarEmoji;
  final String? className;
  final String? classEmoji;
  final String rank;
  final int level;
  final int xp;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final int strength;
  final int endurance;
  final int agility;
  final int flexibility;
  final int stamina;
  final int weeklyRuns;
  final double weeklyDistanceKm;
  final int weeklyXpEarned;
  final int currentStreak;
  final int availableStatPoints;
  final bool loginRewardAvailable;
  final GearBonusesDto? gearBonuses;
  final TalentSummary? talents;
  // ── Tutorial progress ──
  /// 0 = not started (intro modal pending), 1–6 = step bubbles,
  /// 7 = outro modal pending, -1 = skipped by user, 99 = fully completed.
  final int tutorialStep;

  /// Bitmask: bit 0 = xp-stats, bit 1 = quests-streaks, bit 2 = activity-logging,
  /// bit 3 = world-map, bit 4 = boss-system.
  final int tutorialTopicsSeen;

  /// Separate world-map walkthrough. 0 = not started, 1..8 = in progress,
  /// -1 = skipped, 99 = completed.
  final int mapTutorialStep;

  const CharacterProfile({
    required this.username,
    required this.avatarEmoji,
    required this.className,
    required this.classEmoji,
    required this.rank,
    required this.level,
    required this.xp,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
    required this.strength,
    required this.endurance,
    required this.agility,
    required this.flexibility,
    required this.stamina,
    required this.weeklyRuns,
    required this.weeklyDistanceKm,
    required this.weeklyXpEarned,
    required this.currentStreak,
    required this.availableStatPoints,
    this.loginRewardAvailable = false,
    this.gearBonuses,
    this.talents,
    this.tutorialStep = 0,
    this.tutorialTopicsSeen = 0,
    this.mapTutorialStep = 0,
  });

  factory CharacterProfile.fromJson(Map<String, dynamic> json) =>
      CharacterProfile(
        username: json['username'] as String,
        avatarEmoji: json['avatarEmoji'] as String?,
        className: json['className'] as String?,
        classEmoji: json['classEmoji'] as String?,
        rank: json['rank'] as String,
        level: json['level'] as int,
        xp: json['xp'] as int,
        xpForCurrentLevel: json['xpForCurrentLevel'] as int,
        xpForNextLevel: json['xpForNextLevel'] as int,
        strength: json['strength'] as int,
        endurance: json['endurance'] as int,
        agility: json['agility'] as int,
        flexibility: json['flexibility'] as int,
        stamina: json['stamina'] as int,
        weeklyRuns: json['weeklyRuns'] as int,
        weeklyDistanceKm: (json['weeklyDistanceKm'] as num).toDouble(),
        weeklyXpEarned: json['weeklyXpEarned'] as int,
        currentStreak: json['currentStreak'] as int,
        availableStatPoints: json['availableStatPoints'] as int? ?? 0,
        loginRewardAvailable: json['loginRewardAvailable'] as bool? ?? false,
        gearBonuses: json['gearBonuses'] != null
            ? GearBonusesDto.fromJson(
                json['gearBonuses'] as Map<String, dynamic>)
            : null,
        talents: json['talents'] != null
            ? TalentSummary.fromJson(json['talents'] as Map<String, dynamic>)
            : null,
        tutorialStep: json['tutorialStep'] as int? ?? 0,
        tutorialTopicsSeen: json['tutorialTopicsSeen'] as int? ?? 0,
        mapTutorialStep: json['mapTutorialStep'] as int? ?? 0,
      );

  double get xpProgress {
    final needed = xpForNextLevel - xpForCurrentLevel;
    if (needed <= 0) return 1.0;
    return ((xp - xpForCurrentLevel) / needed).clamp(0.0, 1.0);
  }

  int get xpRemaining => xpForNextLevel - xp;
}
