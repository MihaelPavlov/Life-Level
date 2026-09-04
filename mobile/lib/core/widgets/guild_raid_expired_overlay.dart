import 'package:flutter/material.dart';
import '../../features/boss/widgets/boss_icon.dart';
import '../../features/guild/models/guild_models.dart';
import '../constants/app_colors.dart';

Future<void> showGuildRaidExpiredOverlay(
  BuildContext context,
  GuildRaidExpiredInfo info,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss guild raid expired popup',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 360),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, _, __) => _GuildRaidExpiredDialog(info: info),
  );
}

class _GuildRaidExpiredDialog extends StatelessWidget {
  final GuildRaidExpiredInfo info;

  const _GuildRaidExpiredDialog({required this.info});

  @override
  Widget build(BuildContext context) {
    final progress = info.maxHp <= 0 ? 0.0 : info.totalDamage / info.maxHp;
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 340,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.42)),
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withValues(alpha: 0.18),
                blurRadius: 44,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GUILD RAID EXPIRED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.red,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 112,
                height: 112,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.58),
                    width: 2,
                  ),
                ),
                child: BossIcon(
                  icon: info.bossIcon.isEmpty ? '?' : info.bossIcon,
                  size: 90,
                  emojiSize: 52,
                  visualScale: info.bossIcon.startsWith('assets/') ? 1.24 : 1,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                info.bossName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The raid timer ended before the guild could finish the boss.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  height: 12,
                  color: AppColors.surface,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                    child: Container(color: AppColors.red),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ExpiredMetric(
                    label: 'Damage',
                    value: '${info.totalDamage}/${info.maxHp}',
                  ),
                  const SizedBox(width: 10),
                  _ExpiredMetric(
                    label: 'HP missed',
                    value: '${info.remainingHp}',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiredMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ExpiredMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
