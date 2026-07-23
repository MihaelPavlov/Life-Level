import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/item_icon_image.dart';
import '../models/encounter_models.dart';

class MerchantSheet extends StatefulWidget {
  final TrailEncounterNode encounter;
  final Future<void> Function()? onNotInterested;

  const MerchantSheet({
    super.key,
    required this.encounter,
    this.onNotInterested,
  });

  @override
  State<MerchantSheet> createState() => _MerchantSheetState();
}

class _MerchantSheetState extends State<MerchantSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  bool _dismissing = false;

  MerchantEncounterData get _data => widget.encounter.merchant!;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inHours >= 24) {
      final days = d.inDays;
      final hours = d.inHours % 24;
      return '${days}d ${hours}h';
    }
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 32, offset: Offset(0, -8))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildTimerRow(),
                    const SizedBox(height: 14),
                    _buildItemsHeader(),
                    const SizedBox(height: 10),
                    ..._data.items.map(_buildItemRow),
                    const SizedBox(height: 4),
                    _buildDismissButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.orange.withOpacity(0.4)),
          ),
          alignment: Alignment.center,
          child: const Text('🪙', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WANDERING MERCHANT',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              Text(
                _data.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const Text(
                'Appears on your path · Rare goods',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.orange.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _blink,
                builder: (_, __) => Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange.withOpacity(0.4 + 0.6 * _blink.value),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Leaves in ${_formatDuration(_data.timeLeft)}',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '· Gone after timer expires',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildItemsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'AVAILABLE ITEMS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.orange.withOpacity(0.3)),
          ),
          child: Text(
            '⭐ ${_data.playerXp} XP',
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(MerchantItem item) {
    final rarityColor = _rarityColor(item.rarity);
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase coming soon'),
          duration: Duration(seconds: 2),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rarityColor.withOpacity(0.3)),
              ),
              alignment: Alignment.center,
              child: ItemIconImage(
                itemId: item.itemId ?? '',
                itemName: item.name,
                emojiFallback: item.emoji,
                size: 32,
                emojiSize: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.rarity.toUpperCase() +
                        (item.rarity == 'mystery' ? ' MYSTERY' : ''),
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.xpCost}',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'XP',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissButton() {
    return OutlinedButton(
      onPressed: _dismissing ? null : _handleNotInterested,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      child: Text(_dismissing ? 'Continuing...' : 'Not interested · Let merchant pass'),
    );
  }

  Future<void> _handleNotInterested() async {
    final callback = widget.onNotInterested;
    if (callback == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _dismissing = true);
    try {
      await callback();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _dismissing = false);
    }
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'rare':     return AppColors.blue;
      case 'uncommon': return AppColors.green;
      case 'mystery':  return AppColors.purple;
      default:         return AppColors.textSecondary;
    }
  }
}
