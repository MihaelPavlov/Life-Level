import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'map_colors.dart';
import 'map_ui_components.dart';
import 'services/map_service.dart';
import 'models/map_models.dart';
import 'widgets/boss_node_sheet.dart';
import 'widgets/chest_node_sheet.dart';
import 'widgets/dungeon_node_sheet.dart';
import 'widgets/crossroads_node_sheet.dart';
import 'widgets/zone_node_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NodeDetailSheet
// ─────────────────────────────────────────────────────────────────────────────
class NodeDetailSheet extends StatefulWidget {
  final MapNodeModel node;
  final bool isAdjacent;
  final double? distanceKm;
  final UserMapProgressModel userProgress;
  final VoidCallback onDestinationSet;
  final VoidCallback onRefresh;
  final void Function(int newLevel) onLevelUp;

  const NodeDetailSheet({
    super.key,
    required this.node,
    required this.isAdjacent,
    this.distanceKm,
    required this.userProgress,
    required this.onDestinationSet,
    required this.onRefresh,
    required this.onLevelUp,
  });

  @override
  State<NodeDetailSheet> createState() => _NodeDetailSheetState();
}

class _NodeDetailSheetState extends State<NodeDetailSheet> {
  bool _settingDestination = false;

  bool get _isLevelMet =>
      widget.node.isStartNode || (widget.node.userState?.isLevelMet ?? false);
  bool get _isCurrentNode => widget.node.userState?.isCurrentNode ?? false;
  bool get _isDestination => widget.node.userState?.isDestination ?? false;

  Future<void> _setDestination() async {
    setState(() => _settingDestination = true);
    try {
      await MapService().setDestination(widget.node.id);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDestinationSet();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _settingDestination = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = mapNodeColor(widget.node.type);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: kMapBorder, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: color.withOpacity(0.4), width: 1.5),
                          ),
                          child: Center(
                              child: Text(widget.node.icon,
                                  style: const TextStyle(fontSize: 26))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.node.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Wrap(spacing: 6, children: [
                                MapPill(widget.node.region,
                                    color: AppColors.purple),
                                MapPill('Lv ${widget.node.levelRequirement}+',
                                    color: _isLevelMet
                                        ? AppColors.green
                                        : AppColors.orange),
                                if (_isCurrentNode)
                                  MapPill('📍 Here', color: AppColors.green),
                                if (_isDestination)
                                  MapPill('🎯 Destination',
                                      color: AppColors.orange),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (!_isLevelMet) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kMapSurface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kMapBorder),
                        ),
                        child: Row(children: [
                          const Text('🔒', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                            'Reach level ${widget.node.levelRequirement} to unlock this location.',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          )),
                        ]),
                      ),
                    ] else ...[
                      if (widget.node.description != null) ...[
                        Text(widget.node.description!,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.5)),
                        const SizedBox(height: 16),
                      ],
                      _buildTypeContent(),
                      if ((widget.userProgress.pendingDistanceKm ?? 0) > 0) ...[
                        const SizedBox(height: 16),
                        _buildReserveKmRow(),
                      ],
                      const SizedBox(height: 16),
                      _buildDestinationButton(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeContent() {
    switch (widget.node.type) {
      case 'Boss':
        return BossNodeSheet(
          node: widget.node,
          isCurrentNode: _isCurrentNode,
          onRefresh: widget.onRefresh,
          onLevelUp: widget.onLevelUp,
        );
      case 'Chest':
        return ChestNodeSheet(
          node: widget.node,
          isCurrentNode: _isCurrentNode,
          onRefresh: widget.onRefresh,
          onLevelUp: widget.onLevelUp,
        );
      case 'Dungeon':
        return DungeonNodeSheet(
          node: widget.node,
          isCurrentNode: _isCurrentNode,
          onRefresh: widget.onRefresh,
          onLevelUp: widget.onLevelUp,
        );
      case 'Crossroads':
        return CrossroadsNodeSheet(
          node: widget.node,
          isCurrentNode: _isCurrentNode,
          onRefresh: widget.onRefresh,
          onLevelUp: widget.onLevelUp,
        );
      default:
        return ZoneNodeSheet(
          node: widget.node,
          isCurrentNode: _isCurrentNode,
          distanceKm: widget.distanceKm,
        );
    }
  }

  Widget _buildReserveKmRow() {
    final km = widget.userProgress.pendingDistanceKm!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.08),
        border: Border.all(color: AppColors.purple.withOpacity(0.28)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('\u26a1', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RESERVE KM',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Banked from recent activities',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${km.toStringAsFixed(2)} km',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationButton() {
    if (_isCurrentNode) return const SizedBox.shrink();
    if (!widget.isAdjacent) {
      return Text('Not reachable from current location',
          style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12));
    }
    if (_isDestination) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.orange.withOpacity(0.4)),
        ),
        child: const Center(
            child: Text('🎯 Currently Heading Here',
                style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w600))),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _settingDestination ? null : _setDestination,
        child: _settingDestination
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(
                'Set Destination → ${widget.distanceKm != null ? "${widget.distanceKm!.toStringAsFixed(1)} km" : ""}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}
