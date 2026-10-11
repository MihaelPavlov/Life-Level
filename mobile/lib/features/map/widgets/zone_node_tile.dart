import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../models/world_map_models.dart';
import 'map_icon_resolver.dart';
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
  final RegionTheme? regionTheme;
  final String? regionName;

  /// Name of the region that defeating this zone's boss unlocks. Used only
  /// when [ZoneNode.isBoss] is true to render the "Boss · Unlocks X" sub-label.
  final String? nextRegionName;

  final VoidCallback? onTap;

  const ZoneNodeBubble({
    super.key,
    required this.node,
    this.journey,
    this.regionTheme,
    this.regionName,
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
    // The region boss stays hidden (a silhouette in a normal circle) until you
    // stand on its zone; then the full boss art steps out of the circle.
    final bossArt = node.isBoss ? AppIcons.bossAssetForName(node.name) : null;
    final bossRevealed = bossArt != null &&
        (node.status == ZoneNodeStatus.active ||
            node.status == ZoneNodeStatus.completed);
    final bossHidden = node.isBoss && !bossRevealed;
    final sub = bossHidden
        ? 'Region boss · reach him to reveal'
        : _subLabel(node, widget.journey, widget.nextRegionName);
    final subColor = _subColor(node);

    final Widget figure = bossRevealed
        ? _RevealedBoss(key: const ValueKey('boss-art'), asset: bossArt, pulse: _pulse)
        : _Circle(
            key: const ValueKey('circle'),
            node: node,
            pulse: _pulse,
            accent: accent,
            regionTheme: widget.regionTheme,
            regionName: widget.regionName,
            hiddenBoss: bossHidden,
          );

    final bubble = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.duration(
              context, const Duration(milliseconds: 600),
              reduced: Duration.zero),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          // The art grows up out of the circle's base.
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
          layoutBuilder: (current, previous) => Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [...previous, if (current != null) current],
          ),
          child: figure,
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: Text(
            bossHidden ? '???' : node.name,
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
              Positioned(
                // Above the boss's head when the full art is showing.
                top: bossRevealed ? -_RevealedBoss.overhang - 14 : -10,
                child: const _YouAreHereBadge(),
              ),
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
  final RegionTheme? regionTheme;
  final String? regionName;

  /// The region boss before you reach it: its art as a dark silhouette, a
  /// dimmer ring and a lock badge.
  final bool hiddenBoss;
  const _Circle({
    super.key,
    required this.node,
    required this.pulse,
    required this.accent,
    required this.regionTheme,
    required this.regionName,
    this.hiddenBoss = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = _size(node);
    final borderWidth = node.status == ZoneNodeStatus.active ? 3.0 : 2.0;
    final isCompleted = node.status == ZoneNodeStatus.completed;
    final isLocked = node.status == ZoneNodeStatus.locked;
    final iconAsset = zoneNodeIconAsset(
      node,
      regionTheme: regionTheme,
      regionName: regionName,
    );
    Widget nodeIcon = MapIconOrEmoji(
      asset: iconAsset,
      emoji: node.emoji,
      size: _iconSize(node),
      emojiSize: _emojiSize(node),
      emojiColor: accent,
      emojiWeight: FontWeight.w700,
      visualScale: node.isBoss
          ? 1.7
          : node.isCrossroads
              ? 1.25
              : node.isChest
                  ? 1.3
                  : 1.45,
      visualOffset: node.isBoss ? const Offset(-0.75, -1.5) : Offset.zero,
    );
    if (hiddenBoss) {
      // Greyscale and nearly black: you can tell something big waits there,
      // not what.
      nodeIcon = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          .07, .07, .07, 0, 0, //
          .06, .06, .06, 0, 0, //
          .06, .06, .06, 0, 0, //
          0, 0, 0, 1, 0,
        ]),
        child: nodeIcon,
      );
    }
    final ringColor = hiddenBoss ? accent.withOpacity(0.55) : accent;

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
        borderRadius: node.isCrossroads ? BorderRadius.circular(12) : null,
        border: Border.all(color: ringColor, width: borderWidth),
      ),
      child: isCompleted && !node.isBoss
          ? Icon(Icons.check_rounded, size: _emojiSize(node) + 4, color: accent)
          : node.isCrossroads
              ? null
              : nodeIcon,
    );

    // Crossroads renders as a rotated-45° square with an upright emoji.
    if (node.isCrossroads) {
      circle = Transform.rotate(angle: 0.785398, child: circle);
      circle = Stack(alignment: Alignment.center, children: [
        circle,
        nodeIcon,
      ]);
    }

    if (hiddenBoss) {
      circle = Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          Positioned(
            right: -4,
            bottom: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A0C),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.75), width: 1.5),
              ),
              child: Icon(Icons.lock_rounded,
                  size: 12, color: accent.withOpacity(0.9)),
            ),
          ),
        ],
      );
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

  double _iconSize(ZoneNode n) {
    if (n.status == ZoneNodeStatus.active) return 34;
    if (n.isBoss) return 32;
    if (n.status == ZoneNodeStatus.locked) return 22;
    if (n.status == ZoneNodeStatus.completed) return 24;
    return 28;
  }
}

/// The region boss once you stand on its zone (or have beaten it): the full
/// boss art standing on a glowing red ground ring. It keeps a node-sized base
/// so the trail row doesn't grow; the art rises above it into the space
/// between rows.
class _RevealedBoss extends StatelessWidget {
  final String asset;
  final AnimationController pulse;
  const _RevealedBoss({super.key, required this.asset, required this.pulse});

  static const double base = 72;
  static const double artSize = 168;

  /// How far the art reaches above the base.
  static const double overhang = artSize - base - 6;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: base,
      height: base,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Ground ring under his feet, breathing with the node pulse.
          Positioned(
            bottom: -10,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, __) {
                final t = pulse.value;
                return Container(
                  width: 150,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.elliptical(75, 17)),
                    border: Border.all(
                        color: AppColors.red.withOpacity(0.45 + 0.2 * t),
                        width: 1.5),
                    gradient: RadialGradient(colors: [
                      AppColors.red.withOpacity(0.55 + 0.2 * t),
                      AppColors.red.withOpacity(0.12),
                      AppColors.red.withOpacity(0),
                    ], stops: const [0, .55, 1]),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -6,
            child: Image.asset(
              asset,
              width: artSize,
              height: artSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ],
      ),
    );
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
      return 'Chest · Opened';
    }
    if (n.status == ZoneNodeStatus.active) return 'Chest · tap to open';
    return 'Chest';
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
