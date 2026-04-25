import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/dungeon_floor_cleared_notifier.dart';
import '../../../core/services/nav_tab_notifier.dart';
import '../../../core/services/world_zone_refresh_notifier.dart';
import '../../boss/models/boss_list_item.dart';
import '../../boss/providers/boss_provider.dart';
import '../../map/models/world_map_models.dart';
import '../../map/models/world_zone_models.dart';
import '../../map/services/world_zone_service.dart';
import '../providers/world_progress_provider.dart';
import '../widgets/home_card.dart';
import '../widgets/home_hero_button.dart';
import '../widgets/home_progress_bar.dart';

/// The home screen's portal into the world map. Single morphing card at the
/// top of home — always shows the player's current (or destination) world
/// zone with a type-aware body:
///
///  * Boss raid active  → red glow, HP bar, "Fight →"  (priority)
///  * Traveling         → blue glow, distance-to-go, "View on map →"
///  * Boss zone         → red glow, "Ready for the raid", "View on map →"
///  * Chest zone        → orange glow, reward XP, "Open chest →"
///  * Dungeon zone      → purple glow, floor progress, "Enter dungeon →"
///  * Crossroads zone   → blue glow, branch preview, "Choose path →"
///  * Standard / Entry  → blue glow, "Explore from here", "Open map →"
///
/// Every non-boss-raid CTA switches the shell to the world tab so the world
/// hub overlay is visible above the bottom nav.
class HomePortalCard extends ConsumerStatefulWidget {
  final VoidCallback? onSync;
  const HomePortalCard({super.key, this.onSync});

  @override
  ConsumerState<HomePortalCard> createState() => _HomePortalCardState();
}

class _HomePortalCardState extends ConsumerState<HomePortalCard> {
  late final StreamSubscription<DungeonFloorClearedEvent> _floorClearedSub;
  late final StreamSubscription<void> _worldRefreshSub;
  // Branch zone id currently being committed via a SetDestination call —
  // surfaced to the crossroads variant so the row dims while in flight.
  String? _pickingBranchId;

  Future<void> _pickCrossroadsBranch(WorldZoneModel branch) async {
    if (_pickingBranchId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Choose ${branch.name}?',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Once you commit to this path, the sibling branches lock '
          'permanently for this character.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Choose path'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _pickingBranchId = branch.id);
    try {
      await WorldZoneService().setDestination(branch.id);
      WorldZoneRefreshNotifier.notify();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Heading to ${branch.name}')),
      );
    } on PathAlreadyChosenException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already chose a different path here.'),
        ),
      );
    } on BranchRequiresCrossroadsArrivalException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Travel to the crossroads first, then pick a branch.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not choose path: $e')),
      );
    } finally {
      if (mounted) setState(() => _pickingBranchId = null);
    }
  }

  @override
  void initState() {
    super.initState();
    // After a workout clears a dungeon floor, the active floor advances —
    // invalidate the dungeon state cache so the home portal swaps in the
    // next floor's name + target. We also refresh world progress in case
    // the floor completion triggers a region/zone advance.
    _floorClearedSub = DungeonFloorClearedNotifier.stream.listen((_) {
      if (!mounted) return;
      ref.invalidate(dungeonStateProvider);
      ref.invalidate(worldProgressProvider);
      ref.invalidate(currentRegionDetailProvider);
    });
    // Generic world-refresh signal (logged workouts, set-destination, etc.).
    _worldRefreshSub = WorldZoneRefreshNotifier.stream.listen((_) {
      if (!mounted) return;
      ref.invalidate(dungeonStateProvider);
      ref.invalidate(worldProgressProvider);
      ref.invalidate(currentRegionDetailProvider);
    });
  }

  @override
  void dispose() {
    _floorClearedSub.cancel();
    _worldRefreshSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final onSync = widget.onSync;
    // Active boss raid from bossListProvider still wins over anything else.
    final activeBoss = ref
        .watch(bossListProvider)
        .valueOrNull
        ?.where((b) => b.isActive)
        .toList()
        .firstOrNull;
    if (activeBoss != null) {
      return _BossRaidPortal(boss: activeBoss, onSync: onSync);
    }

    final worldAsync = ref.watch(worldProgressProvider);
    if (worldAsync.hasError) {
      return _PortalErrorCard(
        message: worldAsync.error.toString(),
        onRetry: () => ref.invalidate(worldProgressProvider),
      );
    }
    final world = worldAsync.valueOrNull;
    if (world == null) return const _PortalPlaceholder();

    final region = ref.watch(currentRegionDetailProvider).valueOrNull;

    final pickedZone = _pickPortalZone(world);
    if (pickedZone == null) return const _NoZonePortal();
    WorldZoneModel zone = pickedZone;

    // When the player is parked on a zone with no destination AND nothing
    // actionable to do here (Standard/Entry/spent-Chest), slide the portal
    // forward to suggest the next zone instead of showing a useless
    // "explore from here" or stale "Open chest" CTA.
    //
    // Boss / Dungeon / Crossroads / unopened-Chest zones keep their
    // type-specific portal — those have a meaningful CTA on the current zone.
    final standingNode =
        region?.nodes.where((n) => n.id == zone.id).firstOrNull;
    final hasNoDestination =
        world.userProgress.destinationZoneId == null ||
            world.userProgress.destinationZoneId!.isEmpty;
    final chestExplicitlyUnopened = standingNode?.chestIsOpened == false;

    // Pre-load dungeon state so both the slide-forward check and the
    // dungeon variant can use it without watching twice.
    final dungeonState = (zone.type == 'dungeon')
        ? ref.watch(dungeonStateProvider(zone.id)).valueOrNull
        : null;
    final dungeonCompleted = (dungeonState?.status ==
            DungeonRunStatus.completed) ||
        (dungeonState != null &&
            dungeonState.floors.isNotEmpty &&
            dungeonState.floors
                .every((f) => f.status == DungeonFloorStatus.completed)) ||
        // Fallback when the dungeon state hasn't loaded yet — region detail
        // already reports the run status per zone.
        (standingNode?.dungeonStatus == DungeonRunStatus.completed);

    final isNonActionableHere = hasNoDestination &&
        switch (zone.type) {
          // Backend emits WorldZoneType.ToString().ToLowerInvariant() — values
          // are: entry / standard / crossroads / boss / chest / dungeon. The
          // literal 'zone' is a legacy default we still accept for safety.
          'standard' || 'zone' || 'entry' => true,
          'chest' => !chestExplicitlyUnopened,
          'dungeon' => dungeonCompleted,
          _ => false, // boss / crossroads keep their own portal
        };
    final regionChip = _buildRegionChip(region);
    final regionId =
        world.userProgress.currentRegionId ?? region?.id;
    if (isNonActionableHere) {
      final next = _pickNextZoneAfter(world, zone);
      if (next != null) {
        return _NextZoneHintPortal(
          zone: next,
          world: world,
          regionChip: regionChip,
          regionId: regionId,
          onSync: onSync,
        );
      }
    }

    final isTraveling = (world.userProgress.currentEdgeId ?? '').isNotEmpty;
    if (isTraveling) {
      return _TravelingPortal(
        world: world,
        destination: zone,
        regionChip: regionChip,
        regionId: regionId,
        onSync: onSync,
      );
    }

    final node = region?.nodes.where((n) => n.id == zone.id).firstOrNull;

    switch (zone.type) {
      case 'boss':
        return _BossZonePortal(
          zone: zone,
          regionChip: regionChip,
          regionId: regionId,
          onSync: onSync,
        );
      case 'chest':
        return _ChestPortal(
          zone: zone,
          node: node,
          regionChip: regionChip,
          regionId: regionId,
          onSync: onSync,
        );
      case 'dungeon':
        return _DungeonPortal(
          zone: zone,
          node: node,
          dungeonState: dungeonState,
          regionChip: regionChip,
          regionId: regionId,
          onSync: onSync,
        );
      case 'crossroads':
        return _CrossroadsPortal(
          zone: zone,
          world: world,
          region: region,
          regionChip: regionChip,
          regionId: regionId,
          onPickBranch: _pickCrossroadsBranch,
          busyBranchId: _pickingBranchId,
          onSync: onSync,
        );
      case 'entry':
      case 'standard':
      case 'zone':
      default:
        return _StandardPortal(
          zone: zone,
          regionChip: regionChip,
          regionId: regionId,
          onSync: onSync,
        );
    }
  }
}

// ── Zone picker ──────────────────────────────────────────────────────────────
WorldZoneModel? _pickPortalZone(WorldFullData world) {
  final destId = world.userProgress.destinationZoneId;
  if (destId != null && destId.isNotEmpty) {
    final d =
        world.zones.cast<WorldZoneModel?>().firstWhere(
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
/// current zone is consumed (e.g. opened chest) and the portal should nudge
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
WorldZoneModel? _pickNextZoneAfter(WorldFullData world, WorldZoneModel from) {
  final adjacentIds = <String>{
    for (final e in world.edges)
      if (e.fromZoneId == from.id) e.toZoneId
      else if (e.isBidirectional && e.toZoneId == from.id) e.fromZoneId,
  };
  if (adjacentIds.isEmpty) return null;

  final neighbors = <WorldZoneModel>[
    for (final id in adjacentIds)
      ...world.zones.where((z) => z.id == id),
  ]..sort((a, b) {
      final t = a.tier.compareTo(b.tier);
      return t != 0 ? t : a.name.compareTo(b.name);
    });
  if (neighbors.isEmpty) return null;

  bool isReady(WorldZoneModel z) {
    final state = z.userState;
    return state != null && state.isUnlocked && state.isLevelMet;
  }

  // 1) forward (higher tier) and ready
  for (final z in neighbors) {
    if (z.tier > from.tier && isReady(z)) return z;
  }
  // 2) forward, even if locked
  for (final z in neighbors) {
    if (z.tier > from.tier) return z;
  }
  // 3) sideways at same tier, ready
  for (final z in neighbors) {
    if (z.tier == from.tier && isReady(z)) return z;
  }
  // 4) anything adjacent
  return neighbors.first;
}

String? _buildRegionChip(RegionCard? region) {
  if (region == null || region.name.isEmpty) return null;
  final emoji = region.emoji.isNotEmpty ? '${region.emoji} ' : '';
  return '$emoji${region.name} · Ch. ${region.chapterIndex}';
}

/// Switch to the shell's 'world' tab so the world hub renders as an overlay
/// above the bottom nav (instead of `Navigator.push`, which would cover the
/// nav). The hub highlights the active region — one tap drills in. Region id
/// is currently informational only; deep-link to RegionDetailScreen via the
/// hub is a follow-up.
void _openWorldDestination(BuildContext context, String? regionId) {
  NavTabNotifier.switchTo('world');
}

// ── Variants ─────────────────────────────────────────────────────────────────

class _BossRaidPortal extends StatelessWidget {
  final BossListItem boss;
  final VoidCallback? onSync;
  const _BossRaidPortal({required this.boss, required this.onSync});

  @override
  Widget build(BuildContext context) {
    final remaining = boss.timeRemaining;
    final timer =
        remaining != null ? _fmtDuration(remaining) : '${boss.timerDays}d';
    final hpRemaining = boss.hpRemaining;
    final hpProgress = boss.maxHp > 0 ? hpRemaining / boss.maxHp : 0.0;
    return _HeroShell(
      accent: AppColors.red,
      label: '⚔️ BOSS RAID · $timer LEFT',
      labelColor: AppColors.red,
      title: boss.name,
      sub: 'Raid active. Every workout you log deals damage to ${boss.name}.',
      barLabel: 'Boss HP',
      barValue:
          '${_fmtNumber(hpRemaining)} / ${_fmtNumber(boss.maxHp)}',
      barValueColor: AppColors.red,
      barProgress: hpProgress,
      barColors: const [AppColors.red, AppColors.redDark],
      primaryLabel: 'Fight →',
      primaryStyle: HomeHeroButtonStyle.solidRed,
      onPrimary: () => NavTabNotifier.switchTo('boss'),
      onSync: onSync,
    );
  }
}

class _TravelingPortal extends StatelessWidget {
  final WorldFullData world;
  final WorldZoneModel destination;
  final String? regionChip;
  final String? regionId;
  final VoidCallback? onSync;
  const _TravelingPortal({
    required this.world,
    required this.destination,
    required this.regionChip,
    required this.regionId,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final edgeId = world.userProgress.currentEdgeId;
    final edge =
        world.edges.cast<WorldZoneEdgeModel?>().firstWhere(
              (e) => e!.id == edgeId,
              orElse: () => null,
            );
    final travelled = world.userProgress.distanceTraveledOnEdge;
    final total = edge?.distanceKm ?? 0;
    final progress = total > 0 ? (travelled / total).clamp(0.0, 1.0) : 0.0;
    final remaining = (total - travelled).clamp(0.0, double.infinity);
    final typeBadge = _typeBadge(destination.type);
    final label = total > 0
        ? 'TRAVELING · ${remaining.toStringAsFixed(1)} KM TO GO'
        : 'TRAVELING';
    return _HeroShell(
      accent: AppColors.blue,
      label: label,
      labelColor: AppColors.blue,
      title: '$typeBadge${destination.name}',
      sub: destination.description ??
          'Keep logging workouts to close the distance.',
      regionChip: regionChip,
      barLabel: 'Distance travelled',
      barValue:
          '${travelled.toStringAsFixed(1)} / ${total.toStringAsFixed(1)} km',
      barValueColor: AppColors.textPrimary,
      barProgress: progress,
      barColors: const [AppColors.blue, AppColors.purple],
      primaryLabel: 'View on map →',
      primaryStyle: HomeHeroButtonStyle.solidBlue,
      onPrimary: () => _openWorldDestination(context, regionId),
      onSync: onSync,
    );
  }
}

class _StandardPortal extends StatelessWidget {
  final WorldZoneModel zone;
  final String? regionChip;
  final String? regionId;
  final VoidCallback? onSync;
  const _StandardPortal({
    required this.zone,
    required this.regionChip,
    required this.regionId,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return _HeroShell(
      accent: AppColors.blue,
      label: 'CURRENT ZONE · EXPLORE FROM HERE',
      labelColor: AppColors.blue,
      title: '${_typeBadge(zone.type)}${zone.name}',
      sub: zone.description ??
          'Pick a destination on the map to start travelling.',
      regionChip: regionChip,
      barLabel: 'Zone progress',
      barValue: zone.nodeCount > 0
          ? '${zone.completedNodeCount ?? 0} / ${zone.nodeCount} nodes'
          : '—',
      barValueColor: AppColors.textPrimary,
      barProgress: zone.nodeCount > 0
          ? ((zone.completedNodeCount ?? 0) / zone.nodeCount).clamp(0.0, 1.0)
          : 0.0,
      barColors: const [AppColors.blue, AppColors.purple],
      primaryLabel: 'Open map →',
      primaryStyle: HomeHeroButtonStyle.solidBlue,
      onPrimary: () => _openWorldDestination(context, regionId),
      onSync: onSync,
    );
  }
}

class _BossZonePortal extends StatelessWidget {
  final WorldZoneModel zone;
  final String? regionChip;
  final String? regionId;
  final VoidCallback? onSync;
  const _BossZonePortal({
    required this.zone,
    required this.regionChip,
    required this.regionId,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return _HeroShell(
      accent: AppColors.red,
      label: '⚔️ BOSS ZONE · READY FOR THE RAID',
      labelColor: AppColors.red,
      title: '👹 ${zone.name}',
      sub: zone.description ??
          'The boss awaits. Enter the map to start the fight.',
      regionChip: regionChip,
      barLabel: 'Defeat reward',
      barValue: '+${zone.totalXp} XP',
      barValueColor: AppColors.red,
      barProgress: 1.0,
      barColors: const [AppColors.red, AppColors.redDark],
      primaryLabel: 'Fight →',
      primaryStyle: HomeHeroButtonStyle.solidRed,
      onPrimary: () => _openWorldDestination(context, regionId),
      onSync: onSync,
    );
  }
}

class _ChestPortal extends StatelessWidget {
  final WorldZoneModel zone;
  final ZoneNode? node;
  final String? regionChip;
  final String? regionId;
  final VoidCallback? onSync;
  const _ChestPortal({
    required this.zone,
    required this.node,
    required this.regionChip,
    required this.regionId,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final reward = node?.chestRewardXp ?? zone.totalXp;
    final opened = node?.chestIsOpened == true;
    final labelSuffix = opened ? ' · OPENED' : '';
    return _HeroShell(
      accent: AppColors.orange,
      label: '🗝 TREASURE CHEST$labelSuffix',
      labelColor: AppColors.orange,
      title: '💎 ${zone.name}',
      sub: opened
          ? 'You already claimed this reward. Move on to the next zone.'
          : (zone.description ??
              'A hidden cache waits for you. Stand on the zone to open it.'),
      regionChip: regionChip,
      barLabel: opened ? 'Reward claimed' : 'Reward on open',
      barValue: '+$reward XP',
      barValueColor: AppColors.orange,
      barProgress: opened ? 1.0 : 0.6,
      barColors: const [AppColors.orange, AppColors.red],
      primaryLabel: opened ? 'View on map →' : 'Open chest →',
      primaryStyle: HomeHeroButtonStyle.solidOrange,
      onPrimary: () => _openWorldDestination(context, regionId),
      onSync: onSync,
    );
  }
}

class _DungeonPortal extends StatelessWidget {
  final WorldZoneModel zone;
  final ZoneNode? node;
  final DungeonState? dungeonState;
  final String? regionChip;
  final String? regionId;
  final VoidCallback? onSync;
  const _DungeonPortal({
    required this.zone,
    required this.node,
    required this.dungeonState,
    required this.regionChip,
    required this.regionId,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    // Floor counts. Prefer the dungeon-state response (it covers in-progress
    // and per-floor data); fall back to ZoneNode counts (cached on
    // RegionDetail) when the state hasn't loaded yet.
    final stateFloors = dungeonState?.floors ?? const [];
    final total = stateFloors.isNotEmpty
        ? stateFloors.length
        : (node?.dungeonFloorsTotal ?? 0);
    final done = stateFloors.isNotEmpty
        ? stateFloors
            .where((f) => f.status == DungeonFloorStatus.completed)
            .length
        : (node?.dungeonFloorsCompleted ?? 0);
    final current = (done + 1).clamp(1, total == 0 ? 1 : total);

    // Find the floor the player is currently on (or the first locked one,
    // which is what they need to clear next).
    DungeonFloor? activeFloor;
    for (final f in stateFloors) {
      if (f.status == DungeonFloorStatus.active) {
        activeFloor = f;
        break;
      }
    }
    activeFloor ??= stateFloors.cast<DungeonFloor?>().firstWhere(
          (f) => f!.status == DungeonFloorStatus.locked,
          orElse: () => null,
        );
    final isActiveRun = stateFloors.any(
      (f) => f.status == DungeonFloorStatus.active,
    );

    // Bar shows the active floor's workout progress when the run is live
    // (e.g. 1.4 / 3.0 km running), otherwise overall floor completion count.
    final String barLabel;
    final String barValue;
    final double barProgress;
    if (isActiveRun && activeFloor != null) {
      barLabel = 'Floor ${activeFloor.ordinal}: ${activeFloor.activityType}';
      barValue =
          '${_fmtNum(activeFloor.progressValue)} / ${activeFloor.targetLabel}';
      barProgress = activeFloor.progressFraction;
    } else {
      barLabel = total > 0 ? 'Floor progress' : 'Dungeon';
      barValue = total > 0 ? '$done / $total cleared' : '—';
      barProgress = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    }

    // Inline next-floor preview (chip row) — populated when we have state.
    final nextFloorPreview = activeFloor != null
        ? '${activeFloor.emoji.isNotEmpty ? '${activeFloor.emoji} ' : ''}'
            'Floor ${activeFloor.ordinal} · '
            '${activeFloor.name.isNotEmpty ? activeFloor.name : activeFloor.activityType} '
            '· ${activeFloor.targetLabel}'
        : null;

    final statusText = _dungeonStatusLabel(node?.dungeonStatus);
    final floorLabel = total > 0
        ? 'FLOOR $current / $total'
        : 'DUNGEON';
    return _HeroShell(
      accent: AppColors.purple,
      label: '🏰 DUNGEON · $floorLabel',
      labelColor: AppColors.purple,
      title: '🗿 ${zone.name}',
      sub: statusText ??
          (zone.description ??
              'Clear every floor to claim the bonus XP. Each floor is one workout.'),
      regionChip: regionChip,
      branchPreview: nextFloorPreview,
      barLabel: barLabel,
      barValue: barValue,
      barValueColor: AppColors.purple,
      barProgress: barProgress,
      barColors: const [AppColors.purple, AppColors.blue],
      primaryLabel: 'Enter dungeon →',
      primaryStyle: HomeHeroButtonStyle.solidPurple,
      onPrimary: () => _openWorldDestination(context, regionId),
      onSync: onSync,
    );
  }
}

class _CrossroadsPortal extends StatelessWidget {
  final WorldZoneModel zone;
  final WorldFullData world;
  final RegionDetail? region;
  final String? regionChip;
  final String? regionId;
  /// Tap handler installed by the orchestrator. Null in tests/static use.
  final Future<void> Function(WorldZoneModel branch)? onPickBranch;
  /// Currently in-flight branch id (drawn dimmed with a spinner).
  final String? busyBranchId;
  final VoidCallback? onSync;
  const _CrossroadsPortal({
    required this.zone,
    required this.world,
    required this.region,
    required this.regionChip,
    required this.regionId,
    required this.onSync,
    this.onPickBranch,
    this.busyBranchId,
  });

  @override
  Widget build(BuildContext context) {
    // Authoritative branch list: RegionDetail flags every branch zone with
    // `branchOf == this crossroads' id`. Falling back to "any outgoing edge"
    // would include the zone the user just came from (bidirectional edges
    // count both ways), which is exactly what we want to exclude.
    final branchIds = region == null
        ? <String>{}
        : region!.nodes
            .where((n) => n.branchOf == zone.id)
            .map((n) => n.id)
            .toSet();

    final branches = <_BranchEntry>[];
    for (final e in world.edges) {
      // Edges originating from the crossroads point at *forward* zones;
      // bidirectional incoming edges from a previous zone are the user's
      // route here, not a branch — skip them.
      if (e.fromZoneId != zone.id) continue;
      // When RegionDetail is loaded use it as the branch filter; otherwise
      // accept every outgoing edge as best-effort.
      if (branchIds.isNotEmpty && !branchIds.contains(e.toZoneId)) continue;
      final z = world.zones.cast<WorldZoneModel?>().firstWhere(
            (zz) => zz!.id == e.toZoneId,
            orElse: () => null,
          );
      if (z != null) {
        branches.add(_BranchEntry(zone: z, distanceKm: e.distanceKm));
      }
    }

    return HomeCard(
      borderColor: AppColors.blue.withValues(alpha: 0.4),
      glowColor: AppColors.blue.withValues(alpha: 0.12),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (regionChip != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                regionChip!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            '🗺 CROSSROADS · CHOOSE YOUR PATH',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '🚩 ${zone.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick a branch on the map. Your choice is permanent — sibling path locks.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (branches.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No branches wired yet.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...branches.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _BranchRow(
                    entry: b,
                    busy: busyBranchId == b.zone.id,
                    onTap: onPickBranch == null
                        ? null
                        : () => onPickBranch!(b.zone),
                  ),
                )),
          const SizedBox(height: 10),
          Row(
            children: [
              HomeHeroButton(
                label: '⟳ Sync',
                style: HomeHeroButtonStyle.ghost,
                onTap: onSync,
              ),
              const SizedBox(width: 8),
              HomeHeroButton(
                label: 'Choose on map →',
                style: HomeHeroButtonStyle.solidBlue,
                onTap: () => _openWorldDestination(context, regionId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchEntry {
  final WorldZoneModel zone;
  final double distanceKm;
  const _BranchEntry({required this.zone, required this.distanceKm});
}

class _BranchRow extends StatelessWidget {
  final _BranchEntry entry;
  final bool busy;
  final VoidCallback? onTap;
  const _BranchRow({required this.entry, this.busy = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final z = entry.zone;
    final typeColor = _typeColor(z.type);
    final levelGated = z.userState?.isLevelMet == false;
    final disabled = onTap == null || busy;
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: busy ? 0.04 : 0.06),
        border: Border.all(color: typeColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Opacity(
        opacity: busy ? 0.5 : 1.0,
        child: Row(
          children: [
            Text(
              _typeBadge(z.type).isNotEmpty ? _typeBadge(z.type) : '🌿',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    z.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (entry.distanceKm > 0)
                        '→ ${entry.distanceKm.toStringAsFixed(1)} km',
                      if (z.totalXp > 0) '+${z.totalXp} XP',
                      'Tier ${z.tier}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.blue,
                ),
              )
            else ...[
              _Pill(label: _typeLabel(z.type), color: typeColor),
              if (levelGated) ...[
                const SizedBox(width: 4),
                _Pill(
                  label: '⚷ Lv ${z.levelRequirement}+',
                  color: AppColors.red,
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Text(
                  '→',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: disabled ? null : onTap,
      child: row,
    );
  }
}

// ── Fallbacks ────────────────────────────────────────────────────────────────

class _PortalPlaceholder extends StatelessWidget {
  const _PortalPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: AppColors.blue,
        strokeWidth: 2,
      ),
    );
  }
}

class _PortalErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PortalErrorCard({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WORLD MAP · LOAD FAILED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.red,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Couldn’t reach the world map endpoint.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoZonePortal extends StatelessWidget {
  const _NoZonePortal();
  @override
  Widget build(BuildContext context) {
    return _HeroShell(
      accent: AppColors.blue,
      label: 'CURRENT ADVENTURE · NO ZONE YET',
      labelColor: AppColors.blue,
      title: 'Pick your first step',
      sub: 'Open the map to enter the world and begin your journey.',
      barLabel: 'Progress',
      barValue: '—',
      barValueColor: AppColors.textSecondary,
      barProgress: 0.0,
      barColors: const [AppColors.blue, AppColors.purple],
      primaryLabel: 'Open map →',
      primaryStyle: HomeHeroButtonStyle.solidBlue,
      onPrimary: () => _openWorldDestination(context, null),
      onSync: null,
    );
  }
}

// ── Next-zone hint variant ───────────────────────────────────────────────────
//
// Shown when the player is parked on a spent zone (e.g. opened chest) with no
// destination, and `_pickNextZoneAfter` returns a forward neighbour. Replaces
// the misleading "Suggested next: 0 / 1 nodes" bar from the prior overload of
// `_StandardPortal` with an actionable row of pills.
class _NextZoneHintPortal extends StatelessWidget {
  final WorldZoneModel zone;
  final WorldFullData world;
  final String? regionChip;
  final String? regionId;
  final VoidCallback? onSync;
  const _NextZoneHintPortal({
    required this.zone,
    required this.world,
    required this.regionChip,
    required this.regionId,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final fromId = world.userProgress.currentZoneId;
    final edge = world.edges.cast<WorldZoneEdgeModel?>().firstWhere(
          (e) =>
              e != null &&
              ((e.fromZoneId == fromId && e.toZoneId == zone.id) ||
                  (e.isBidirectional &&
                      e.toZoneId == fromId &&
                      e.fromZoneId == zone.id)),
          orElse: () => null,
        );
    final distanceKm = edge?.distanceKm;
    final levelGated = zone.userState?.isLevelMet == false;

    final pills = <Widget>[
      if (distanceKm != null && distanceKm > 0)
        _Pill(
          label: '→ ${distanceKm.toStringAsFixed(1)} km',
          color: AppColors.blue,
        ),
      if (zone.totalXp > 0)
        _Pill(label: '+${zone.totalXp} XP', color: AppColors.orange),
      _Pill(label: _typeLabel(zone.type), color: _typeColor(zone.type)),
      if (levelGated)
        _Pill(
          label: '⚷ Lv ${zone.levelRequirement}+',
          color: AppColors.red,
        ),
    ];

    return HomeCard(
      borderColor: AppColors.blue.withValues(alpha: 0.4),
      glowColor: AppColors.blue.withValues(alpha: 0.12),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (regionChip != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                regionChip!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            '✨ NEXT UP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_typeBadge(zone.type)}${zone.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            zone.description ??
                'Travel to ${zone.name} for the next reward.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: pills),
          const SizedBox(height: 14),
          Row(
            children: [
              HomeHeroButton(
                label: '⟳ Sync',
                style: HomeHeroButtonStyle.ghost,
                onTap: onSync,
              ),
              const SizedBox(width: 8),
              HomeHeroButton(
                label: 'Travel here →',
                style: HomeHeroButtonStyle.solidBlue,
                onTap: () => _openWorldDestination(context, regionId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

String _typeLabel(String type) =>
    type.isEmpty ? 'Standard' : '${type[0].toUpperCase()}${type.substring(1)}';

Color _typeColor(String type) {
  switch (type) {
    case 'boss':
      return AppColors.red;
    case 'chest':
      return AppColors.orange;
    case 'dungeon':
      return AppColors.purple;
    case 'crossroads':
      return AppColors.blue;
    case 'entry':
      return AppColors.green;
    default:
      return AppColors.textSecondary;
  }
}

// ── Type badge + helpers ─────────────────────────────────────────────────────

String _typeBadge(String type) {
  switch (type) {
    case 'boss':       return '👹 ';
    case 'chest':      return '🗝 ';
    case 'dungeon':    return '🏰 ';
    case 'crossroads': return '🗺 ';
    case 'entry':      return '🚪 ';
    default:           return '';
  }
}

String? _dungeonStatusLabel(DungeonRunStatus? s) {
  switch (s) {
    case DungeonRunStatus.inProgress:
      return 'Run in progress. Keep stacking workouts to clear floors.';
    case DungeonRunStatus.completed:
      return 'All floors cleared. Bonus XP already claimed.';
    case DungeonRunStatus.abandoned:
      return 'Run abandoned when you left. Re-enter to try again.';
    default:
      return null;
  }
}

String _fmtDuration(Duration d) {
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes}m';
}

String _fmtNumber(int n) {
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
  }
  return n.toString();
}

/// Human-friendly double — drops the decimal when the value is whole,
/// otherwise shows one decimal. Used by the dungeon portal for floor
/// progress (e.g. 3 / 3 km, 1.4 / 3 km).
String _fmtNum(double v) {
  if (v == v.truncateToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(1);
}

// ── Hero shell (visuals) ─────────────────────────────────────────────────────
class _HeroShell extends StatelessWidget {
  final Color accent;
  final String label;
  final Color labelColor;
  final String title;
  final String sub;
  final String? regionChip;
  final String barLabel;
  final String barValue;
  final Color barValueColor;
  final double barProgress;
  final List<Color> barColors;
  final String? branchPreview;
  final String primaryLabel;
  final HomeHeroButtonStyle primaryStyle;
  final VoidCallback? onPrimary;
  final VoidCallback? onSync;

  const _HeroShell({
    required this.accent,
    required this.label,
    required this.labelColor,
    required this.title,
    required this.sub,
    this.regionChip,
    required this.barLabel,
    required this.barValue,
    required this.barValueColor,
    required this.barProgress,
    required this.barColors,
    this.branchPreview,
    required this.primaryLabel,
    required this.primaryStyle,
    required this.onPrimary,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      borderColor: accent.withValues(alpha: 0.4),
      glowColor: accent.withValues(alpha: 0.12),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (regionChip != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                regionChip!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (branchPreview != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                branchPreview!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                barLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                barValue,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: barValueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HomeProgressBar(
            progress: barProgress,
            colors: barColors,
            height: 10,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              HomeHeroButton(
                label: '⟳ Sync',
                style: HomeHeroButtonStyle.ghost,
                onTap: onSync,
              ),
              const SizedBox(width: 8),
              HomeHeroButton(
                label: primaryLabel,
                style: primaryStyle,
                onTap: onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
