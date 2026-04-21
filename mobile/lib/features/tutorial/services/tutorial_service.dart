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
  final int xpAwarded;

  const TutorialUpdateResult({
    required this.tutorialStep,
    required this.tutorialTopicsSeen,
    required this.xpAwarded,
  });

  factory TutorialUpdateResult.fromJson(Map<String, dynamic> json) {
    return TutorialUpdateResult(
      tutorialStep: json['tutorialStep'] as int? ?? 0,
      tutorialTopicsSeen: json['tutorialTopicsSeen'] as int? ?? 0,
      xpAwarded: json['xpAwarded'] as int? ?? 0,
    );
  }
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
}
