class StreakData {
  final int current;
  final int longest;
  final int shieldsAvailable;
  final bool shieldUsedToday;
  final DateTime? lastActivityDate;
  final int totalDaysActive;

  const StreakData({
    required this.current,
    required this.longest,
    required this.shieldsAvailable,
    required this.shieldUsedToday,
    required this.lastActivityDate,
    required this.totalDaysActive,
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
      );

  static StreakData empty() => const StreakData(
        current: 0,
        longest: 0,
        shieldsAvailable: 0,
        shieldUsedToday: false,
        lastActivityDate: null,
        totalDaysActive: 0,
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

  factory UseShieldResult.fromJson(Map<String, dynamic> json) => UseShieldResult(
        success: json['success'] as bool,
        message: json['message'] as String,
        shieldsRemaining: json['shieldsRemaining'] as int,
      );
}
