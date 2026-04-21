import 'package:flutter/material.dart';
import 'models/tutorial_placement.dart';
import 'models/tutorial_step.dart';
import 'models/tutorial_topic.dart';
import 'services/tutorial_service.dart';

/// Drives the tutorial state machine. Owns the "currently visible step",
/// registered target keys (wired by `MainShell` + Home cards), and the
/// pending XP-reward flash that the overlay shows during step transitions.
///
/// The controller is a `ChangeNotifier` so any widget that wants to react
/// (the overlay root, the "waiting" state of the action-gated step, the
/// tutorials hub row ✓ indicators…) can call `listenable.addListener` or
/// wrap itself in an `AnimatedBuilder`. Riverpod wires it as a singleton
/// via `tutorialControllerProvider`.
class TutorialController extends ChangeNotifier {
  TutorialController({TutorialService? service})
      : _api = service ?? TutorialService();

  final TutorialService _api;

  // ── state ────────────────────────────────────────────────────────────────
  TutorialStep? _step;
  TutorialTopic? _topic;
  int _topicsSeen = 0;
  int? _pendingXpReward;
  bool _busy = false;
  bool _shouldShowIntroModal = false;
  bool _shouldShowOutroModal = false;

  /// Topic replay queue. Consumed one step at a time by `advance()`.
  /// When empty during a topic replay the controller calls `stop()`.
  final List<TutorialStep> _topicQueue = [];

  /// Registered target `GlobalKey`s keyed by [TutorialStep.targetKeyId].
  /// MainShell + Home cards register themselves during `initState`; the
  /// controller reads the RenderBox on demand to compute the bubble rect.
  final Map<String, GlobalKey> _targetKeys = {};

  // ── getters ──────────────────────────────────────────────────────────────
  TutorialStep? get step => _step;
  TutorialTopic? get topic => _topic;
  int get topicsSeen => _topicsSeen;
  int? get pendingXpReward => _pendingXpReward;
  bool get isBusy => _busy;
  bool get isActive => _step != null;
  bool get shouldShowIntroModal => _shouldShowIntroModal;
  bool get shouldShowOutroModal => _shouldShowOutroModal;
  bool get isTopicReplay => _topic != null;

  /// Step 4 is gated — UI shows "Waiting…" instead of "Next". On a topic
  /// replay we drop the gate so the user can just tap through.
  bool get isActionGated =>
      _step == TutorialStep.logActivity && !isTopicReplay;

  // ── target registration ─────────────────────────────────────────────────
  /// Registers a GlobalKey for a step target. Safe to call multiple times —
  /// the latest key always wins (supports hot reload / key replacement).
  void registerKey(String id, GlobalKey key) {
    _targetKeys[id] = key;
  }

  void unregisterKey(String id) {
    _targetKeys.remove(id);
  }

  /// Returns the current step's target rect in global coordinates, or `null`
  /// if no key is registered yet (e.g. the Home screen isn't mounted).
  Rect? currentTargetRect() {
    final step = _step;
    if (step == null) return null;
    final keyId = step.targetKeyId;
    if (keyId == null) return null;
    final key = _targetKeys[keyId];
    final ctx = key?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  /// Chooses a placement for the current bubble based on the target rect
  /// and the full screen size. Defaults to `below` when no rect is known.
  BubblePlacement currentPlacement(Size screen) {
    final rect = currentTargetRect();
    if (rect == null) return BubblePlacement.below;
    return choosePlacement(rect, screen);
  }

  /// Returns true if `topic` has been replayed / seen at least once.
  bool hasSeenTopic(TutorialTopic t) =>
      (_topicsSeen & (1 << t.bitIndex)) != 0;

  // ── lifecycle ────────────────────────────────────────────────────────────

  /// Hydrates state from the backend-provided `CharacterProfile` fields.
  /// Called by `MainShell` after the profile loads. Triggers the auto-start
  /// of the tutorial when the server step is 0 (intro pending).
  void hydrateFromProfile({
    required int serverStep,
    required int serverTopicsSeen,
  }) {
    _topicsSeen = serverTopicsSeen;
    // -1 = skipped, 99 = completed: nothing to show.
    if (serverStep < 0 || serverStep >= 99) {
      if (_step != null) {
        _step = null;
        _topic = null;
        notifyListeners();
      }
      return;
    }
    // Only auto-start if we're not already running (e.g. a topic replay).
    if (_topic != null) return;

    if (serverStep == 0) {
      _step = TutorialStep.intro;
      _shouldShowIntroModal = true;
    } else {
      _step = TutorialStep.fromServer(serverStep);
    }
    notifyListeners();
  }

  /// Jumps to a specific step (used by intro "Begin" and tests).
  Future<void> startFromStep(TutorialStep step) async {
    _topic = null;
    _topicQueue.clear();
    _step = step;
    _shouldShowIntroModal = step == TutorialStep.intro;
    _shouldShowOutroModal = step == TutorialStep.outro;
    notifyListeners();
  }

  /// Starts a single-topic replay. Fires `/replay-topic` to mark the bit,
  /// then steps through the topic's bubbles locally (no XP, no outro).
  Future<void> startTopic(TutorialTopic topic) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      final result = await _api.replayTopic(topic);
      _topicsSeen = result.tutorialTopicsSeen;
    } catch (_) {
      // Still allow the replay UI to show even if the bit-mark call fails —
      // the user hasn't lost anything and the overlay is read-only data.
    } finally {
      _busy = false;
    }
    _topic = topic;
    _topicQueue
      ..clear()
      ..addAll(topic.steps);
    if (_topicQueue.isEmpty) {
      _topic = null;
      notifyListeners();
      return;
    }
    _step = _topicQueue.removeAt(0);
    notifyListeners();
  }

  /// Resets the backend to step 0 and restarts the full walkthrough.
  /// No XP on replay (server enforces one-shot rewards).
  Future<void> replayAll() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      final result = await _api.replayAll();
      _topicsSeen = result.tutorialTopicsSeen;
    } catch (_) {
      // Proceed regardless — the intro modal path is safe to show.
    } finally {
      _busy = false;
    }
    _topic = null;
    _topicQueue.clear();
    _step = TutorialStep.intro;
    _shouldShowIntroModal = true;
    notifyListeners();
  }

  /// Advances one step. On topic replays, pops from the local queue; on the
  /// full flow, calls `/advance` and trusts the server to move forward.
  Future<void> advance() async {
    if (_busy || _step == null) return;

    // Topic replay: local-only progression, no server call, no rewards.
    if (_topic != null) {
      if (_topicQueue.isEmpty) {
        await stop();
        return;
      }
      _step = _topicQueue.removeAt(0);
      notifyListeners();
      return;
    }

    // Intro → step 1: treat as a local UI transition + `/advance` to bump
    // the server step from 0 to 1 (and award the first XP).
    _busy = true;
    notifyListeners();
    try {
      final result = await _api.advance();
      _topicsSeen = result.tutorialTopicsSeen;
      if (result.xpAwarded > 0) {
        _pendingXpReward = result.xpAwarded;
      }
      _shouldShowIntroModal = false;
      final next = TutorialStep.fromServer(result.tutorialStep);
      if (next == null) {
        // Server jumped to a terminal state (shouldn't happen mid-flow,
        // but handle defensively).
        _step = null;
      } else if (next == TutorialStep.outro) {
        _step = TutorialStep.outro;
        _shouldShowOutroModal = true;
      } else {
        _step = next;
      }
    } catch (_) {
      // Leave the current step visible; caller can surface an error toast.
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Clears the pending XP chip after the toast has faded. Called by the
  /// overlay widget after ~1200ms so the same chip doesn't re-show on rebuild.
  void clearPendingReward() {
    if (_pendingXpReward == null) return;
    _pendingXpReward = null;
    notifyListeners();
  }

  /// Marks the intro modal as consumed (caller pushed the bubble flow).
  void dismissIntroModal() {
    if (!_shouldShowIntroModal) return;
    _shouldShowIntroModal = false;
    notifyListeners();
  }

  /// Marks the outro modal as consumed.
  void dismissOutroModal() {
    if (!_shouldShowOutroModal) return;
    _shouldShowOutroModal = false;
    notifyListeners();
  }

  /// Confirms skip (caller already showed the confirmation sheet). Writes
  /// `tutorialStep = -1` on the server and clears local state.
  Future<void> skip() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      final result = await _api.skip();
      _topicsSeen = result.tutorialTopicsSeen;
    } catch (_) {
      // Best-effort: still dismiss locally so the user isn't stuck.
    } finally {
      _busy = false;
    }
    await stop();
  }

  /// Clears the overlay without hitting the backend.
  Future<void> stop() async {
    _step = null;
    _topic = null;
    _topicQueue.clear();
    _pendingXpReward = null;
    _shouldShowIntroModal = false;
    _shouldShowOutroModal = false;
    notifyListeners();
  }
}
