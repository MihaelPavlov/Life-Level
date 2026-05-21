import 'dart:async';
import '../../features/activity/models/activity_models.dart';

/// Fired by `log_activity_screen` for each boss whose HP hit 0 from the just-
/// logged activity. Consumed by `main_shell.dart` which shows a celebration
/// overlay (`showBossDefeatedOverlay`).
class BossDefeatedNotifier {
  BossDefeatedNotifier._();
  static final StreamController<BossDefeatedInfo> _controller =
      StreamController<BossDefeatedInfo>.broadcast();
  static Stream<BossDefeatedInfo> get stream => _controller.stream;
  static void notify(BossDefeatedInfo info) => _controller.add(info);
}
