import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Onboarding steps, in order. Values saved by the old Welcome → Class →
/// Avatar setup flow no longer parse and resume from [welcome].
enum SetupStep {
  /// Only for accounts made with Google or Apple, which start with a
  /// generated name.
  username,
  welcome,
  connect,
  importing,
  level,
  analyze,
  classReveal,
  avatar,
  map,
}

/// Where a player left onboarding, so a restart (or the OAuth redirect
/// cold-starting the app) lands them back on the same step.
class SetupResumeState {
  final SetupStep step;
  final List<String> ringItems;

  /// "strava" or "health"; null when logging workouts by hand.
  final String? source;
  final String? classId;

  /// "detected", "changed" or "manual".
  final String? classSource;
  final String? avatarEmoji;

  /// Raw `/onboarding/import` response, so the Level screen can be rebuilt.
  final Map<String, dynamic>? importJson;

  const SetupResumeState({
    required this.step,
    required this.ringItems,
    this.source,
    this.classId,
    this.classSource,
    this.avatarEmoji,
    this.importJson,
  });

  SetupResumeState copyWith({
    SetupStep? step,
    String? source,
    String? classId,
    String? classSource,
    String? avatarEmoji,
    Map<String, dynamic>? importJson,
    bool clearSource = false,
  }) =>
      SetupResumeState(
        step: step ?? this.step,
        ringItems: ringItems,
        source: clearSource ? null : (source ?? this.source),
        classId: classId ?? this.classId,
        classSource: classSource ?? this.classSource,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        importJson: importJson ?? this.importJson,
      );

  Map<String, dynamic> toJson() => {
        'step': step.name,
        'ringItems': ringItems,
        'source': source,
        'classId': classId,
        'classSource': classSource,
        'avatarEmoji': avatarEmoji,
        'importJson': importJson,
      };

  factory SetupResumeState.fromJson(Map<String, dynamic> json) {
    final import = json['importJson'];
    return SetupResumeState(
      step: SetupStep.values.firstWhere(
        (value) => value.name == json['step'],
        orElse: () => SetupStep.welcome,
      ),
      ringItems: ((json['ringItems'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      source: json['source'] as String?,
      classId: json['classId'] as String?,
      classSource: json['classSource'] as String?,
      avatarEmoji: json['avatarEmoji'] as String?,
      importJson: import is Map ? Map<String, dynamic>.from(import) : null,
    );
  }
}

class SetupResumeService {
  SetupResumeService._();

  static final instance = SetupResumeService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _storageKey = 'setup_resume_state';

  Future<void> saveWelcome({required List<String> ringItems}) =>
      save(SetupResumeState(step: SetupStep.welcome, ringItems: ringItems));

  Future<void> save(SetupResumeState state) => _storage.write(
        key: _storageKey,
        value: jsonEncode(state.toJson()),
      );

  Future<SetupResumeState?> load() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return SetupResumeState.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      await clear();
    }

    return null;
  }

  Future<void> clear() => _storage.delete(key: _storageKey);
}
