import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/world_zone_refresh_notifier.dart';
import '../map_ui_components.dart';
import '../services/crossroads_service.dart';
import '../models/map_models.dart';

class CrossroadsNodeSheet extends StatefulWidget {
  final MapNodeModel node;
  final bool isCurrentNode;
  final VoidCallback onRefresh;
  final void Function(int newLevel) onLevelUp;

  const CrossroadsNodeSheet({
    super.key,
    required this.node,
    required this.isCurrentNode,
    required this.onRefresh,
    required this.onLevelUp,
  });

  @override
  State<CrossroadsNodeSheet> createState() => _CrossroadsNodeSheetState();
}

class _CrossroadsNodeSheetState extends State<CrossroadsNodeSheet> {
  bool _busy = false;
  String? _status;
  final _service = CrossroadsService();

  Widget _buildStatusMessage(String status) {
    final isSuccess = status.startsWith('✓');
    final color = isSuccess ? AppColors.orange : AppColors.red;
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

  Future<void> _choosePath(String crossroadsId, String pathId) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final result = await _service.choosePath(crossroadsId, pathId);
      if (mounted) {
        final name = result['pathName'] as String? ?? '';
        setState(() {
          _busy = false;
          _status = '✓ "$name" chosen — journey begins!';
        });
        widget.onRefresh();
        WorldZoneRefreshNotifier.notify();
        final leveledUp = result['leveledUp'] as bool? ?? false;
        final newLevel = result['newLevel'] as int? ?? 0;
        if (leveledUp && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
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
    final crossroads = widget.node.crossroads;
    if (crossroads == null) return const SizedBox.shrink();
    final hasChosen = crossroads.chosenPathId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Expanded(child: MapSectionLabel('CHOOSE YOUR PATH')),
          if (hasChosen) MapPill('Path chosen', color: AppColors.orange),
        ]),
        const SizedBox(height: 8),
        if (!hasChosen && widget.isCurrentNode)
          const Text(
            'Tap a path to commit to it. This cannot be changed.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        if (!hasChosen && widget.isCurrentNode) const SizedBox(height: 10),
        ...crossroads.paths.map((p) {
          final isChosen = crossroads.chosenPathId == p.id;
          final canChoose = !hasChosen && widget.isCurrentNode && !_busy;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SelectablePathCard(
              path: p,
              isChosen: isChosen,
              isDisabled: hasChosen && !isChosen,
              canChoose: canChoose,
              onTap: canChoose ? () => _choosePath(crossroads.id, p.id) : null,
            ),
          );
        }),

        if (_status != null) ...[
          const SizedBox(height: 4),
          _buildStatusMessage(_status!),
        ],
      ],
    );
  }
}
