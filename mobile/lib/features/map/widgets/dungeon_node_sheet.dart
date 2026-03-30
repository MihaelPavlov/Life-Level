import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../map_ui_components.dart';
import '../services/dungeon_service.dart';
import '../models/map_models.dart';

class DungeonNodeSheet extends StatefulWidget {
  final MapNodeModel node;
  final bool isCurrentNode;
  final VoidCallback onRefresh;
  final void Function(int newLevel) onLevelUp;

  const DungeonNodeSheet({
    super.key,
    required this.node,
    required this.isCurrentNode,
    required this.onRefresh,
    required this.onLevelUp,
  });

  @override
  State<DungeonNodeSheet> createState() => _DungeonNodeSheetState();
}

class _DungeonNodeSheetState extends State<DungeonNodeSheet> {
  bool _busy = false;
  String? _status;
  bool? _localDiscovered;
  int? _localFloor;
  final _service = DungeonService();

  Widget _buildStatusMessage(String status) {
    final color = status.startsWith('✓') ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _enter(String dungeonId) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await _service.enter(dungeonId);
      if (mounted) {
        setState(() {
          _busy = false;
          _localDiscovered = true;
          _status = '✓ Entered dungeon. Complete floors below.';
        });
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) setState(() {
        _busy = false;
        _status = '✗ $e';
      });
    }
  }

  Future<void> _completeFloor(String dungeonId, int floorNumber) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final result = await _service.completeFloor(dungeonId, floorNumber);
      if (mounted) {
        final xp = result['rewardXp'] as int? ?? 0;
        final isCleared = result['isFullyCleared'] as bool? ?? false;
        final newFloor = result['currentFloor'] as int? ?? floorNumber;
        setState(() {
          _busy = false;
          _localFloor = newFloor;
          _status = isCleared
              ? '✓ Dungeon cleared! +$xp XP'
              : '✓ Floor $floorNumber complete! +$xp XP';
        });
        widget.onRefresh();
        final leveledUp = result['leveledUp'] as bool? ?? false;
        final newLevel = result['newLevel'] as int? ?? 0;
        if (leveledUp && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) widget.onLevelUp(newLevel);
        }
      }
    } catch (e) {
      if (mounted) setState(() {
        _busy = false;
        _status = '✗ $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dungeon = widget.node.dungeonPortal;
    if (dungeon == null) return const SizedBox.shrink();

    final currentFloor = _localFloor ?? dungeon.currentFloor;
    final isDiscovered = _localDiscovered ?? dungeon.isDiscovered;
    final isFullyCleared = currentFloor >= dungeon.totalFloors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(dungeon.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700))),
          if (isFullyCleared)
            MapPill('✓ Cleared', color: AppColors.green)
          else if (isDiscovered)
            MapPill('Floor $currentFloor/${dungeon.totalFloors}',
                color: AppColors.purple)
          else
            MapPill('Undiscovered', color: AppColors.textSecondary),
        ]),
        const SizedBox(height: 12),
        const MapSectionLabel('FLOORS'),
        const SizedBox(height: 6),
        ...dungeon.floors.map((f) {
          final isCompleted = f.floorNumber <= currentFloor;
          final isNextFloor =
              f.floorNumber == currentFloor + 1 && isDiscovered;
          return DungeonFloorRow(
            floor: f,
            isCompleted: isCompleted,
            isNext: isNextFloor && widget.isCurrentNode,
            isBusy: _busy,
            onComplete: widget.isCurrentNode && isNextFloor && !_busy
                ? () => _completeFloor(dungeon.id, f.floorNumber)
                : null,
          );
        }),

        if (_status != null) ...[
          const SizedBox(height: 10),
          _buildStatusMessage(_status!),
        ],

        if (widget.isCurrentNode && !isDiscovered) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _busy ? null : () => _enter(dungeon.id),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('🌀 Enter Dungeon',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }
}
