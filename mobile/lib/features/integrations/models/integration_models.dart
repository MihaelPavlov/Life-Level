class ExternalActivityDto {
  final String provider;
  final String externalId;
  final String activityType;
  final int durationMinutes;
  final double? distanceKm;
  final int? calories;
  final int? heartRateAvg;
  final DateTime performedAt;

  const ExternalActivityDto({
    required this.provider,
    required this.externalId,
    required this.activityType,
    required this.durationMinutes,
    this.distanceKm,
    this.calories,
    this.heartRateAvg,
    required this.performedAt,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'externalId': externalId,
        'activityType': activityType,
        'durationMinutes': durationMinutes,
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (calories != null) 'calories': calories,
        if (heartRateAvg != null) 'heartRateAvg': heartRateAvg,
        'performedAt': performedAt.toIso8601String(),
      };
}

class SyncBatchRequest {
  final List<ExternalActivityDto> activities;
  const SyncBatchRequest({required this.activities});

  Map<String, dynamic> toJson() => {
        'activities': activities.map((a) => a.toJson()).toList(),
      };
}

class SyncResult {
  final int imported;
  final int skipped;
  final List<String> errors;

  const SyncResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });

  const SyncResult.empty() : imported = 0, skipped = 0, errors = const [];

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
        imported: (json['imported'] as int?) ?? 0,
        skipped: (json['skipped'] as int?) ?? 0,
        errors: (json['errors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  bool get hasErrors => errors.isNotEmpty;
  bool get isEmpty => imported == 0 && skipped == 0 && errors.isEmpty;

  String get summary {
    if (imported == 0 && skipped == 0) return 'No new activities';
    if (imported > 0 && skipped == 0) return 'Synced $imported ${imported == 1 ? 'activity' : 'activities'}';
    if (imported > 0) return 'Synced $imported new, $skipped already synced';
    return '$skipped already synced';
  }
}

class IntegrationSyncState {
  final bool isHealthConnected;
  final bool isSyncing;
  final DateTime? lastSyncAt;
  final SyncResult? lastResult;
  final bool isStravaConnected;
  final String? stravaAthleteName;
  final bool isGarminConnected;
  final String? garminDisplayName;

  const IntegrationSyncState({
    required this.isHealthConnected,
    required this.isSyncing,
    this.lastSyncAt,
    this.lastResult,
    this.isStravaConnected = false,
    this.stravaAthleteName,
    this.isGarminConnected = false,
    this.garminDisplayName,
  });

  IntegrationSyncState copyWith({
    bool? isHealthConnected,
    bool? isSyncing,
    DateTime? lastSyncAt,
    SyncResult? lastResult,
    bool? isStravaConnected,
    String? stravaAthleteName,
    bool clearStravaAthleteName = false,
    bool? isGarminConnected,
    String? garminDisplayName,
    bool clearGarminDisplayName = false,
  }) =>
      IntegrationSyncState(
        isHealthConnected: isHealthConnected ?? this.isHealthConnected,
        isSyncing: isSyncing ?? this.isSyncing,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        lastResult: lastResult ?? this.lastResult,
        isStravaConnected: isStravaConnected ?? this.isStravaConnected,
        stravaAthleteName: clearStravaAthleteName
            ? null
            : (stravaAthleteName ?? this.stravaAthleteName),
        isGarminConnected: isGarminConnected ?? this.isGarminConnected,
        garminDisplayName: clearGarminDisplayName
            ? null
            : (garminDisplayName ?? this.garminDisplayName),
      );
}

// ── Strava status ─────────────────────────────────────────────────────────────
class StravaStatusDto {
  final bool isConnected;
  final String? athleteName;
  final int? athleteId;
  final DateTime? connectedAt;

  const StravaStatusDto({
    required this.isConnected,
    this.athleteName,
    this.athleteId,
    this.connectedAt,
  });

  factory StravaStatusDto.fromJson(Map<String, dynamic> json) => StravaStatusDto(
        isConnected: json['isConnected'] as bool? ?? false,
        athleteName: json['athleteName'] as String?,
        athleteId: json['athleteId'] as int?,
        connectedAt: json['connectedAt'] != null
            ? DateTime.parse(json['connectedAt'] as String)
            : null,
      );
}

// ── Garmin status ──────────────────────────────────────────────────────────────
class GarminStatusDto {
  final bool isConnected;
  final String? displayName;
  final String? garminUserId;
  final DateTime? connectedAt;

  const GarminStatusDto({
    required this.isConnected,
    this.displayName,
    this.garminUserId,
    this.connectedAt,
  });

  factory GarminStatusDto.fromJson(Map<String, dynamic> json) => GarminStatusDto(
        isConnected: json['isConnected'] as bool? ?? false,
        displayName: json['displayName'] as String?,
        garminUserId: json['garminUserId'] as String?,
        connectedAt: json['connectedAt'] != null
            ? DateTime.parse(json['connectedAt'] as String)
            : null,
      );
}
