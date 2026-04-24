// ─────────────────────────────────────────────────────────────────────────────
// World map models — align with the rebuilt backend (/api/map/world, /api/map/region/{id}).
//
// Two-level navigation:
//   • WorldMapData        → list of regions + user + optional active journey
//   • RegionDetail        → single region + ordered zone nodes + edges
// ─────────────────────────────────────────────────────────────────────────────

// ── Enums ────────────────────────────────────────────────────────────────────

enum ZoneNodeStatus { completed, active, next, available, locked }
enum RegionStatus { active, completed, locked }
enum RegionBossStatus { locked, available, defeated }
enum RegionTheme { forest, ocean, mountain, volcano, frost, desert }

ZoneNodeStatus zoneNodeStatusFromString(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'completed': return ZoneNodeStatus.completed;
    case 'active':    return ZoneNodeStatus.active;
    case 'next':      return ZoneNodeStatus.next;
    case 'available': return ZoneNodeStatus.available;
    default:          return ZoneNodeStatus.locked;
  }
}

RegionStatus regionStatusFromString(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'active':    return RegionStatus.active;
    case 'completed': return RegionStatus.completed;
    default:          return RegionStatus.locked;
  }
}

RegionBossStatus regionBossStatusFromString(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'available': return RegionBossStatus.available;
    case 'defeated':  return RegionBossStatus.defeated;
    default:          return RegionBossStatus.locked;
  }
}

RegionTheme regionThemeFromString(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'forest':   return RegionTheme.forest;
    case 'ocean':    return RegionTheme.ocean;
    case 'mountain': return RegionTheme.mountain;
    case 'volcano':  return RegionTheme.volcano;
    case 'frost':    return RegionTheme.frost;
    case 'desert':   return RegionTheme.desert;
    default:         return RegionTheme.forest;
  }
}

// ── User / active journey ────────────────────────────────────────────────────

class WorldUser {
  final int level;
  final String characterName;
  const WorldUser({required this.level, required this.characterName});

  factory WorldUser.fromJson(Map<String, dynamic> json) => WorldUser(
        level: (json['level'] as num?)?.toInt() ?? 1,
        characterName: json['characterName'] as String? ?? '',
      );
}

class ActiveJourney {
  final String destinationZoneName;
  final String destinationZoneEmoji;
  final String regionName;
  final double distanceTravelledKm;
  final double distanceTotalKm;
  final int arrivalXpReward;
  final String? arrivalBonusLabel;

  const ActiveJourney({
    required this.destinationZoneName,
    required this.destinationZoneEmoji,
    required this.regionName,
    required this.distanceTravelledKm,
    required this.distanceTotalKm,
    required this.arrivalXpReward,
    this.arrivalBonusLabel,
  });

  double get progress {
    if (distanceTotalKm <= 0) return 0.0;
    return (distanceTravelledKm / distanceTotalKm).clamp(0.0, 1.0);
  }

  factory ActiveJourney.fromJson(Map<String, dynamic> json) => ActiveJourney(
        destinationZoneName: json['destinationZoneName'] as String? ?? '',
        destinationZoneEmoji: json['destinationZoneEmoji'] as String? ?? '',
        regionName: json['regionName'] as String? ?? '',
        distanceTravelledKm:
            (json['distanceTravelledKm'] as num?)?.toDouble() ?? 0.0,
        distanceTotalKm:
            (json['distanceTotalKm'] as num?)?.toDouble() ?? 0.0,
        arrivalXpReward: (json['arrivalXpReward'] as num?)?.toInt() ?? 0,
        arrivalBonusLabel: json['arrivalBonusLabel'] as String?,
      );
}

// ── Region pin (small badge on a region card) ────────────────────────────────

class RegionPin {
  final String label;
  final String value;
  const RegionPin({required this.label, required this.value});

  factory RegionPin.fromJson(Map<String, dynamic> json) => RegionPin(
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
      );
}

// ── Region card (hub list item) ──────────────────────────────────────────────

class RegionCard {
  final String id;
  final String name;
  final String emoji;
  final String lore;
  final String bossName;
  final RegionTheme theme;
  final int chapterIndex;
  final int levelRequirement;
  final int completedZones;
  final int totalZones;
  final int totalXpEarned;
  final int? zonesUntilBoss;
  final RegionStatus status;
  final RegionBossStatus bossStatus;
  final List<RegionPin> pins;

  const RegionCard({
    required this.id,
    required this.name,
    required this.emoji,
    required this.lore,
    required this.bossName,
    required this.theme,
    required this.chapterIndex,
    required this.levelRequirement,
    required this.completedZones,
    required this.totalZones,
    required this.totalXpEarned,
    required this.zonesUntilBoss,
    required this.status,
    required this.bossStatus,
    required this.pins,
  });

  double get progress {
    if (totalZones <= 0) return 0.0;
    return (completedZones / totalZones).clamp(0.0, 1.0);
  }

  factory RegionCard.fromJson(Map<String, dynamic> json) => RegionCard(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
        lore: json['lore'] as String? ?? '',
        bossName: json['bossName'] as String? ?? '',
        theme: regionThemeFromString(json['theme'] as String?),
        chapterIndex: (json['chapterIndex'] as num?)?.toInt() ?? 0,
        levelRequirement: (json['levelRequirement'] as num?)?.toInt() ?? 1,
        completedZones: (json['completedZones'] as num?)?.toInt() ?? 0,
        totalZones: (json['totalZones'] as num?)?.toInt() ?? 0,
        totalXpEarned: (json['totalXpEarned'] as num?)?.toInt() ?? 0,
        zonesUntilBoss: (json['zonesUntilBoss'] as num?)?.toInt(),
        status: regionStatusFromString(json['status'] as String?),
        bossStatus: regionBossStatusFromString(json['bossStatus'] as String?),
        pins: (json['pins'] as List?)
                ?.map((e) => RegionPin.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

// ── Region detail (single region + nodes + edges) ────────────────────────────

class RegionDetail extends RegionCard {
  final List<ZoneNode> nodes;
  final List<ZoneEdge> edges;

  /// Map of crossroadsZoneId → chosenBranchZoneId. Populated when the user
  /// has already picked a fork at a crossroads; the chosen branch follows
  /// normal progression rules, the sibling is permanently locked.
  final Map<String, String> pathChoices;

  const RegionDetail({
    required super.id,
    required super.name,
    required super.emoji,
    required super.lore,
    required super.bossName,
    required super.theme,
    required super.chapterIndex,
    required super.levelRequirement,
    required super.completedZones,
    required super.totalZones,
    required super.totalXpEarned,
    required super.zonesUntilBoss,
    required super.status,
    required super.bossStatus,
    required super.pins,
    required this.nodes,
    required this.edges,
    required this.pathChoices,
  });

  factory RegionDetail.fromJson(Map<String, dynamic> json) {
    final base = RegionCard.fromJson(json);
    final choicesList = (json['pathChoices'] as List?) ?? const [];
    final choices = <String, String>{
      for (final raw in choicesList)
        if (raw is Map<String, dynamic>)
          raw['crossroadsZoneId'] as String: raw['chosenZoneId'] as String,
    };
    return RegionDetail(
      id: base.id,
      name: base.name,
      emoji: base.emoji,
      lore: base.lore,
      bossName: base.bossName,
      theme: base.theme,
      chapterIndex: base.chapterIndex,
      levelRequirement: base.levelRequirement,
      completedZones: base.completedZones,
      totalZones: base.totalZones,
      totalXpEarned: base.totalXpEarned,
      zonesUntilBoss: base.zonesUntilBoss,
      status: base.status,
      bossStatus: base.bossStatus,
      pins: base.pins,
      nodes: (json['nodes'] as List?)
              ?.map((e) => ZoneNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      edges: (json['edges'] as List?)
              ?.map((e) => ZoneEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pathChoices: choices,
    );
  }
}

// ── Zone node (single point on the region trail) ─────────────────────────────

class ZoneNode {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int tier;
  final int levelRequirement;
  final int xpReward;
  final double distanceKm;
  final ZoneNodeStatus status;
  final bool isCrossroads;
  final bool isBoss;

  /// When non-null, this zone is one branch of a crossroads. All siblings
  /// share the same `branchOf` value — the id of the parent crossroads zone.
  final String? branchOf;

  final int? nodesCompleted;
  final int? nodesTotal;
  final int? loreCollected;
  final int? loreTotal;

  const ZoneNode({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.tier,
    required this.levelRequirement,
    required this.xpReward,
    required this.distanceKm,
    required this.status,
    required this.isCrossroads,
    required this.isBoss,
    this.branchOf,
    this.nodesCompleted,
    this.nodesTotal,
    this.loreCollected,
    this.loreTotal,
  });

  factory ZoneNode.fromJson(Map<String, dynamic> json) => ZoneNode(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
        description: json['description'] as String? ?? '',
        tier: (json['tier'] as num?)?.toInt() ?? 1,
        levelRequirement: (json['levelRequirement'] as num?)?.toInt() ?? 1,
        xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        status: zoneNodeStatusFromString(json['status'] as String?),
        isCrossroads: json['isCrossroads'] as bool? ?? false,
        isBoss: json['isBoss'] as bool? ?? false,
        branchOf: json['branchOf'] as String?,
        nodesCompleted: (json['nodesCompleted'] as num?)?.toInt(),
        nodesTotal: (json['nodesTotal'] as num?)?.toInt(),
        loreCollected: (json['loreCollected'] as num?)?.toInt(),
        loreTotal: (json['loreTotal'] as num?)?.toInt(),
      );
}

// ── Zone edge (directional link between two nodes) ───────────────────────────

class ZoneEdge {
  final String fromId;
  final String toId;
  const ZoneEdge({required this.fromId, required this.toId});

  factory ZoneEdge.fromJson(Map<String, dynamic> json) => ZoneEdge(
        fromId: json['fromId'] as String,
        toId: json['toId'] as String,
      );
}

// ── World map aggregate ──────────────────────────────────────────────────────

class WorldMapData {
  final WorldUser user;
  final ActiveJourney? activeJourney;
  final List<RegionCard> regions;

  const WorldMapData({
    required this.user,
    required this.activeJourney,
    required this.regions,
  });

  int get unlockedRegionCount =>
      regions.where((r) => r.status != RegionStatus.locked).length;

  factory WorldMapData.fromJson(Map<String, dynamic> json) => WorldMapData(
        user: WorldUser.fromJson(
            (json['user'] as Map<String, dynamic>?) ?? const {}),
        activeJourney: json['activeJourney'] == null
            ? null
            : ActiveJourney.fromJson(
                json['activeJourney'] as Map<String, dynamic>),
        regions: (json['regions'] as List?)
                ?.map((e) => RegionCard.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
