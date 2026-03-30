// ─────────────────────────────────────────────────────────────────────────────
// Domain models for the world map feature
// ─────────────────────────────────────────────────────────────────────────────

import 'models/world_zone_models.dart';

enum ZoneStatus { completed, active, available, locked }

class ZoneData {
  const ZoneData({
    required this.id,
    required this.name,
    required this.icon,
    required this.status,
    required this.tier,
    required this.relativeX,
    required this.region,
    this.nodeCount,
    this.completedNodeCount,
    this.totalXp,
    this.distanceKm,
    required this.levelRequirement,
    required this.isCrossroads,
    this.description,
    this.absoluteX,
    this.absoluteY,
    this.isDestination = false,
  });

  final String id;
  final String name;
  final String icon;
  final ZoneStatus status;
  final int tier;
  final double relativeX;
  final String region;
  final int? nodeCount;
  final int? completedNodeCount;
  final int? totalXp;
  final int? distanceKm;
  final int levelRequirement;
  final bool isCrossroads;
  final String? description;
  // Absolute canvas positions from API — used by the screen instead of
  // the tier/relativeX fallback layout when both are present.
  final double? absoluteX;
  final double? absoluteY;
  final bool isDestination;

  // ── Factory from API model ─────────────────────────────────────────────────

  static ZoneData fromApiModel(WorldZoneModel m, {bool isTraveling = false}) {
    final ZoneStatus status;
    final state = m.userState;
    if (state == null) {
      status = ZoneStatus.locked;
    } else if (state.isDestination) {
      status = ZoneStatus.active;
    } else if (state.isCurrentZone && isTraveling) {
      status = ZoneStatus.completed;
    } else if (state.isCurrentZone) {
      status = ZoneStatus.active;
    } else if (state.isUnlocked) {
      status = ZoneStatus.completed;
    } else if (state.isLevelMet) {
      status = ZoneStatus.available;
    } else {
      status = ZoneStatus.locked;
    }

    // Normalise admin-panel X (0–390 canvas) to a 0..1 relative fraction.
    // Y is always derived from tier in the painter — the admin-panel pixel Y
    // is in a different coordinate space and must not be used directly.
    const double adminCanvasWidth = 390.0;
    final relX = (m.positionX / adminCanvasWidth).clamp(0.05, 0.95);

    return ZoneData(
      id: m.id,
      name: m.name,
      icon: m.icon,
      status: status,
      tier: m.tier,
      relativeX: relX,
      region: m.region,
      nodeCount: m.nodeCount,
      completedNodeCount: m.completedNodeCount,
      totalXp: m.totalXp,
      distanceKm: m.totalDistanceKm.round(),
      levelRequirement: m.levelRequirement,
      isCrossroads: m.isCrossroads,
      description: m.description,
      absoluteX: null,  // do not use admin pixel coords directly
      absoluteY: null,
      isDestination: state?.isDestination ?? false,
    );
  }
}
