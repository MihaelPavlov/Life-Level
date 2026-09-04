import 'dart:async';
import '../../features/activity/models/activity_models.dart';

class GuildRaidVictoryNotifier {
  GuildRaidVictoryNotifier._();

  static final StreamController<GuildRaidVictoryInfo> _controller =
      StreamController<GuildRaidVictoryInfo>.broadcast();

  static Stream<GuildRaidVictoryInfo> get stream => _controller.stream;
  static void notify(GuildRaidVictoryInfo info) => _controller.add(info);
}
