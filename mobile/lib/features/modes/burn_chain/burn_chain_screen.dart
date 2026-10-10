import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../../core/widgets/app_toast.dart';
import '../../activity/log_activity_screen.dart';
import '../../activity/models/activity_models.dart';
import '../widgets/mode_ui.dart';
import 'burn_chain_provider.dart';
import 'burn_chain_rules.dart';

const _glow = Color(0xFF2E1508);

class BurnChainScreen extends ConsumerStatefulWidget {
  const BurnChainScreen({super.key});

  @override
  ConsumerState<BurnChainScreen> createState() => _BurnChainScreenState();
}

class _BurnChainScreenState extends ConsumerState<BurnChainScreen> {
  bool _celebrating = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(burnChainProvider);
    final view = async.valueOrNull;
    if (view != null) _maybeCelebrate(view);

    final chain = view?.chain;
    return ModeScaffold(
      title: chain?.phase == BurnChainPhase.live
          ? 'BURN CHAIN · LIVE'
          : 'BURN CHAIN',
      glow: _glow,
      trailing: chain != null && chain.links.isNotEmpty
          ? ModeCoinChip('+${modeFmt(chain.totalCoins)}')
          : null,
      child: switch (async) {
        AsyncData(:final value) => AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotionTokens.micro),
            child: switch (value.chain.phase) {
              BurnChainPhase.idle => const _Intro(key: ValueKey('idle')),
              BurnChainPhase.live =>
                _Live(chain: value.chain, key: const ValueKey('live')),
              BurnChainPhase.ended =>
                _Ended(chain: value.chain, key: const ValueKey('ended')),
              BurnChainPhase.cooldown =>
                _Cooldown(chain: value.chain, key: const ValueKey('cooldown')),
            },
          ),
        AsyncError() =>
          _Error(onRetry: () => ref.read(burnChainProvider.notifier).refresh()),
        _ => const Center(child: CircularProgressIndicator(color: kBurnOrange)),
      },
    );
  }

  /// Shows the ×2 moment once for a new beat; other new links are just
  /// marked seen (the live list or the end screen already shows them).
  void _maybeCelebrate(BurnChainView view) {
    final link = view.unseenLink;
    if (link == null || _celebrating) return;
    _celebrating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (link.kind == ChainLinkKind.beat) {
        await showBurnChainBeat(context, link, view.chain);
      }
      await ref.read(burnChainProvider.notifier).markSeen();
      _celebrating = false;
    });
  }
}

// ── Idle: how it works + start ──────────────────────────────────────────────

class _Intro extends ConsumerWidget {
  const _Intro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: const [
              Center(
                child: ModeGlowArt(
                    asset: AppIcons.rewardStreakFire,
                    glow: kBurnOrange,
                    size: 110),
              ),
              Text(
                'Beat your last burn',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: kBurnOrangeLight),
              ),
              SizedBox(height: 6),
              Text(
                'For 24 hours, every workout you log or import joins the chain.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.45, color: kBody),
              ),
              SizedBox(height: 18),
              _Rule(
                badge: Text('1',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                badgeColor: AppColors.surfaceElevated,
                title: 'First workout sets the bar',
                body:
                    'It pays 1 coin per 5 calories and becomes the number to beat.',
              ),
              SizedBox(height: 10),
              _Rule(
                badge: Text('×2',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: kBurnInk)),
                badgeColor: kBurnOrange,
                highlight: true,
                title: 'Burn more, earn double',
                body:
                    'Beat the bar and its coin reward pays ×2. It becomes the new bar.',
              ),
              SizedBox(height: 10),
              _Rule(
                badge: Icon(Icons.link_off_rounded,
                    size: 18, color: Color(0xFFFF8B84)),
                badgeColor: Color(0xFF2A1215),
                title: 'Burn less and the chain breaks',
                body: 'That workout still pays × 1, then the chain ends.',
              ),
              SizedBox(height: 10),
              Text(
                'Workouts under $kBurnChainMinMinutes minutes don\'t count.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ModeCta.burn(
          label: 'START 24H CHAIN',
          onTap: () async {
            try {
              await ref.read(burnChainProvider.notifier).start();
            } catch (error) {
              if (context.mounted) {
                AppToast.error(
                    context,
                    playerErrorMessage(error,
                        fallback: 'Could not start Burn Chain.'));
              }
            }
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Workouts from before you start don\'t count',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  final Widget badge;
  final Color badgeColor;
  final String title;
  final String body;
  final bool highlight;

  const _Rule({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.body,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => ModePanel(
        color: highlight ? const Color(0xFF22140A) : AppColors.surface,
        border: highlight ? kBurnOrange : null,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: badge,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(body,
                      style: const TextStyle(
                          fontSize: 12, height: 1.35, color: kBody)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Live ────────────────────────────────────────────────────────────────────

class _Live extends ConsumerWidget {
  final BurnChainState chain;
  const _Live({required this.chain, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now().toUtc();
    final left = chain.timeLeft(now);
    final progress = left.inSeconds / kBurnChainWindow.inSeconds;
    final bar = chain.bar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            color: kBurnOrange,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.read(burnChainProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Center(
                  child: _BarRing(
                    progress: progress,
                    label: bar == null ? 'FIRST WORKOUT' : 'BAR TO BEAT',
                    value: bar == null ? '—' : '$bar',
                    unit: bar == null ? 'sets the bar' : 'kcal',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: kBurnOrange),
                    const SizedBox(width: 6),
                    Text('${modeDuration(left)} left',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 18),
                const ModeLabel('YOUR CHAIN'),
                const SizedBox(height: 8),
                for (final link in chain.links) ...[
                  _LinkRow(link: link),
                  const _Connector(),
                ],
                _NextSlot(bar: bar),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ModeCta.blue(
          label: 'Log workout',
          icon: Icons.add_rounded,
          onTap: () async {
            await Navigator.push(
                context, AppRoute(builder: (_) => const LogActivityScreen()));
            await ref.read(burnChainProvider.notifier).refresh();
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Imported workouts join the chain automatically',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _BarRing extends StatelessWidget {
  final double progress;
  final String label;
  final String value;
  final String unit;

  const _BarRing({
    required this.progress,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 210,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _RingPainter(progress.clamp(0, 1))),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: kBody)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        color: kBurnOrangeLight)),
                Text(unit,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kBody)),
              ],
            ),
          ],
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = kBurnOrange.withValues(alpha: .16));
    canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = kBurnOrange);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _LinkRow extends StatelessWidget {
  final ChainLink link;
  const _LinkRow({required this.link});

  @override
  Widget build(BuildContext context) {
    final type = _activityType(link.type);
    final (Color bg, Color? border) = switch (link.kind) {
      ChainLinkKind.beat => (const Color(0xFF22140A), kBurnOrange),
      ChainLinkKind.breaker => (
          const Color(0xFF1C1012),
          const Color(0x80F85149)
        ),
      ChainLinkKind.base => (AppColors.surface, null),
    };
    final detail = switch (link.kind) {
      ChainLinkKind.base => '${link.calories} kcal · sets the bar',
      ChainLinkKind.beat =>
        '${link.calories} kcal · beat ${link.barBefore} · ×$kBurnChainBeatMultiplier',
      ChainLinkKind.breaker =>
        '${link.calories} kcal · ${link.barBefore! - link.calories} short, chain broken',
    };
    return ModePanel(
      color: bg,
      border: border,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: type == null
                ? const Icon(Icons.fitness_center_rounded,
                    size: 20, color: kBody)
                : AppIconImage(type.iconAsset, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${type?.displayName ?? link.type} · ${link.durationMinutes} min',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(detail,
                    style: TextStyle(
                        fontSize: 12,
                        color: link.kind == ChainLinkKind.breaker
                            ? const Color(0xFFFF8B84)
                            : kBody)),
              ],
            ),
          ),
          const AppIconImage(AppIcons.homeCoinIcon, size: 16),
          const SizedBox(width: 4),
          Text('+${modeFmt(link.coins)}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: kGoldLight)),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 33),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(width: 2, height: 14, color: kBurnOrange),
        ),
      );
}

class _NextSlot extends StatelessWidget {
  final int? bar;
  const _NextSlot({required this.bar});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kBurnOrange.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBurnOrange, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kBurnOrange.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(bar == null ? '1' : '×2',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: kBurnOrangeLight)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bar == null ? 'First workout' : 'Next workout',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    bar == null
                        ? 'Any workout of $kBurnChainMinMinutes+ min sets the bar'
                        : 'Burn more than $bar kcal to earn double',
                    style: const TextStyle(fontSize: 12, color: kBody),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Ended ───────────────────────────────────────────────────────────────────

class _Ended extends ConsumerWidget {
  final BurnChainState chain;
  const _Ended({required this.chain, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = chain.bestLink;
    final broken = chain.endReason == BurnChainEndReason.broken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              const Center(
                child: ModeGlowArt(
                    asset: AppIcons.rewardChestBurst,
                    glow: kGoldLight,
                    size: 140),
              ),
              Text(
                broken ? 'CHAIN COMPLETE' : 'TIME\'S UP',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: kBurnOrange),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIconImage(AppIcons.homeCoinIcon, size: 40),
                    const SizedBox(width: 10),
                    Text('+${modeFmt(chain.totalCoins)}',
                        style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: kGoldLight)),
                  ],
                ),
              ),
              Text(
                chain.links.isEmpty
                    ? 'No workouts in this chain'
                    : '${chain.links.length} workouts · ${chain.beats} beaten',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: kBody),
              ),
              const SizedBox(height: 16),
              for (final link in chain.links) ...[
                _LinkRow(link: link),
                const SizedBox(height: 6),
              ],
              if (best != null) ...[
                const SizedBox(height: 6),
                ModePanel(
                  child: Row(
                    children: [
                      const AppIconImage(AppIcons.rewardStreakFire, size: 30),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ModeLabel('BEST BURN THIS CHAIN'),
                          const SizedBox(height: 2),
                          Text(
                            '${best.calories} kcal · ${_activityType(best.type)?.displayName ?? best.type}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ModeCta(
          label: chain.totalCoins > 0
              ? 'Collect ${modeFmt(chain.totalCoins)} coins'
              : 'Close chain',
          onTap: () async {
            try {
              await ref.read(burnChainProvider.notifier).collect();
              if (context.mounted && chain.totalCoins > 0) {
                AppToast.show(
                  context,
                  'Chain collected',
                  detail: chain.talentCrystals > 0
                      ? '+${modeFmt(chain.totalCoins)} coins · +${chain.talentCrystals} Talent Crystal${chain.talentCrystals == 1 ? '' : 's'}'
                      : '+${modeFmt(chain.totalCoins)} coins',
                );
              }
            } catch (error) {
              if (context.mounted) {
                AppToast.error(
                    context,
                    playerErrorMessage(error,
                        fallback: 'Could not collect Burn Chain rewards.'));
              }
            }
          },
        ),
      ],
    );
  }
}

class _Cooldown extends StatelessWidget {
  final BurnChainState chain;
  const _Cooldown({required this.chain, super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: ModePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ModeGlowArt(
                  asset: AppIcons.rewardStreakFire,
                  glow: kBurnOrange,
                  size: 92),
              const SizedBox(height: 14),
              const Text('CHAIN COLLECTED',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: kBurnOrangeLight)),
              const SizedBox(height: 8),
              Text(
                'A new chain opens in ${modeDuration(chain.timeLeft(DateTime.now().toUtc()))}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kBody),
              ),
            ],
          ),
        ),
      );
}

class _Error extends StatelessWidget {
  final VoidCallback onRetry;
  const _Error({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Couldn\'t load your workouts.',
                style: TextStyle(color: kBody)),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      );
}

// ── ×2 moment ───────────────────────────────────────────────────────────────

Future<void> showBurnChainBeat(
    BuildContext context, ChainLink link, BurnChainState chain) {
  return showAppBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => _BeatSheet(link: link, chain: chain),
  );
}

class _BeatSheet extends StatelessWidget {
  final ChainLink link;
  final BurnChainState chain;
  const _BeatSheet({required this.link, required this.chain});

  @override
  Widget build(BuildContext context) {
    final linkNo = chain.links.indexOf(link) + 1;
    final old = link.barBefore ?? 0;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: kBurnOrange)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 20, 16, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('CHAIN LINK $linkNo',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: kBurnOrange)),
          const Text('×2',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                height: 1,
                color: kBurnOrangeLight,
                shadows: [Shadow(color: Color(0x99F0883E), blurRadius: 30)],
              )),
          const Text('You beat the bar!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bar(value: old, of: link.calories, label: 'Old bar'),
                const SizedBox(width: 14),
                _Bar(
                  value: link.calories,
                  of: link.calories,
                  label: _activityType(link.type)?.displayName ?? link.type,
                  hot: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ModePanel(
            color: kGold.withValues(alpha: .08),
            border: kGold.withValues(alpha: .4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${link.calories} kcal × $kBurnChainBeatMultiplier =',
                      style: const TextStyle(fontSize: 15, color: kBody)),
                  const SizedBox(width: 8),
                  const AppIconImage(AppIcons.homeCoinIcon, size: 26),
                  const SizedBox(width: 6),
                  Text('+${modeFmt(link.coins)}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: kGoldLight)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ModeCta.burn(
            label: 'Keep the chain going',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final int of;
  final String label;
  final bool hot;

  const _Bar({
    required this.value,
    required this.of,
    required this.label,
    this.hot = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = of <= 0 ? 0.0 : 90 * value / of;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: hot ? 15 : 13,
                  fontWeight: FontWeight.w900,
                  color: hot ? kBurnOrangeLight : kBody)),
          const SizedBox(height: 4),
          Container(
            height: h.clamp(6, 90),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              color: hot ? null : AppColors.border,
              gradient: hot
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [kBurnOrangeTop, Color(0xFFC9611D)])
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

ActivityType? _activityType(String apiValue) {
  for (final t in ActivityType.values) {
    if (t.apiValue == apiValue) return t;
  }
  return null;
}
