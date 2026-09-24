class BossListItem {
  final String id;
  final String name;
  final String icon;
  final int maxHp;
  final int armor;
  final int counterattackDamage;
  final int rewardXp;
  final int timerDays;
  final bool isMini;
  final String region;
  final String nodeName;
  final int levelRequirement;

  /// World-zone Guid this boss is bound to (null for legacy local-map bosses).
  /// Used by the home portal to map the current boss zone → its boss row.
  final String? worldZoneId;
  final String? trailEncounterTemplateId;

  // Gameplay
  final bool canFight;

  // User state
  final bool activated;
  final int hpDealt;
  final bool isDefeated;
  final bool isExpired;
  final DateTime? startedAt;
  final DateTime? timerExpiresAt;
  final DateTime? defeatedAt;
  final bool isTargeted;
  final int currentPlayerHp;
  final int playerMaxHp;
  final int playerDefense;
  final double playerMitigation;
  final DateTime? recoveryEndsAt;

  const BossListItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.maxHp,
    this.armor = 0,
    this.counterattackDamage = 0,
    required this.rewardXp,
    required this.timerDays,
    required this.isMini,
    required this.region,
    required this.nodeName,
    required this.levelRequirement,
    this.worldZoneId,
    this.trailEncounterTemplateId,
    required this.canFight,
    required this.activated,
    required this.hpDealt,
    required this.isDefeated,
    required this.isExpired,
    this.startedAt,
    this.timerExpiresAt,
    this.defeatedAt,
    this.isTargeted = false,
    this.currentPlayerHp = 0,
    this.playerMaxHp = 0,
    this.playerDefense = 0,
    this.playerMitigation = 0,
    this.recoveryEndsAt,
  });

  bool get isActive => activated && !isDefeated && !isExpired;

  int get hpRemaining => maxHp - hpDealt;

  double get hpPercent => maxHp > 0 ? hpDealt / maxHp : 0;

  Duration? get timeRemaining {
    if (timerExpiresAt == null) return null;
    final diff = timerExpiresAt!.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get regionDisplay {
    // "ForestOfEndurance" → "Forest of Endurance"
    return region.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
  }

  factory BossListItem.fromJson(Map<String, dynamic> json) => BossListItem(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        maxHp: json['maxHp'],
        armor: (json['armor'] as num?)?.toInt() ?? 0,
        counterattackDamage:
            (json['counterattackDamage'] as num?)?.toInt() ?? 0,
        rewardXp: json['rewardXp'],
        timerDays: json['timerDays'],
        isMini: json['isMini'] ?? false,
        region: json['region'] ?? '',
        nodeName: json['nodeName'] ?? '',
        levelRequirement: json['levelRequirement'] ?? 0,
        worldZoneId: json['worldZoneId'] as String?,
        trailEncounterTemplateId: json['trailEncounterTemplateId'] as String?,
        canFight: json['canFight'] ?? false,
        activated: json['activated'] ?? false,
        hpDealt: json['hpDealt'] ?? 0,
        isDefeated: json['isDefeated'] ?? false,
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
        isTargeted: json['isTargeted'] as bool? ?? false,
        currentPlayerHp: (json['currentPlayerHp'] as num?)?.toInt() ?? 0,
        playerMaxHp: (json['playerMaxHp'] as num?)?.toInt() ?? 0,
        playerDefense: (json['playerDefense'] as num?)?.toInt() ?? 0,
        playerMitigation: (json['playerMitigation'] as num?)?.toDouble() ?? 0,
        recoveryEndsAt: json['recoveryEndsAt'] != null
            ? DateTime.parse(json['recoveryEndsAt'])
            : null,
      );
}
