enum ActivityType { running, cycling, gym, yoga, swimming, hiking, climbing, walking }

extension ActivityTypeExt on ActivityType {
  String get displayName => name[0].toUpperCase() + name.substring(1);

  String get emoji {
    switch (this) {
      case ActivityType.running:
        return '🏃';
      case ActivityType.cycling:
        return '🚴';
      case ActivityType.gym:
        return '💪';
      case ActivityType.yoga:
        return '🧘';
      case ActivityType.swimming:
        return '🏊';
      case ActivityType.hiking:
        return '🥾';
      case ActivityType.climbing:
        return '🧗';
      case ActivityType.walking:
        return '🚶';
    }
  }

  String get apiValue => name[0].toUpperCase() + name.substring(1);
}

class LogActivityRequest {
  final ActivityType type;
  final int durationMinutes;
  final double? distanceKm;
  final int? calories;
  final int? heartRateAvg;

  const LogActivityRequest({
    required this.type,
    required this.durationMinutes,
    this.distanceKm,
    this.calories,
    this.heartRateAvg,
  });

  Map<String, dynamic> toJson() => {
        'type': type.apiValue,
        'durationMinutes': durationMinutes,
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (calories != null) 'calories': calories,
        if (heartRateAvg != null) 'heartRateAvg': heartRateAvg,
      };
}

class CompletedQuestSummary {
  final String questId;
  final String title;
  final int rewardXp;

  const CompletedQuestSummary({
    required this.questId,
    required this.title,
    required this.rewardXp,
  });

  factory CompletedQuestSummary.fromJson(Map<String, dynamic> json) =>
      CompletedQuestSummary(
        questId: json['questId'] as String,
        title: json['title'] as String,
        rewardXp: json['rewardXp'] as int? ?? 0,
      );
}

class BlockedItemInfo {
  final String itemName;
  final String itemIcon;

  const BlockedItemInfo({required this.itemName, required this.itemIcon});

  factory BlockedItemInfo.fromJson(Map<String, dynamic> json) => BlockedItemInfo(
        itemName: json['itemName'] as String,
        itemIcon: json['itemIcon'] as String,
      );
}

class GrantedItemInfo {
  final String itemId;
  final String name;
  final String icon;
  final String rarity;
  final String slot;

  const GrantedItemInfo({
    required this.itemId,
    required this.name,
    required this.icon,
    required this.rarity,
    required this.slot,
  });

  factory GrantedItemInfo.fromJson(Map<String, dynamic> json) => GrantedItemInfo(
        itemId: json['itemId'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? '',
        rarity: json['rarity'] as String? ?? '',
        slot: json['slot'] as String? ?? '',
      );
}

class UnlockedZoneInfo {
  final String zoneId;
  final String name;
  final String icon;
  final String region;
  final int levelRequirement;

  const UnlockedZoneInfo({
    required this.zoneId,
    required this.name,
    required this.icon,
    required this.region,
    required this.levelRequirement,
  });

  factory UnlockedZoneInfo.fromJson(Map<String, dynamic> json) => UnlockedZoneInfo(
        zoneId: json['zoneId'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? '',
        region: json['region'] as String? ?? '',
        levelRequirement: json['levelRequirement'] as int? ?? 1,
      );
}

class LevelUpUnlocks {
  final int statPointsGained;
  final List<GrantedItemInfo> grantedItems;
  final List<UnlockedZoneInfo> unlockedZones;

  const LevelUpUnlocks({
    required this.statPointsGained,
    required this.grantedItems,
    required this.unlockedZones,
  });

  bool get isEmpty =>
      statPointsGained <= 0 && grantedItems.isEmpty && unlockedZones.isEmpty;

  factory LevelUpUnlocks.fromJson(Map<String, dynamic> json) => LevelUpUnlocks(
        statPointsGained: json['statPointsGained'] as int? ?? 0,
        grantedItems: (json['grantedItems'] as List<dynamic>? ?? [])
            .map((e) => GrantedItemInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        unlockedZones: (json['unlockedZones'] as List<dynamic>? ?? [])
            .map((e) => UnlockedZoneInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LogActivityResult {
  final String activityId;
  final int xpGained;
  final int strGained;
  final int endGained;
  final int agiGained;
  final int flxGained;
  final int staGained;
  final bool leveledUp;
  final int? newLevel;
  final List<CompletedQuestSummary> completedQuests;
  final bool streakUpdated;
  final int currentStreak;
  final bool allDailyQuestsCompleted;
  final int bonusXpAwarded;
  final int xpBonusApplied;
  final List<BlockedItemInfo> blockedItems;
  final LevelUpUnlocks? levelUpUnlocks;

  const LogActivityResult({
    required this.activityId,
    required this.xpGained,
    required this.strGained,
    required this.endGained,
    required this.agiGained,
    required this.flxGained,
    required this.staGained,
    required this.leveledUp,
    required this.newLevel,
    required this.completedQuests,
    required this.streakUpdated,
    required this.currentStreak,
    required this.allDailyQuestsCompleted,
    required this.bonusXpAwarded,
    this.xpBonusApplied = 0,
    this.blockedItems = const [],
    this.levelUpUnlocks,
  });

  factory LogActivityResult.fromJson(Map<String, dynamic> json) =>
      LogActivityResult(
        activityId: json['activityId'] as String,
        xpGained: json['xpGained'] as int,
        strGained: json['strGained'] as int? ?? 0,
        endGained: json['endGained'] as int? ?? 0,
        agiGained: json['agiGained'] as int? ?? 0,
        flxGained: json['flxGained'] as int? ?? 0,
        staGained: json['staGained'] as int? ?? 0,
        leveledUp: json['leveledUp'] as bool? ?? false,
        newLevel: json['newLevel'] as int?,
        completedQuests: (json['completedQuests'] as List<dynamic>?)
                ?.map((j) => CompletedQuestSummary.fromJson(
                    j as Map<String, dynamic>))
                .toList() ??
            [],
        streakUpdated: json['streakUpdated'] as bool? ?? false,
        currentStreak: json['currentStreak'] as int? ?? 0,
        allDailyQuestsCompleted:
            json['allDailyQuestsCompleted'] as bool? ?? false,
        bonusXpAwarded: json['bonusXpAwarded'] as int? ?? 0,
        xpBonusApplied: json['xpBonusApplied'] as int? ?? 0,
        blockedItems: (json['blockedItems'] as List<dynamic>? ?? [])
            .map((e) => BlockedItemInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        levelUpUnlocks: json['levelUpUnlocks'] == null
            ? null
            : LevelUpUnlocks.fromJson(
                json['levelUpUnlocks'] as Map<String, dynamic>),
      );
}

class ActivityHistoryDto {
  final String id;
  final String type;
  final int durationMinutes;
  final double distanceKm;
  final int calories;
  final int? heartRateAvg;
  final int xpGained;
  final int strGained;
  final int endGained;
  final int agiGained;
  final int flxGained;
  final int staGained;
  final int steps;
  final DateTime loggedAt;

  const ActivityHistoryDto({
    required this.id,
    required this.type,
    required this.durationMinutes,
    required this.distanceKm,
    required this.calories,
    this.heartRateAvg,
    required this.xpGained,
    required this.strGained,
    required this.endGained,
    required this.agiGained,
    required this.flxGained,
    required this.staGained,
    required this.steps,
    required this.loggedAt,
  });

  factory ActivityHistoryDto.fromJson(Map<String, dynamic> json) =>
      ActivityHistoryDto(
        id:              json['id'] as String,
        type:            json['type'] as String,
        durationMinutes: json['durationMinutes'] as int,
        distanceKm:      (json['distanceKm'] as num).toDouble(),
        calories:        (json['calories'] as int?) ?? 0,
        heartRateAvg:    json['heartRateAvg'] as int?,
        xpGained:        (json['xpGained'] as num).toInt(),
        strGained:       (json['strGained'] as int?) ?? 0,
        endGained:       (json['endGained'] as int?) ?? 0,
        agiGained:       (json['agiGained'] as int?) ?? 0,
        flxGained:       (json['flxGained'] as int?) ?? 0,
        staGained:       (json['staGained'] as int?) ?? 0,
        steps:           (json['steps'] as int?) ?? 0,
        loggedAt:        DateTime.parse(json['loggedAt'] as String),
      );

  ActivityType? get activityType {
    try {
      return ActivityType.values.firstWhere((e) => e.apiValue == type);
    } catch (_) {
      return null;
    }
  }
}
