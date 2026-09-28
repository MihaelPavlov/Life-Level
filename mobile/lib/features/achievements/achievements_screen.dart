import 'package:flutter/material.dart';

import 'roads/reward_roads_hub.dart';

/// Achievements = Reward Roads: one road per category, stage chests, and
/// rewards claimed with coins and gems.
class AchievementsScreen extends StatelessWidget {
  final VoidCallback? onClose;
  const AchievementsScreen({super.key, this.onClose});

  @override
  Widget build(BuildContext context) => Navigator(
        // Keep road-detail routes inside the Achievements shell overlay. Using
        // the app's root navigator here would cover MainShell's bottom bar.
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => RewardRoadsHub(onClose: onClose),
        ),
      );
}
