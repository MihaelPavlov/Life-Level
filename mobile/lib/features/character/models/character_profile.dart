import '../../items/models/item_models.dart';

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
  // ── Tutorial progress ──
  /// 0 = not started (intro modal pending), 1–6 = step bubbles,
  /// 7 = outro modal pending, -1 = skipped by user, 99 = fully completed.
  final int tutorialStep;

  /// Bitmask: bit 0 = xp-stats, bit 1 = quests-streaks, bit 2 = activity-logging,
  /// bit 3 = world-map, bit 4 = boss-system.
  final int tutorialTopicsSeen;

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
    this.tutorialStep = 0,
    this.tutorialTopicsSeen = 0,
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
        tutorialStep: json['tutorialStep'] as int? ?? 0,
        tutorialTopicsSeen: json['tutorialTopicsSeen'] as int? ?? 0,
      );

  double get xpProgress {
    final needed = xpForNextLevel - xpForCurrentLevel;
    if (needed <= 0) return 1.0;
    return ((xp - xpForCurrentLevel) / needed).clamp(0.0, 1.0);
  }

  int get xpRemaining => xpForNextLevel - xp;
}
