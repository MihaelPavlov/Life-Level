/// A workout a provider reported that has not been turned into XP yet.
class PendingWorkout {
  final String id;
  final String provider;
  final String activityType;
  final int durationMinutes;
  final double? distanceKm;
  final int? calories;
  final DateTime performedAt;

  /// True when the same workout already came in from another provider.
  final bool isDuplicate;
  final String? duplicateOfProvider;

  /// Base XP and stats before gear, talent and class bonuses.
  final int previewXp;
  final int previewStrength;
  final int previewEndurance;
  final int previewAgility;
  final int previewFlexibility;
  final int previewStamina;

  const PendingWorkout({
    required this.id,
    required this.provider,
    required this.activityType,
    required this.durationMinutes,
    this.distanceKm,
    this.calories,
    required this.performedAt,
    this.isDuplicate = false,
    this.duplicateOfProvider,
    this.previewXp = 0,
    this.previewStrength = 0,
    this.previewEndurance = 0,
    this.previewAgility = 0,
    this.previewFlexibility = 0,
    this.previewStamina = 0,
  });

  factory PendingWorkout.fromJson(Map<String, dynamic> j) => PendingWorkout(
        id: j['id'] as String,
        provider: j['provider'] as String? ?? '',
        activityType: j['activityType'] as String? ?? '',
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        calories: (j['calories'] as num?)?.toInt(),
        performedAt:
            DateTime.tryParse(j['performedAt'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        isDuplicate: j['status'] == 'Duplicate',
        duplicateOfProvider: j['duplicateOfProvider'] as String?,
        previewXp: (j['previewXp'] as num?)?.toInt() ?? 0,
        previewStrength: (j['previewStrength'] as num?)?.toInt() ?? 0,
        previewEndurance: (j['previewEndurance'] as num?)?.toInt() ?? 0,
        previewAgility: (j['previewAgility'] as num?)?.toInt() ?? 0,
        previewFlexibility: (j['previewFlexibility'] as num?)?.toInt() ?? 0,
        previewStamina: (j['previewStamina'] as num?)?.toInt() ?? 0,
      );
}

class PendingWorkoutList {
  final List<PendingWorkout> items;
  final int pendingCount;
  const PendingWorkoutList({required this.items, required this.pendingCount});

  static const empty = PendingWorkoutList(items: [], pendingCount: 0);

  List<PendingWorkout> get pending =>
      items.where((w) => !w.isDuplicate).toList();

  factory PendingWorkoutList.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PendingWorkout.fromJson)
        .toList();
    return PendingWorkoutList(
      items: items,
      pendingCount: (j['pendingCount'] as num?)?.toInt() ??
          items.where((w) => !w.isDuplicate).length,
    );
  }
}

class ImportedWorkout {
  final String pendingId;
  final String activityType;
  final String provider;
  final double? distanceKm;
  final int durationMinutes;
  final int xpGained;
  final int strength;
  final int endurance;
  final int agility;
  final int flexibility;
  final int stamina;

  const ImportedWorkout({
    required this.pendingId,
    required this.activityType,
    required this.provider,
    this.distanceKm,
    required this.durationMinutes,
    required this.xpGained,
    this.strength = 0,
    this.endurance = 0,
    this.agility = 0,
    this.flexibility = 0,
    this.stamina = 0,
  });

  factory ImportedWorkout.fromJson(Map<String, dynamic> j) => ImportedWorkout(
        pendingId: j['pendingId'] as String? ?? '',
        activityType: j['activityType'] as String? ?? '',
        provider: j['provider'] as String? ?? '',
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        xpGained: (j['xpGained'] as num?)?.toInt() ?? 0,
        strength: (j['strength'] as num?)?.toInt() ?? 0,
        endurance: (j['endurance'] as num?)?.toInt() ?? 0,
        agility: (j['agility'] as num?)?.toInt() ?? 0,
        flexibility: (j['flexibility'] as num?)?.toInt() ?? 0,
        stamina: (j['stamina'] as num?)?.toInt() ?? 0,
      );
}

class ImportPendingResult {
  final List<ImportedWorkout> imported;
  final int skipped;
  final List<String> errors;
  final int totalXp;
  final double totalDistanceKm;
  final int remainingPending;

  const ImportPendingResult({
    required this.imported,
    this.skipped = 0,
    this.errors = const [],
    this.totalXp = 0,
    this.totalDistanceKm = 0,
    this.remainingPending = 0,
  });

  factory ImportPendingResult.fromJson(Map<String, dynamic> j) =>
      ImportPendingResult(
        imported: (j['imported'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ImportedWorkout.fromJson)
            .toList(),
        skipped: (j['skipped'] as num?)?.toInt() ?? 0,
        errors: (j['errors'] as List? ?? const []).map((e) => '$e').toList(),
        totalXp: (j['totalXp'] as num?)?.toInt() ?? 0,
        totalDistanceKm: (j['totalDistanceKm'] as num?)?.toDouble() ?? 0,
        remainingPending: (j['remainingPending'] as num?)?.toInt() ?? 0,
      );

  /// Stat gains summed over every imported workout, largest first.
  List<MapEntry<String, int>> get statGains {
    final totals = <String, int>{
      'STR': imported.fold(0, (a, w) => a + w.strength),
      'END': imported.fold(0, (a, w) => a + w.endurance),
      'AGI': imported.fold(0, (a, w) => a + w.agility),
      'FLX': imported.fold(0, (a, w) => a + w.flexibility),
      'STA': imported.fold(0, (a, w) => a + w.stamina),
    };
    return totals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}
