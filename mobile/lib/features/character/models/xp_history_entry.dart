class XpHistoryEntry {
  final String id;
  final String source;
  final String sourceEmoji;
  final String description;
  final int xp;
  final DateTime earnedAt;

  const XpHistoryEntry({
    required this.id,
    required this.source,
    required this.sourceEmoji,
    required this.description,
    required this.xp,
    required this.earnedAt,
  });

  factory XpHistoryEntry.fromJson(Map<String, dynamic> json) => XpHistoryEntry(
        id: json['id'] as String,
        source: json['source'] as String,
        sourceEmoji: json['sourceEmoji'] as String,
        description: json['description'] as String,
        xp: json['xp'] as int,
        earnedAt: DateTime.parse(json['earnedAt'] as String),
      );

  String get timeAgo {
    final diff = DateTime.now().toUtc().difference(earnedAt.toUtc());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${earnedAt.day}/${earnedAt.month}/${earnedAt.year}';
  }
}
