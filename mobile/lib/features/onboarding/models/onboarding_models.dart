import '../../character/models/character_class.dart';

/// One workout recovered by the history import (drives the import feed).
class ImportedWorkout {
  final String type;
  final DateTime performedAt;
  final int durationMinutes;
  final double distanceKm;
  final int xp;

  const ImportedWorkout({
    required this.type,
    required this.performedAt,
    required this.durationMinutes,
    required this.distanceKm,
    required this.xp,
  });

  factory ImportedWorkout.fromJson(Map<String, dynamic> j) => ImportedWorkout(
        type: j['type'] as String,
        performedAt: DateTime.parse(j['performedAt'] as String).toLocal(),
        durationMinutes: j['durationMinutes'] as int,
        distanceKm: (j['distanceKm'] as num).toDouble(),
        xp: (j['xp'] as num).toInt(),
      );
}

/// Result of `POST /onboarding/import`.
class OnboardingImportResult {
  final String source;
  final int imported;
  final int skipped;
  final int rejectedManualCount;
  final int totalMinutes;
  final double totalKm;
  final double totalAdventureDistanceKm;
  final int totalXp;
  final bool leveledUp;
  final int previousLevel;
  final int newLevel;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final List<ImportedWorkout> workouts;
  final List<String> errors;

  const OnboardingImportResult({
    required this.source,
    required this.imported,
    required this.skipped,
    required this.rejectedManualCount,
    required this.totalMinutes,
    required this.totalKm,
    required this.totalAdventureDistanceKm,
    required this.totalXp,
    required this.leveledUp,
    required this.previousLevel,
    required this.newLevel,
    required this.windowStart,
    required this.windowEnd,
    required this.workouts,
    required this.errors,
  });

  /// Nothing imported (the player logs workouts by hand instead).
  static const empty = OnboardingImportResult(
    source: 'none',
    imported: 0,
    skipped: 0,
    rejectedManualCount: 0,
    totalMinutes: 0,
    totalKm: 0,
    totalAdventureDistanceKm: 0,
    totalXp: 0,
    leveledUp: false,
    previousLevel: 0,
    newLevel: 0,
    windowStart: null,
    windowEnd: null,
    workouts: [],
    errors: [],
  );

  factory OnboardingImportResult.fromJson(Map<String, dynamic> j) =>
      OnboardingImportResult(
        source: j['source'] as String? ?? '',
        imported: j['imported'] as int? ?? 0,
        skipped: j['skipped'] as int? ?? 0,
        rejectedManualCount: j['rejectedManualCount'] as int? ?? 0,
        totalMinutes: j['totalMinutes'] as int? ?? 0,
        totalKm: (j['totalKm'] as num?)?.toDouble() ?? 0,
        totalAdventureDistanceKm:
            (j['totalAdventureDistanceKm'] as num?)?.toDouble() ?? 0,
        totalXp: (j['totalXp'] as num?)?.toInt() ?? 0,
        leveledUp: j['leveledUp'] as bool? ?? false,
        previousLevel: j['previousLevel'] as int? ?? 0,
        newLevel: j['newLevel'] as int? ?? 0,
        windowStart:
            DateTime.tryParse(j['windowStart'] as String? ?? '')?.toLocal(),
        windowEnd:
            DateTime.tryParse(j['windowEnd'] as String? ?? '')?.toLocal(),
        workouts: ((j['workouts'] as List?) ?? const [])
            .map((e) => ImportedWorkout.fromJson(e as Map<String, dynamic>))
            .toList(),
        errors: ((j['errors'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// Class detection states, in the order the backend evaluates them.
enum ClassDetectionState {
  insufficient,
  devoted,
  multisport,
  hybrid,
  balanced,
  close,
  clear;

  static ClassDetectionState parse(String? s) => ClassDetectionState.values
      .firstWhere((v) => v.name == s, orElse: () => insufficient);

  /// States that ask the player to choose between two or more classes.
  bool get isChoice => this == close || this == hybrid || this == multisport;
}

class ClassShare {
  final String classId;
  final String className;
  final int minutes;
  final double share;

  const ClassShare(this.classId, this.className, this.minutes, this.share);

  factory ClassShare.fromJson(Map<String, dynamic> j) => ClassShare(
        j['classId'] as String,
        j['className'] as String,
        j['minutes'] as int,
        (j['share'] as num).toDouble(),
      );
}

class ActivityShare {
  final String type;
  final int workouts;
  final int minutes;
  final double share;

  const ActivityShare(this.type, this.workouts, this.minutes, this.share);

  factory ActivityShare.fromJson(Map<String, dynamic> j) => ActivityShare(
        j['type'] as String,
        j['workouts'] as int,
        j['minutes'] as int,
        (j['share'] as num).toDouble(),
      );
}

/// Result of `GET /character/class-recommendation`.
class ClassRecommendation {
  final ClassDetectionState state;
  final String? recommendedClassId;
  final List<String> alternativeClassIds;
  final String? traitKey;
  final String? devotedActivityType;
  final List<ClassShare> shares;
  final List<ActivityShare> activities;
  final int workoutCount;
  final int activeMinutes;
  final List<CharacterClass> classes;

  const ClassRecommendation({
    required this.state,
    required this.recommendedClassId,
    required this.alternativeClassIds,
    required this.traitKey,
    required this.devotedActivityType,
    required this.shares,
    required this.activities,
    required this.workoutCount,
    required this.activeMinutes,
    required this.classes,
  });

  factory ClassRecommendation.fromJson(Map<String, dynamic> j) =>
      ClassRecommendation(
        state: ClassDetectionState.parse(j['state'] as String?),
        recommendedClassId: j['recommendedClassId'] as String?,
        alternativeClassIds: ((j['alternativeClassIds'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        traitKey: j['traitKey'] as String?,
        devotedActivityType: j['devotedActivityType'] as String?,
        shares: ((j['shares'] as List?) ?? const [])
            .map((e) => ClassShare.fromJson(e as Map<String, dynamic>))
            .toList(),
        activities: ((j['activities'] as List?) ?? const [])
            .map((e) => ActivityShare.fromJson(e as Map<String, dynamic>))
            .toList(),
        workoutCount: j['workoutCount'] as int? ?? 0,
        activeMinutes: j['activeMinutes'] as int? ?? 0,
        classes: ((j['classes'] as List?) ?? const [])
            .map((e) => CharacterClass.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  CharacterClass? classById(String? id) =>
      id == null ? null : classes.where((c) => c.id == id).firstOrNull;

  CharacterClass? classByName(String name) => classes
      .where((c) => c.name.toLowerCase() == name.toLowerCase())
      .firstOrNull;

  CharacterClass? get recommended => classById(recommendedClassId);

  List<CharacterClass> get alternatives =>
      alternativeClassIds.map(classById).whereType<CharacterClass>().toList();

  /// Classes a player may pick by hand (hybrids come from detection only).
  List<CharacterClass> get pickable =>
      classes.where((c) => !c.isHybrid).toList();

  double shareOf(String classId) =>
      shares.where((s) => s.classId == classId).firstOrNull?.share ?? 0;
}
