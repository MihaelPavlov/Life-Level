class BossData {
  final String id;
  final String name;
  final String icon;
  final int maxHp;
  final int rewardXp;
  final int timerDays;
  final bool isMini;
  final int hpDealt;
  final bool isDefeated;
  final bool isExpired;
  final DateTime? startedAt;
  final DateTime? timerExpiresAt;
  final DateTime? defeatedAt;

  const BossData({
    required this.id,
    required this.name,
    required this.icon,
    required this.maxHp,
    required this.rewardXp,
    required this.timerDays,
    required this.isMini,
    required this.hpDealt,
    required this.isDefeated,
    required this.isExpired,
    this.startedAt,
    this.timerExpiresAt,
    this.defeatedAt,
  });

  bool get isActivated => startedAt != null;

  factory BossData.fromJson(Map<String, dynamic> json) => BossData(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        maxHp: json['maxHp'],
        rewardXp: json['rewardXp'],
        timerDays: json['timerDays'],
        isMini: json['isMini'] ?? false,
        hpDealt: json['hpDealt'],
        isDefeated: json['isDefeated'],
        isExpired: json['isExpired'] ?? false,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'])
            : null,
        timerExpiresAt: json['timerExpiresAt'] != null
            ? DateTime.parse(json['timerExpiresAt'])
            : null,
        defeatedAt: json['defeatedAt'] != null
            ? DateTime.parse(json['defeatedAt'])
            : null,
      );
}
