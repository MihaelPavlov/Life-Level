import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/map_focus_notifier.dart';
import '../../../core/services/nav_tab_notifier.dart';
import '../../boss/models/boss_list_item.dart';
import '../../boss/providers/boss_provider.dart';
import '../../map/models/world_map_models.dart';
import '../../map/models/world_zone_models.dart';
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
/// Every non-boss-raid CTA fires `MapFocusNotifier.focus(zone.id)` and
/// `NavTabNotifier.switchTo('map')` so the map tab re-centers on the zone.
class HomePortalCard extends ConsumerWidget {
  final VoidCallback? onSync;
  const HomePortalCard({super.key, this.onSync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final world = ref.watch(worldProgressProvider).valueOrNull;
    if (world == null) return const _PortalPlaceholder();

    final zone = _pickPortalZone(world);
    if (zone == null) return const _NoZonePortal();

    final region = ref.watch(currentRegionDetailProvider).valueOrNull;
    final regionChip = _buildRegionChip(region);

    final isTraveling = (world.userProgress.currentEdgeId ?? '').isNotEmpty;
    if (isTraveling) {
      return _TravelingPortal(
        world: world,
        destination: zone,
        regionChip: regionChip,
        onSync: onSync,
      );
    }

    final node = region?.nodes.where((n) => n.id == zone.id).firstOrNull;

    switch (zone.type) {
      case 'boss':
        return _BossZonePortal(
          zone: zone,
          regionChip: regionChip,
          onSync: onSync,
        );
      case 'chest':
        return _ChestPortal(
          zone: zone,
          node: node,
          regionChip: regionChip,
          onSync: onSync,
        );
      case 'dungeon':
        return _DungeonPortal(
          zone: zone,
          node: node,
          regionChip: regionChip,
          onSync: onSync,
        );
      case 'crossroads':
        return _CrossroadsPortal(
          zone: zone,
          world: world,
          regionChip: regionChip,
          onSync: onSync,
        );
      case 'entry':
      case 'zone':
      default:
        return _StandardPortal(
          zone: zone,
          regionChip: regionChip,
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

String? _buildRegionChip(RegionCard? region) {
  if (region == null || region.name.isEmpty) return null;
  final emoji = region.emoji.isNotEmpty ? '${region.emoji} ' : '';
  return '$emoji${region.name} · Ch. ${region.chapterIndex}';
}

void _openMapFocused(String zoneId) {
  MapFocusNotifier.focus(zoneId);
  NavTabNotifier.switchTo('map');
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
  final VoidCallback? onSync;
  const _TravelingPortal({
    required this.world,
    required this.destination,
    required this.regionChip,
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
      onPrimary: () => _openMapFocused(destination.id),
      onSync: onSync,
    );
  }
}

class _StandardPortal extends StatelessWidget {
  final WorldZoneModel zone;
  final String? regionChip;
  final VoidCallback? onSync;
  const _StandardPortal({
    required this.zone,
    required this.regionChip,
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
      onPrimary: () => _openMapFocused(zone.id),
      onSync: onSync,
    );
  }
}

class _BossZonePortal extends StatelessWidget {
  final WorldZoneModel zone;
  final String? regionChip;
  final VoidCallback? onSync;
  const _BossZonePortal({
    required this.zone,
    required this.regionChip,
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
      onPrimary: () => _openMapFocused(zone.id),
      onSync: onSync,
    );
  }
}

class _ChestPortal extends StatelessWidget {
  final WorldZoneModel zone;
  final ZoneNode? node;
  final String? regionChip;
  final VoidCallback? onSync;
  const _ChestPortal({
    required this.zone,
    required this.node,
    required this.regionChip,
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
      onPrimary: () => _openMapFocused(zone.id),
      onSync: onSync,
    );
  }
}

class _DungeonPortal extends StatelessWidget {
  final WorldZoneModel zone;
  final ZoneNode? node;
  final String? regionChip;
  final VoidCallback? onSync;
  const _DungeonPortal({
    required this.zone,
    required this.node,
    required this.regionChip,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final total = node?.dungeonFloorsTotal ?? 0;
    final done = node?.dungeonFloorsCompleted ?? 0;
    final current = (done + 1).clamp(1, total == 0 ? 1 : total);
    final progress =
        total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
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
      barLabel: total > 0 ? 'Floor progress' : 'Dungeon',
      barValue: total > 0 ? '$done / $total cleared' : '—',
      barValueColor: AppColors.purple,
      barProgress: progress,
      barColors: const [AppColors.purple, AppColors.blue],
      primaryLabel: 'Enter dungeon →',
      primaryStyle: HomeHeroButtonStyle.solidPurple,
      onPrimary: () => _openMapFocused(zone.id),
      onSync: onSync,
    );
  }
}

class _CrossroadsPortal extends StatelessWidget {
  final WorldZoneModel zone;
  final WorldFullData world;
  final String? regionChip;
  final VoidCallback? onSync;
  const _CrossroadsPortal({
    required this.zone,
    required this.world,
    required this.regionChip,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final branches = world.edges
        .where((e) =>
            e.fromZoneId == zone.id ||
            (e.isBidirectional && e.toZoneId == zone.id))
        .map((e) => e.fromZoneId == zone.id ? e.toZoneId : e.fromZoneId)
        .map((id) => world.zones
            .cast<WorldZoneModel?>()
            .firstWhere((z) => z!.id == id, orElse: () => null))
        .whereType<WorldZoneModel>()
        .toList();
    final branchText = branches.isEmpty
        ? 'No branches wired yet.'
        : branches
            .take(2)
            .map((b) => '${_typeBadge(b.type)}${b.name}')
            .join('  •  ');
    return _HeroShell(
      accent: AppColors.blue,
      label: '🗺 CROSSROADS · CHOOSE YOUR PATH',
      labelColor: AppColors.blue,
      title: '🚩 ${zone.name}',
      sub:
          'Pick a branch on the map. Your choice is permanent — sibling path locks.',
      regionChip: regionChip,
      barLabel: 'Possible branches',
      barValue: '${branches.length}',
      barValueColor: AppColors.textPrimary,
      barProgress: branches.isNotEmpty ? 0.5 : 0.0,
      barColors: const [AppColors.blue, AppColors.purple],
      branchPreview: branchText,
      primaryLabel: 'Choose path →',
      primaryStyle: HomeHeroButtonStyle.solidBlue,
      onPrimary: () => _openMapFocused(zone.id),
      onSync: onSync,
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
      onPrimary: () {
        MapFocusNotifier.focus(null);
        NavTabNotifier.switchTo('map');
      },
      onSync: null,
    );
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
