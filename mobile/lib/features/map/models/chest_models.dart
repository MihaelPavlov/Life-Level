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
