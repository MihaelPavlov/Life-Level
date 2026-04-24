/// A single damage event rendered on the boss battle page's RECENT HITS
/// list. The backend computes this on read from the user's Activities that
/// fall inside the boss's fight window, so there's no persisted event row —
/// each item reflects the activity as it was logged and the damage it
/// would deal under the current formula.
class BossDamageHistoryItem {
  final String activityId;
  final String activityType; // "Running", "Gym", ...
  final int durationMinutes;
  final double distanceKm;
  final int calories;
  final int damage;
  final DateTime loggedAt;

  const BossDamageHistoryItem({
    required this.activityId,
    required this.activityType,
    required this.durationMinutes,
    required this.distanceKm,
    required this.calories,
    required this.damage,
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
        loggedAt: DateTime.parse(json['loggedAt'] as String).toLocal(),
      );

  /// Emoji for the activity type, matching the palette used elsewhere.
  String get activityEmoji {
    switch (activityType.toLowerCase()) {
      case 'running':  return '🏃';
      case 'cycling':  return '🚴';
      case 'gym':      return '💪';
      case 'yoga':     return '🧘';
      case 'swimming': return '🏊';
      case 'hiking':   return '🥾';
      case 'climbing': return '🧗';
      case 'walking':  return '🚶';
      default:         return '⚡';
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
