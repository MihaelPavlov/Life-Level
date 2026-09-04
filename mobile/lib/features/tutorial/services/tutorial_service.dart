import '../../../core/api/api_client.dart';
import '../models/tutorial_topic.dart';

/// Response shape from all four `/api/tutorial/*` endpoints.
///
/// The backend returns only the three tutorial-specific fields; the full
/// `CharacterProfile` refresh happens separately via `GET /api/character/me`
/// when a caller needs the rest of the character state.
class TutorialUpdateResult {
  final int tutorialStep;
  final int tutorialTopicsSeen;
  final int mapTutorialStep;
  final int xpAwarded;

  const TutorialUpdateResult({
    required this.tutorialStep,
    required this.tutorialTopicsSeen,
    required this.mapTutorialStep,
    required this.xpAwarded,
  });

  factory TutorialUpdateResult.fromJson(Map<String, dynamic> json) {
    return TutorialUpdateResult(
      tutorialStep: _readInt(json, 'tutorialStep') ?? 0,
      tutorialTopicsSeen: _readInt(json, 'tutorialTopicsSeen') ?? 0,
      mapTutorialStep: _readInt(json, 'mapTutorialStep') ?? 0,
      xpAwarded: _readInt(json, 'xpAwarded') ?? 0,
    );
  }
}

class MapTutorialUpdateResult {
  final int mapTutorialStep;

  const MapTutorialUpdateResult({required this.mapTutorialStep});

  factory MapTutorialUpdateResult.fromJson(Map<String, dynamic> json) {
    return MapTutorialUpdateResult(
      mapTutorialStep: _readInt(json, 'mapTutorialStep') ?? 0,
    );
  }
}

int? _readInt(Map<String, dynamic> json, String camelCaseKey) {
  final pascalCaseKey =
      camelCaseKey[0].toUpperCase() + camelCaseKey.substring(1);
  final value = json[camelCaseKey] ?? json[pascalCaseKey];
  return value is int ? value : (value is num ? value.toInt() : null);
}

/// Thin wrapper over the four tutorial endpoints.
class TutorialService {
  final _dio = ApiClient.instance;

  /// POST /api/tutorial/advance — increments step, awards XP on first pass.
  /// Backend rejects when server's current step is 4 (action-gated — that
  /// transition is triggered by a real activity log via the SharedKernel port).
  Future<TutorialUpdateResult> advance() async {
    final res = await _dio.post('/tutorial/advance');
    return TutorialUpdateResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /api/tutorial/skip — sets tutorialStep = -1, no XP.
  Future<TutorialUpdateResult> skip() async {
    final res = await _dio.post('/tutorial/skip');
    return TutorialUpdateResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /api/tutorial/replay-all — resets tutorialStep to 0 so the full
  /// flow replays. Does not re-award XP.
  Future<TutorialUpdateResult> replayAll() async {
    final res = await _dio.post('/tutorial/replay-all');
    return TutorialUpdateResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /api/tutorial/replay-topic — marks the topic bit in the bitmask.
  /// Does not change tutorialStep.
  Future<TutorialUpdateResult> replayTopic(TutorialTopic topic) async {
    final res = await _dio.post(
      '/tutorial/replay-topic',
      data: {'topic': topic.apiValue},
    );
    return TutorialUpdateResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MapTutorialUpdateResult> startMapTutorial() async {
    final res = await _dio.post('/tutorial/map/start');
    return MapTutorialUpdateResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MapTutorialUpdateResult> advanceMapTutorial() async {
    final res = await _dio.post('/tutorial/map/advance');
    return MapTutorialUpdateResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MapTutorialUpdateResult> skipMapTutorial() async {
    final res = await _dio.post('/tutorial/map/skip');
    return MapTutorialUpdateResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MapTutorialUpdateResult> replayMapTutorial() async {
    final res = await _dio.post('/tutorial/map/replay');
    return MapTutorialUpdateResult.fromJson(res.data as Map<String, dynamic>);
  }
}
