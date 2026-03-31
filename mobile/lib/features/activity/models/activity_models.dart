enum ActivityType { running, cycling, gym, yoga, swimming, hiking, climbing }

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
