import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/encounter_models.dart';

class BlockerSheet extends StatelessWidget {
  final TrailEncounterNode encounter;
  final VoidCallback? onFight;

  const BlockerSheet({super.key, required this.encounter, this.onFight});

  BlockerEncounterData get _data => encounter.blocker!;

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    if (days > 0) return '${days}d ${hours}h';
    return '${d.inHours}h ${d.inMinutes % 60}m';
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
                child: _data.isInCombat ? _buildInCombat(context) : _buildInitial(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isInCombat: false),
        const SizedBox(height: 12),
        _buildTimerPill(_formatDuration(_data.retreatsIn)),
        const SizedBox(height: 14),
        _buildHpBar(),
        const SizedBox(height: 14),
        _buildInfoBox(
          color: AppColors.red,
          title: 'YOUR JOURNEY IS PAUSED',
          rows: [
            _InfoRow(
              icon: '⛔',
              text:
                  'Progress toward ${_data.blockedZoneName} is frozen until this creature is defeated or retreats.',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildInfoBox(
          color: AppColors.green,
          title: 'HOW TO DEAL DAMAGE',
          rows: [
            _InfoRow(
              icon: '🏋',
              text: 'Log any workout → damage scales with duration & calories burned',
            ),
            _InfoRow(
              icon: '🏃',
              text: 'Running & cycling deal bonus damage to this type of blocker',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildRewards(),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onFight?.call();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            '⚔️ Start Fighting · Log a Workout',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          child: Text('Wait for it to retreat (${_formatDuration(_data.retreatsIn)})'),
        ),
      ],
    );
  }

  Widget _buildInCombat(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isInCombat: true),
        const SizedBox(height: 14),
        _buildHpBar(),
        const SizedBox(height: 12),
        _buildDamageTracker(),
        const SizedBox(height: 12),
        _buildInfoBox(
          color: AppColors.red,
          title: 'JOURNEY STILL PAUSED',
          rows: [
            _InfoRow(
              icon: '📍',
              text:
                  'Journey to ${_data.blockedZoneName} unfreezes the moment HP reaches 0.',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildEstimateCard(),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onFight?.call();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            '🏋 Log Workout · Deal More Damage',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required bool isInCombat}) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.red.withOpacity(0.4)),
          ),
          alignment: Alignment.center,
          child: const Text('🐺', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isInCombat ? '⚔️ IN COMBAT' : '⛔ PATH BLOCKER',
                style: const TextStyle(
                  color: AppColors.red,
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
              Text(
                isInCombat && _data.lastHitDescription != null
                    ? 'Your last hit: ${_data.lastHitDescription}'
                    : 'Mini-boss · Blocking ${_data.blockedZoneName}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.red.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.red,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Retreats in $label if ignored',
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHpBar() {
    final frac = _data.hpFraction.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🔥 BOSS HP',
              style: TextStyle(
                color: AppColors.red,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${_data.currentHp} / ${_data.maxHp}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF0d1117),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.red.withOpacity(0.25)),
          ),
          clipBehavior: Clip.hardEdge,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: frac,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFf85149), Color(0xFFff6b3d)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required Color color,
    required String title,
    required List<_InfoRow> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.text,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRewards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DEFEAT REWARDS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _data.rewards.map((r) => _RewardChip(label: r)).toList(),
        ),
      ],
    );
  }

  Widget _buildDamageTracker() {
    final frac = (_data.playerDamageDone / _data.maxHp).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR DAMAGE',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Text('🧝', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0d1117),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: frac,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFf85149), Color(0xFFff6b3d)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_data.playerDamageDone} dmg',
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstimateCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EST. TO DEFEAT',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '~1 more workout',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'RETREATS IN',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDuration(_data.retreatsIn),
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
}

class _RewardChip extends StatelessWidget {
  final String label;
  const _RewardChip({required this.label});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.orange;
    if (label.contains('Item')) color = AppColors.blue;
    if (label.contains('unblocked') || label.contains('Journey')) {
      color = AppColors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
