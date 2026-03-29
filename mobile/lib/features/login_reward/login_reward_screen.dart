import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/level_up_notifier.dart';
import '../character/providers/character_provider.dart';
import 'models/login_reward_models.dart';
import 'providers/login_reward_provider.dart';

class LoginRewardScreen extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const LoginRewardScreen({super.key, required this.onDismiss});

  @override
  ConsumerState<LoginRewardScreen> createState() => _LoginRewardScreenState();
}

class _LoginRewardScreenState extends ConsumerState<LoginRewardScreen> {
  bool _claiming = false;
  LoginRewardClaimResult? _claimed;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(loginRewardStatusProvider);

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: _buildModal,
    );
  }

  Widget _buildModal(LoginRewardStatus status) {
    // If already claimed today and we have not just claimed in this session,
    // dismiss immediately so the dialog does not show on re-entry.
    if (status.claimedToday && _claimed == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDismiss());
      return const SizedBox.shrink();
    }

    final currentDay = _claimed?.dayInCycle ?? status.dayInCycle;

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF161b22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.15),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Text(
                    'Daily Reward',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day $currentDay of 7',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 7-day cycle row
                  _SevenDayCycle(currentDay: currentDay),
                  const SizedBox(height: 24),

                  // Reward display
                  if (_claimed == null) ...[
                    const Text(
                      "TODAY'S REWARD",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        Text(
                          '+${status.nextRewardXp} XP',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (status.nextRewardIncludesShield) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('🛡️', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 6),
                          Text(
                            '+ Streak Shield',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (status.nextRewardIsXpStorm) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('⚡', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 6),
                          Text(
                            '+ XP Storm!',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    // Claimed state
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+${_claimed!.xpAwarded} XP Claimed!',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_claimed!.includesShield) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('🛡️', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 6),
                          Text(
                            'Streak Shield Added!',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_claimed!.isXpStorm) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('⚡', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 6),
                          Text(
                            'XP Storm Activated!',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _claiming
                          ? null
                          : (_claimed != null ? widget.onDismiss : _claim),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _claimed != null
                            ? AppColors.green
                            : AppColors.blue,
                        disabledBackgroundColor:
                            AppColors.blue.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _claiming
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _claimed != null ? 'Continue' : 'Claim Reward',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _claim() async {
    setState(() => _claiming = true);
    try {
      final result =
          await ref.read(loginRewardServiceProvider).claimReward();
      setState(() {
        _claimed = result;
        _claiming = false;
      });
      // Refresh character profile so XP/level updates everywhere.
      ref.invalidate(characterProfileProvider);
      // Fire level-up overlay if applicable.
      if (result.leveledUp && result.newLevel != null) {
        LevelUpNotifier.notify(result.newLevel!);
      }
    } catch (e) {
      setState(() => _claiming = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim reward: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }
}

// ── Seven-day cycle row ────────────────────────────────────────────────────────
class _SevenDayCycle extends StatelessWidget {
  final int currentDay; // 1–7

  const _SevenDayCycle({required this.currentDay});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isPast = day < currentDay;
        final isToday = day == currentDay;
        final hasShield = day == 3;
        final hasStorm = day == 7;

        return Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPast
                    ? AppColors.green.withValues(alpha: 0.3)
                    : isToday
                        ? AppColors.blue
                        : const Color(0xFF1e2632),
                border: Border.all(
                  color: isToday
                      ? AppColors.blue
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isPast
                    ? const Icon(
                        Icons.check,
                        color: AppColors.green,
                        size: 16,
                      )
                    : hasShield && isToday
                        ? const Text(
                            '🛡️',
                            style: TextStyle(fontSize: 14),
                          )
                        : hasStorm && isToday
                            ? const Text(
                                '⚡',
                                style: TextStyle(fontSize: 14),
                              )
                            : Text(
                                '$day',
                                style: TextStyle(
                                  color: isToday
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'D$day',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        );
      }),
    );
  }
}
