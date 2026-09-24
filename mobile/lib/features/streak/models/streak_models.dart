class StreakData {
  final int current;
  final int longest;
  final int shieldsAvailable;
  final bool shieldUsedToday;
  final DateTime? lastActivityDate;
  final int totalDaysActive;
  final int pendingRewardCoins;
  final bool canClaimDailyReward;
  final int nextRewardCoins;

  const StreakData({
    required this.current,
    required this.longest,
    required this.shieldsAvailable,
    required this.shieldUsedToday,
    required this.lastActivityDate,
    required this.totalDaysActive,
    required this.pendingRewardCoins,
    required this.canClaimDailyReward,
    required this.nextRewardCoins,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
        current: json['current'] as int,
        longest: json['longest'] as int,
        shieldsAvailable: json['shieldsAvailable'] as int,
        shieldUsedToday: json['shieldUsedToday'] as bool,
        lastActivityDate: json['lastActivityDate'] != null
            ? DateTime.parse(json['lastActivityDate'] as String)
            : null,
        totalDaysActive: json['totalDaysActive'] as int,
        pendingRewardCoins: (json['pendingRewardCoins'] as num?)?.toInt() ?? 0,
        canClaimDailyReward: json['canClaimDailyReward'] as bool? ?? false,
        nextRewardCoins: (json['nextRewardCoins'] as num?)?.toInt() ?? 10,
      );

  static StreakData empty() => const StreakData(
        current: 0,
        longest: 0,
        shieldsAvailable: 0,
        shieldUsedToday: false,
        lastActivityDate: null,
        totalDaysActive: 0,
        pendingRewardCoins: 0,
        canClaimDailyReward: false,
        nextRewardCoins: 10,
      );

  bool get canUseShield =>
      shieldsAvailable > 0 && !shieldUsedToday && current > 0;
}

class ClaimStreakRewardResult {
  final int coinsClaimed;
  final String message;

  const ClaimStreakRewardResult({
    required this.coinsClaimed,
    required this.message,
  });

  factory ClaimStreakRewardResult.fromJson(Map<String, dynamic> json) =>
      ClaimStreakRewardResult(
        coinsClaimed: (json['coinsClaimed'] as num?)?.toInt() ?? 0,
        message: json['message'] as String? ?? 'Streak reward claimed.',
      );
}

class UseShieldResult {
  final bool success;
  final String message;
  final int shieldsRemaining;

  const UseShieldResult({
    required this.success,
    required this.message,
    required this.shieldsRemaining,
  });

  factory UseShieldResult.fromJson(Map<String, dynamic> json) =>
      UseShieldResult(
        success: json['success'] as bool,
        message: json['message'] as String,
        shieldsRemaining: json['shieldsRemaining'] as int,
      );
}
