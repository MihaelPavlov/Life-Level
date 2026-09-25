import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/services/boss_overlay_notifier.dart';
import '../../../core/services/dungeon_floor_cleared_notifier.dart';
import '../../../core/services/world_map_notifier.dart';
import '../../../core/services/world_zone_refresh_notifier.dart';
import '../../../core/widgets/app_toast.dart';
import '../../boss/models/boss_list_item.dart';
import '../../boss/providers/boss_provider.dart';
import '../../map/models/encounter_models.dart';
import '../../map/models/world_map_models.dart';
import '../../map/models/world_zone_models.dart';
import '../../map/services/world_zone_service.dart';
import '../providers/world_progress_provider.dart';
import '../widgets/home_card.dart';
import '../widgets/home_hero_button.dart';
import '../widgets/home_progress_bar.dart';
import '../../boss/widgets/boss_icon.dart';

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
    final confirmed = await showAppDialog<bool>(
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
      AppToast.info(context, 'Heading to ${branch.name}',
          icon: Icons.alt_route_rounded);
    } on PathAlreadyChosenException {
      if (!mounted) return;
      AppToast.warning(context, 'You already chose a different path here.');
    } on BranchRequiresCrossroadsArrivalException {
      if (!mounted) return;
      AppToast.warning(
          context, 'Travel to the crossroads first, then pick a branch.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Could not choose path: $e');
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
    final hasNoDestination = world.userProgress.destinationZoneId == null ||
        world.userProgress.destinationZoneId!.isEmpty;
    final chestExplicitlyUnopened = standingNode?.chestIsOpened == false;

    // Pre-load dungeon state so both the slide-forward check and the
    // dungeon variant can use it without watching twice.
    final dungeonState = (zone.type == 'dungeon')
        ? ref.watch(dungeonStateProvider(zone.id)).valueOrNull
        : null;
    final dungeonCompleted =
        (dungeonState?.status == DungeonRunStatus.completed) ||
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
    final regionId = world.userProgress.currentRegionId ?? region?.id;
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
      final encounter = _currentEdgeEncounter(world, region);
      if (encounter != null) {
        return _EncounterPortal(
          encounter: encounter,
          world: world,
          destination: zone,
          regionChip: regionChip,
          regionId: regionId,
          onSync: onSync,
        );
      }
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
void _openWorldDestination(String? regionId) {
  WorldMapNotifier.open(autoOpenActiveRegion: regionId != null);
}

// ── Variants ─────────────────────────────────────────────────────────────────

TrailEncounterNode? _currentEdgeEncounter(
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
          _encounterPriority(a.type).compareTo(_encounterPriority(b.type));
      return typePriority != 0 ? typePriority : b.t.compareTo(a.t);
    });

  return matches.firstOrNull;
}

int _encounterPriority(TrailEncounterType type) {
  switch (type) {
    case TrailEncounterType.blocker:
      return 0;
    case TrailEncounterType.merchant:
      return 1;
    case TrailEncounterType.story:
      return 2;
  }
}

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
      leadingVisual: _BossPortalIcon(boss: boss),
      barLabel: 'Boss HP',
      barValue: '${_fmtNumber(hpRemaining)} / ${_fmtNumber(boss.maxHp)}',
      barValueColor: AppColors.red,
      barProgress: hpProgress,
      barColors: const [AppColors.red, AppColors.redDark],
      primaryLabel: 'Fight →',
      primaryStyle: HomeHeroButtonStyle.solidRed,
      onPrimary: () => BossOverlayNotifier.notifyForBoss(boss.id),
      onSync: onSync,
    );
  }
}

class _EncounterPortal extends StatelessWidget {
  final TrailEncounterNode encounter;
  final WorldFullData world;
  final WorldZoneModel destination;
  final String? regionChip;
  final String? regionId;
  final VoidCallback? onSync;

  const _EncounterPortal({
    required this.encounter,
    required this.world,
    required this.destination,
    required this.regionChip,
    required this.regionId,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final edgeId = world.userProgress.currentEdgeId;
    final edge = world.edges.cast<WorldZoneEdgeModel?>().firstWhere(
          (e) => e?.id == edgeId,
          orElse: () => null,
        );
    final travelled = world.userProgress.distanceTraveledOnEdge;
    final total = edge?.distanceKm ?? 0;
    final progress = total > 0 ? (travelled / total).clamp(0.0, 1.0) : 0.0;
    final title = _encounterTitle(encounter);
    final accent = _encounterAccent(encounter.type);
    final label = _encounterPortalLabel(encounter.type);
    final sub = _encounterSubtitle(encounter, destination);
    final preview = _encounterPreview(encounter);

    return _HeroShell(
      accent: accent,
      label: label,
      labelColor: accent,
      title: title,
      sub: sub,
      regionChip: regionChip,
      barLabel: 'Distance reached',
      barValue: total > 0
          ? '${travelled.toStringAsFixed(1)} / ${total.toStringAsFixed(1)} km'
          : 'Encounter reached',
      barValueColor: accent,
      barProgress: progress,
      barColors: [accent, AppColors.orange],
      branchPreview: preview,
      primaryLabel: encounter.type == TrailEncounterType.blocker
          ? 'View blocker'
          : 'Open map ->',
      primaryStyle: encounter.type == TrailEncounterType.blocker
          ? HomeHeroButtonStyle.solidRed
          : encounter.type == TrailEncounterType.merchant
              ? HomeHeroButtonStyle.solidOrange
              : HomeHeroButtonStyle.solidPurple,
      onPrimary: () => _openWorldDestination(regionId),
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
    final edge = world.edges.cast<WorldZoneEdgeModel?>().firstWhere(
          (e) => e!.id == edgeId,
          orElse: () => null,
        );
    final travelled = world.userProgress.distanceTraveledOnEdge;
    final total = edge?.distanceKm ?? 0;
    final progress = total > 0 ? (travelled / total).clamp(0.0, 1.0) : 0.0;
    final remaining = (total - travelled).clamp(0.0, double.infinity);
    final typeBadge = _typeBadge(destination.type);
    return _HeroShell(
      accent: AppColors.blue,
      labelColor: AppColors.blue,
      title: '$typeBadge${destination.name}',
      titleTrailing:
          total > 0 ? '${remaining.toStringAsFixed(1)} KM TO GO' : null,
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
      onPrimary: () => _openWorldDestination(regionId),
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
      onPrimary: () => _openWorldDestination(regionId),
      onSync: onSync,
    );
  }
}

class _BossZonePortal extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Map this boss zone → its boss row. Backend exposes `worldZoneId` on
    // BossListItemDto; if the row is missing the boss hasn't lazy-spawned
    // yet (rare, since the bridge spawns on arrival).
    final bosses = ref.watch(bossListProvider).valueOrNull;
    final boss = bosses
        ?.cast<BossListItem?>()
        .firstWhere((b) => b!.worldZoneId == zone.id, orElse: () => null);

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
      onPrimary: () {
        if (boss == null) {
          // Lazy-spawn race or list still loading: fall back to the boss
          // list (no preselect) and tell the user to retry.
          BossOverlayNotifier.notify();
          AppToast.info(
            context,
            'Boss is spawning - log a workout to engage.',
            icon: Icons.sports_martial_arts_rounded,
          );
          return;
        }
        BossOverlayNotifier.notifyForBoss(boss.id);
      },
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
      showProgressBar: false,
      primaryLabel: opened ? 'View on map →' : 'Open chest →',
      primaryStyle: HomeHeroButtonStyle.solidOrange,
      onPrimary: () => _openWorldDestination(regionId),
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
    final floorLabel = total > 0 ? 'FLOOR $current / $total' : 'DUNGEON';
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
      onPrimary: () => _openWorldDestination(regionId),
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
                border:
                    Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
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
                onTap: () => _openWorldDestination(regionId),
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
      onPrimary: () => _openWorldDestination(null),
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
/// "Next up" card. When the zone is open to travel (not level-gated) it
/// idles with a light sweep across the card every 6 s, a shine on the
/// Travel button, and footsteps walking inside the distance pill — a quiet
/// "you can go here" nudge. Level-gated zones stay still.
class _NextZoneHintPortal extends StatefulWidget {
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
  State<_NextZoneHintPortal> createState() => _NextZoneHintPortalState();
}

class _NextZoneHintPortalState extends State<_NextZoneHintPortal>
    with TickerProviderStateMixin {
  // Light sweep + button shine share one slow loop; the footsteps walk on
  // their own faster one.
  late final AnimationController _sweep = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 6000));
  late final AnimationController _steps = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  // Breathe: border/glow swell and the button arrow nudges once per breath.
  late final AnimationController _breath = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3600));

  WorldZoneModel get zone => widget.zone;
  WorldFullData get world => widget.world;
  String? get regionChip => widget.regionChip;
  String? get regionId => widget.regionId;
  VoidCallback? get onSync => widget.onSync;

  bool get _idle =>
      zone.userState?.isLevelMet != false && AppMotion.isFull(context);

  void _sync() {
    if (_idle) {
      if (!_sweep.isAnimating) _sweep.repeat();
      if (!_steps.isAnimating) _steps.repeat();
      if (!_breath.isAnimating) _breath.repeat();
    } else {
      _sweep.stop();
      _steps.stop();
      _breath.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_NextZoneHintPortal old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _sweep.dispose();
    _steps.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idle = _idle;
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
        idle
            ? _StepsPill(
                label: '${distanceKm.toStringAsFixed(1)} km',
                color: AppColors.blue,
                steps: _steps,
              )
            : _Pill(
                label: '→ ${distanceKm.toStringAsFixed(1)} km',
                color: AppColors.blue,
              ),
      if (zone.totalXp > 0)
        _Pill(label: '+${zone.totalXp} XP', color: AppColors.orange),
      _Pill(label: _typeLabel(zone.type), color: _typeColor(zone.type)),
    ];

    final content = Column(
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
        Row(
          children: [
            const Text(
              '✨ NEXT UP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.blue,
              ),
            ),
            if (levelGated) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.75),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🔒 LOCKED',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ],
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
          zone.description ?? 'Travel to ${zone.name} for the next reward.',
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
              label: levelGated
                  ? '🔒 Level ${zone.levelRequirement} required'
                  : 'Travel here →',
              style: levelGated
                  ? HomeHeroButtonStyle.locked
                  : HomeHeroButtonStyle.solidBlue,
              onTap: levelGated ? null : () => _openWorldDestination(regionId),
              shine: idle ? _sweep : null,
              nudge: idle ? _breath : null,
            ),
          ],
        ),
      ],
    );
    HomeCard cardWith(double breath) => HomeCard(
          borderColor: (levelGated ? AppColors.red : AppColors.blue)
              .withValues(alpha: levelGated ? 0.65 : 0.4 + 0.55 * breath),
          glowColor: (levelGated ? AppColors.red : AppColors.blue)
              .withValues(alpha: levelGated ? 0.16 : 0.12 + 0.23 * breath),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: content,
        );
    if (!idle) return cardWith(0);
    // Breathe: the blue border and glow slowly brighten and fade.
    final card = AnimatedBuilder(
      animation: _breath,
      builder: (_, __) =>
          cardWith((1 - math.cos(_breath.value * 2 * math.pi)) / 2),
    );
    // Light sweep over the card body (the card has a 14 px bottom margin).
    return Stack(
      children: [
        card,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 14,
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedBuilder(
                animation: _sweep,
                builder: (_, __) {
                  final p = ((_sweep.value - .55) / .3).clamp(0.0, 1.0);
                  if (p <= 0 || p >= 1) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment(-1.6 + 3.2 * p, 0),
                    child: Transform(
                      transform: Matrix4.skewX(-.32),
                      child: Container(
                        width: 90,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Color(0x007DB8FF),
                            Color(0x247DB8FF),
                            Color(0x1AFFFFFF),
                            Color(0x247DB8FF),
                            Color(0x007DB8FF),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Distance pill with little footsteps walking in place of the arrow.
class _StepsPill extends StatelessWidget {
  final String label;
  final Color color;
  final Animation<double> steps;
  const _StepsPill(
      {required this.label, required this.color, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 12,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: steps,
                builder: (_, __) => Stack(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Builder(builder: (_) {
                        final p = (steps.value + i * .25) % 1;
                        final o = p < .15
                            ? p / .15
                            : p > .85
                                ? (1 - p) / .15
                                : 1.0;
                        return Positioned(
                          left: -4 + 18 * p,
                          top: i.isEven ? 3 : 6,
                          child: Opacity(
                            opacity: o,
                            child: Container(
                              width: 4,
                              height: 5,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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

class _BossPortalIcon extends StatelessWidget {
  final BossListItem boss;

  const _BossPortalIcon({required this.boss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF230808),
        border: Border.all(color: AppColors.red, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.38),
            blurRadius: 24,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: BossIcon(
        icon: boss.icon,
        size: 60,
        emojiSize: 34,
        visualScale: 1.15,
        visualOffset: const Offset(-0.75, -1.5),
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

String _encounterTitle(TrailEncounterNode enc) {
  switch (enc.type) {
    case TrailEncounterType.blocker:
      return '${_encounterEmoji(enc)} ${enc.blocker?.name ?? 'Path blocker'}';
    case TrailEncounterType.merchant:
      return '${_encounterEmoji(enc)} ${enc.merchant?.name ?? 'Trail merchant'}';
    case TrailEncounterType.story:
      return '${_encounterEmoji(enc)} ${enc.story?.npcName ?? 'Story encounter'}';
  }
}

String _encounterEmoji(TrailEncounterNode enc) {
  switch (enc.type) {
    case TrailEncounterType.blocker:
      return '💀';
    case TrailEncounterType.merchant:
      return '🪙';
    case TrailEncounterType.story:
      return enc.story?.portrait.isNotEmpty == true
          ? enc.story!.portrait
          : '🧙';
  }
}

String _encounterPortalLabel(TrailEncounterType type) {
  switch (type) {
    case TrailEncounterType.blocker:
      return 'PATH BLOCKED · NPC ENCOUNTER';
    case TrailEncounterType.merchant:
      return 'TRAIL MERCHANT · NPC ENCOUNTER';
    case TrailEncounterType.story:
      return 'STORY ENCOUNTER · NPC';
  }
}

String _encounterSubtitle(
  TrailEncounterNode enc,
  WorldZoneModel destination,
) {
  switch (enc.type) {
    case TrailEncounterType.blocker:
      final name = enc.blocker?.name ?? 'This NPC';
      return '$name is holding the road to ${destination.name}. Defeat them to keep traveling.';
    case TrailEncounterType.merchant:
      final count = enc.merchant?.items.length ?? 0;
      return count > 0
          ? 'A merchant is waiting on your route with $count item${count == 1 ? "" : "s"}.'
          : 'A merchant is waiting on your route.';
    case TrailEncounterType.story:
      return enc.story?.dialogue.isNotEmpty == true
          ? enc.story!.dialogue
          : 'Someone on the trail has a story for you.';
  }
}

String? _encounterPreview(TrailEncounterNode enc) {
  switch (enc.type) {
    case TrailEncounterType.blocker:
      final blocker = enc.blocker;
      if (blocker == null) return null;
      final rewards = blocker.rewards.take(2).join(' · ');
      return rewards.isEmpty
          ? 'HP ${blocker.currentHp} / ${blocker.maxHp}'
          : 'HP ${blocker.currentHp} / ${blocker.maxHp} · $rewards';
    case TrailEncounterType.merchant:
      final merchant = enc.merchant;
      if (merchant == null || merchant.items.isEmpty) return null;
      return merchant.items.take(2).map((i) => i.name).join(' · ');
    case TrailEncounterType.story:
      final story = enc.story;
      if (story == null) return null;
      return story.npcTitle.isNotEmpty
          ? '${story.npcTitle} · +${story.loreXp} lore XP'
          : '+${story.loreXp} lore XP';
  }
}

Color _encounterAccent(TrailEncounterType type) {
  switch (type) {
    case TrailEncounterType.blocker:
      return AppColors.red;
    case TrailEncounterType.merchant:
      return AppColors.orange;
    case TrailEncounterType.story:
      return AppColors.purple;
  }
}

String _typeBadge(String type) {
  switch (type) {
    case 'boss':
      return '👹 ';
    case 'chest':
      return '🗝 ';
    case 'dungeon':
      return '🏰 ';
    case 'crossroads':
      return '🗺 ';
    case 'entry':
      return '🚪 ';
    default:
      return '';
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
  final String? label;
  final Color labelColor;
  final String title;
  final String? titleTrailing;
  final String sub;
  final String? regionChip;
  final Widget? leadingVisual;
  final String barLabel;
  final String barValue;
  final Color barValueColor;
  final double barProgress;
  final List<Color> barColors;
  final bool showProgressBar;
  final String? branchPreview;
  final String primaryLabel;
  final HomeHeroButtonStyle primaryStyle;
  final VoidCallback? onPrimary;
  final VoidCallback? onSync;

  const _HeroShell({
    required this.accent,
    this.label,
    required this.labelColor,
    required this.title,
    this.titleTrailing,
    required this.sub,
    this.regionChip,
    this.leadingVisual,
    required this.barLabel,
    required this.barValue,
    required this.barValueColor,
    required this.barProgress,
    required this.barColors,
    this.showProgressBar = true,
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
          if (label != null && label!.isNotEmpty) ...[
            Text(
              label!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (leadingVisual != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leadingVisual!,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
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
                ),
                if (titleTrailing != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    titleTrailing!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
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
          ],
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
          if (showProgressBar) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: HomeProgressBar(
                    progress: barProgress,
                    colors: barColors,
                    height: 10,
                  ),
                ),
                const SizedBox(width: 8),
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
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.09),
                border: Border.all(color: accent.withValues(alpha: 0.28)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    barLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    barValue,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: barValueColor,
                    ),
                  ),
                ],
              ),
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
