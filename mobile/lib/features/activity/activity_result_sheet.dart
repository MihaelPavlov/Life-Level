import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/motion/app_motion.dart';
import '../../core/services/dungeon_floor_cleared_notifier.dart';
import '../../core/services/guild_raid_victory_notifier.dart';
import '../../core/services/inventory_full_notifier.dart';
import '../../core/services/level_up_notifier.dart';
import '../../core/services/world_zone_refresh_notifier.dart';
import '../../core/session/invalidate_user_providers.dart';
import '../../core/services/client_experience_service.dart';
import '../boss/replay/home_boss_replay.dart';
import '../map/widgets/encounter_intercept_sheet.dart';
import 'models/activity_models.dart';
import 'providers/activity_provider.dart';
import 'log_activity_screen.dart';

class ActivitySubmissionSheet extends ConsumerStatefulWidget {
  final LogActivityRequest request;
  final String operationId;
  const ActivitySubmissionSheet({
    super.key,
    required this.request,
    required this.operationId,
  });

  @override
  ConsumerState<ActivitySubmissionSheet> createState() =>
      _ActivitySubmissionSheetState();
}

class _ActivitySubmissionSheetState
    extends ConsumerState<ActivitySubmissionSheet> {
  LogActivityResult? _result;
  Object? _error;
  bool _submitting = false;
  bool _effectsApplied = false;

  @override
  void initState() {
    super.initState();
    _submit();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final started = DateTime.now();
    ClientExperienceService.instance.record(
        name: 'presentation_started',
        feature: 'activity',
        outcome: 'log_activity',
        operationId: widget.operationId);
    try {
      final result = await ref
          .read(activityServiceProvider)
          .logActivity(widget.request, operationId: widget.operationId);
      if (!mounted) return;
      _applyEffects(result);
      setState(() {
        _result = result;
        _submitting = false;
      });
      ClientExperienceService.instance.record(
          name: 'mutation_confirmed',
          feature: 'activity',
          outcome: 'log_activity',
          durationMs: DateTime.now().difference(started).inMilliseconds,
          operationId: widget.operationId);
      final encounter = result.activeEncounter;
      if (encounter != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showAppBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            isDismissible: !encounter.isBlocker,
            enableDrag: !encounter.isBlocker,
            builder: (_) => EncounterInterceptSheet(
              encounter: encounter,
              destinationZoneName: 'your destination',
            ),
          );
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _submitting = false;
      });
      ClientExperienceService.instance.record(
          name: 'mutation_rolled_back',
          feature: 'activity',
          outcome: 'log_activity',
          durationMs: DateTime.now().difference(started).inMilliseconds,
          operationId: widget.operationId);
    }
  }

  void _applyEffects(LogActivityResult result) {
    if (_effectsApplied) return;
    _effectsApplied = true;
    invalidateUserScopedProviders(ref);
    WorldZoneRefreshNotifier.notify();
    if (result.leveledUp && result.newLevel != null) {
      LevelUpNotifier.notify(result.newLevel!, unlocks: result.levelUpUnlocks);
    }
    for (final blocked in result.blockedItems) {
      InventoryFullNotifier.notify(blocked);
    }
    requestBossReplay();
    for (final raid in result.guildRaidDefeats) {
      GuildRaidVictoryNotifier.notify(raid);
    }
    final credit = result.floorCreditResult;
    if (credit != null) {
      DungeonFloorClearedNotifier.notify(DungeonFloorClearedEvent(
        dungeonName: credit.dungeonName,
        clearedFloorOrdinal: credit.clearedFloorOrdinal,
        totalFloors: credit.totalFloors,
        runCompleted: credit.runCompleted,
        bonusXpAwarded: credit.bonusXpAwarded,
      ));
    }
  }

  void _edit() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(AppRoute(
      builder: (_) => LogActivityScreen(initialRequest: widget.request),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return ActivityResultSheet(result: _result!);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_error == null ? Icons.auto_awesome : Icons.cloud_off_rounded,
                color: _error == null ? AppColors.orange : AppColors.red,
                size: 44),
            const SizedBox(height: 16),
            Text(
                _error == null
                    ? 'Finishing your workout…'
                    : 'Could not save workout',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              _error == null
                  ? 'Calculating XP, quests, and adventure progress.'
                  : 'Your activity details are preserved.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: 22),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _edit,
                    child: const Text('Edit Activity'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: const Text('Retry'),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

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
      if (r.strGained > 0)
        _StatChip(label: 'STR +${r.strGained}', color: AppColors.red),
      if (r.endGained > 0)
        _StatChip(label: 'END +${r.endGained}', color: AppColors.green),
      if (r.agiGained > 0)
        _StatChip(label: 'AGI +${r.agiGained}', color: AppColors.blue),
      if (r.flxGained > 0)
        _StatChip(label: 'FLX +${r.flxGained}', color: AppColors.purple),
      if (r.staGained > 0)
        _StatChip(label: 'STA +${r.staGained}', color: AppColors.orange),
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
                                  color:
                                      AppColors.orange.withValues(alpha: 0.4)),
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

              if (r.adventureDistanceKm > 0) ...[
                _ResultBanner(
                  icon: '🗺️',
                  text:
                      '+${formatAdventureKm(r.adventureDistanceKm)} Adventure km',
                  color: AppColors.green,
                ),
                const SizedBox(height: 16),
              ],

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

              if (r.bossCombatTurn != null) ...[
                _BossTurnCard(turn: r.bossCombatTurn!),
                const SizedBox(height: 12),
              ],

              // Streak update
              if (r.streakUpdated) ...[
                _ResultBanner(
                  icon: '🔥',
                  text:
                      'Streak: ${r.currentStreak} day${r.currentStreak != 1 ? 's' : ''}!',
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

class _BossTurnCard extends StatelessWidget {
  final BossCombatTurnInfo turn;

  const _BossTurnCard({required this.turn});

  @override
  Widget build(BuildContext context) {
    final skipped = turn.skipReason != null;
    final color = skipped ? AppColors.orange : AppColors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BOSS TURN · ${turn.bossName.toUpperCase()}',
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7)),
          const SizedBox(height: 7),
          Text(
            skipped
                ? 'Recovering — this workout earned normal rewards but did not attack.'
                : 'You dealt ${turn.damageDealt} damage · Boss ${turn.bossHpAfter}/${turn.bossMaxHp} HP',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          if (!skipped && !turn.bossDefeated) ...[
            const SizedBox(height: 5),
            Text(
              'Boss hit back for ${turn.damageTaken} · You ${turn.playerHpAfter}/${turn.playerMaxHp} HP',
              style: TextStyle(
                  color: turn.playerDefeated
                      ? AppColors.orange
                      : AppColors.textSecondary,
                  fontSize: 11),
            ),
          ],
        ],
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
