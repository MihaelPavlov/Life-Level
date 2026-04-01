class TitleDto {
  final String id;
  final String emoji;
  final String name;
  final String unlockCondition;
  final bool isEarned;
  final bool isEquipped;

  const TitleDto({
    required this.id,
    required this.emoji,
    required this.name,
    required this.unlockCondition,
    required this.isEarned,
    required this.isEquipped,
  });

  factory TitleDto.fromJson(Map<String, dynamic> json) => TitleDto(
        id: json['id'] as String,
        emoji: json['emoji'] as String,
        name: json['name'] as String,
        unlockCondition: json['unlockCondition'] as String,
        isEarned: json['isEarned'] as bool,
        isEquipped: json['isEquipped'] as bool,
      );

  TitleDto copyWith({
    String? id,
    String? emoji,
    String? name,
    String? unlockCondition,
    bool? isEarned,
    bool? isEquipped,
  }) =>
      TitleDto(
        id: id ?? this.id,
        emoji: emoji ?? this.emoji,
        name: name ?? this.name,
        unlockCondition: unlockCondition ?? this.unlockCondition,
        isEarned: isEarned ?? this.isEarned,
        isEquipped: isEquipped ?? this.isEquipped,
      );
}

class RankProgressionDto {
  final String currentRank;
  final int bossesDefeated;
  final int bossesRequiredForNextRank;
  final int bossesRemainingForNextRank;
  final String? nextRank;

  const RankProgressionDto({
    required this.currentRank,
    required this.bossesDefeated,
    required this.bossesRequiredForNextRank,
    required this.bossesRemainingForNextRank,
    required this.nextRank,
  });

  factory RankProgressionDto.fromJson(Map<String, dynamic> json) =>
      RankProgressionDto(
        currentRank: json['currentRank'] as String,
        bossesDefeated: json['bossesDefeated'] as int,
        bossesRequiredForNextRank: json['bossesRequiredForNextRank'] as int,
        bossesRemainingForNextRank: json['bossesRemainingForNextRank'] as int,
        nextRank: json['nextRank'] as String?,
      );
}

class TitlesAndRanksResponse {
  final String activeTitleEmoji;
  final String activeTitleName;
  final RankProgressionDto rankProgression;
  final List<TitleDto> earnedTitles;
  final List<TitleDto> lockedTitles;

  const TitlesAndRanksResponse({
    required this.activeTitleEmoji,
    required this.activeTitleName,
    required this.rankProgression,
    required this.earnedTitles,
    required this.lockedTitles,
  });

  factory TitlesAndRanksResponse.fromJson(Map<String, dynamic> json) =>
      TitlesAndRanksResponse(
        activeTitleEmoji: json['activeTitleEmoji'] as String? ?? '',
        activeTitleName: json['activeTitleName'] as String? ?? '',
        rankProgression: RankProgressionDto.fromJson(
            json['rankProgression'] as Map<String, dynamic>),
        earnedTitles: (json['earnedTitles'] as List<dynamic>)
            .map((j) => TitleDto.fromJson(j as Map<String, dynamic>))
            .toList(),
        lockedTitles: (json['lockedTitles'] as List<dynamic>)
            .map((j) => TitleDto.fromJson(j as Map<String, dynamic>))
            .toList(),
      );

  TitlesAndRanksResponse copyWith({
    String? activeTitleEmoji,
    String? activeTitleName,
    RankProgressionDto? rankProgression,
    List<TitleDto>? earnedTitles,
    List<TitleDto>? lockedTitles,
  }) =>
      TitlesAndRanksResponse(
        activeTitleEmoji: activeTitleEmoji ?? this.activeTitleEmoji,
        activeTitleName: activeTitleName ?? this.activeTitleName,
        rankProgression: rankProgression ?? this.rankProgression,
        earnedTitles: earnedTitles ?? this.earnedTitles,
        lockedTitles: lockedTitles ?? this.lockedTitles,
      );
}
