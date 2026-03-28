class CharacterSetupResult {
  final String characterId;
  final String className;
  final String classEmoji;
  final String avatarEmoji;
  final int xp;
  final int level;
  final bool isSetupComplete;

  const CharacterSetupResult({
    required this.characterId,
    required this.className,
    required this.classEmoji,
    required this.avatarEmoji,
    required this.xp,
    required this.level,
    required this.isSetupComplete,
  });

  factory CharacterSetupResult.fromJson(Map<String, dynamic> json) =>
      CharacterSetupResult(
        characterId: json['characterId'] as String,
        className: json['className'] as String,
        classEmoji: json['classEmoji'] as String,
        avatarEmoji: json['avatarEmoji'] as String,
        xp: json['xp'] as int,
        level: json['level'] as int,
        isSetupComplete: json['isSetupComplete'] as bool,
      );
}
