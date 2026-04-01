import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'models/activity_models.dart';

class ActivityResultSheet extends StatefulWidget {
  final LogActivityResult result;

  const ActivityResultSheet({super.key, required this.result});

  @override
  State<ActivityResultSheet> createState() => _ActivityResultSheetState();
}

class _ActivityResultSheetState extends State<ActivityResultSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _xpAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _xpAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    final statGains = <_StatChip>[
      if (r.strGained > 0) _StatChip(label: 'STR +${r.strGained}', color: AppColors.red),
      if (r.endGained > 0) _StatChip(label: 'END +${r.endGained}', color: AppColors.green),
      if (r.agiGained > 0) _StatChip(label: 'AGI +${r.agiGained}', color: AppColors.blue),
      if (r.flxGained > 0) _StatChip(label: 'FLX +${r.flxGained}', color: AppColors.purple),
      if (r.staGained > 0) _StatChip(label: 'STA +${r.staGained}', color: AppColors.orange),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Center(
                child: Text(
                  'Workout Complete! 💪',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // XP gained (animated counter)
              Center(
                child: AnimatedBuilder(
                  animation: _xpAnim,
                  builder: (_, __) {
                    final displayed = (r.xpGained * _xpAnim.value).round();
                    return Column(
                      children: [
                        Text(
                          '+$displayed XP',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'XP Gained',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (r.xpBonusApplied > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.orange
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '\u26a1 +${r.xpBonusApplied} XP from gear',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Stat gain chips
              if (statGains.isNotEmpty) ...[
                const Text(
                  'STAT GAINS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statGains.map((chip) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: chip.color.withValues(alpha: 0.12),
                        border: Border.all(
                          color: chip.color.withValues(alpha: 0.35),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chip.label,
                        style: TextStyle(
                          color: chip.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Streak update
              if (r.streakUpdated) ...[
                _ResultBanner(
                  icon: '🔥',
                  text: 'Streak: ${r.currentStreak} day${r.currentStreak != 1 ? 's' : ''}!',
                  color: AppColors.orange,
                ),
                const SizedBox(height: 8),
              ],

              // Completed quests
              if (r.completedQuests.isNotEmpty) ...[
                const Text(
                  'QUESTS COMPLETED',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ...r.completedQuests.map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '+${q.rewardXp} XP',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],


              // All daily quests bonus
              if (r.allDailyQuestsCompleted) ...[
                _ResultBanner(
                  icon: '🎯',
                  text: 'All Daily Quests Done! +${r.bonusXpAwarded} XP Bonus!',
                  color: AppColors.green,
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(
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
    );
  }
}

class _StatChip {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});
}

class _ResultBanner extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const _ResultBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
