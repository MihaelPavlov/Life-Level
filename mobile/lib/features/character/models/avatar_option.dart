class AvatarOption {
  final String emoji;
  final String name;
  final bool isUnlocked;
  final bool isEquipped;
  final String? unlockRequirement;
  final int sortOrder;

  const AvatarOption({
    required this.emoji,
    required this.name,
    required this.isUnlocked,
    required this.isEquipped,
    required this.sortOrder,
    this.unlockRequirement,
  });

  factory AvatarOption.fromJson(Map<String, dynamic> json) => AvatarOption(
        emoji: json['emoji'] as String,
        name: json['name'] as String? ?? '',
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        isEquipped: json['isEquipped'] as bool? ?? false,
        unlockRequirement: json['unlockRequirement'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}
