import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/world_map_models.dart';
import 'world_map_theme.dart';

/// Bottom sheet shown when a node on the region trail is tapped. Adaptive:
///
///   • Available / Next / Locked → chips + description + "Set as destination" / disabled CTA
///   • Active (destination set, en route) → journey progress card + disabled CTA
///   • Crossroads → purple "Choose a path" CTA with a dashed branching note
class ZoneDetailSheet extends StatelessWidget {
  final ZoneNode node;
  final String regionName;
  final int userLevel;
  final ActiveJourney? activeJourney;
  final bool isDestination;
  final VoidCallback? onSetDestination;

  /// Callback for the crossroads `⚖ Choose a path` CTA. When non-null on a
  /// crossroads node, tapping the CTA dismisses this sheet and opens the
  /// two-branch choice sheet. Null on non-crossroads taps and on crossroads
  /// taps without seeded branches (CTA falls back to disabled).
  final VoidCallback? onChooseCrossroadsPath;

  /// Callback for the chest `🎁 Open chest` CTA (fires only when `isChest &&
  /// status == active && !chestIsOpened`).
  final VoidCallback? onOpenChest;

  /// Callback for the dungeon `⚔️ Enter dungeon` / `Return — Floor X/Y` CTA.
  final VoidCallback? onEnterDungeon;

  /// Callback for the boss `⚔️ Fight {name}` CTA. Fires only when the user
  /// is AT the boss zone (`status == active`). On tap the backend lazy-spawns
  /// a legacy Boss row bridged to this zone, then the shell's Boss overlay
  /// opens so the user can log workouts to damage the boss.
  final VoidCallback? onFightBoss;

  /// Name of the next region (Ocean of Balance, …) — used in the
  /// "Victory unlocks" reward card and the disabled `✓ Defeated · Unlocks X`
  /// label for already-cleared bosses.
  final String? nextRegionName;

  /// Populated when `node` is a branch (`node.branchOf != null`) — the name
  /// of the parent crossroads. Used in the gated "Reach X first" CTA label.
  final String? parentCrossroadsName;

  /// True when the user is currently standing at the parent crossroads so
  /// branch CTAs can fire `setDestination`. When false, the branch CTA is
  /// disabled with a "Reach {parent} first" label.
  final bool userAtParentCrossroads;

  const ZoneDetailSheet({
    super.key,
    required this.node,
    required this.regionName,
    required this.userLevel,
    required this.activeJourney,
    required this.isDestination,
    required this.onSetDestination,
    this.onChooseCrossroadsPath,
    this.onOpenChest,
    this.onEnterDungeon,
    this.onFightBoss,
    this.nextRegionName,
    this.parentCrossroadsName,
    this.userAtParentCrossroads = false,
  });

  bool get _hasActiveJourney =>
      activeJourney != null && activeJourney!.distanceTotalKm > 0;

  /// True when this sheet is showing the zone the user is currently traveling
  /// TO (destination flagged + an active journey is in flight).
  bool get _showTravelingView => isDestination && _hasActiveJourney;

  bool get _levelMet => userLevel >= node.levelRequirement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(color: Color(0x8C000000), blurRadius: 40, offset: Offset(0, -18)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(top: 4, bottom: 14),
                ),
              ),
              _Head(node: node, regionName: regionName, isDestination: isDestination),
              const SizedBox(height: 14),
              if (node.isCrossroads)
                _CrossroadsNote()
              else
                _Chips(node: node, levelMet: _levelMet),
              const SizedBox(height: 14),
              if (_showTravelingView)
                _JourneyCard(journey: activeJourney!)
              else
                Text(
                  node.description.isEmpty
                      ? 'No description available yet.'
                      : node.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 16),
              _Cta(
                node: node,
                levelMet: _levelMet,
                showTravelingView: _showTravelingView,
                onSetDestination: onSetDestination,
                onChooseCrossroadsPath: onChooseCrossroadsPath,
                onOpenChest: onOpenChest,
                onEnterDungeon: onEnterDungeon,
                onFightBoss: onFightBoss,
                nextRegionName: nextRegionName,
                parentCrossroadsName: parentCrossroadsName,
                userAtParentCrossroads: userAtParentCrossroads,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Head extends StatelessWidget {
  final ZoneNode node;
  final String regionName;
  final bool isDestination;
  const _Head({
    required this.node,
    required this.regionName,
    required this.isDestination,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ZoneNodeColors.of(node.status);
    final chipColor = node.isBoss
        ? AppColors.red
        : node.isCrossroads
            ? AppColors.purple
            : colors.accent;

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [chipColor.withOpacity(0.2), chipColor.withOpacity(0.08)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: chipColor.withOpacity(0.4)),
          ),
          child: Text(node.emoji, style: const TextStyle(fontSize: 30)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$regionName · Tier ${node.tier}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              _StatusPill(node: node, isDestination: isDestination),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ZoneNode node;
  final bool isDestination;
  const _StatusPill({required this.node, required this.isDestination});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    if (node.isCrossroads) {
      color = AppColors.purple;
      label = 'Crossroads';
    } else if (node.status == ZoneNodeStatus.active) {
      color = AppColors.blue;
      label = 'You are here';
    } else if (node.status == ZoneNodeStatus.next || isDestination) {
      color = AppColors.orange;
      label = isDestination
          ? 'Traveling · ${node.distanceKm.toStringAsFixed(1)} km'
          : 'Available · ${node.distanceKm.toStringAsFixed(1)} km';
    } else if (node.status == ZoneNodeStatus.completed) {
      color = AppColors.green;
      label = 'Completed';
    } else if (node.status == ZoneNodeStatus.locked) {
      color = AppColors.textMuted;
      label = '🔒 Locked · Lv ${node.levelRequirement}';
    } else {
      color = AppColors.textSecondary;
      label = 'Available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  final ZoneNode node;
  final bool levelMet;
  const _Chips({required this.node, required this.levelMet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Chip(
            label: 'Level req',
            value: levelMet
                ? 'Lv ${node.levelRequirement}+ ✓'
                : 'Lv ${node.levelRequirement}+',
            valueColor: levelMet ? AppColors.green : AppColors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            label: 'Distance',
            value: node.distanceKm > 0
                ? '${node.distanceKm.toStringAsFixed(1)} km'
                : '—',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            label: 'XP reward',
            value: node.xpReward > 0 ? '+${node.xpReward}' : '—',
            valueColor: AppColors.orange,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Chip({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrossroadsNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          const Text('✦', style: TextStyle(color: AppColors.purple, fontSize: 14)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Branching point · no entry required. Cross to choose a path.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final ActiveJourney journey;
  const _JourneyCard({required this.journey});

  @override
  Widget build(BuildContext context) {
    final percent = (journey.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange.withOpacity(0.1), AppColors.orange.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'YOUR JOURNEY',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${journey.distanceTravelledKm.toStringAsFixed(1)} / ${journey.distanceTotalKm.toStringAsFixed(1)} km · $percent%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.hardEdge,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: journey.progress,
              child: Container(color: AppColors.orange),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'To · ${journey.destinationZoneName}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
              ),
              Text(
                'Arrival · +${journey.arrivalXpReward} XP',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  final ZoneNode node;
  final bool levelMet;
  final bool showTravelingView;
  final VoidCallback? onSetDestination;
  final VoidCallback? onChooseCrossroadsPath;
  final VoidCallback? onOpenChest;
  final VoidCallback? onEnterDungeon;
  final VoidCallback? onFightBoss;
  final String? nextRegionName;
  final String? parentCrossroadsName;
  final bool userAtParentCrossroads;
  const _Cta({
    required this.node,
    required this.levelMet,
    required this.showTravelingView,
    required this.onSetDestination,
    required this.onChooseCrossroadsPath,
    required this.onOpenChest,
    required this.onEnterDungeon,
    required this.onFightBoss,
    required this.nextRegionName,
    required this.parentCrossroadsName,
    required this.userAtParentCrossroads,
  });

  @override
  Widget build(BuildContext context) {
    // "Choose a path" only makes sense when the user is AT the crossroads
    // (and the parent wired a callback). Otherwise fall through so the
    // crossroads can be set as a regular destination — user will travel
    // to the fork and pick a branch on arrival.
    if (node.isCrossroads && onChooseCrossroadsPath != null) {
      return _CtaButton(
        label: '⚖ Choose a path',
        color: AppColors.purple,
        onTap: onChooseCrossroadsPath,
        disabled: false,
      );
    }

    // Chest-specific CTA wins over the generic paths when we're at the chest.
    if (node.isChest) {
      final reward = node.chestRewardXp ?? 0;
      if (node.chestIsOpened == true ||
          node.status == ZoneNodeStatus.completed) {
        return _CtaButton(
          label: '✓ Opened · +$reward XP',
          color: AppColors.green,
          onTap: null,
          disabled: true,
        );
      }
      if (node.status == ZoneNodeStatus.active) {
        return _CtaButton(
          label: '🎁 Open chest · +$reward XP',
          color: AppColors.orange,
          onTap: onOpenChest,
          disabled: onOpenChest == null,
        );
      }
      // Still en route — fall through to standard set-as-destination below.
    }

    // Dungeon-specific CTA paths.
    if (node.isDungeon) {
      final dStatus = node.dungeonStatus ?? DungeonRunStatus.notEntered;
      final total = node.dungeonFloorsTotal ?? 0;
      final done = node.dungeonFloorsCompleted ?? 0;
      final forfeited = node.dungeonFloorsForfeited ?? 0;

      if (dStatus == DungeonRunStatus.completed ||
          node.status == ZoneNodeStatus.completed) {
        return const _CtaButton(
          label: '✓ Dungeon cleared',
          color: AppColors.green,
          onTap: null,
          disabled: true,
        );
      }
      if (dStatus == DungeonRunStatus.abandoned) {
        return _CtaButton(
          label: '✕ Abandoned · $forfeited/$total lost',
          color: AppColors.textMuted,
          onTap: null,
          disabled: true,
        );
      }
      if (node.status == ZoneNodeStatus.locked || !levelMet) {
        return _CtaButton(
          label: '🔒 Locked · Lv ${node.levelRequirement}',
          color: AppColors.textMuted,
          onTap: null,
          disabled: true,
        );
      }
      if (node.status == ZoneNodeStatus.active) {
        if (dStatus == DungeonRunStatus.inProgress) {
          // Resume — show active floor position.
          final current = done + 1 <= total ? done + 1 : total;
          return _CtaButton(
            label: 'Return — Floor $current / $total',
            color: AppColors.orange,
            onTap: onEnterDungeon,
            disabled: onEnterDungeon == null,
          );
        }
        return _CtaButton(
          label: '⚔️ Enter dungeon',
          color: AppColors.red,
          onTap: onEnterDungeon,
          disabled: onEnterDungeon == null,
        );
      }
      // Still en route — fall through to set-as-destination.
    }

    // Boss-specific CTAs — fight on arrival, "defeated" after victory.
    if (node.isBoss) {
      if (node.status == ZoneNodeStatus.completed) {
        final lbl = nextRegionName != null
            ? '✓ Defeated · Unlocks $nextRegionName'
            : '✓ Defeated';
        return _CtaButton(
          label: lbl,
          color: AppColors.green,
          onTap: null,
          disabled: true,
        );
      }
      if (node.status == ZoneNodeStatus.active) {
        return _CtaButton(
          label: '⚔️ Fight ${node.name}',
          color: AppColors.red,
          onTap: onFightBoss,
          disabled: onFightBoss == null,
        );
      }
      // Fall through for available/next/locked — inherits Standard CTAs.
    }

    if (node.status == ZoneNodeStatus.active) {
      return const _CtaButton(
        label: 'You are here',
        color: AppColors.blue,
        onTap: null,
        disabled: true,
      );
    }
    if (node.status == ZoneNodeStatus.completed) {
      return const _CtaButton(
        label: '✓ Completed',
        color: AppColors.green,
        onTap: null,
        disabled: true,
      );
    }
    if (node.status == ZoneNodeStatus.locked || !levelMet) {
      return _CtaButton(
        label: '🔒 Locked · Lv ${node.levelRequirement}',
        color: AppColors.textMuted,
        onTap: null,
        disabled: true,
      );
    }
    // Branch gate — branches can only be set as destination from the
    // parent crossroads. If the user isn't there yet, disable the CTA
    // with a readable label instead of firing a backend call that fails.
    if (node.branchOf != null && !userAtParentCrossroads) {
      final name = parentCrossroadsName ?? 'the crossroads';
      return _CtaButton(
        label: '🔒 Reach $name first',
        color: AppColors.textMuted,
        onTap: null,
        disabled: true,
      );
    }
    // Current destination + mid-journey → idempotent re-affirm CTA. Taps
    // are no-op server-side (same destination, progress preserved) but the
    // button stays enabled so the UI never feels frozen.
    if (showTravelingView) {
      return _CtaButton(
        label: '✓ Heading here',
        color: AppColors.orange,
        onTap: onSetDestination,
        disabled: onSetDestination == null,
      );
    }
    return _CtaButton(
      label: '→ Set as destination',
      color: AppColors.orange,
      onTap: onSetDestination,
      disabled: onSetDestination == null,
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;
  const _CtaButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.75)],
                ),
          color: disabled ? AppColors.surfaceElevated : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled ? AppColors.border : color.withOpacity(0.6),
          ),
          boxShadow: disabled
              ? null
              : [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16)],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled ? AppColors.textSecondary : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
