import 'package:flutter/widgets.dart';

import '../character/models/character_class.dart';
import '../character/models/character_profile.dart';
import '../character/models/level_up_receipt.dart';
import '../character/services/character_service.dart';
import '../character/setup/setup_resume_service.dart';
import '../integrations/models/integration_models.dart';
import 'models/onboarding_models.dart';
import 'services/onboarding_service.dart';

/// Data sources the player can import from.
abstract final class OnboardingSource {
  static const strava = 'strava';
  static const health = 'health';
}

/// State shared by every onboarding screen. Persists the current step so a
/// restart or the Strava OAuth redirect resumes where the player left off.
class OnboardingController extends ChangeNotifier {
  OnboardingController(
    SetupResumeState initial, {
    OnboardingService? service,
    CharacterService? characters,
  })  : _resume = initial,
        _service = service ?? OnboardingService(),
        _characters = characters ?? CharacterService() {
    final json = initial.importJson;
    if (json != null) importResult = OnboardingImportResult.fromJson(json);
  }

  final OnboardingService _service;
  final CharacterService _characters;
  SetupResumeState _resume;

  SetupStep get step => _resume.step;
  List<String> get ringItems => _resume.ringItems;
  String? get source => _resume.source;
  String? get avatarEmoji => _resume.avatarEmoji;
  String? get classSource => _resume.classSource;

  /// Workouts found by the connected source (Connect screen reward).
  int? foundWorkouts;

  /// Health Connect workouts read on the device, sent on import.
  List<ExternalActivityDto> healthWorkouts = const [];

  OnboardingImportResult? importResult;
  CharacterProfile? profile;
  List<LevelUpReceipt> receipts = const [];
  ClassRecommendation? recommendation;

  CharacterClass? get chosenClass =>
      recommendation?.classById(_resume.classId);

  // ── Navigation ─────────────────────────────────────────────────────────────

  void goTo(SetupStep step) {
    _resume = _resume.copyWith(step: step);
    _persist();
    notifyListeners();
  }

  void next() {
    final i = SetupStep.values.indexOf(step);
    if (i < SetupStep.values.length - 1) goTo(SetupStep.values[i + 1]);
  }

  /// Back from a step. Steps after the import can't undo it, so they return
  /// to the class choice at most.
  void back() {
    switch (step) {
      case SetupStep.connect:
        goTo(SetupStep.welcome);
      case SetupStep.avatar:
        goTo(SetupStep.classReveal);
      case SetupStep.map:
        goTo(SetupStep.avatar);
      default:
        break;
    }
  }

  // ── Sources & import ───────────────────────────────────────────────────────

  void chooseSource(String? source) {
    _resume = source == null
        ? _resume.copyWith(clearSource: true)
        : _resume.copyWith(source: source);
    _persist();
    notifyListeners();
  }

  Future<int> previewStrava() async {
    foundWorkouts = await _service.previewStrava();
    notifyListeners();
    return foundWorkouts!;
  }

  Future<OnboardingImportResult> runImport() async {
    final src = source;
    if (src == null) {
      importResult = OnboardingImportResult.empty;
    } else {
      importResult = await _service.importHistory(
        source: src,
        activities: src == OnboardingSource.health ? healthWorkouts : const [],
      );
    }
    _resume = _resume.copyWith(importJson: _importJson(importResult!));
    _persist();
    notifyListeners();
    return importResult!;
  }

  /// Level, XP and the batch level-up receipt after the import.
  Future<void> loadLevel() async {
    profile = await _characters.getProfile();
    try {
      receipts = await _characters.getPendingLevelUps();
    } catch (_) {
      receipts = const [];
    }
    notifyListeners();
  }

  /// The Level screen already celebrated these — don't repeat them on Home.
  Future<void> acknowledgeReceipts() async {
    for (final r in receipts) {
      try {
        await _characters.acknowledgeLevelUp(r.id);
      } catch (_) {}
    }
    receipts = const [];
  }

  // ── Class & avatar ─────────────────────────────────────────────────────────

  Future<ClassRecommendation> loadRecommendation({bool force = false}) async {
    if (recommendation != null && !force) return recommendation!;
    recommendation = await _service.getRecommendation();
    final rec = recommendation!;
    if (_resume.classId == null && rec.recommendedClassId != null) {
      _resume = _resume.copyWith(
          classId: rec.recommendedClassId, classSource: 'detected');
      _persist();
    }
    notifyListeners();
    return rec;
  }

  void chooseClass(CharacterClass cls) {
    final rec = recommendation;
    final src = rec == null || rec.recommendedClassId == null
        ? 'manual'
        : cls.id == rec.recommendedClassId
            ? 'detected'
            : 'changed';
    _resume = _resume.copyWith(classId: cls.id, classSource: src);
    _persist();
    notifyListeners();
  }

  void chooseAvatar(String emoji) {
    _resume = _resume.copyWith(avatarEmoji: emoji);
    _persist();
    notifyListeners();
  }

  /// Saves class + avatar and ends onboarding.
  Future<void> completeSetup() async {
    final cls = chosenClass;
    final avatar = avatarEmoji;
    if (cls == null || avatar == null) {
      throw StateError('Choose a class and an avatar first.');
    }
    await _characters.setupCharacter(
      classId: cls.id,
      avatarEmoji: avatar,
      classSource: classSource,
    );
    await SetupResumeService.instance.clear();
  }

  void _persist() => SetupResumeService.instance.save(_resume);

  static Map<String, dynamic> _importJson(OnboardingImportResult r) => {
        'source': r.source,
        'imported': r.imported,
        'skipped': r.skipped,
        'totalMinutes': r.totalMinutes,
        'totalKm': r.totalKm,
        'totalXp': r.totalXp,
        'leveledUp': r.leveledUp,
        'previousLevel': r.previousLevel,
        'newLevel': r.newLevel,
        'windowStart': r.windowStart?.toUtc().toIso8601String(),
        'windowEnd': r.windowEnd?.toUtc().toIso8601String(),
        'workouts': [
          for (final w in r.workouts)
            {
              'type': w.type,
              'performedAt': w.performedAt.toUtc().toIso8601String(),
              'durationMinutes': w.durationMinutes,
              'distanceKm': w.distanceKm,
              'xp': w.xp,
            }
        ],
        'errors': r.errors,
      };
}

/// Gives every onboarding screen access to the controller.
class OnboardingScope extends InheritedNotifier<OnboardingController> {
  const OnboardingScope({
    super.key,
    required OnboardingController controller,
    required super.child,
  }) : super(notifier: controller);

  static OnboardingController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<OnboardingScope>()!
      .notifier!;

  static OnboardingController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<OnboardingScope>()!.notifier!;
}
