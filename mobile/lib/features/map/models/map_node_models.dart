import 'boss_models.dart';
import 'chest_models.dart';
import 'dungeon_models.dart';
import 'crossroads_models.dart';

export 'boss_models.dart';
export 'chest_models.dart';
export 'dungeon_models.dart';
export 'crossroads_models.dart';

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
