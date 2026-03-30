import 'package:flutter/material.dart';
import 'world_map_data.dart';
import 'world_map_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorldMapLayout
// ─────────────────────────────────────────────────────────────────────────────
// Pure layout calculations for tier-based zone positioning.
// Extracted from WorldMapScreen to keep screen state focused on loading/interaction.
// ─────────────────────────────────────────────────────────────────────────────

class WorldMapLayout {
  WorldMapLayout._();

  /// Repositions each zone's [relativeX] so that zones within the same tier
  /// are evenly distributed across the canvas width.
  /// Preserves left/right ordering from the original [relativeX].
  static List<ZoneData> applyTierLayout(List<ZoneData> zones) {
    final tierIndices = <int, List<int>>{};
    for (int i = 0; i < zones.length; i++) {
      tierIndices.putIfAbsent(zones[i].tier, () => []).add(i);
    }
    for (final ids in tierIndices.values) {
      ids.sort((a, b) => zones[a].relativeX.compareTo(zones[b].relativeX));
    }

    final result = List<ZoneData?>.filled(zones.length, null);
    for (final ids in tierIndices.values) {
      final xs = _tierXPositions(ids.length);
      for (int j = 0; j < ids.length; j++) {
        final z = zones[ids[j]];
        result[ids[j]] = ZoneData(
          id: z.id,
          name: z.name,
          icon: z.icon,
          status: z.status,
          tier: z.tier,
          relativeX: xs[j],
          region: z.region,
          nodeCount: z.nodeCount,
          completedNodeCount: z.completedNodeCount,
          totalXp: z.totalXp,
          distanceKm: z.distanceKm,
          levelRequirement: z.levelRequirement,
          isCrossroads: z.isCrossroads,
          description: z.description,
          isDestination: z.isDestination,
        );
      }
    }
    return result.cast<ZoneData>();
  }

  /// Returns evenly-spaced X positions (as fractions of canvas width) for
  /// [count] zones within a single tier.
  static List<double> _tierXPositions(int count) {
    switch (count) {
      case 1:
        return [0.5];
      case 2:
        return [0.30, 0.70];
      case 3:
        return [0.20, 0.50, 0.80];
      default:
        return [
          for (int i = 0; i < count; i++) 0.15 + 0.70 / (count - 1) * i,
        ];
    }
  }

  /// Canvas Y centre for a zone, derived from its tier.
  static Offset centreFor(ZoneData z) {
    final y = kTopPadding + z.tier * kTierHeight;
    final x = z.relativeX * kCanvasWidth;
    return Offset(x, y);
  }
}
