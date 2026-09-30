import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/motion/app_motion.dart';
import '../../core/shell/shell_constants.dart';
import '../../core/services/nav_tab_notifier.dart';
import '../../core/widgets/currency_chip.dart';
import '../character/providers/character_provider.dart';
import '../shop/shop_screen.dart';
import 'burn_chain/burn_chain_provider.dart';
import 'burn_chain/burn_chain_rules.dart';
import 'burn_chain/burn_chain_screen.dart';
import 'treasure_delve/delve_provider.dart';
import 'treasure_delve/treasure_delve_screen.dart';
import 'widgets/mode_banner.dart';
import 'widgets/mode_ui.dart';

/// The Mode tab: one painted banner per game mode.
class ModesScreen extends ConsumerWidget {
  const ModesScreen({super.key});

  static void openBurnChain(BuildContext context) => Navigator.push(
      context, AppRoute(builder: (_) => const BurnChainScreen()));

  static void openTreasureDelve(BuildContext context) => Navigator.push(
      context, AppRoute(builder: (_) => const TreasureDelveScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(characterProfileProvider).valueOrNull?.talents;
    final chain = ref.watch(burnChainProvider).valueOrNull?.chain;
    final delve = ref.watch(delveStatusProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0e1c34),
      body: Stack(
        children: [
          Positioned.fill(
            child:
                Image.asset(AppIcons.regionChestsBackground, fit: BoxFit.cover),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.blue,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                ref.invalidate(delveStatusProvider);
                await ref.read(burnChainProvider.notifier).refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                // Top room for the back arrow / wallet row drawn above.
                padding: const EdgeInsets.fromLTRB(16, 56, 16, kNavBarH + 60),
                children: [
                  const _TitleRibbon('Modes'),
                  const SizedBox(height: 16),
                  ModeBanner(
                    art: AppIcons.modeBurnChainBanner,
                    accent: kBurnOrange,
                    border: const Color(0xFFFFC27A),
                    kicker: 'Coins ×2',
                    kickerColor: kBurnOrangeLight,
                    title: 'Burn Chain',
                    rewards: const [
                      ModeRewardTile(
                          icon: AppIcons.homeCoinIcon, color: AppColors.orange),
                    ],
                    footerIcon: AppIcons.rewardStreakFire,
                    footer: _burnFooter(chain),
                    alert: chain != null && chain.phase == BurnChainPhase.ended,
                    onTap: () => openBurnChain(context),
                  ),
                  const SizedBox(height: 18),
                  ModeBanner(
                    art: AppIcons.modeTreasureDelveBanner,
                    accent: AppColors.blue,
                    border: const Color(0xFF8CC0FF),
                    kicker: 'Gold',
                    kickerColor: kGoldLight,
                    title: 'Treasure Delve',
                    rewards: const [
                      ModeRewardTile(
                          icon: AppIcons.homeCoinIcon, color: AppColors.orange),
                      ModeRewardTile(
                          icon: AppIcons.shopChestRare,
                          color: AppColors.purple),
                    ],
                    footerIcon: AppIcons.itemEnergyGel,
                    footer: delve == null
                        ? const ModeFooterText('Runs left: …')
                        : ModeFooterText('Runs left: ',
                            value: '${delve.runsLeft}',
                            valueColor: delve.runsLeft > 0
                                ? AppColors.green
                                : AppColors.textSecondary),
                    alert: (delve?.runsLeft ?? 0) > 0,
                    onTap: () => openTreasureDelve(context),
                  ),
                  const SizedBox(height: 18),
                  const ModeComingSoonCard(),
                ],
              ),
            ),
          ),
          // Same header as Region Chests: back arrow left, wallet right.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Back to Home',
                    onPressed: () => NavTabNotifier.switchTo('home'),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 26),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _WalletChip(
                          icon: AppIcons.homeGemIcon,
                          value: '${wallet?.gems ?? 0}'),
                      const SizedBox(width: 10),
                      _WalletChip(
                          icon: AppIcons.homeCoinIcon,
                          value: modeFmt(wallet?.coins ?? 0)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _burnFooter(BurnChainState? chain) {
    if (chain == null) return const ModeFooterText('Chain window: 24h');
    switch (chain.phase) {
      case BurnChainPhase.idle:
        return const ModeFooterText('Chain window: ',
            value: '24h', valueColor: kBurnOrangeLight);
      case BurnChainPhase.live:
        final bar = chain.bar;
        final left = modeDuration(chain.timeLeft(DateTime.now().toUtc()));
        return bar == null
            ? ModeFooterText('Log a workout · ',
                value: '$left left', valueColor: kBurnOrangeLight)
            : ModeFooterText('Beat $bar kcal · ',
                value: '$left left', valueColor: kBurnOrangeLight);
      case BurnChainPhase.ended:
        return ModeFooterText('Collect ',
            value: '${modeFmt(chain.totalCoins)} coins',
            valueColor: kGoldLight);
      case BurnChainPhase.cooldown:
        return ModeFooterText('Next chain in ',
            value: modeDuration(chain.timeLeft(DateTime.now().toUtc())),
            valueColor: kBurnOrangeLight);
    }
  }
}

/// Wallet chip styled like the Region Chests header; tapping opens the Shop.
class _WalletChip extends StatelessWidget {
  final String icon;
  final String value;

  const _WalletChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => CurrencyChip(
        iconAsset: icon,
        value: value,
        onTapAdd: () => Navigator.of(context)
            .push(AppRoute(builder: (_) => const ShopScreen())),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        backgroundColor: const Color(0xFF0b1420),
        borderColor: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        iconSize: 15,
        valueFontSize: 11.5,
        gap: 5,
      );
}

/// The Region Chests gold ribbon with the page name.
class _TitleRibbon extends StatelessWidget {
  final String text;
  const _TitleRibbon(this.text);

  static const double _aspect = 1537 / 327;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: 280,
          child: AspectRatio(
            aspectRatio: _aspect,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(AppIcons.regionChestsTitleBanner,
                    fit: BoxFit.contain),
                Text(text,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5a3300),
                        letterSpacing: 0.3)),
              ],
            ),
          ),
        ),
      );
}
