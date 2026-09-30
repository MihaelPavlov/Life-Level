import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../character/providers/character_provider.dart';
import '../widgets/mode_ui.dart';
import 'delve_engine.dart';
import 'delve_provider.dart';
import 'delve_run_screen.dart';

const kDelveGlow = Color(0xFF2A1F0A);

/// Vault entrance: today's reward, modifier, runs left and the way in.
class TreasureDelveScreen extends ConsumerWidget {
  const TreasureDelveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(delveStatusProvider);
    final profile = ref.watch(characterProfileProvider).valueOrNull;
    final coins = profile?.talents?.coins ?? 0;

    return ModeScaffold(
      title: 'TREASURE DELVE',
      glow: kDelveGlow,
      trailing: ModeCoinChip(modeFmt(coins), color: AppColors.textPrimary),
      child: switch (status) {
        AsyncData(:final value) when profile != null => _Entrance(
            status: value,
            strongest: strongestStat(profile),
            strongestValue: strongestStat(profile).valueFor(profile)),
        AsyncError() => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(delveStatusProvider),
              child: const Text('Couldn\'t load. Try again'),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator(color: kGold)),
      },
    );
  }
}

class _Entrance extends ConsumerWidget {
  final DelveStatus status;
  final DelveStat strongest;
  final int strongestValue;

  const _Entrance({
    required this.status,
    required this.strongest,
    required this.strongestValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEnter = status.activeRun != null || status.runsLeft > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              const Center(
                child: ModeGlowArt(
                    asset: AppIcons.shopChestLegendary, glow: kGold, size: 160),
              ),
              const Text(
                'The Gilded Vault',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: kGoldLight),
              ),
              const SizedBox(height: 6),
              const Text(
                '$kDelveChambers chambers below. Push deeper for bigger hauls, '
                'and bank before your luck runs out.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.45, color: kBody),
              ),
              const SizedBox(height: 18),
              GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 92,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Stat(
                    label: 'POSSIBLE REWARD',
                    child: Row(children: [
                      const AppIconImage(AppIcons.homeCoinIcon, size: 20),
                      const SizedBox(width: 6),
                      Text(modeFmt(delveMaxReward()),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: kGoldLight)),
                    ]),
                  ),
                  const _Stat(
                    label: 'CHAMBERS',
                    child: Text('$kDelveChambers',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  _Stat(
                    label: 'TODAY\'S MODIFIER',
                    border: kGold.withValues(alpha: .45),
                    child: Row(children: [
                      AppIconImage(status.featured.icon, size: 22),
                      const SizedBox(width: 6),
                      Text('${status.featured.short} rooms ',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('+${(kDelveModifierBonus * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kGold)),
                    ]),
                  ),
                  _Stat(
                    label: 'YOUR BEST STAT',
                    child: Row(children: [
                      AppIconImage(strongest.icon, size: 22),
                      const SizedBox(width: 6),
                      Text('${strongest.short} ',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('$strongestValue',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _EnergyStrip(status: status),
              if (status.bestRun > 0) ...[
                const SizedBox(height: 8),
                Text('Best run: ${modeFmt(status.bestRun)} coins',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ModeCta(
          label: status.activeRun == null ? 'ENTER THE VAULT' : 'RESUME RUN',
          onTap: canEnter
              ? () async {
                  final ok = await ref.read(delveRunProvider.notifier).start();
                  if (ok && context.mounted) {
                    Navigator.push(context,
                        AppRoute(builder: (_) => const DelveRunScreen()));
                  }
                }
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          status.activeRun != null
              ? 'Your current run is waiting'
              : canEnter
              ? 'Uses 1 of your ${status.runsLeft} ${status.runsLeft == 1 ? 'run' : 'runs'}'
              : 'No runs left today',
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final Widget child;
  final Color? border;

  const _Stat({required this.label, required this.child, this.border});

  @override
  Widget build(BuildContext context) => ModePanel(
        border: border,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ModeLabel(label),
            const SizedBox(height: 6),
            FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: child),
          ],
        ),
      );
}

/// Where today's runs came from, or how to earn one.
class _EnergyStrip extends StatelessWidget {
  final DelveStatus status;
  const _EnergyStrip({required this.status});

  @override
  Widget build(BuildContext context) {
    final String text;
    if (status.runsEarned == 0) {
      text = 'Log a 20-min workout to earn a run (45 min earns 2)';
    } else if (status.runsEarned >= kDelveMaxRunsPerDay) {
      text = 'Daily maximum of $kDelveMaxRunsPerDay runs earned';
    } else {
      text = 'Earned from today\'s workouts. A 45-min workout earns 2.';
    }
    final hasRuns = status.runsLeft > 0;
    final color = hasRuns ? AppColors.green : AppColors.textSecondary;
    return ModePanel(
      color: color.withValues(alpha: .1),
      border: color.withValues(alpha: .35),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const AppIconImage(AppIcons.itemEnergyGel, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 12.5, color: Color(0xFFC9D4E3))),
          ),
          const SizedBox(width: 8),
          Text(
            '${status.runsLeft} / ${status.runsEarned}',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
