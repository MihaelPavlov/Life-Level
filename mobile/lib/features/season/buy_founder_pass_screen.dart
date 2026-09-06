import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_toast.dart';
import 'models/season_models.dart';
import 'providers/season_provider.dart';
import 'widgets/season_theme.dart';

class BuyFounderPassScreen extends ConsumerStatefulWidget {
  final String theme;
  const BuyFounderPassScreen({super.key, this.theme = 'ember'});

  @override
  ConsumerState<BuyFounderPassScreen> createState() => _BuyFounderPassScreenState();
}

class _BuyFounderPassScreenState extends ConsumerState<BuyFounderPassScreen> {
  bool _busy = false;

  Future<void> _unlock() async {
    setState(() => _busy = true);
    try {
      await ref.read(seasonProvider.notifier).purchaseFounderPass();
      if (!mounted) return;
      AppToast.success(context, 'Founder Pass unlocked!', icon: Icons.lock_open_rounded);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = SeasonAccent.of(widget.theme);
    final track = ref.watch(seasonProvider).valueOrNull;
    final founderRewards = <SeasonTier>[
      if (track != null)
        ...track.tiers.where((t) => t.founder.type != 'None' && !t.isMilestone),
    ];
    final milestone = track?.tiers
        .where((t) => t.isMilestone)
        .cast<SeasonTier?>()
        .firstWhere((_) => true, orElse: () => null);
    final freeCount = track == null
        ? 0
        : track.tiers.where((t) => t.free.type != 'None').length;
    final founderCount = track == null
        ? 0
        : track.tiers.where((t) => t.founder.type != 'None').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text('FOUNDER PASS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppColors.textPrimary,
                        )),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Hero band
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: accent.accent.withValues(alpha: 0.4)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.accent.withValues(alpha: 0.20),
                          AppColors.purple.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          seasonIconAsset('item_aura_stone'),
                          width: 58,
                          height: 58,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text('🔥',
                              style: TextStyle(fontSize: 44)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SEASON ${track?.season?.number ?? 1}',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                    color: accent.accent),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track?.season?.name ?? 'Season',
                                style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Value line
                  Row(
                    children: [
                      const Text('Founder Pass',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary)),
                      const SizedBox(width: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Free in testing',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF05101f))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Unlocks the Founder lane for every tier, all season. '
                    'One unlock — keeps delivering as you climb.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Free vs Founder
                  Row(
                    children: [
                      Expanded(
                        child: _CompareCard(
                          label: 'FREE · you have this',
                          value: '$freeCount',
                          sub: 'rewards this season',
                          accent: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CompareCard(
                          label: 'FOUNDER',
                          value: '+$founderCount',
                          sub: 'extra · higher rarity',
                          accent: accent.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const Text('WHAT YOU GET',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ...founderRewards.take(8).map((t) => _GiveRow(tier: t)),
                  if (founderRewards.length > 8)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '+ ${founderRewards.length - 8} more Founder rewards across the track',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 9.5, color: AppColors.textMuted),
                      ),
                    ),

                  if (milestone != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3a2a52)),
                        gradient: LinearGradient(colors: [
                          AppColors.purple.withValues(alpha: 0.16),
                          accent.accent.withValues(alpha: 0.07),
                        ]),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            seasonIconAsset(milestone.founder.iconKey),
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.emoji_events_rounded,
                                size: 36,
                                color: AppColors.purple),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'TIER ${milestone.tier} · SEASON FINALE',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: AppColors.purple)),
                                const SizedBox(height: 2),
                                Text(milestone.founder.label,
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary)),
                                const Text('Carries between seasons',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_rounded, size: 14, color: AppColors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Everything you\'ve '),
                              TextSpan(
                                  text: 'already reached',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700)),
                              TextSpan(
                                  text:
                                      ' unlocks instantly as claimable — you still tap each to collect it.'),
                            ],
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sticky CTA
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _busy ? null : _unlock,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Unlock the Founder Pass',
                              style: TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('No payment required in this build',
                      style: TextStyle(fontSize: 8.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color accent;
  const _CompareCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: accent)),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: accent == AppColors.textSecondary
                      ? AppColors.textPrimary
                      : accent)),
          const SizedBox(height: 1),
          Text(sub,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _GiveRow extends StatelessWidget {
  final SeasonTier tier;
  const _GiveRow({required this.tier});

  @override
  Widget build(BuildContext context) {
    final r = tier.founder;
    final rarityColor = seasonRarityColor(r.rarity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset(
            seasonIconAsset(r.iconKey),
            width: 30,
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard_rounded,
                size: 24, color: AppColors.textMuted),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.label,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                if (rarityColor != null)
                  Text((r.rarity ?? '').toUpperCase(),
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: rarityColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('Tier ${tier.tier}',
                style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
