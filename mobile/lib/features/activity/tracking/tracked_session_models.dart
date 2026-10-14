import '../models/activity_models.dart';

class TrackedSessionDto {
  final String sessionId;
  final ActivityType type;
  final DateTime endedAt;
  final int activeSeconds;
  final double distanceMeters;
  final bool gpsMeasured;
  final String? rewardedActivityId;

  const TrackedSessionDto({
    required this.sessionId,
    required this.type,
    required this.endedAt,
    required this.activeSeconds,
    required this.distanceMeters,
    required this.gpsMeasured,
    this.rewardedActivityId,
  });

  factory TrackedSessionDto.fromJson(Map<String, dynamic> json) =>
      TrackedSessionDto(
        sessionId: json['sessionId'] as String,
        type: activityTypeFromApiValue(json['type'] as String)!,
        endedAt: DateTime.parse(json['endedAtUtc'] as String),
        activeSeconds: (json['activeSeconds'] as num).toInt(),
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        gpsMeasured: json['gpsMeasured'] == true,
        rewardedActivityId: json['rewardedActivityId'] as String?,
      );
}
