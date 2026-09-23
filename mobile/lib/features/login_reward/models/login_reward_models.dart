class LoginRewardStatus {
  final int dayInCycle;
  final bool claimedToday;
  final int nextRewardXp;
  final bool nextRewardIncludesShield;
  final bool nextRewardIsXpStorm;
  final int totalLoginDays;
  final List<LoginRewardDay> days;

  const LoginRewardStatus({
    required this.dayInCycle,
    required this.claimedToday,
    required this.nextRewardXp,
    required this.nextRewardIncludesShield,
    required this.nextRewardIsXpStorm,
    required this.totalLoginDays,
    this.days = const [],
  });

  factory LoginRewardStatus.fromJson(Map<String, dynamic> json) =>
      LoginRewardStatus(
        dayInCycle: json['dayInCycle'] as int,
        claimedToday: json['claimedToday'] as bool,
        nextRewardXp: json['nextRewardXp'] as int,
        nextRewardIncludesShield: json['nextRewardIncludesShield'] as bool,
        nextRewardIsXpStorm: json['nextRewardIsXpStorm'] as bool,
        totalLoginDays: json['totalLoginDays'] as int,
        days: ((json['days'] as List<dynamic>?) ?? const [])
            .map((e) => LoginRewardDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LoginRewardDay {
  final int day;
  final int xp;
  final bool includesShield;
  final bool isXpStorm;

  const LoginRewardDay(
      {required this.day,
      required this.xp,
      required this.includesShield,
      required this.isXpStorm});

  factory LoginRewardDay.fromJson(Map<String, dynamic> json) => LoginRewardDay(
        day: (json['day'] as num).toInt(),
        xp: (json['xp'] as num).toInt(),
        includesShield: json['includesShield'] as bool? ?? false,
        isXpStorm: json['isXpStorm'] as bool? ?? false,
      );
}

class LoginRewardClaimResult {
  final int dayInCycle;
  final int xpAwarded;
  final bool includesShield;
  final bool isXpStorm;
  final bool leveledUp;
  final int? newLevel;

  const LoginRewardClaimResult({
    required this.dayInCycle,
    required this.xpAwarded,
    required this.includesShield,
    required this.isXpStorm,
    required this.leveledUp,
    required this.newLevel,
  });

  factory LoginRewardClaimResult.fromJson(Map<String, dynamic> json) =>
      LoginRewardClaimResult(
        dayInCycle: json['dayInCycle'] as int,
        xpAwarded: json['xpAwarded'] as int,
        includesShield: json['includesShield'] as bool,
        isXpStorm: json['isXpStorm'] as bool,
        leveledUp: json['leveledUp'] as bool,
        newLevel: json['newLevel'] as int?,
      );
}
