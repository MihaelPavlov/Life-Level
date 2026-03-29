// ─────────────────────────────────────────────────────────────────────────────
// Domain models for the world map feature
// ─────────────────────────────────────────────────────────────────────────────

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
}
