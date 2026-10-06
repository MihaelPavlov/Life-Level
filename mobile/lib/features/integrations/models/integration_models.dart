enum ExternalRecordingMethod { unknown, active, automatic, manual }

extension ExternalRecordingMethodWire on ExternalRecordingMethod {
  String get wireName => switch (this) {
        ExternalRecordingMethod.unknown => 'Unknown',
        ExternalRecordingMethod.active => 'Active',
        ExternalRecordingMethod.automatic => 'Automatic',
        ExternalRecordingMethod.manual => 'Manual',
      };
}

class ExternalActivityDto {
  final String provider;
  final String externalId;
  final String activityType;
  final int durationMinutes;
  final double? distanceKm;
  final int? calories;
  final int? heartRateAvg;

  /// Real step count from the phone; only daily step walks carry it.
  final int? steps;
  final ExternalRecordingMethod recordingMethod;
  final DateTime performedAt;

  const ExternalActivityDto({
    required this.provider,
    required this.externalId,
    required this.activityType,
    required this.durationMinutes,
    this.distanceKm,
    this.calories,
    this.heartRateAvg,
    this.steps,
    this.recordingMethod = ExternalRecordingMethod.unknown,
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
        if (steps != null) 'steps': steps,
        'recordingMethod': recordingMethod.wireName,
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
  final int rejectedManual;
  final double totalAdventureDistanceKm;
  final List<String> errors;

  const SyncResult({
    required this.imported,
    required this.skipped,
    this.rejectedManual = 0,
    this.totalAdventureDistanceKm = 0,
    required this.errors,
  });

  const SyncResult.empty()
      : imported = 0,
        skipped = 0,
        rejectedManual = 0,
        totalAdventureDistanceKm = 0,
        errors = const [];

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
        imported: (json['imported'] as int?) ?? 0,
        skipped: (json['skipped'] as int?) ?? 0,
        rejectedManual: (json['rejectedManual'] as int?) ?? 0,
        totalAdventureDistanceKm:
            (json['totalAdventureDistanceKm'] as num?)?.toDouble() ?? 0,
        errors: (json['errors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  bool get hasErrors => errors.isNotEmpty;
  bool get isEmpty =>
      imported == 0 && skipped == 0 && rejectedManual == 0 && errors.isEmpty;

  String get summary {
    final travel = totalAdventureDistanceKm > 0
        ? ' · ${_formatAdventureKm(totalAdventureDistanceKm)} Adventure km'
        : '';
    if (imported == 0 && skipped == 0 && rejectedManual == 0) {
      return 'No new activities';
    }
    final rejected = rejectedManual > 0
        ? ' · $rejectedManual manual ${rejectedManual == 1 ? 'entry' : 'entries'} rejected'
        : '';
    if (imported > 0 && skipped == 0) {
      return 'Synced $imported ${imported == 1 ? 'activity' : 'activities'}$travel$rejected';
    }
    if (imported > 0) {
      return 'Synced $imported new, $skipped already synced$travel$rejected';
    }
    if (rejectedManual > 0 && skipped == 0) {
      return '$rejectedManual manual ${rejectedManual == 1 ? 'entry' : 'entries'} rejected';
    }
    return '$skipped already synced';
  }
}

String _formatAdventureKm(double value) =>
    value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

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

  factory StravaStatusDto.fromJson(Map<String, dynamic> json) =>
      StravaStatusDto(
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

  factory GarminStatusDto.fromJson(Map<String, dynamic> json) =>
      GarminStatusDto(
        isConnected: json['isConnected'] as bool? ?? false,
        displayName: json['displayName'] as String?,
        garminUserId: json['garminUserId'] as String?,
        connectedAt: json['connectedAt'] != null
            ? DateTime.parse(json['connectedAt'] as String)
            : null,
      );
}
