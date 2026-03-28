class CharacterClass {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String tagline;
  final double strMultiplier;
  final double endMultiplier;
  final double agiMultiplier;
  final double flxMultiplier;
  final double staMultiplier;

  const CharacterClass({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.tagline,
    required this.strMultiplier,
    required this.endMultiplier,
    required this.agiMultiplier,
    required this.flxMultiplier,
    required this.staMultiplier,
  });

  factory CharacterClass.fromJson(Map<String, dynamic> json) => CharacterClass(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        description: json['description'] as String,
        tagline: json['tagline'] as String,
        strMultiplier: (json['strMultiplier'] as num).toDouble(),
        endMultiplier: (json['endMultiplier'] as num).toDouble(),
        agiMultiplier: (json['agiMultiplier'] as num).toDouble(),
        flxMultiplier: (json['flxMultiplier'] as num).toDouble(),
        staMultiplier: (json['staMultiplier'] as num).toDouble(),
      );
}
