import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/level_up_notifier.dart';
import '../../character/providers/character_provider.dart';
import '../../login_reward/models/login_reward_models.dart';
import '../../login_reward/providers/login_reward_provider.dart';

/// Small pending/claimed chip shown on home as a re-entry point to the
/// login-reward flow. When the user dismisses the auto-modal in MainShell,
/// this chip is the only way back to claim.
///
/// Matches `.home3-reward` + `.home3-reward--claimed` in home-v3.html.
/// Hides itself entirely while the status is loading or errors out so it
/// never flashes during app start.
class HomeLoginRewardChip extends ConsumerStatefulWidget {
  const HomeLoginRewardChip({super.key});

  @override
  ConsumerState<HomeLoginRewardChip> createState() =>
      _HomeLoginRewardChipState();
}

class _HomeLoginRewardChipState
    extends ConsumerState<HomeLoginRewardChip> {
  bool _claiming = false;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(loginRewardStatusProvider);

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        if (status.claimedToday) {
          return _ClaimedVariant(status: status);
        }
        return _PendingVariant(
          status: status,
          claiming: _claiming,
          onClaim: _handleClaim,
        );
      },
    );
  }

  Future<void> _handleClaim() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    try {
      final service = ref.read(loginRewardServiceProvider);
      final result = await service.claimReward();

      if (result.leveledUp && result.newLevel != null) {
        LevelUpNotifier.notify(result.newLevel!);
      }

      // Refresh everything the reward touches.
      ref.invalidate(loginRewardStatusProvider);
      ref.invalidate(characterProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '+${result.xpAwarded} XP claimed'
              '${result.includesShield ? ' \u00B7 +Shield' : ''}'
              '${result.isXpStorm ? ' \u00B7 XP Storm!' : ''}',
            ),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim failed: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }
}

// ── PENDING VARIANT ───────────────────────────────────────────────────────────
class _PendingVariant extends StatelessWidget {
  final LoginRewardStatus status;
  final bool claiming;
  final VoidCallback onClaim;

  const _PendingVariant({
    required this.status,
    required this.claiming,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.1),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.orange.withValues(alpha: 0.22),
                    AppColors.orange.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.45),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                '\uD83C\uDF81', // 🎁
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAY ${status.dayInCycle} REWARD READY',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _Pips(currentDay: status.dayInCycle),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _ClaimButton(claiming: claiming, onTap: onClaim),
          ],
        ),
      ),
    );
  }

  String _subtitle(LoginRewardStatus status) {
    final parts = <String>['Claim +${status.nextRewardXp} XP'];
    if (status.nextRewardIncludesShield) parts.add('+Shield');
    if (status.nextRewardIsXpStorm) parts.add('XP Storm!');
    return parts.join(' \u00B7 ');
  }
}

class _Pips extends StatelessWidget {
  final int currentDay;
  const _Pips({required this.currentDay});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final day = i + 1;
        final isDone = day < currentDay;
        final isCurrent = day == currentDay;
        Color color;
        List<BoxShadow>? shadow;
        if (isCurrent) {
          color = AppColors.orange;
          shadow = [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.6),
              blurRadius: 6,
            ),
          ];
        } else if (isDone) {
          color = AppColors.orange;
          shadow = null;
        } else {
          color = AppColors.surfaceElevated;
          shadow = null;
        }
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == 6 ? 0 : 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: shadow,
            ),
          ),
        );
      }),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final bool claiming;
  final VoidCallback onTap;

  const _ClaimButton({required this.claiming, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: claiming ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.orange, Color(0xFFd4881a)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.35),
              blurRadius: 14,
            ),
          ],
        ),
        child: claiming
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Claim',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }
}

// ── CLAIMED VARIANT (collapsed line) ─────────────────────────────────────────
class _ClaimedVariant extends StatelessWidget {
  final LoginRewardStatus status;

  const _ClaimedVariant({required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.35),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text(
                '\u2713',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DAY ${status.dayInCycle} CLAIMED',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Text(
                    'Next reward unlocks tomorrow',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
