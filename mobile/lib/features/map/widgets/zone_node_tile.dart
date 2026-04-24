import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/world_map_models.dart';
import 'world_map_theme.dart';

/// A single bubble on the region trail: emoji circle, name, sub-label, and an
/// optional "YOU ARE HERE" chip for the active node. Layout matches
/// `.rv3-bubble` in `design-mockup/map/WORLD-MAP-FINAL-MOCKUP.html`.
///
/// The widget is status-driven — circle size, border, colour, and the sub-label
/// text are all picked from [ZoneNode.status] (with overrides for boss /
/// crossroads). The parent trail ([ZoneTrail]) is responsible for positioning
/// this bubble to the left, right, or centre of the row.
class ZoneNodeBubble extends StatefulWidget {
  final ZoneNode node;
  final ActiveJourney? journey;

  /// Name of the region that defeating this zone's boss unlocks. Used only
  /// when [ZoneNode.isBoss] is true to render the "Boss · Unlocks X" sub-label.
  final String? nextRegionName;

  final VoidCallback? onTap;

  const ZoneNodeBubble({
    super.key,
    required this.node,
    this.journey,
    this.nextRegionName,
    this.onTap,
  });

  @override
  State<ZoneNodeBubble> createState() => _ZoneNodeBubbleState();
}

class _ZoneNodeBubbleState extends State<ZoneNodeBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final accent = _bubbleAccent(node);
    final sub = _subLabel(node, widget.journey, widget.nextRegionName);
    final subColor = _subColor(node);

    final bubble = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Circle(node: node, pulse: _pulse, accent: accent),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: Text(
            node.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: node.status == ZoneNodeStatus.locked
                  ? AppColors.textMuted
                  : AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ],
    );

    final content = node.status == ZoneNodeStatus.active
        ? Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              bubble,
              const Positioned(top: -10, child: _YouAreHereBadge()),
            ],
          )
        : bubble;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Circle extends StatelessWidget {
  final ZoneNode node;
  final AnimationController pulse;
  final Color accent;
  const _Circle({
    required this.node,
    required this.pulse,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final size = _size(node);
    final borderWidth =
        node.status == ZoneNodeStatus.active ? 3.0 : 2.0;
    final isCompleted = node.status == ZoneNodeStatus.completed;
    final isLocked = node.status == ZoneNodeStatus.locked;

    Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.22), accent.withOpacity(0.06)],
        ),
        shape: node.isCrossroads ? BoxShape.rectangle : BoxShape.circle,
        borderRadius:
            node.isCrossroads ? BorderRadius.circular(12) : null,
        border: Border.all(color: accent, width: borderWidth),
      ),
      child: Text(
        isCompleted ? '✓' : node.emoji,
        style: TextStyle(
          fontSize: _emojiSize(node),
          color: isCompleted ? accent : null,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    // Crossroads renders as a rotated-45° square with an upright emoji.
    if (node.isCrossroads) {
      circle = Transform.rotate(angle: 0.785398, child: circle);
      circle = Stack(alignment: Alignment.center, children: [
        circle,
        Text(
          node.emoji,
          style: TextStyle(fontSize: _emojiSize(node), color: accent),
        ),
      ]);
    }

    // Dim locked bubbles so the trail focus stays on the unlocked chain.
    if (isLocked) {
      circle = Opacity(opacity: 0.6, child: circle);
    }

    // Pulsing glow for active + boss nodes.
    if (node.status == ZoneNodeStatus.active || node.isBoss) {
      final glowColor = accent;
      return AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          final t = pulse.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.35 + 0.25 * t),
                  blurRadius: 24 + 12 * t,
                  spreadRadius: 2 + 2 * t,
                ),
              ],
            ),
            child: circle,
          );
        },
      );
    }

    return circle;
  }

  double _size(ZoneNode n) {
    if (n.status == ZoneNodeStatus.active) return 72;
    if (n.isBoss) return 68;
    if (n.status == ZoneNodeStatus.next) return 60;
    if (n.isCrossroads) return 60;
    if (n.status == ZoneNodeStatus.locked) return 46;
    if (n.status == ZoneNodeStatus.completed) return 48;
    return 56; // available
  }

  double _emojiSize(ZoneNode n) {
    if (n.status == ZoneNodeStatus.active) return 30;
    if (n.isBoss) return 26;
    if (n.status == ZoneNodeStatus.locked) return 18;
    if (n.status == ZoneNodeStatus.completed) return 20;
    return 24;
  }
}

class _YouAreHereBadge extends StatelessWidget {
  const _YouAreHereBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'YOU ARE HERE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── Style helpers ───────────────────────────────────────────────────────────

Color _bubbleAccent(ZoneNode n) {
  if (n.isBoss) return AppColors.red;
  if (n.isCrossroads) return AppColors.purple;
  if (n.isDungeon) return AppColors.purple;
  if (n.isChest) return AppColors.orange;
  return ZoneNodeColors.of(n.status).accent;
}

Color _subColor(ZoneNode n) {
  if (n.isBoss) return AppColors.red;
  if (n.isCrossroads) return AppColors.purple;
  switch (n.status) {
    case ZoneNodeStatus.completed:
      return AppColors.green;
    case ZoneNodeStatus.active:
      return AppColors.blue;
    case ZoneNodeStatus.next:
      return AppColors.orange;
    case ZoneNodeStatus.available:
      return AppColors.textSecondary;
    case ZoneNodeStatus.locked:
      return AppColors.textMuted;
  }
}

String _subLabel(ZoneNode n, ActiveJourney? journey, String? nextRegionName) {
  if (n.isBoss) {
    final target = nextRegionName ?? 'next region';
    return 'Boss · Unlocks $target';
  }
  if (n.isCrossroads) return 'Crossroads';
  if (n.isChest) {
    if (n.chestIsOpened == true) {
      return 'Chest · +${n.chestRewardXp ?? 0} XP · Opened';
    }
    if (n.status == ZoneNodeStatus.active) return 'Chest · tap to open';
    return 'Chest · +${n.chestRewardXp ?? 0} XP';
  }
  if (n.isDungeon) {
    final total = n.dungeonFloorsTotal ?? 0;
    final done = n.dungeonFloorsCompleted ?? 0;
    final lost = n.dungeonFloorsForfeited ?? 0;
    switch (n.dungeonStatus) {
      case DungeonRunStatus.completed:
        return 'Dungeon · Cleared ✓';
      case DungeonRunStatus.abandoned:
        return 'Dungeon · $lost/$total lost';
      case DungeonRunStatus.inProgress:
        return 'Floor ${done + 1 <= total ? done + 1 : total} / $total';
      default:
        return 'Dungeon · $total floors';
    }
  }

  final isBranch = n.branchOf != null;

  switch (n.status) {
    case ZoneNodeStatus.completed:
      return n.xpReward > 0 ? '+${n.xpReward} XP' : 'Completed';

    case ZoneNodeStatus.active:
      if (journey != null) {
        return 'Departing · ${journey.distanceTravelledKm.toStringAsFixed(1)} km';
      }
      return 'Tier ${n.tier} · Current';

    case ZoneNodeStatus.next:
      if (journey != null) {
        final remaining =
            (journey.distanceTotalKm - journey.distanceTravelledKm)
                .clamp(0.0, double.infinity);
        return 'Destination · ${remaining.toStringAsFixed(1)} km to go';
      }
      return 'Next · ${n.distanceKm.toStringAsFixed(1)} km';

    case ZoneNodeStatus.available:
      if (isBranch) return 'Branch · ${n.distanceKm.toStringAsFixed(1)} km';
      return 'Available · ${n.distanceKm.toStringAsFixed(1)} km';

    case ZoneNodeStatus.locked:
      if (isBranch) return 'Other path chosen';
      return 'Lv ${n.levelRequirement} · Locked';
  }
}
