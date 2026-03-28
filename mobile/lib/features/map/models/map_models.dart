class MapNodeModel {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String type; // Zone, Boss, Crossroads, Dungeon, Chest, Event
  final String region;
  final double positionX;
  final double positionY;
  final int levelRequirement;
  final bool isStartNode;
  final bool isHidden;
  final int rewardXp;
  final BossData? boss;
  final ChestData? chest;
  final DungeonPortalData? dungeonPortal;
  final CrossroadsData? crossroads;
  final NodeUserState? userState;

  const MapNodeModel({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.type,
    required this.region,
    required this.positionX,
    required this.positionY,
    required this.levelRequirement,
    required this.isStartNode,
    required this.isHidden,
    required this.rewardXp,
    this.boss,
    this.chest,
    this.dungeonPortal,
    this.crossroads,
    this.userState,
  });

  factory MapNodeModel.fromJson(Map<String, dynamic> json) => MapNodeModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        icon: json['icon'],
        type: json['type'],
        region: json['region'],
        positionX: (json['positionX'] as num).toDouble(),
        positionY: (json['positionY'] as num).toDouble(),
        levelRequirement: json['levelRequirement'],
        isStartNode: json['isStartNode'],
        isHidden: json['isHidden'],
        rewardXp: json['rewardXp'] as int? ?? 0,
        boss: json['boss'] != null ? BossData.fromJson(json['boss']) : null,
        chest:
            json['chest'] != null ? ChestData.fromJson(json['chest']) : null,
        dungeonPortal: json['dungeonPortal'] != null
            ? DungeonPortalData.fromJson(json['dungeonPortal'])
            : null,
        crossroads: json['crossroads'] != null
            ? CrossroadsData.fromJson(json['crossroads'])
            : null,
        userState: json['userState'] != null
            ? NodeUserState.fromJson(json['userState'])
            : null,
      );
}

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
        startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
        timerExpiresAt: json['timerExpiresAt'] != null ? DateTime.parse(json['timerExpiresAt']) : null,
        defeatedAt: json['defeatedAt'] != null ? DateTime.parse(json['defeatedAt']) : null,
      );
}

class ChestData {
  final String id;
  final String rarity;
  final int rewardXp;
  final bool isCollected;

  const ChestData({
    required this.id,
    required this.rarity,
    required this.rewardXp,
    required this.isCollected,
  });

  factory ChestData.fromJson(Map<String, dynamic> json) => ChestData(
        id: json['id'],
        rarity: json['rarity'],
        rewardXp: json['rewardXp'],
        isCollected: json['isCollected'],
      );
}

class DungeonFloorData {
  final int floorNumber;
  final String requiredActivity;
  final int requiredMinutes;
  final int rewardXp;

  const DungeonFloorData({
    required this.floorNumber,
    required this.requiredActivity,
    required this.requiredMinutes,
    required this.rewardXp,
  });

  factory DungeonFloorData.fromJson(Map<String, dynamic> json) =>
      DungeonFloorData(
        floorNumber: json['floorNumber'],
        requiredActivity: json['requiredActivity'],
        requiredMinutes: json['requiredMinutes'],
        rewardXp: json['rewardXp'],
      );
}

class DungeonPortalData {
  final String id;
  final String name;
  final int totalFloors;
  final int currentFloor;
  final bool isDiscovered;
  final List<DungeonFloorData> floors;

  const DungeonPortalData({
    required this.id,
    required this.name,
    required this.totalFloors,
    required this.currentFloor,
    required this.isDiscovered,
    required this.floors,
  });

  factory DungeonPortalData.fromJson(Map<String, dynamic> json) =>
      DungeonPortalData(
        id: json['id'],
        name: json['name'],
        totalFloors: json['totalFloors'],
        currentFloor: json['currentFloor'],
        isDiscovered: json['isDiscovered'],
        floors: (json['floors'] as List)
            .map((f) => DungeonFloorData.fromJson(f))
            .toList(),
      );
}

class CrossroadsPathData {
  final String id;
  final String name;
  final double distanceKm;
  final String difficulty;
  final int estimatedDays;
  final int rewardXp;
  final String? additionalRequirement;
  final String? leadsToNodeId;

  const CrossroadsPathData({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.difficulty,
    required this.estimatedDays,
    required this.rewardXp,
    this.additionalRequirement,
    this.leadsToNodeId,
  });

  factory CrossroadsPathData.fromJson(Map<String, dynamic> json) =>
      CrossroadsPathData(
        id: json['id'],
        name: json['name'],
        distanceKm: (json['distanceKm'] as num).toDouble(),
        difficulty: json['difficulty'],
        estimatedDays: json['estimatedDays'],
        rewardXp: json['rewardXp'],
        additionalRequirement: json['additionalRequirement'],
        leadsToNodeId: json['leadsToNodeId'],
      );
}

class CrossroadsData {
  final String id;
  final List<CrossroadsPathData> paths;
  final String? chosenPathId;

  const CrossroadsData({
    required this.id,
    required this.paths,
    this.chosenPathId,
  });

  factory CrossroadsData.fromJson(Map<String, dynamic> json) => CrossroadsData(
        id: json['id'],
        paths: (json['paths'] as List)
            .map((p) => CrossroadsPathData.fromJson(p))
            .toList(),
        chosenPathId: json['chosenPathId'],
      );
}

class NodeUserState {
  final bool isUnlocked;
  final bool isLevelMet;
  final bool isCurrentNode;
  final bool isDestination;

  const NodeUserState({
    required this.isUnlocked,
    required this.isLevelMet,
    required this.isCurrentNode,
    required this.isDestination,
  });

  factory NodeUserState.fromJson(Map<String, dynamic> json) => NodeUserState(
        isUnlocked: json['isUnlocked'],
        isLevelMet: json['isLevelMet'] ?? false,
        isCurrentNode: json['isCurrentNode'],
        isDestination: json['isDestination'],
      );
}

class MapEdgeModel {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  final double distanceKm;
  final bool isBidirectional;

  const MapEdgeModel({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.distanceKm,
    required this.isBidirectional,
  });

  factory MapEdgeModel.fromJson(Map<String, dynamic> json) => MapEdgeModel(
        id: json['id'],
        fromNodeId: json['fromNodeId'],
        toNodeId: json['toNodeId'],
        distanceKm: (json['distanceKm'] as num).toDouble(),
        isBidirectional: json['isBidirectional'],
      );
}

class UserMapProgressModel {
  final String currentNodeId;
  final String? currentEdgeId;
  final double distanceTraveledOnEdge;
  final String? destinationNodeId;
  final List<String> unlockedNodeIds;

  const UserMapProgressModel({
    required this.currentNodeId,
    this.currentEdgeId,
    required this.distanceTraveledOnEdge,
    this.destinationNodeId,
    required this.unlockedNodeIds,
  });

  factory UserMapProgressModel.fromJson(Map<String, dynamic> json) =>
      UserMapProgressModel(
        currentNodeId: json['currentNodeId'],
        currentEdgeId: json['currentEdgeId'],
        distanceTraveledOnEdge:
            (json['distanceTraveledOnEdge'] as num).toDouble(),
        destinationNodeId: json['destinationNodeId'],
        unlockedNodeIds: (json['unlockedNodeIds'] as List)
            .map((e) => e.toString())
            .toList(),
      );
}

class MapFullData {
  final List<MapNodeModel> nodes;
  final List<MapEdgeModel> edges;
  final UserMapProgressModel userProgress;
  final int characterLevel;

  const MapFullData({
    required this.nodes,
    required this.edges,
    required this.userProgress,
    required this.characterLevel,
  });

  factory MapFullData.fromJson(Map<String, dynamic> json) => MapFullData(
        nodes: (json['nodes'] as List)
            .map((n) => MapNodeModel.fromJson(n))
            .toList(),
        edges: (json['edges'] as List)
            .map((e) => MapEdgeModel.fromJson(e))
            .toList(),
        userProgress: UserMapProgressModel.fromJson(json['userProgress']),
        characterLevel: json['characterLevel'] ?? 1,
      );
}
