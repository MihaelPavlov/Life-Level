import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../map_colors.dart';
import '../map_ui_components.dart';
import '../map_banners.dart';
import '../map_debug_panel.dart';
import '../services/boss_service.dart';
import '../models/map_models.dart';

class BossNodeSheet extends StatefulWidget {
  final MapNodeModel node;
  final bool isCurrentNode;
  final VoidCallback onRefresh;
  final void Function(int newLevel) onLevelUp;

  const BossNodeSheet({
    super.key,
    required this.node,
    required this.isCurrentNode,
    required this.onRefresh,
    required this.onLevelUp,
  });

  @override
  State<BossNodeSheet> createState() => _BossNodeSheetState();
}

class _BossNodeSheetState extends State<BossNodeSheet> {
  bool _busy = false;
  String? _status;
  int? _localHpDealt;
  bool? _localDefeated;
  bool? _localActivated;
  bool? _localExpired;
  final _service = BossService();

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

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

  Future<void> _activate(String bossId) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await _service.activateFight(bossId);
      if (mounted) {
        final timerDays = widget.node.boss?.timerDays ?? 7;
        setState(() {
          _busy = false;
          _localActivated = true;
          _status = '✓ Fight activated! ${timerDays}d timer started.';
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

  Future<void> _damage(String bossId, int damage) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final result = await _service.dealDamage(bossId, damage);
      if (mounted) {
        final defeated = result['isDefeated'] as bool? ?? false;
        final justDefeated = result['justDefeated'] as bool? ?? false;
        final newHpDealt = result['hpDealt'] as int? ?? 0;
        final maxHp = result['maxHp'] as int? ?? 0;
        final xp = result['rewardXpAwarded'] as int? ?? 0;
        setState(() {
          _busy = false;
          _localHpDealt = newHpDealt;
          if (defeated) _localDefeated = true;
          _status = defeated
              ? '✓ DEFEATED! +$xp XP awarded!'
              : '✓ -$damage HP dealt ($newHpDealt/$maxHp)';
        });
        widget.onRefresh();
        if (justDefeated && mounted) {
          _showBossSlainOverlay(context, boss: widget.node.boss!, xpAwarded: xp);
          final leveledUp = result['leveledUp'] as bool? ?? false;
          final newLevel = result['newLevel'] as int? ?? 0;
          if (leveledUp) {
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) widget.onLevelUp(newLevel);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() {
        _busy = false;
        _status = '✗ $e';
      });
    }
  }

  void _showBossSlainOverlay(BuildContext context,
      {required BossData boss, required int xpAwarded}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) =>
          BossSlainOverlay(boss: boss, xpAwarded: xpAwarded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boss = widget.node.boss;
    if (boss == null) return const SizedBox.shrink();

    final hpDealt = _localHpDealt ?? boss.hpDealt;
    final isDefeated = _localDefeated ?? boss.isDefeated;
    final isActivated = _localActivated ?? boss.isActivated;
    final isExpired = _localExpired ?? boss.isExpired;

    final hpRemaining = boss.maxHp - hpDealt;
    final hpPct =
        isDefeated ? 0.0 : (hpRemaining / boss.maxHp).clamp(0.0, 1.0);
    final hpBarColor = isDefeated
        ? AppColors.green
        : isExpired
            ? AppColors.textSecondary
            : AppColors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(boss.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(boss.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              if (boss.isMini)
                const Text('Mini Boss · No travel required',
                    style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
            ],
          )),
          const SizedBox(width: 8),
          if (isDefeated)
            MapPill('✓ Defeated', color: AppColors.green)
          else if (isExpired)
            MapPill('⌛ Expired', color: AppColors.textSecondary)
          else if (isActivated)
            MapPill('⚔️ Active', color: AppColors.orange),
        ]),
        const SizedBox(height: 10),

        const MapSectionLabel('HP'),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hpPct,
            minHeight: 8,
            backgroundColor: kMapSurface2,
            valueColor: AlwaysStoppedAnimation(hpBarColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Text('$hpDealt dealt',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
          const Spacer(),
          Text('$hpRemaining / ${boss.maxHp} HP remaining',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 10),

        Wrap(spacing: 8, runSpacing: 6, children: [
          MapInfoChip('⚡ ${boss.rewardXp} XP reward'),
          MapInfoChip('⏱ ${boss.timerDays}d timer'),
          if (boss.isMini) MapInfoChip('🌍 Fight anywhere'),
          if (boss.timerExpiresAt != null && !isDefeated && !isExpired)
            MapInfoChip('🗓 Expires ${_formatDate(boss.timerExpiresAt!)}'),
          if (boss.defeatedAt != null)
            MapInfoChip('🏆 Defeated ${_formatDate(boss.defeatedAt!)}'),
        ]),

        if (_status != null) ...[
          const SizedBox(height: 10),
          _buildStatusMessage(_status!),
        ],

        if ((widget.isCurrentNode || boss.isMini) && !isDefeated) ...[
          const SizedBox(height: 14),
          if (!isActivated && !isExpired) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      boss.isMini ? AppColors.orange : AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _busy ? null : () => _activate(boss.id),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        boss.isMini
                            ? '⚡ Challenge Mini Boss'
                            : '⚔️ Activate Fight',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ] else if (isActivated && !isExpired) ...[
            const MapSectionLabel('DEAL DAMAGE'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [10, 25, 50, 100, 200]
                  .map((dmg) => DebugButton(
                        label: '-$dmg HP',
                        color:
                            boss.isMini ? AppColors.orange : AppColors.red,
                        onTap: _busy ? null : () => _damage(boss.id, dmg),
                      ))
                  .toList(),
            ),
          ] else if (isExpired) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kMapSurface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kMapBorder),
              ),
              child: const Row(children: [
                Text('⌛', style: TextStyle(fontSize: 16)),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                  'Timer expired. Use the debug panel to reset.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                )),
              ]),
            ),
          ],
        ],
      ],
    );
  }
}
