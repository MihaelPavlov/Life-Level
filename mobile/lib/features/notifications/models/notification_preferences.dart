class NotificationPreferences {
  final bool pushEnabled;
  final bool levelUpEnabled;
  final bool questEnabled;
  final bool bossEnabled;
  final bool streakEnabled;
  final bool rankEnabled;
  final bool quietHoursEnabled;
  final int quietHoursStartUtc;
  final int quietHoursEndUtc;

  const NotificationPreferences({
    required this.pushEnabled,
    required this.levelUpEnabled,
    required this.questEnabled,
    required this.bossEnabled,
    required this.streakEnabled,
    required this.rankEnabled,
    required this.quietHoursEnabled,
    required this.quietHoursStartUtc,
    required this.quietHoursEndUtc,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        pushEnabled: json['pushEnabled'] as bool? ?? true,
        levelUpEnabled: json['levelUpEnabled'] as bool? ?? true,
        questEnabled: json['questEnabled'] as bool? ?? true,
        bossEnabled: json['bossEnabled'] as bool? ?? true,
        streakEnabled: json['streakEnabled'] as bool? ?? true,
        rankEnabled: json['rankEnabled'] as bool? ?? true,
        quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? true,
        quietHoursStartUtc: json['quietHoursStartUtc'] as int? ?? 22,
        quietHoursEndUtc: json['quietHoursEndUtc'] as int? ?? 8,
      );

  Map<String, dynamic> toJson() => {
        'pushEnabled': pushEnabled,
        'levelUpEnabled': levelUpEnabled,
        'questEnabled': questEnabled,
        'bossEnabled': bossEnabled,
        'streakEnabled': streakEnabled,
        'rankEnabled': rankEnabled,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStartUtc': quietHoursStartUtc,
        'quietHoursEndUtc': quietHoursEndUtc,
      };

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? levelUpEnabled,
    bool? questEnabled,
    bool? bossEnabled,
    bool? streakEnabled,
    bool? rankEnabled,
    bool? quietHoursEnabled,
    int? quietHoursStartUtc,
    int? quietHoursEndUtc,
  }) =>
      NotificationPreferences(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        levelUpEnabled: levelUpEnabled ?? this.levelUpEnabled,
        questEnabled: questEnabled ?? this.questEnabled,
        bossEnabled: bossEnabled ?? this.bossEnabled,
        streakEnabled: streakEnabled ?? this.streakEnabled,
        rankEnabled: rankEnabled ?? this.rankEnabled,
        quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
        quietHoursStartUtc: quietHoursStartUtc ?? this.quietHoursStartUtc,
        quietHoursEndUtc: quietHoursEndUtc ?? this.quietHoursEndUtc,
      );
}
