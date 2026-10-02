import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_level/features/unlocks/models/unlock_models.dart';
import 'package:life_level/features/unlocks/providers/unlocks_provider.dart';

/// Everything unlocked and nothing fresh, without calling the API.
Override get allUnlockedOverride =>
    unlocksSnapshotProvider.overrideWithValue(UnlocksSnapshot.open);
