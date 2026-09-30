import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../../core/widgets/app_toast.dart';
import '../../character/providers/character_provider.dart';
import '../widgets/mode_ui.dart';
import 'delve_engine.dart';
import 'delve_provider.dart';

const _cursedBg = Color(0xFF1B1428);
const _treasureBg = Color(0xFF0F1D33);
const _failRed = Color(0xFFFF8B84);

Color _pathColor(DelvePath p) => switch (p) {
      DelvePath.safe => AppColors.green,
      DelvePath.treasure => AppColors.blue,
      DelvePath.cursed => AppColors.purple,
    };

/// One Treasure Delve run, from chamber 1 to banking or failing.
class DelveRunScreen extends ConsumerWidget {
  const DelveRunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(delveRunProvider);
    if (run == null) return const SizedBox.shrink();
    final done = run.phase == DelvePhase.result;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context, ref, run);
      },
      child: ModeScaffold(
        title: switch (run.phase) {
          DelvePhase.result => 'TREASURE DELVE',
          DelvePhase.challenge =>
            'CHAMBER ${run.chamber + 1} · ${run.chosen!.path.title.toUpperCase()}',
          _ => 'CHAMBER ${run.chamber + 1} OF $kDelveChambers',
        },
        glow: switch (run.phase) {
          DelvePhase.challenge => const Color(0xFF0F2645),
          DelvePhase.result when run.end == DelveEnd.failed =>
            const Color(0xFF2A1215),
          _ => const Color(0xFF2A1F0A),
        },
        onBack: () => _leave(context, ref, run),
        trailing: done ? null : ModeCoinChip(modeFmt(run.total)),
        child: AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotionTokens.micro),
          child: KeyedSubtree(
            key: ValueKey('${run.chamber}-${run.phase}'),
            child: switch (run.phase) {
              DelvePhase.choosing => _Choosing(run: run),
              DelvePhase.challenge => _Challenge(run: run),
              DelvePhase.decision => _Decision(run: run),
              DelvePhase.result => _Result(run: run),
            },
          ),
        ),
      ),
    );
  }

  /// Leaving mid-run banks what the player has; leaving the result screen
  /// closes the run.
  Future<void> _leave(BuildContext context, WidgetRef ref, DelveRun run) async {
    final notifier = ref.read(delveRunProvider.notifier);
    if (run.phase == DelvePhase.result) {
      await _collect(context, ref, run);
      return;
    }
    final leave = await showAppBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _LeaveSheet(run: run),
    );
    if (leave == true) notifier.bank();
  }
}

Future<void> _collect(BuildContext context, WidgetRef ref, DelveRun run) async {
  final notifier = ref.read(delveRunProvider.notifier);
  if (run.payout > 0) {
    AppToast.show(
      context,
      '+${modeFmt(run.payout)} coins from the vault',
      detail: run.cleared.length >= 5
          ? '+2 Talent Crystals'
          : run.cleared.length >= 3
              ? '+1 Talent Crystal'
              : null,
    );
  }
  // Pop first so the screen never renders without a run.
  Navigator.of(context).pop();
  await notifier.finish();
}

// ── Coin header ─────────────────────────────────────────────────────────────

class _Purse extends StatelessWidget {
  final DelveRun run;
  const _Purse({required this.run});

  @override
  Widget build(BuildContext context) => ModePanel(
        border: kGold.withValues(alpha: .4),
        child: Row(
          children: [
            const AppIconImage(AppIcons.homeCoinIcon, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ModeLabel('SECURED'),
                  Text(modeFmt(run.secured),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: kGoldLight,
                          height: 1.1)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const ModeLabel('AT RISK'),
                Text(run.atRisk > 0 ? '+${modeFmt(run.atRisk)}' : '0',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: run.atRisk > 0
                            ? kBurnOrange
                            : AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      );
}

// ── Choosing ────────────────────────────────────────────────────────────────

class _Choosing extends ConsumerStatefulWidget {
  final DelveRun run;
  const _Choosing({required this.run});

  @override
  ConsumerState<_Choosing> createState() => _ChoosingState();
}

class _ChoosingState extends ConsumerState<_Choosing> {
  late DelveOption _selected = widget.run.options[1];

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Purse(run: run),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChamberRail(current: run.chamber),
              const SizedBox(width: 14),
              Expanded(
                child: ListView(
                  children: [
                    const Text('Choose your path',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    for (final o in run.options) ...[
                      _PathCard(
                        option: o,
                        selected: identical(o, _selected),
                        onTap: () => setState(() => _selected = o),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ModeCta.blue(
          label: 'Take the ${_selected.path.title}',
          onTap: () => ref.read(delveRunProvider.notifier).choose(_selected),
        ),
      ],
    );
  }
}

class _ChamberRail extends StatelessWidget {
  final int current;
  const _ChamberRail({required this.current});

  @override
  Widget build(BuildContext context) {
    final nodes = <Widget>[];
    for (var i = 0; i < kDelveChambers; i++) {
      if (i > 0) {
        nodes.add(Container(
          width: 3,
          height: 44,
          color: i <= current ? AppColors.green : AppColors.border,
        ));
      }
      nodes.add(_node(i));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: SizedBox(width: 36, child: Column(children: nodes)),
    );
  }

  Widget _node(int i) {
    if (i < current) {
      return Container(
        width: 30,
        height: 30,
        decoration:
            const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
        child:
            const Icon(Icons.check_rounded, size: 18, color: Color(0xFF04130A)),
      );
    }
    if (i == current) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kDelveGlowDark,
          shape: BoxShape.circle,
          border: Border.all(color: kGold, width: 3),
          boxShadow: [
            BoxShadow(color: kGold.withValues(alpha: .6), blurRadius: 18),
          ],
        ),
        alignment: Alignment.center,
        child: Text('${i + 1}',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, color: kGoldLight)),
      );
    }
    final last = i == kDelveChambers - 1;
    return Container(
      width: last ? 36 : 30,
      height: last ? 36 : 30,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      alignment: Alignment.center,
      child: last
          ? const Opacity(
              opacity: .6,
              child: AppIconImage(AppIcons.rewardTreasureChest, size: 22))
          : Text('${i + 1}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary)),
    );
  }
}

const kDelveGlowDark = Color(0xFF2A1F0A);

class _PathCard extends StatelessWidget {
  final DelveOption option;
  final bool selected;
  final VoidCallback onTap;

  const _PathCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _pathColor(option.path);
    final bg = switch (option.path) {
      DelvePath.safe => AppColors.surface,
      DelvePath.treasure => _treasureBg,
      DelvePath.cursed => _cursedBg,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.path.title}, ${option.path.difficulty.toLowerCase()}, '
          '${option.coins} coins',
      child: AppPressable(
        onTap: onTap,
        pressedScale: .98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? color : color.withValues(alpha: .45),
                width: selected ? 2 : 1.5),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: .3), blurRadius: 20)
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(option.path.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color.lerp(color, Colors.white, .3))),
                  ),
                  _Tag(option.path.difficulty,
                      color: option.path == DelvePath.cursed
                          ? AppColors.red
                          : color),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  AppIconImage(option.event.stat.icon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        '${option.event.title} · ${option.event.stat.short}',
                        style: const TextStyle(fontSize: 12.5, color: kBody)),
                  ),
                  const AppIconImage(AppIcons.homeCoinIcon, size: 14),
                  const SizedBox(width: 4),
                  Text('+${option.coins}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
              if (option.path.itemChance > 0 || option.boosted) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (option.path.itemChance > 0)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIconImage(AppIcons.shopChestRare, size: 16),
                          SizedBox(width: 4),
                          Text('Chance of an item',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purple)),
                        ],
                      ),
                    if (option.boosted)
                      Text('Modifier +${(kDelveModifierBonus * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: kGold)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Color.lerp(color, Colors.white, .3))),
      );
}

// ── Challenge ───────────────────────────────────────────────────────────────

class _Challenge extends ConsumerWidget {
  final DelveRun run;
  const _Challenge({required this.run});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = run.chosen!;
    final profile = ref.watch(characterProfileProvider).valueOrNull;
    final stat = profile == null ? 0 : o.event.stat.valueFor(profile);
    final odds = o.odds;
    final oddsColor = switch (odds) {
      DelveOdds.certain || DelveOdds.high => AppColors.green,
      DelveOdds.good => AppColors.blue,
      DelveOdds.risky => AppColors.orange,
      DelveOdds.low => AppColors.red,
    };
    final scaleMax = ((o.recommended > stat ? o.recommended : stat) * 1.4)
        .clamp(10, 999)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.blue.withValues(alpha: .35),
                      AppColors.blue.withValues(alpha: 0),
                    ]),
                    border: Border.all(
                        color: AppColors.blue.withValues(alpha: .55), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: AppIconImage(o.event.stat.icon, size: 84),
                ),
              ),
              const SizedBox(height: 12),
              Text('${o.event.stat.name.toUpperCase()} CHALLENGE',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                      color: Color(0xFF7DB6FF))),
              Text(o.event.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(o.event.flavour,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, height: 1.45, color: kBody)),
              const SizedBox(height: 18),
              ModePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!o.path.guaranteed) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Your ${o.event.stat.short}',
                              style:
                                  const TextStyle(fontSize: 13, color: kBody)),
                          Text('$stat',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.blue)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _StatBar(
                          value: stat / scaleMax,
                          marker: o.recommended / scaleMax),
                      const SizedBox(height: 8),
                      Text('Recommended: ${o.recommended}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: oddsColor.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: oddsColor.withValues(alpha: .4)),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < 5; i++)
                            Container(
                              width: 8,
                              height: 16,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: i < odds.segments
                                    ? oddsColor
                                    : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(odds.label,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: oddsColor)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Outcome(
                      label: 'IF YOU CLEAR IT',
                      color: AppColors.green,
                      text: '+${o.coins}',
                      extra: o.path.itemChance > 0 ? ' + item?' : null,
                    ),
                  ),
                  if (!o.path.guaranteed) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Outcome(
                        label: 'IF YOU FAIL',
                        color: _failRed,
                        text: 'Keep ${modeFmt(run.secured)}',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ModeCta.blue(
          label: o.path.guaranteed
              ? 'Walk through'
              : 'Take on the ${o.event.title}',
          onTap: () => ref.read(delveRunProvider.notifier).attempt(),
        ),
        TextButton(
          onPressed: () => ref.read(delveRunProvider.notifier).backToPaths(),
          child: const Text('Pick another path',
              style: TextStyle(color: kBody, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  final double value;
  final double marker;
  const _StatBar({required this.value, required this.marker});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => SizedBox(
          height: 22,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: c.maxWidth * value.clamp(0, 1),
                height: 12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2F6FC4), AppColors.blue]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Positioned(
                left: (c.maxWidth * marker.clamp(0, 1)) - 1.5,
                child: Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _Outcome extends StatelessWidget {
  final String label;
  final Color color;
  final String text;
  final String? extra;

  const _Outcome({
    required this.label,
    required this.color,
    required this.text,
    this.extra,
  });

  @override
  Widget build(BuildContext context) => ModePanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModeLabel(label, color: color),
            const SizedBox(height: 5),
            Row(
              children: [
                const AppIconImage(AppIcons.homeCoinIcon, size: 16),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(text,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                if (extra != null)
                  Text(extra!,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple)),
              ],
            ),
          ],
        ),
      );
}

// ── Decision ────────────────────────────────────────────────────────────────

class _Decision extends ConsumerWidget {
  final DelveRun run;
  const _Decision({required this.run});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = run.total;
    final securedShare = total == 0 ? 1.0 : run.secured / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.green.withValues(alpha: .45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.green),
                      const SizedBox(width: 6),
                      Text('${run.chosen!.event.title} cleared',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.green)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                  child: AppIconImage(AppIcons.homeCoinIcon, size: 72)),
              const SizedBox(height: 8),
              const Text('IN YOUR BAG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                      color: Color(0xFFC9D4E3))),
              Text(modeFmt(total),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: kGoldLight)),
              if (run.lastItem) ...[
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIconImage(AppIcons.shopChestRare, size: 20),
                    SizedBox(width: 6),
                    Text('You found an item!',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.purple)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ModePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: SizedBox(
                        height: 14,
                        child: Row(
                          children: [
                            Expanded(
                              flex: (securedShare * 100).round().clamp(1, 100),
                              child: const ColoredBox(color: kGold),
                            ),
                            if (run.atRisk > 0) ...[
                              const SizedBox(width: 3),
                              Expanded(
                                flex: ((1 - securedShare) * 100)
                                    .round()
                                    .clamp(1, 100),
                                child:
                                    const ColoredBox(color: Color(0xFFB8621A)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ModeLabel('SECURED · ALWAYS KEPT'),
                              Text(modeFmt(run.secured),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: kGoldLight)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const ModeLabel('AT RISK'),
                            Text('+${modeFmt(run.atRisk)}',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: kBurnOrange)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ModePanel(
                color: _cursedBg,
                border: AppColors.purple.withValues(alpha: .45),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.purple, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text('${run.chamber + 2}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFC9A7FF))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Continue to chamber ${run.chamber + 2}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                              'Rewards ×$kDelveDepthMultiplier · fail and you keep ${modeFmt(run.secured)}',
                              style:
                                  const TextStyle(fontSize: 12, color: kBody)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ModeCta.blue(
          label: 'Continue deeper',
          icon: Icons.arrow_downward_rounded,
          onTap: () => ref.read(delveRunProvider.notifier).continueDeeper(),
        ),
        const SizedBox(height: 10),
        ModeOutlineCta(
          label: 'Bank ${modeFmt(total)} coins',
          leading: const AppIconImage(AppIcons.homeCoinIcon, size: 20),
          onTap: () => ref.read(delveRunProvider.notifier).bank(),
        ),
      ],
    );
  }
}

// ── Result ──────────────────────────────────────────────────────────────────

class _Result extends ConsumerWidget {
  final DelveRun run;
  const _Result({required this.run});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = run.end == DelveEnd.failed;
    final runsLeft = ref.watch(delveStatusProvider).valueOrNull?.runsLeft;
    final (String kicker, Color kickerColor) = switch (run.end) {
      DelveEnd.failed => ('THE VAULT FOUGHT BACK', _failRed),
      DelveEnd.cleared => ('VAULT CLEARED', kGold),
      _ => ('VAULT BANKED', kGold),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              Center(
                child: ModeGlowArt(
                  asset: failed
                      ? AppIcons.rewardTreasureChest
                      : AppIcons.rewardChestBurst,
                  glow: failed ? AppColors.red : kGoldLight,
                  size: 150,
                ),
              ),
              Text(kicker,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: kickerColor)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIconImage(AppIcons.homeCoinIcon, size: 44),
                    const SizedBox(width: 10),
                    Text('+${modeFmt(run.payout)}',
                        style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: kGoldLight)),
                  ],
                ),
              ),
              if (failed)
                Text(
                  run.secured > 0
                      ? 'You kept your ${modeFmt(run.secured)} secured coins.'
                      : 'Nothing was secured this time.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: kBody),
                ),
              const SizedBox(height: 16),
              ModePanel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    _Row(
                      label: 'Chambers cleared',
                      value: Text('${run.cleared.length} of $kDelveChambers',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                    if (run.cleared.isNotEmpty)
                      _Row(
                        label: 'Paths taken',
                        value: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final p in run.cleared)
                              Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  color: _pathColor(p).withValues(alpha: .2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _pathColor(p)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (failed)
                      _Row(
                        label: 'Lost in the vault',
                        value: const Text('At-risk coins',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _failRed)),
                        last: run.itemsFound == 0,
                      ),
                    if (run.itemsFound > 0)
                      _Row(
                        label: 'Items found',
                        value: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIconImage(AppIcons.shopChestRare,
                                size: 20),
                            const SizedBox(width: 6),
                            Text('${run.itemsFound}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.purple)),
                          ],
                        ),
                        last: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (runsLeft != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIconImage(AppIcons.itemEnergyGel, size: 18),
              const SizedBox(width: 6),
              Text(
                runsLeft == 0
                    ? 'No runs left today'
                    : '$runsLeft ${runsLeft == 1 ? 'run' : 'runs'} left today',
                style: const TextStyle(fontSize: 12.5, color: kBody),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        ModeCta(
          label: run.payout > 0
              ? 'Collect ${modeFmt(run.payout)} coins'
              : 'Leave the vault',
          onTap: () => _collect(context, ref, run),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final Widget value;
  final bool last;

  const _Row({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.surfaceElevated)),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 13, color: kBody))),
            value,
          ],
        ),
      );
}

// ── Leave mid-run ───────────────────────────────────────────────────────────

class _LeaveSheet extends StatelessWidget {
  final DelveRun run;
  const _LeaveSheet({required this.run});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: EdgeInsets.fromLTRB(
            16, 20, 16, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Leave the vault?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              run.total > 0
                  ? 'You bank ${modeFmt(run.total)} coins and this run ends.'
                  : 'This run ends and it still counts as used.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kBody),
            ),
            const SizedBox(height: 18),
            ModeCta(
              label: run.total > 0 ? 'Bank and leave' : 'Leave',
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            ModeOutlineCta(
              label: 'Keep delving',
              color: AppColors.blue,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
}
