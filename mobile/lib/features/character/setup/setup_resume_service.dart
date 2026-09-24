import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/character_class.dart';

enum SetupStep {
  welcome,
  classSelection,
  avatarSelection,
  characterCreated,
}

class SetupResumeState {
  final SetupStep step;
  final List<String> ringItems;
  final CharacterClass? selectedClass;
  final String? avatarEmoji;

  const SetupResumeState({
    required this.step,
    required this.ringItems,
    this.selectedClass,
    this.avatarEmoji,
  });

  Map<String, dynamic> toJson() => {
        'step': step.name,
        'ringItems': ringItems,
        'selectedClass': selectedClass?.toJson(),
        'avatarEmoji': avatarEmoji,
      };

  factory SetupResumeState.fromJson(Map<String, dynamic> json) {
    final selectedClassJson = json['selectedClass'];

    return SetupResumeState(
      step: SetupStep.values.firstWhere(
        (value) =>
            value.name == (json['step'] as String? ?? SetupStep.welcome.name),
        orElse: () => SetupStep.welcome,
      ),
      ringItems: ((json['ringItems'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      selectedClass: selectedClassJson is Map<String, dynamic>
          ? CharacterClass.fromJson(selectedClassJson)
          : selectedClassJson is Map
              ? CharacterClass.fromJson(
                  Map<String, dynamic>.from(selectedClassJson),
                )
              : null,
      avatarEmoji: json['avatarEmoji'] as String?,
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

  Future<void> saveWelcome({required List<String> ringItems}) {
    return _save(
      SetupResumeState(
        step: SetupStep.welcome,
        ringItems: ringItems,
      ),
    );
  }

  Future<void> saveClassSelection({
    required List<String> ringItems,
    CharacterClass? selectedClass,
  }) {
    return _save(
      SetupResumeState(
        step: SetupStep.classSelection,
        ringItems: ringItems,
        selectedClass: selectedClass,
      ),
    );
  }

  Future<void> saveAvatarSelection({
    required List<String> ringItems,
    required CharacterClass selectedClass,
    String? avatarEmoji,
  }) {
    return _save(
      SetupResumeState(
        step: SetupStep.avatarSelection,
        ringItems: ringItems,
        selectedClass: selectedClass,
        avatarEmoji: avatarEmoji,
      ),
    );
  }

  Future<void> saveCharacterCreated({
    required List<String> ringItems,
    required CharacterClass selectedClass,
    required String avatarEmoji,
  }) {
    return _save(
      SetupResumeState(
        step: SetupStep.characterCreated,
        ringItems: ringItems,
        selectedClass: selectedClass,
        avatarEmoji: avatarEmoji,
      ),
    );
  }

  Future<SetupResumeState?> load() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SetupResumeState.fromJson(decoded);
      }
      if (decoded is Map) {
        return SetupResumeState.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      await clear();
    }

    return null;
  }

  Future<void> clear() => _storage.delete(key: _storageKey);

  Future<void> _save(SetupResumeState state) {
    return _storage.write(
      key: _storageKey,
      value: jsonEncode(state.toJson()),
    );
  }
}
