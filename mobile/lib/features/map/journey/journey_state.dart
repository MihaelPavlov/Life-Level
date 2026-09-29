import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../boss/models/boss_list_item.dart';
import '../../boss/providers/boss_provider.dart';
import '../../character/providers/character_provider.dart';
import '../../home/providers/world_progress_provider.dart';
import '../models/encounter_models.dart';
import '../models/world_map_models.dart';
import '../models/world_zone_models.dart';

// ── Shared journey helpers ────────────────────────────────────────────────────
// Used by both the journey card (HomePortalCard) and the Map button, so the
// two always describe the same situation.

/// The zone the journey is about: the destination when one is set, else the
/// zone the player stands on.
WorldZoneModel? pickPortalZone(WorldFullData world) {
  final destId = world.userProgress.destinationZoneId;
  if (destId != null && destId.isNotEmpty) {
    final d = world.zones.cast<WorldZoneModel?>().firstWhere(
          (z) => z!.id == destId,
          orElse: () => null,
        );
    if (d != null) return d;
  }
  final curId = world.userProgress.currentZoneId;
  if (curId.isNotEmpty) {
    final c = world.zones.cast<WorldZoneModel?>().firstWhere(
          (z) => z!.id == curId,
          orElse: () => null,
        );
    if (c != null) return c;
  }
  return null;
}

/// Pick a reasonable "next" zone reachable from `from` — used when the
/// current zone is consumed (e.g. opened chest) and the journey should nudge
/// forward instead of showing a spent CTA.
///
/// Adjacency is symmetric (bidirectional edges include both directions),
/// so we have to disambiguate "forward" vs "backward" ourselves. Priority:
///   1. Adjacent zones with `tier > from.tier` and unlocked + level-met
///      (forward and ready-to-travel — the canonical "next").
///   2. Adjacent zones with `tier > from.tier`, regardless of unlock state
///      (forward but locked — still the right hint).
///   3. Adjacent zones with `tier == from.tier`, unlocked + level-met
///      (sideways at same difficulty).
///   4. Fallback: first adjacent zone.
///
/// Within a priority bucket we sort by tier ascending then name for
/// deterministic output across reloads.
WorldZoneModel? pickNextZoneAfter(WorldFullData world, WorldZoneModel from) {
  final adjacentIds = <String>{
    for (final e in world.edges)
      if (e.fromZoneId == from.id)
        e.toZoneId
      else if (e.isBidirectional && e.toZoneId == from.id)
        e.fromZoneId,
  };
  if (adjacentIds.isEmpty) return null;

  final neighbors = <WorldZoneModel>[
    for (final id in adjacentIds) ...world.zones.where((z) => z.id == id),
  ]..sort((a, b) {
      final t = a.tier.compareTo(b.tier);
      return t != 0 ? t : a.name.compareTo(b.name);
    });
  if (neighbors.isEmpty) return null;

  bool isReady(WorldZoneModel z) {
    final state = z.userState;
    return state != null && state.isUnlocked && state.isLevelMet;
  }

  for (final z in neighbors) {
    if (z.tier > from.tier && isReady(z)) return z;
  }
  for (final z in neighbors) {
    if (z.tier > from.tier) return z;
  }
  for (final z in neighbors) {
    if (z.tier == from.tier && isReady(z)) return z;
  }
  return neighbors.first;
}

/// The trail encounter on the edge the player is walking, if any.
/// Blockers win over merchants, merchants over story beats.
TrailEncounterNode? currentEdgeEncounter(
  WorldFullData world,
  RegionDetail? region,
) {
  final edgeId = world.userProgress.currentEdgeId;
  if (edgeId == null || edgeId.isEmpty || region == null) return null;

  final edge = world.edges.cast<WorldZoneEdgeModel?>().firstWhere(
        (e) => e?.id == edgeId,
        orElse: () => null,
      );
  if (edge == null) return null;

  final matches = region.encounters
      .where((enc) =>
          (enc.fromZoneId == edge.fromZoneId &&
              enc.toZoneId == edge.toZoneId) ||
          (edge.isBidirectional &&
              enc.fromZoneId == edge.toZoneId &&
              enc.toZoneId == edge.fromZoneId))
      .toList()
    ..sort((a, b) {
      final typePriority =
          encounterPriority(a.type).compareTo(encounterPriority(b.type));
      return typePriority != 0 ? typePriority : b.t.compareTo(a.t);
    });

  return matches.firstOrNull;
}

int encounterPriority(TrailEncounterType type) {
  switch (type) {
    case TrailEncounterType.blocker:
      return 0;
    case TrailEncounterType.merchant:
      return 1;
    case TrailEncounterType.story:
      return 2;
  }
}

/// True when the player stands on a zone with no destination and nothing to
/// do there, so the journey should suggest the next zone instead.
bool isNonActionableHere({
  required WorldFullData world,
  required WorldZoneModel zone,
  required RegionDetail? region,
  required DungeonState? dungeonState,
}) {
  final standingNode = region?.nodes.where((n) => n.id == zone.id).firstOrNull;
  final hasNoDestination = world.userProgress.destinationZoneId == null ||
      world.userProgress.destinationZoneId!.isEmpty;
  final chestExplicitlyUnopened = standingNode?.chestIsOpened == false;
  final dungeonCompleted =
      (dungeonState?.status == DungeonRunStatus.completed) ||
          (dungeonState != null &&
              dungeonState.floors.isNotEmpty &&
              dungeonState.floors
                  .every((f) => f.status == DungeonFloorStatus.completed)) ||
          (standingNode?.dungeonStatus == DungeonRunStatus.completed);
  return hasNoDestination &&
      switch (zone.type) {
        // Backend emits WorldZoneType.ToString().ToLowerInvariant() — values
        // are: entry / standard / crossroads / boss / chest / dungeon. The
        // literal 'zone' is a legacy default we still accept for safety.
        'standard' || 'zone' || 'entry' => true,
        'chest' => !chestExplicitlyUnopened,
        'dungeon' => dungeonCompleted,
        _ => false,
      };
}

String formatJourneyDuration(Duration d) {
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes}m';
}

// ── Map button state ──────────────────────────────────────────────────────────

/// Every situation the journey card can show, mirrored on the Map button.
enum JourneyKind {
  loading,
  error,
  firstStep,
  pickNext,
  levelLocked,
  traveling,
  blocker,
  merchant,
  story,
  bossRaid,
  bossZone,
  chest,
  chestOpened,
  dungeon,
  crossroads,
  explore,
}

/// How the ring around the Map button is drawn.
enum JourneyRing { progress, dashed, split, segments }

/// What the Map button shows: colour, ring, icon, the short label under the
/// icon and whether it pulses with a dot ("act now").
@immutable
class JourneyOrbState {
  final JourneyKind kind;
  final Color color;
  final JourneyRing ring;

  /// 0..1 for [JourneyRing.progress]; ignored otherwise.
  final double progress;

  /// For [JourneyRing.segments]: total segments and how many are filled.
  final int segments;
  final int segmentsDone;
  final String? iconAsset;
  final IconData? icon;
  final String label;
  final bool alert;

  /// Screen-reader description, e.g. "Traveling, 1.4 km to Whispering Fork".
  final String semantics;

  const JourneyOrbState({
    required this.kind,
    required this.color,
    required this.ring,
    this.progress = 0,
    this.segments = 0,
    this.segmentsDone = 0,
    this.iconAsset,
    this.icon,
    required this.label,
    this.alert = false,
    required this.semantics,
  });

  static const loading = JourneyOrbState(
    kind: JourneyKind.loading,
    color: AppColors.blue,
    ring: JourneyRing.dashed,
    iconAsset: AppIcons.mapDestination,
    label: 'Map',
    semantics: 'Map',
  );

  @override
  bool operator ==(Object other) =>
      other is JourneyOrbState &&
      other.kind == kind &&
      other.color == color &&
      other.ring == ring &&
      other.progress == progress &&
      other.segments == segments &&
      other.segmentsDone == segmentsDone &&
      other.iconAsset == iconAsset &&
      other.icon == icon &&
      other.label == label &&
      other.alert == alert;

  @override
  int get hashCode => Object.hash(kind, color, ring, progress, segments,
      segmentsDone, iconAsset, icon, label, alert);
}

const _teal = Color(0xFF38D9C8);
const _grey = Color(0xFF8B949E);
const _ringBattle = 'assets/icons/ring_battle.png';

String _km(double v) => '${v.toStringAsFixed(1)} km';

/// Maps the same inputs the journey card uses onto the Map button's look.
/// Follows the card's order exactly: active boss raid first, then the world
/// state (first step → next-zone hint → traveling/encounter → zone type).
JourneyOrbState resolveJourneyOrb({
  required BossListItem? activeBoss,
  required AsyncValue<WorldFullData> worldAsync,
  required RegionDetail? region,
  required DungeonState? dungeonState,
  required double xpProgress,
}) {
  final boss = activeBoss;
  if (boss != null) {
    final frac = boss.maxHp > 0 ? boss.hpRemaining / boss.maxHp : 0.0;
    final left = boss.timeRemaining;
    final timer = left != null
        ? formatJourneyDuration(left).split(' ').first
        : '${boss.timerDays}d';
    final pct = (frac * 100).round();
    return JourneyOrbState(
      kind: JourneyKind.bossRaid,
      color: AppColors.red,
      ring: JourneyRing.progress,
      progress: frac.clamp(0.0, 1.0),
      iconAsset: AppIcons.ringBoss,
      label: '$pct% · $timer',
      semantics: 'Boss fight, ${boss.name} at $pct% health',
    );
  }

  if (worldAsync.hasError) {
    return const JourneyOrbState(
      kind: JourneyKind.error,
      color: _grey,
      ring: JourneyRing.dashed,
      icon: Icons.refresh_rounded,
      label: 'Retry',
      semantics: 'Map could not load, tap to retry',
    );
  }
  final world = worldAsync.valueOrNull;
  if (world == null) return JourneyOrbState.loading;

  final picked = pickPortalZone(world);
  if (picked == null) {
    return const JourneyOrbState(
      kind: JourneyKind.firstStep,
      color: AppColors.blue,
      ring: JourneyRing.dashed,
      iconAsset: AppIcons.mapCurrentLocation,
      label: 'Start',
      alert: true,
      semantics: 'Pick your first step on the map',
    );
  }

  if (isNonActionableHere(
      world: world, zone: picked, region: region, dungeonState: dungeonState)) {
    final next = pickNextZoneAfter(world, picked);
    if (next != null) {
      if (next.userState?.isLevelMet == false) {
        return JourneyOrbState(
          kind: JourneyKind.levelLocked,
          color: _grey,
          ring: JourneyRing.progress,
          progress: xpProgress.clamp(0.0, 1.0),
          icon: Icons.lock_rounded,
          label: 'Lv ${next.levelRequirement}',
          semantics: '${next.name} opens at level ${next.levelRequirement}',
        );
      }
      return JourneyOrbState(
        kind: JourneyKind.pickNext,
        color: AppColors.blue,
        ring: JourneyRing.dashed,
        iconAsset: AppIcons.mapDestination,
        label: 'Pick',
        alert: true,
        semantics: 'Choose where to go next: ${next.name}',
      );
    }
  }

  final traveling = (world.userProgress.currentEdgeId ?? '').isNotEmpty;
  if (traveling) {
    final edgeId = world.userProgress.currentEdgeId;
    final edge = world.edges
        .cast<WorldZoneEdgeModel?>()
        .firstWhere((e) => e?.id == edgeId, orElse: () => null);
    final travelled = world.userProgress.distanceTraveledOnEdge;
    final total = edge?.distanceKm ?? 0;
    final frac = total > 0 ? (travelled / total).clamp(0.0, 1.0) : 0.0;
    final remaining = (total - travelled).clamp(0.0, double.infinity);

    final enc = currentEdgeEncounter(world, region);
    if (enc != null) {
      switch (enc.type) {
        case TrailEncounterType.blocker:
          final b = enc.blocker;
          final hp = b == null || b.maxHp <= 0 ? 1.0 : b.currentHp / b.maxHp;
          return JourneyOrbState(
            kind: JourneyKind.blocker,
            color: AppColors.red,
            ring: JourneyRing.progress,
            progress: hp.clamp(0.0, 1.0),
            iconAsset: _ringBattle,
            label: 'Blocked',
            alert: true,
            semantics: 'Path blocked on the way to ${picked.name}',
          );
        case TrailEncounterType.merchant:
          return JourneyOrbState(
            kind: JourneyKind.merchant,
            color: AppColors.orange,
            ring: JourneyRing.progress,
            progress: frac,
            iconAsset: AppIcons.rewardGrantItem,
            label: 'Merchant',
            alert: true,
            semantics: 'A merchant waits on your route',
          );
        case TrailEncounterType.story:
          return JourneyOrbState(
            kind: JourneyKind.story,
            color: _teal,
            ring: JourneyRing.progress,
            progress: frac,
            icon: Icons.chat_bubble_rounded,
            label: 'Story',
            alert: true,
            semantics: 'Someone on the trail has a story for you',
          );
      }
    }
    return JourneyOrbState(
      kind: JourneyKind.traveling,
      color: AppColors.blue,
      ring: JourneyRing.progress,
      progress: frac,
      iconAsset: AppIcons.mapDestination,
      label: total > 0 ? _km(remaining) : 'Travel',
      semantics: total > 0
          ? 'Traveling, ${_km(remaining)} to ${picked.name}'
          : 'Traveling to ${picked.name}',
    );
  }

  final node = region?.nodes.where((n) => n.id == picked.id).firstOrNull;
  switch (picked.type) {
    case 'boss':
      return JourneyOrbState(
        kind: JourneyKind.bossZone,
        color: AppColors.red,
        ring: JourneyRing.progress,
        progress: 1,
        iconAsset: AppIcons.ringBoss,
        label: 'Boss',
        alert: true,
        semantics: 'Boss zone ${picked.name}, ready for the raid',
      );
    case 'chest':
      final opened = node?.chestIsOpened == true;
      return JourneyOrbState(
        kind: opened ? JourneyKind.chestOpened : JourneyKind.chest,
        color: AppColors.orange,
        ring: JourneyRing.progress,
        progress: 1,
        iconAsset: AppIcons.rewardTreasureChest,
        label: opened ? 'Opened' : 'Open',
        alert: !opened,
        semantics: opened
            ? 'Chest at ${picked.name} already opened'
            : 'Treasure chest at ${picked.name}, ready to open',
      );
    case 'dungeon':
      final floors = dungeonState?.floors ?? const [];
      final total = floors.length;
      final done =
          floors.where((f) => f.status == DungeonFloorStatus.completed).length;
      final cleared = node?.dungeonStatus == DungeonRunStatus.completed ||
          (total > 0 && done >= total);
      return JourneyOrbState(
        kind: JourneyKind.dungeon,
        color: AppColors.purple,
        ring: total > 0 ? JourneyRing.segments : JourneyRing.dashed,
        segments: total,
        segmentsDone: done,
        iconAsset: AppIcons.zoneTheConvergence,
        label: total > 0 ? '$done / $total' : 'Dungeon',
        alert: !cleared,
        semantics: total > 0
            ? 'Dungeon ${picked.name}, $done of $total floors cleared'
            : 'Dungeon ${picked.name}',
      );
    case 'crossroads':
      return JourneyOrbState(
        kind: JourneyKind.crossroads,
        color: AppColors.purple,
        ring: JourneyRing.split,
        iconAsset: AppIcons.zoneFirstFork,
        label: 'Choose',
        alert: true,
        semantics: 'Crossroads at ${picked.name}, choose your path',
      );
    default:
      return JourneyOrbState(
        kind: JourneyKind.explore,
        color: AppColors.blue,
        ring: JourneyRing.dashed,
        iconAsset: AppIcons.mapDestination,
        label: 'Explore',
        semantics: 'At ${picked.name}, pick a destination on the map',
      );
  }
}

/// The Map button's look, live from the same providers the journey card uses.
final journeyOrbStateProvider = Provider.autoDispose<JourneyOrbState>((ref) {
  final activeBoss = ref
      .watch(bossListProvider)
      .valueOrNull
      ?.where((b) => b.isActive)
      .firstOrNull;
  final worldAsync = ref.watch(worldProgressProvider);
  final region = ref.watch(currentRegionDetailProvider).valueOrNull;
  final world = worldAsync.valueOrNull;
  final zone = world == null ? null : pickPortalZone(world);
  final dungeonState = zone != null && zone.type == 'dungeon'
      ? ref.watch(dungeonStateProvider(zone.id)).valueOrNull
      : null;
  final xpProgress =
      ref.watch(characterProfileProvider).valueOrNull?.xpProgress ?? 0.0;
  return resolveJourneyOrb(
    activeBoss: activeBoss,
    worldAsync: worldAsync,
    region: region,
    dungeonState: dungeonState,
    xpProgress: xpProgress,
  );
});
