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
    this.totalXp,
    this.distanceKm,
    required this.levelRequirement,
    required this.isCrossroads,
    this.description,
    this.absoluteX,
    this.absoluteY,
  });

  final String id;
  final String name;
  final String icon;
  final ZoneStatus status;
  final int tier;
  final double relativeX;
  final String region;
  final int? nodeCount;
  final int? totalXp;
  final int? distanceKm;
  final int levelRequirement;
  final bool isCrossroads;
  final String? description;
  // Absolute canvas positions from API — used by the screen instead of
  // the tier/relativeX fallback layout when both are present.
  final double? absoluteX;
  final double? absoluteY;

  // ── Factory from API model ─────────────────────────────────────────────────

  static ZoneData fromApiModel(WorldZoneModel m) {
    final ZoneStatus status;
    final state = m.userState;
    if (state == null) {
      status = ZoneStatus.locked;
    } else if (state.isCurrentZone) {
      status = ZoneStatus.active;
    } else if (state.isUnlocked) {
      status = ZoneStatus.completed;
    } else if (state.isLevelMet) {
      status = ZoneStatus.available;
    } else {
      status = ZoneStatus.locked;
    }

    return ZoneData(
      id: m.id,
      name: m.name,
      icon: m.icon,
      status: status,
      tier: m.tier,
      relativeX: 0.5, // fallback; absoluteX/Y take priority in _centreFor
      region: m.region,
      nodeCount: m.nodeCount,
      totalXp: m.totalXp,
      distanceKm: m.totalDistanceKm.round(),
      levelRequirement: m.levelRequirement,
      isCrossroads: m.isCrossroads,
      description: m.description,
      absoluteX: m.positionX,
      absoluteY: m.positionY,
    );
  }
}
