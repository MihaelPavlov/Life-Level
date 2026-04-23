import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/world_map_models.dart';
import 'world_map_theme.dart';

/// Single row in the region-detail vertical trail. Renders:
///   • colored ring containing the zone emoji
///   • name, tier, description
///   • distance + XP on the right
///   • skull / fork accent for boss / crossroads nodes
class ZoneNodeTile extends StatefulWidget {
  final ZoneNode node;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const ZoneNodeTile({
    super.key,
    required this.node,
    required this.isFirst,
    required this.isLast,
    this.onTap,
  });

  @override
  State<ZoneNodeTile> createState() => _ZoneNodeTileState();
}

class _ZoneNodeTileState extends State<ZoneNodeTile>
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
    final colors = ZoneNodeColors.of(node.status);

    final highlight = node.isBoss
        ? AppColors.red
        : node.isCrossroads
            ? AppColors.purple
            : colors.accent;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Rail(
              isFirst: widget.isFirst,
              isLast: widget.isLast,
              accent: highlight,
              status: node.status,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _NodeCircle(node: node, pulse: _pulse),
                    const SizedBox(width: 12),
                    Expanded(child: _Body(node: node, colors: colors)),
                    const SizedBox(width: 8),
                    _MetaColumn(node: node),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Rail extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Color accent;
  final ZoneNodeStatus status;
  const _Rail({
    required this.isFirst,
    required this.isLast,
    required this.accent,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final solid = status == ZoneNodeStatus.completed ||
        status == ZoneNodeStatus.active;
    final color = solid
        ? accent.withOpacity(0.6)
        : AppColors.border.withOpacity(0.8);

    return SizedBox(
      width: 36,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 2,
              color: isFirst ? Colors.transparent : color,
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeCircle extends StatelessWidget {
  final ZoneNode node;
  final AnimationController pulse;
  const _NodeCircle({required this.node, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final colors = ZoneNodeColors.of(node.status);
    final accent = node.isBoss
        ? AppColors.red
        : node.isCrossroads
            ? AppColors.purple
            : colors.accent;
    final size = node.status == ZoneNodeStatus.active
        ? 58.0
        : node.isBoss
            ? 56.0
            : 48.0;
    final emojiSize = node.status == ZoneNodeStatus.active ? 26.0 : 22.0;

    Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.22), accent.withOpacity(0.08)],
        ),
        shape: node.isCrossroads ? BoxShape.rectangle : BoxShape.circle,
        borderRadius:
            node.isCrossroads ? BorderRadius.circular(12) : null,
        border: Border.all(
          color: accent,
          width: node.status == ZoneNodeStatus.active ? 2.5 : 2,
          style: node.status == ZoneNodeStatus.next
              ? BorderStyle.solid
              : BorderStyle.solid,
        ),
      ),
      child: Transform.rotate(
        angle: node.isCrossroads ? 0 : 0,
        child: Text(
          node.status == ZoneNodeStatus.completed ? '✓' : node.emoji,
          style: TextStyle(
            fontSize: emojiSize,
            color: node.status == ZoneNodeStatus.completed ? accent : null,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    if (node.isCrossroads) {
      circle = Transform.rotate(angle: 0.785398, child: circle);
      circle = Stack(alignment: Alignment.center, children: [
        circle,
        Text(
          node.emoji,
          style: TextStyle(fontSize: emojiSize, color: accent),
        ),
      ]);
    }

    if (node.status == ZoneNodeStatus.active) {
      return AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          final t = pulse.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.35 + 0.25 * t),
                  blurRadius: 22 + 10 * t,
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
}

class _Body extends StatelessWidget {
  final ZoneNode node;
  final ZoneNodeColors colors;
  const _Body({required this.node, required this.colors});

  @override
  Widget build(BuildContext context) {
    final chipColor = node.isBoss
        ? AppColors.red
        : node.isCrossroads
            ? AppColors.purple
            : colors.accent;

    final labels = <String>[];
    if (node.status == ZoneNodeStatus.active) labels.add('You are here');
    if (node.status == ZoneNodeStatus.next) labels.add('Destination');
    if (node.isCrossroads) labels.add('Crossroads');
    if (node.isBoss) labels.add('Boss');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(
              node.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'T${node.tier}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ]),
        if (node.description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            node.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: labels
                .map((l) => _Pill(label: l, color: chipColor))
                .toList(),
          ),
        ],
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  final ZoneNode node;
  const _MetaColumn({required this.node});

  @override
  Widget build(BuildContext context) {
    if (node.isCrossroads) return const SizedBox.shrink();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (node.distanceKm > 0)
          Text(
            '${node.distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (node.xpReward > 0) ...[
          const SizedBox(height: 2),
          Text(
            '+${node.xpReward} XP',
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}
