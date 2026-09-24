/// A single damage event rendered on the boss battle page's RECENT HITS
/// list. Values are persisted by the backend at turn time, so old hits stay
/// stable when equipment, talents, or character stats change later.
class BossDamageHistoryItem {
  final String activityId;
  final String activityType; // "Running", "Gym", ...
  final int durationMinutes;
  final double distanceKm;
  final int calories;
  final int damage;
  final int rawDamage;
  final double damageMultiplier;
  final double bossMitigation;
  final int damageTaken;
  final int playerHpAfter;
  final bool playerDefeated;
  final String? skipReason;
  final DateTime loggedAt;

  const BossDamageHistoryItem({
    required this.activityId,
    required this.activityType,
    required this.durationMinutes,
    required this.distanceKm,
    required this.calories,
    required this.damage,
    this.rawDamage = 0,
    this.damageMultiplier = 1,
    this.bossMitigation = 0,
    this.damageTaken = 0,
    this.playerHpAfter = 0,
    this.playerDefeated = false,
    this.skipReason,
    required this.loggedAt,
  });

  factory BossDamageHistoryItem.fromJson(Map<String, dynamic> json) =>
      BossDamageHistoryItem(
        activityId: json['activityId'] as String,
        activityType: json['activityType'] as String? ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        damage: (json['damage'] as num?)?.toInt() ?? 0,
        rawDamage: (json['rawDamage'] as num?)?.toInt() ?? 0,
        damageMultiplier: (json['damageMultiplier'] as num?)?.toDouble() ?? 1,
        bossMitigation: (json['bossMitigation'] as num?)?.toDouble() ?? 0,
        damageTaken: (json['damageTaken'] as num?)?.toInt() ?? 0,
        playerHpAfter: (json['playerHpAfter'] as num?)?.toInt() ?? 0,
        playerDefeated: json['playerDefeated'] as bool? ?? false,
        skipReason: json['skipReason'] as String?,
        loggedAt: DateTime.parse(json['loggedAt'] as String).toLocal(),
      );

  /// Emoji for the activity type, matching the palette used elsewhere.
  String get activityEmoji {
    switch (activityType.toLowerCase()) {
      case 'running':
        return '🏃';
      case 'cycling':
        return '🚴';
      case 'gym':
        return '💪';
      case 'yoga':
        return '🧘';
      case 'swimming':
        return '🏊';
      case 'hiking':
        return '🥾';
      case 'climbing':
        return '🧗';
      case 'walking':
        return '🚶';
      default:
        return '⚡';
    }
  }

  /// Line like "Running · 5.0 km · 45 min" — skips empty pieces.
  String get summary {
    final parts = <String>[activityType];
    if (distanceKm > 0) parts.add('${distanceKm.toStringAsFixed(1)} km');
    if (durationMinutes > 0) parts.add('$durationMinutes min');
    return parts.join(' · ');
  }
}
