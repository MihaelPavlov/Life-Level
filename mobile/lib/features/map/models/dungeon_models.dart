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
