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
    this.userState,
  });

  factory WorldZoneModel.fromJson(Map<String, dynamic> json) => WorldZoneModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        icon: json['icon'],
        region: json['region'],
        tier: json['tier'] as int,
        positionX: (json['positionX'] as num).toDouble(),
        positionY: (json['positionY'] as num).toDouble(),
        levelRequirement: json['levelRequirement'] as int,
        totalXp: json['totalXp'] as int,
        totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
        isCrossroads: json['isCrossroads'] as bool,
        isStartZone: json['isStartZone'] as bool,
        nodeCount: json['nodeCount'] as int,
        completedNodeCount: json['completedNodeCount'] as int?,
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
  final String? destinationZoneId;
  final List<String> unlockedZoneIds;

  const WorldUserProgress({
    required this.currentZoneId,
    this.currentEdgeId,
    required this.distanceTraveledOnEdge,
    this.destinationZoneId,
    required this.unlockedZoneIds,
  });

  factory WorldUserProgress.fromJson(Map<String, dynamic> json) =>
      WorldUserProgress(
        currentZoneId: json['currentZoneId'],
        currentEdgeId: json['currentEdgeId'],
        distanceTraveledOnEdge:
            (json['distanceTraveledOnEdge'] as num).toDouble(),
        destinationZoneId: json['destinationZoneId'],
        unlockedZoneIds: (json['unlockedZoneIds'] as List)
            .map((e) => e.toString())
            .toList(),
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
            : WorldUserProgress(
                currentZoneId: '',
                distanceTraveledOnEdge: 0,
                unlockedZoneIds: [],
              ),
        characterLevel: json['characterLevel'] as int,
      );
}
