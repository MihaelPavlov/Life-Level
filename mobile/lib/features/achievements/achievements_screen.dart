import 'package:flutter/material.dart';

import 'roads/reward_roads_hub.dart';

/// Achievements = Reward Roads: one road per category, stage chests, and
/// rewards claimed with coins and gems.
class AchievementsScreen extends StatelessWidget {
  final VoidCallback? onClose;
  const AchievementsScreen({super.key, this.onClose});

  @override
  Widget build(BuildContext context) => RewardRoadsHub(onClose: onClose);
}
