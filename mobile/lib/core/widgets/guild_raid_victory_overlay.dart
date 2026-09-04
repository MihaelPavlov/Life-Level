import 'package:flutter/material.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/boss/widgets/boss_icon.dart';
import '../constants/app_colors.dart';

Future<void> showGuildRaidVictoryOverlay(
  BuildContext context,
  GuildRaidVictoryInfo info,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss guild raid victory popup',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 420),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.16),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.86, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
    pageBuilder: (ctx, _, __) => _GuildRaidVictoryDialog(info: info),
  );
}

class _GuildRaidVictoryDialog extends StatefulWidget {
  final GuildRaidVictoryInfo info;
  const _GuildRaidVictoryDialog({required this.info});

  @override
  State<_GuildRaidVictoryDialog> createState() => _GuildRaidVictoryDialogState();
}

class _GuildRaidVictoryDialogState extends State<_GuildRaidVictoryDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    const accent = AppColors.purple;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 340,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.38)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 48,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GUILD RAID CLEARED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 22),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final t = _pulse.value;
                  return Container(
                    width: 118,
                    height: 118,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.24),
                          AppColors.red.withValues(alpha: 0.06),
                        ],
                      ),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.62),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.34 + 0.22 * t),
                          blurRadius: 30 + 16 * t,
                          spreadRadius: 2 + 3 * t,
                        ),
                      ],
                    ),
                    child: BossIcon(
                      icon: info.bossIcon.isEmpty ? '?' : info.bossIcon,
                      size: 94,
                      emojiSize: 54,
                      visualScale: info.bossIcon.startsWith('assets/') ? 1.28 : 1,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Raid boss defeated',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${info.bossName} fell to your guild.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.orange.withValues(alpha: 0.22),
                      AppColors.orange.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'RAID REWARD',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _RewardMetric(
                            label: 'Base',
                            value: '+${info.rewardXp}',
                            color: AppColors.orange,
                          ),
                        ),
                        if (info.mvpBonusXp > 0) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RewardMetric(
                              label: 'MVP',
                              value: '+${info.mvpBonusXp}',
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (info.totalDamage > 0 ||
                  info.yourDamage > 0 ||
                  (info.topContributorUsername?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.85),
                    ),
                  ),
                  child: Column(
                    children: [
                      _RaidStatRow(
                        label: 'Your damage',
                        value: '${info.yourDamage}',
                      ),
                      if (info.totalDamage > 0)
                        _RaidStatRow(
                          label: 'Guild damage',
                          value: '${info.totalDamage}',
                        ),
                      if (info.topContributorUsername?.isNotEmpty ?? false)
                        _RaidStatRow(
                          label: 'Top contributor',
                          value:
                              '${info.topContributorUsername} (${info.topContributorDamage})',
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
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
                  child: const Text('Claim'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RewardMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$value XP',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _RaidStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _RaidStatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
