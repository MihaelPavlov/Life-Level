// ─────────────────────────────────────────────────────────────────────────────
// API models for the world zone map feature
// ─────────────────────────────────────────────────────────────────────────────

class WorldZoneModel {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String region;
  final int tier;
  final double positionX;
  final double positionY;
  final int levelRequirement;
  final int totalXp;
  final double totalDistanceKm;
  final bool isCrossroads;
  final bool isStartZone;
  final int nodeCount;
  final int? completedNodeCount;
  // Typed-zone metadata introduced with the typed-zones backend. Lowercase
  // enum name: "zone" (default), "entry", "boss", "dungeon", "chest",
  // "crossroads". Defaults to "zone" when the backend omits the field.
  final String type;
  final ZoneUserState? userState;

  const WorldZoneModel({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.region,
    required this.tier,
    required this.positionX,
    required this.positionY,
    required this.levelRequirement,
    required this.totalXp,
    required this.totalDistanceKm,
    required this.isCrossroads,
    required this.isStartZone,
    required this.nodeCount,
    this.completedNodeCount,
    this.type = 'zone',
    this.userState,
  });

  factory WorldZoneModel.fromJson(Map<String, dynamic> json) => WorldZoneModel(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        description: json['description'] as String?,
        // Backend serialises the emoji glyph as `emoji`; old mobile callers
        // called it `icon`. Accept either so a future rename is safe.
        icon: (json['icon'] as String?) ?? (json['emoji'] as String?) ?? '',
        region: (json['region'] as String?) ?? '',
        tier: (json['tier'] as num?)?.toInt() ?? 1,
        positionX: (json['positionX'] as num?)?.toDouble() ?? 0,
        positionY: (json['positionY'] as num?)?.toDouble() ?? 0,
        levelRequirement: (json['levelRequirement'] as num?)?.toInt() ?? 1,
        // Backend uses `xpReward`; legacy clients used `totalXp`.
        totalXp: (json['totalXp'] as num?)?.toInt() ??
            (json['xpReward'] as num?)?.toInt() ??
            0,
        totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ??
            (json['distanceKm'] as num?)?.toDouble() ??
            0,
        isCrossroads: (json['isCrossroads'] as bool?) ??
            ((json['type'] as String?) == 'crossroads'),
        isStartZone: (json['isStartZone'] as bool?) ?? false,
        nodeCount: (json['nodeCount'] as num?)?.toInt() ?? 0,
        completedNodeCount: (json['completedNodeCount'] as num?)?.toInt(),
        type: (json['type'] as String?) ?? 'zone',
        userState: json['userState'] != null
            ? ZoneUserState.fromJson(json['userState'])
            : null,
      );
}

class ZoneUserState {
  final bool isUnlocked;
  final bool isLevelMet;
  final bool isCurrentZone;
  final bool isDestination;

  const ZoneUserState({
    required this.isUnlocked,
    required this.isLevelMet,
    required this.isCurrentZone,
    required this.isDestination,
  });

  factory ZoneUserState.fromJson(Map<String, dynamic> json) => ZoneUserState(
        isUnlocked: json['isUnlocked'] as bool,
        isLevelMet: json['isLevelMet'] as bool,
        isCurrentZone: json['isCurrentZone'] as bool,
        isDestination: json['isDestination'] as bool,
      );
}

class WorldZoneEdgeModel {
  final String id;
  final String fromZoneId;
  final String toZoneId;
  final double distanceKm;
  final bool isBidirectional;

  const WorldZoneEdgeModel({
    required this.id,
    required this.fromZoneId,
    required this.toZoneId,
    required this.distanceKm,
    required this.isBidirectional,
  });

  factory WorldZoneEdgeModel.fromJson(Map<String, dynamic> json) =>
      WorldZoneEdgeModel(
        id: json['id'],
        fromZoneId: json['fromZoneId'],
        toZoneId: json['toZoneId'],
        distanceKm: (json['distanceKm'] as num).toDouble(),
        isBidirectional: json['isBidirectional'] as bool,
      );
}

class WorldUserProgress {
  final String currentZoneId;
  final String? currentEdgeId;
  final double distanceTraveledOnEdge;
  final double pendingDistanceKm;
  final String? destinationZoneId;
  final List<String> unlockedZoneIds;
  // ID of the region the user's CurrentZone belongs to. Set by the backend
  // (WorldMapDto.CurrentRegionId) once the typed-zones overview DTO is live;
  // null if unknown or when the user has no current zone yet.
  final String? currentRegionId;

  const WorldUserProgress({
    required this.currentZoneId,
    this.currentEdgeId,
    required this.distanceTraveledOnEdge,
    this.pendingDistanceKm = 0,
    this.destinationZoneId,
    required this.unlockedZoneIds,
    this.currentRegionId,
  });

  factory WorldUserProgress.fromJson(Map<String, dynamic> json) =>
      WorldUserProgress(
        currentZoneId: (json['currentZoneId'] as String?) ?? '',
        currentEdgeId: json['currentEdgeId'] as String?,
        distanceTraveledOnEdge:
            (json['distanceTraveledOnEdge'] as num?)?.toDouble() ?? 0,
        pendingDistanceKm:
            (json['pendingDistanceKm'] as num?)?.toDouble() ?? 0,
        destinationZoneId: json['destinationZoneId'] as String?,
        unlockedZoneIds: (json['unlockedZoneIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        currentRegionId: json['currentRegionId'] as String?,
      );
}

class WorldFullData {
  final List<WorldZoneModel> zones;
  final List<WorldZoneEdgeModel> edges;
  final WorldUserProgress userProgress;
  final int characterLevel;

  const WorldFullData({
    required this.zones,
    required this.edges,
    required this.userProgress,
    required this.characterLevel,
  });

  factory WorldFullData.fromJson(Map<String, dynamic> json) => WorldFullData(
        zones: (json['zones'] as List)
            .map((e) => WorldZoneModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        edges: (json['edges'] as List)
            .map((e) => WorldZoneEdgeModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        userProgress: json['userProgress'] != null
            ? WorldUserProgress.fromJson(json['userProgress'] as Map<String, dynamic>)
            : const WorldUserProgress(
                currentZoneId: '',
                distanceTraveledOnEdge: 0,
                pendingDistanceKm: 0,
                unlockedZoneIds: [],
              ),
        characterLevel: json['characterLevel'] as int,
      );
}
