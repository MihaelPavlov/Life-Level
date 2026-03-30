import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../map_colors.dart';
import '../map_ui_components.dart';
import '../map_banners.dart';
import '../services/chest_service.dart';
import '../models/map_models.dart';

class ChestNodeSheet extends StatefulWidget {
  final MapNodeModel node;
  final bool isCurrentNode;
  final VoidCallback onRefresh;
  final void Function(int newLevel) onLevelUp;

  const ChestNodeSheet({
    super.key,
    required this.node,
    required this.isCurrentNode,
    required this.onRefresh,
    required this.onLevelUp,
  });

  @override
  State<ChestNodeSheet> createState() => _ChestNodeSheetState();
}

class _ChestNodeSheetState extends State<ChestNodeSheet> {
  bool _busy = false;
  String? _status;
  bool? _localCollected;
  final _service = ChestService();

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

  Future<void> _collect(String chestId) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final result = await _service.collect(chestId);
      if (mounted) {
        final xp = result['rewardXp'] as int? ?? 0;
        final rarity = result['rarity'] as String? ?? '';
        setState(() {
          _busy = false;
          _localCollected = true;
        });
        widget.onRefresh();
        if (mounted) _showChestRewardDialog(rarity, xp);
        final leveledUp = result['leveledUp'] as bool? ?? false;
        final newLevel = result['newLevel'] as int? ?? 0;
        if (leveledUp && mounted) {
          await Future.delayed(const Duration(seconds: 2));
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

  void _showChestRewardDialog(String rarity, int xp) {
    final color = mapRarityColor(rarity);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => ChestRewardDialog(rarity: rarity, xp: xp, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chest = widget.node.chest;
    if (chest == null) return const SizedBox.shrink();
    final isCollected = _localCollected ?? chest.isCollected;
    final rarityColor = mapRarityColor(chest.rarity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          MapPill(chest.rarity, color: rarityColor),
          const SizedBox(width: 8),
          MapInfoChip('⚡ ${chest.rewardXp} XP'),
          const SizedBox(width: 8),
          if (isCollected) MapPill('✓ Collected', color: AppColors.green),
        ]),

        if (_status != null) ...[
          const SizedBox(height: 10),
          _buildStatusMessage(_status!),
        ],

        if (widget.isCurrentNode && !isCollected) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kMapGold,
                foregroundColor: const Color(0xFF1a1000),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _busy ? null : () => _collect(chest.id),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Color(0xFF1a1000), strokeWidth: 2))
                  : const Text('📦 Open Chest',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }
}
