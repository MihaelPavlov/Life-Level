import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_models.dart';
import '../services/leaderboard_service.dart';

final leaderboardServiceProvider =
    Provider<LeaderboardService>((_) => LeaderboardService());

/// The board for one scope and metric.
final leaderboardProvider = FutureProvider.autoDispose
    .family<LeaderboardBoard, (LeaderboardScope, LeaderboardMetric)>(
        (ref, key) =>
            ref.watch(leaderboardServiceProvider).getBoard(key.$1, key.$2));

/// The rank-up chest; drives the Adventure Hub dot.
final leaderboardChestProvider = FutureProvider<LeaderboardChest>(
    (ref) => ref.watch(leaderboardServiceProvider).getChest());
