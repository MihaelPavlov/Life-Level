class GuildDetail {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int memberCount;
  final int maxMembers;
  final bool isOpen;
  final bool isLeader;
  final String viewerRole;
  final bool canManageRaid;
  final bool canManageMembers;
  final bool canEditGuild;
  final List<GuildMember> members;
  final GuildRaid? activeRaid;

  const GuildDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.memberCount,
    required this.maxMembers,
    required this.isOpen,
    required this.isLeader,
    required this.viewerRole,
    required this.canManageRaid,
    required this.canManageMembers,
    required this.canEditGuild,
    required this.members,
    required this.activeRaid,
  });

  factory GuildDetail.fromJson(Map<String, dynamic> json) => GuildDetail(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? 'shield',
        memberCount: json['memberCount'] as int? ?? 0,
        maxMembers: json['maxMembers'] as int? ?? 5,
        isOpen: json['isOpen'] as bool? ?? true,
        isLeader: json['isLeader'] as bool? ?? false,
        viewerRole: json['viewerRole'] as String? ?? 'Member',
        canManageRaid: json['canManageRaid'] as bool? ??
            (json['isLeader'] as bool? ?? false),
        canManageMembers: json['canManageMembers'] as bool? ??
            (json['isLeader'] as bool? ?? false),
        canEditGuild: json['canEditGuild'] as bool? ??
            (json['isLeader'] as bool? ?? false),
        members: ((json['members'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(GuildMember.fromJson)
            .toList(),
        activeRaid: json['activeRaid'] is! Map<String, dynamic>
            ? null
            : GuildRaid.fromJson(json['activeRaid'] as Map<String, dynamic>),
      );
}

class GuildSearchItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int memberCount;
  final int maxMembers;
  final bool isOpen;

  const GuildSearchItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.memberCount,
    required this.maxMembers,
    required this.isOpen,
  });

  factory GuildSearchItem.fromJson(Map<String, dynamic> json) =>
      GuildSearchItem(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? 'shield',
        memberCount: json['memberCount'] as int? ?? 0,
        maxMembers: json['maxMembers'] as int? ?? 5,
        isOpen: json['isOpen'] as bool? ?? true,
      );
}

class GuildMember {
  final String userId;
  final String username;
  final String avatarEmoji;
  final String role;
  final DateTime joinedAt;
  final int raidDamage;

  const GuildMember({
    required this.userId,
    required this.username,
    required this.avatarEmoji,
    required this.role,
    required this.joinedAt,
    required this.raidDamage,
  });

  bool get isLeader => role.toLowerCase() == 'leader';
  bool get isOfficer => role.toLowerCase() == 'officer';

  factory GuildMember.fromJson(Map<String, dynamic> json) => GuildMember(
        userId: json['userId'] as String,
        username: json['username'] as String? ?? 'Adventurer',
        avatarEmoji: json['avatarEmoji'] as String? ?? '',
        role: json['role'] as String? ?? 'Member',
        joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
            DateTime.now().toUtc(),
        raidDamage: json['raidDamage'] as int? ?? 0,
      );
}

class GuildRaidBoss {
  final String id;
  final String name;
  final String icon;
  final int maxHp;
  final int rewardXp;
  final int timerDays;
  final bool isMini;

  const GuildRaidBoss({
    required this.id,
    required this.name,
    required this.icon,
    required this.maxHp,
    required this.rewardXp,
    required this.timerDays,
    required this.isMini,
  });

  factory GuildRaidBoss.fromJson(Map<String, dynamic> json) => GuildRaidBoss(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
        maxHp: json['maxHp'] as int? ?? 0,
        rewardXp: json['rewardXp'] as int? ?? 0,
        timerDays: json['timerDays'] as int? ?? 7,
        isMini: json['isMini'] as bool? ?? false,
      );
}

class GuildRaid {
  final String id;
  final String bossId;
  final String bossName;
  final String bossIcon;
  final int maxHp;
  final int baseMaxHp;
  final int rewardXp;
  final int baseRewardXp;
  final int guildSizeAtStart;
  final DateTime startedAt;
  final DateTime expiresAt;
  final int totalDamage;
  final bool isDefeated;
  final bool isExpired;
  final DateTime? defeatedAt;
  final DateTime? rewardClaimedAt;
  final bool rewardClaimed;
  final String? mvpUserId;
  final String? mvpUsername;
  final int mvpDamage;
  final int mvpBonusXp;
  final List<GuildRaidContribution> contributions;

  const GuildRaid({
    required this.id,
    required this.bossId,
    required this.bossName,
    required this.bossIcon,
    required this.maxHp,
    required this.baseMaxHp,
    required this.rewardXp,
    required this.baseRewardXp,
    required this.guildSizeAtStart,
    required this.startedAt,
    required this.expiresAt,
    required this.totalDamage,
    required this.isDefeated,
    required this.isExpired,
    required this.defeatedAt,
    required this.rewardClaimedAt,
    required this.rewardClaimed,
    required this.mvpUserId,
    required this.mvpUsername,
    required this.mvpDamage,
    required this.mvpBonusXp,
    required this.contributions,
  });

  double get hpPercent =>
      maxHp <= 0 ? 0 : (totalDamage / maxHp).clamp(0.0, 1.0).toDouble();
  int get remainingHp => (maxHp - totalDamage).clamp(0, maxHp);

  Duration get timeRemaining {
    final diff = expiresAt.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory GuildRaid.fromJson(Map<String, dynamic> json) => GuildRaid(
        id: json['id'] as String,
        bossId: json['bossId'] as String,
        bossName: json['bossName'] as String? ?? '',
        bossIcon: json['bossIcon'] as String? ?? '',
        maxHp: _intValue(json, 'maxHp'),
        baseMaxHp: _intValueWithFallback(json, 'baseMaxHp', 'maxHp'),
        rewardXp: _intValue(json, 'rewardXp'),
        baseRewardXp: _intValueWithFallback(json, 'baseRewardXp', 'rewardXp'),
        guildSizeAtStart: _intValue(json, 'guildSizeAtStart') <= 0
            ? 1
            : _intValue(json, 'guildSizeAtStart'),
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.now().toUtc(),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.now().toUtc(),
        totalDamage: json['totalDamage'] as int? ?? 0,
        isDefeated: json['isDefeated'] as bool? ?? false,
        isExpired: json['isExpired'] as bool? ?? false,
        defeatedAt: json['defeatedAt'] == null
            ? null
            : DateTime.parse(json['defeatedAt'] as String),
        rewardClaimedAt: json['rewardClaimedAt'] == null
            ? null
            : DateTime.parse(json['rewardClaimedAt'] as String),
        rewardClaimed: json['rewardClaimed'] as bool? ?? false,
        mvpUserId: _nullableStringValue(json, 'mvpUserId'),
        mvpUsername: _nullableStringValue(json, 'mvpUsername'),
        mvpDamage: _intValue(json, 'mvpDamage'),
        mvpBonusXp: _intValue(json, 'mvpBonusXp'),
        contributions: ((json['contributions'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(GuildRaidContribution.fromJson)
            .toList(),
      );
}

class GuildRaidContribution {
  final String userId;
  final String username;
  final String avatarEmoji;
  final int damageDealt;
  final DateTime? lastActivityAt;
  final int rank;
  final bool isMvp;

  const GuildRaidContribution({
    required this.userId,
    required this.username,
    required this.avatarEmoji,
    required this.damageDealt,
    required this.lastActivityAt,
    required this.rank,
    required this.isMvp,
  });

  factory GuildRaidContribution.fromJson(Map<String, dynamic> json) =>
      GuildRaidContribution(
        userId: json['userId'] as String,
        username: json['username'] as String? ?? 'Adventurer',
        avatarEmoji: json['avatarEmoji'] as String? ?? '',
        damageDealt: json['damageDealt'] as int? ?? 0,
        lastActivityAt: json['lastActivityAt'] == null
            ? null
            : DateTime.parse(json['lastActivityAt'] as String),
        rank: _intValue(json, 'rank'),
        isMvp: json['isMvp'] as bool? ?? false,
      );
}

class GuildRaidHpUpdatedInfo {
  final String guildId;
  final String guildRaidId;
  final String bossName;
  final String bossIcon;
  final int maxHp;
  final int totalDamage;
  final int remainingHp;
  final String userId;
  final int damageDelta;
  final int userTotalDamage;

  const GuildRaidHpUpdatedInfo({
    required this.guildId,
    required this.guildRaidId,
    required this.bossName,
    required this.bossIcon,
    required this.maxHp,
    required this.totalDamage,
    required this.remainingHp,
    required this.userId,
    required this.damageDelta,
    required this.userTotalDamage,
  });

  factory GuildRaidHpUpdatedInfo.fromJson(Map<String, dynamic> json) =>
      GuildRaidHpUpdatedInfo(
        guildId: _stringValue(json, 'guildId'),
        guildRaidId: _stringValue(json, 'guildRaidId'),
        bossName: _stringValue(json, 'bossName'),
        bossIcon: _stringValue(json, 'bossIcon'),
        maxHp: _intValue(json, 'maxHp'),
        totalDamage: _intValue(json, 'totalDamage'),
        remainingHp: _intValue(json, 'remainingHp'),
        userId: _stringValue(json, 'userId'),
        damageDelta: _intValue(json, 'damageDelta'),
        userTotalDamage: _intValue(json, 'userTotalDamage'),
      );
}

class GuildRaidStartedInfo {
  final String guildId;
  final String guildRaidId;
  final String bossName;
  final String bossIcon;
  final int maxHp;
  final int rewardXp;
  final DateTime? expiresAt;

  const GuildRaidStartedInfo({
    required this.guildId,
    required this.guildRaidId,
    required this.bossName,
    required this.bossIcon,
    required this.maxHp,
    required this.rewardXp,
    required this.expiresAt,
  });

  factory GuildRaidStartedInfo.fromJson(Map<String, dynamic> json) =>
      GuildRaidStartedInfo(
        guildId: _stringValue(json, 'guildId'),
        guildRaidId: _stringValue(json, 'guildRaidId'),
        bossName: _stringValue(json, 'bossName'),
        bossIcon: _stringValue(json, 'bossIcon'),
        maxHp: _intValue(json, 'maxHp'),
        rewardXp: _intValue(json, 'rewardXp'),
        expiresAt: DateTime.tryParse(_stringValue(json, 'expiresAt')),
      );
}

class GuildRaidExpiredInfo {
  final String guildId;
  final String guildRaidId;
  final String bossName;
  final String bossIcon;
  final int maxHp;
  final int totalDamage;
  final int remainingHp;

  const GuildRaidExpiredInfo({
    required this.guildId,
    required this.guildRaidId,
    required this.bossName,
    required this.bossIcon,
    required this.maxHp,
    required this.totalDamage,
    required this.remainingHp,
  });

  factory GuildRaidExpiredInfo.fromJson(Map<String, dynamic> json) =>
      GuildRaidExpiredInfo(
        guildId: _stringValue(json, 'guildId'),
        guildRaidId: _stringValue(json, 'guildRaidId'),
        bossName: _stringValue(json, 'bossName'),
        bossIcon: _stringValue(json, 'bossIcon'),
        maxHp: _intValue(json, 'maxHp'),
        totalDamage: _intValue(json, 'totalDamage'),
        remainingHp: _intValue(json, 'remainingHp'),
      );
}

String _stringValue(Map<String, dynamic> json, String key) =>
    _value(json, key)?.toString() ?? '';

String? _nullableStringValue(Map<String, dynamic> json, String key) =>
    _value(json, key)?.toString();

int _intValue(Map<String, dynamic> json, String key) =>
    (_value(json, key) as num?)?.toInt() ?? 0;

int _intValueWithFallback(
  Map<String, dynamic> json,
  String key,
  String fallbackKey,
) {
  final value = _intValue(json, key);
  return value == 0 ? _intValue(json, fallbackKey) : value;
}

dynamic _value(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final pascal =
      key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';
  return json[pascal];
}
