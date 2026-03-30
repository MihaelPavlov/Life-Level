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
