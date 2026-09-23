/// Domain model for a single notification item shown in the bell sheet.
///
/// Mirrors the row shape in design-mockup/home/home-v3.html screen 4
/// (`.home3-notif`). The [category] drives the icon-pill colour; [deepLink]
/// is handed to [DeepLinkNotifier] when a row is tapped.
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final String? deepLink;
  final DateTime createdAt;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    required this.isRead,
    this.deepLink,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        body: body,
        category: category,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        deepLink: deepLink,
      );

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final categoryStr = json['category'] as String?;
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? json['sub'] ?? '') as String,
      category: _parseCategory(categoryStr),
      // Backend sends 'sentAt'; fall back to 'createdAt' for future-proofing.
      createdAt: _parseDate(json['sentAt'] ?? json['createdAt']),
      isRead: (json['isRead'] as bool?) ?? false,
      deepLink: (json['deepLink'] as String?) ?? _inferDeepLink(categoryStr),
    );
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  static NotificationCategory _parseCategory(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'storm':
      case 'xpstorm':
      case 'xp_storm':
        return NotificationCategory.storm;
      case 'boss':
      case 'boss-defeated':
      case 'boss_defeated':
        return NotificationCategory.boss;
      case 'guild':
      case 'raid':
        return NotificationCategory.guild;
      case 'quest':
      case 'quest-completed':
      case 'quest_completed':
        return NotificationCategory.quest;
      case 'level-up':
      case 'level_up':
      case 'levelup':
      case 'rank-changed':
      case 'rank_changed':
      case 'streak-broken':
      case 'streak_broken':
      case 'social':
      case 'leaderboard':
      case 'friend':
      default:
        return NotificationCategory.social;
    }
  }

  /// Infers a navigation deeplink from the notification category when the
  /// backend does not return one (NotificationLog has no DeepLink column yet).
  static String _inferDeepLink(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'boss':
      case 'boss-defeated':
      case 'boss_defeated':
        return 'lifelevel://boss';
      case 'quest':
      case 'quest-completed':
      case 'quest_completed':
        return 'lifelevel://rewards';
      case 'rank-changed':
      case 'rank_changed':
        return 'lifelevel://profile';
      default:
        return 'lifelevel://home';
    }
  }
}

/// Visual categories for notification rows — maps 1:1 with `.home3-notif__icon--*`
/// in the v3 mockup.
enum NotificationCategory {
  storm,
  boss,
  guild,
  quest,
  social,
}
