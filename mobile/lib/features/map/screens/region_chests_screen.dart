import '../../unlocks/models/unlock_catalog.dart';
import '../../unlocks/tour/tour_target.dart';
import '../../unlocks/tour/tours/unlock_tours.dart';
import '../../unlocks/tour/unlock_tour_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import 'dart:math' as math;

import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/api_error_state.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/currency_chip.dart';
import '../../character/providers/character_provider.dart';
import '../../rewards/widgets/task_reward_popup.dart';
import '../../shop/shop_screen.dart';
import '../models/region_chest_models.dart';
import '../models/world_map_models.dart';
import '../providers/region_chest_provider.dart';
import '../services/world_zone_service.dart';

/// "Region Chests" — a chest reward for every region fully cleared.
///
/// Region progress comes from the world map while reward eligibility, values,
/// claims and wallet balances are server-authoritative.
///
/// All 15 chapters have real painted banner art (`AppIcons.regionBanners`,
/// generated from the prompts on the design artifact's Art Direction sheet)
/// — the asset already bakes in the hanging rod, frame and diamond/pill
/// slots, so this screen only overlays the chapter number and zone count.
///
/// Reached from the Home screen's Adventure Hub ("Chests" tile).
class RegionChestsScreen extends ConsumerStatefulWidget {
  /// Loads the region list; tests pass a fake.
  final WorldZoneService? worldService;

  const RegionChestsScreen({super.key, this.worldService});

  @override
  ConsumerState<RegionChestsScreen> createState() => _RegionChestsScreenState();
}

class _RegionChestsScreenState extends ConsumerState<RegionChestsScreen> {
  late final _service = widget.worldService ?? WorldZoneService();
  WorldMapData? _data;
  bool _loading = true;
  String? _error;
  int? _focusedIndex;

  /// The region on screen in the last build, so a claim can pin it.
  int _shownIndex = 0;
  String? _claimingRegionId;

  @override
  void initState() {
    super.initState();
    // _load reads Riverpod state. Wait until the ConsumerState is attached to
    // its ProviderScope before touching inherited provider dependencies.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      ref.invalidate(regionChestsProvider);
      final results = await Future.wait([
        _service.getWorldMap(),
        ref.read(regionChestsProvider.future),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results.first as WorldMapData;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<RegionChestClaimResult?> _claim(RegionChestEntry chest) async {
    if (_claimingRegionId != null || chest.status != RegionChestStatus.ready) {
      return null;
    }
    setState(() {
      _claimingRegionId = chest.regionId;
      // The default focus follows the first *ready* chest. Once this one is
      // claimed it would jump to another region and tear down the panel that
      // plays the opening, so keep the claimed region on screen.
      _focusedIndex ??= _shownIndex;
    });
    try {
      final result =
          await ref.read(regionChestsProvider.notifier).claim(chest.regionId);
      ref.invalidate(characterProfileProvider);
      return result;
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Could not claim the chest. Try again.');
      }
      return null;
    } finally {
      if (mounted) setState(() => _claimingRegionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chestsAsync = ref.watch(regionChestsProvider);
    final overview = chestsAsync.valueOrNull;

    return TourOnFirstVisit(
      unlockKey: UnlockKeys.chests,
      child: Scaffold(
        backgroundColor: const Color(0xFF0e1c34),
        body: Stack(
          children: [
            const Positioned.fill(child: _SceneBackground()),
            SafeArea(
              child: _loading || overview == null
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.blue))
                  : _error != null || chestsAsync.hasError
                      ? ApiErrorState(
                          message: _error ?? chestsAsync.error.toString(),
                          onRetry: _load)
                      : _buildContent(_data!, overview),
            ),
            // Back arrow and currency chips share one row so they're always
            // vertically centered against each other, back-left / chips-right.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 26),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _currencyChip(context,
                            iconAsset: AppIcons.homeGemIcon,
                            value: _fmt(overview?.wallet.gems ?? 0)),
                        const SizedBox(width: 10),
                        _currencyChip(context,
                            iconAsset: AppIcons.homeCoinIcon,
                            value: _fmt(overview?.wallet.coins ?? 0)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(WorldMapData data, RegionChestsOverview overview) {
    final regions = [...data.regions]
      ..sort((a, b) => a.chapterIndex.compareTo(b.chapterIndex));
    final chestsByRegion = {
      for (final entry in overview.regions) entry.regionId: entry,
    };
    final defaultFocused = regions.indexWhere((region) {
      final chest = chestsByRegion[region.id];
      return chest?.status == RegionChestStatus.ready;
    });
    final activeFocused =
        regions.indexWhere((r) => r.status == RegionStatus.active);
    final focusedIndex = (_focusedIndex ??
            (defaultFocused >= 0
                ? defaultFocused
                : activeFocused >= 0
                    ? activeFocused
                    : 0))
        .clamp(0, regions.length - 1);
    _shownIndex = focusedIndex;
    final focused = regions[focusedIndex];
    final chest = chestsByRegion[focused.id] ??
        RegionChestEntry(
          regionId: focused.id,
          chapterIndex: focused.chapterIndex,
          coins: 0,
          gems: 0,
          status: RegionChestStatus.locked,
        );
    final left = focusedIndex > 0 ? regions[focusedIndex - 1] : null;
    final right =
        focusedIndex < regions.length - 1 ? regions[focusedIndex + 1] : null;

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, outer) {
          // Everything here is sized to fit the available height in one
          // pass instead of a fixed banner size — the banner carousel is
          // the one flexible element, so it absorbs whatever vertical room
          // is left after the fixed-size chrome around it (title ribbon,
          // region name, rewards panel, caption). A scroll view still
          // wraps the result as a safety net for unusually short windows
          // instead of a hard overflow, but on a normal phone viewport it
          // never actually needs to scroll.
          const headerSpacer = 56.0;
          const titleTopPad = 14.0;
          const titleBottomPad = 12.0;
          const titleWidth = 280.0;
          const titleHeight = titleWidth / (1537 / 327);
          const regionNameHeight = 20.0;
          const rewardsTopPad = 8.0;
          const rewardsHeight = 124.0;
          const captionTopPad = 10.0;
          const captionHeight = 18.0;
          const captionBottomPad = 16.0;
          const fixedHeight = headerSpacer +
              titleTopPad +
              titleHeight +
              titleBottomPad +
              regionNameHeight +
              rewardsTopPad +
              rewardsHeight +
              captionTopPad +
              captionHeight +
              captionBottomPad;

          // The banner area height IS the focused banner's own render
          // height — it sits flush at the top of its Stack (alignment:
          // topCenter, no Positioned), so nothing below it needs extra
          // clearance the way the shorter, `top`-offset side banners do.
          final bannerAreaHeight =
              (outer.maxHeight - fixedHeight).clamp(240.0, 420.0);
          const bannerAspect = 1024 / 1536; // width / height
          final centerWidth = bannerAreaHeight * bannerAspect;
          final sideWidth = centerWidth * (185 / 264);
          final sideTopOffset = 71 * (bannerAreaHeight / 396);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: outer.maxHeight),
              child: Column(
                children: [
                  const SizedBox(height: headerSpacer),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                        28, titleTopPad, 28, titleBottomPad),
                    child: _TitleRibbon(),
                  ),
                  SizedBox(
                    height: bannerAreaHeight,
                    child: LayoutBuilder(
                      builder: (context, inner) {
                        // The side banners must clear the focused banner's
                        // edge with a real gap — otherwise their dimmed
                        // (65%-opacity) art sits directly behind the
                        // focused banner's own transparent PNG margin and
                        // double-exposes through it, reading as a soft
                        // "blur" hugging the focused banner. Solve the
                        // offset from the actual available width instead
                        // of a fixed guess so it never overlaps regardless
                        // of viewport/window size.
                        const gap = 18.0;
                        // Never sit closer to center than this default, but
                        // always go further out than that if the viewport
                        // is narrow enough that the default would overlap
                        // the focused banner.
                        const defaultOffset = -80.0;
                        final requiredOffset =
                            (inner.maxWidth - centerWidth) / 2 -
                                gap -
                                sideWidth;
                        final offset = requiredOffset <= defaultOffset
                            ? requiredOffset
                            : defaultOffset;

                        return Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            if (left != null)
                              Positioned(
                                left: offset,
                                top: sideTopOffset,
                                child: _RegionBanner(
                                    region: left,
                                    chestStatus:
                                        chestsByRegion[left.id]?.status ??
                                            RegionChestStatus.locked,
                                    width: sideWidth,
                                    emphasize: false,
                                    onTap: () => setState(() =>
                                        _focusedIndex = focusedIndex - 1)),
                              ),
                            if (right != null)
                              Positioned(
                                right: offset,
                                top: sideTopOffset,
                                child: TourTarget(
                                  id: TourIds.chestsNext,
                                  child: _RegionBanner(
                                      region: right,
                                      chestStatus:
                                          chestsByRegion[right.id]?.status ??
                                              RegionChestStatus.locked,
                                      width: sideWidth,
                                      emphasize: false,
                                      onTap: () => setState(() =>
                                          _focusedIndex = focusedIndex + 1)),
                                ),
                              ),
                            TourTarget(
                              id: TourIds.chestsCurrent,
                              child: _RegionBanner(
                                  region: focused,
                                  chestStatus: chest.status,
                                  width: centerWidth,
                                  emphasize: true),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      focused.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFcfe3ff)),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(28, rewardsTopPad, 28, 0),
                    child: TourTarget(
                      id: TourIds.chestsRewards,
                      child: _RewardsPanel(
                        key: ValueKey(focused.name),
                        region: focused,
                        chest: chest,
                        claiming: _claimingRegionId == chest.regionId,
                        onClaim: () => _claim(chest),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        28, captionTopPad, 28, captionBottomPad),
                    child: Text(
                      _claimCaption(focused, chest),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFa9c8f5)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _claimCaption(RegionCard region, RegionChestEntry chest) {
    return switch (chest.status) {
      RegionChestStatus.ready => 'Region boss resolved — chest ready',
      RegionChestStatus.claimed => 'Region chest claimed',
      RegionChestStatus.locked => 'Reach ${region.name} to unlock',
      RegionChestStatus.inProgress => 'Resolve ${region.bossName} to claim',
    };
  }
}

int _tierIndexFor(int chapterIndex) =>
    ((chapterIndex - 1) / 3).floor().clamp(0, 4);

// Illustrative reward-slot tint per chest tier. Tier 0 was green (rarityColor's
// "common") — now purple per request; the rest are unchanged.
const _tierColors = [
  Color(0xFFa371f7), // tier 0 (chapters 1-3) — was green, now purple
  Color(0xFF8b949e), // tier 1 (chapters 4-6) — uncommon/grey
  Color(0xFF4f9eff), // tier 2 (chapters 7-9) — rare/blue
  Color(0xFFa371f7), // tier 3 (chapters 10-12) — epic/purple
  Color(0xFFf5a623), // tier 4 (chapters 13-15) — legendary/gold
];

void _openShop(BuildContext context) {
  Navigator.of(context).push(AppRoute(builder: (_) => const ShopScreen()));
}

Widget _currencyChip(BuildContext context,
    {required String iconAsset, required String value}) {
  return CurrencyChip(
    iconAsset: iconAsset,
    value: value,
    onTapAdd: () => _openShop(context),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    backgroundColor: const Color(0xFF0b1420),
    borderColor: Colors.white.withValues(alpha: 0.14),
    borderRadius: BorderRadius.circular(10),
    iconSize: 15,
    valueFontSize: 11.5,
    gap: 5,
  );
}

String _fmt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ── Night-mountain scene background ─────────────────────────────────────────

class _SceneBackground extends StatelessWidget {
  const _SceneBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(AppIcons.regionChestsBackground, fit: BoxFit.cover);
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _TitleRibbon extends StatelessWidget {
  const _TitleRibbon();

  // Native size of the painted ribbon asset, cropped tight to its visible
  // content — the original canvas had huge transparent padding above/below
  // the plaque (~30%/37% of its height), which was showing up as dead
  // space between the title and the banner carousel below it.
  static const double _aspect = 1537 / 327;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        child: AspectRatio(
          aspectRatio: _aspect,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(AppIcons.regionChestsTitleBanner,
                  fit: BoxFit.contain),
              const Text('Region Chests',
                  style: TextStyle(
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
}

// ── Region banner ────────────────────────────────────────────────────────────
//
// Each banner asset (`AppIcons.regionBanners`) already bakes in the hanging
// rod, the painted scene, the frame, an empty diamond (for the chapter
// number) and an empty pill (for the zone count) — so all this widget does
// is lay real region art at its native aspect ratio and overlay two bits of
// live text at the pre-designed slots.

const double _regionBannerAspect = 1024 / 1536;

class _RegionBanner extends StatelessWidget {
  final RegionCard region;
  final RegionChestStatus chestStatus;
  final double width;
  final bool emphasize;
  final VoidCallback? onTap;
  const _RegionBanner(
      {required this.region,
      required this.chestStatus,
      required this.width,
      required this.emphasize,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final art = AppIcons.regionBanners[region.name];
    final locked = region.status == RegionStatus.locked;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: _regionBannerAspect,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (art != null)
                    // Quality forced to `low` (plain bilinear, no mip chain):
                    // the source art (~900-1000px) is shown far smaller here
                    // (185-264px). `medium`/`high` build a mipmap for that
                    // downscale, and mipmapping a large mostly-transparent
                    // RGBA canvas blends the whole texture's average color
                    // across its full bounding box — visible as a soft
                    // rectangular tint bleeding into the transparent margins
                    // above/below the banner's painted shape.
                    Image.asset(art,
                        fit: BoxFit.cover, filterQuality: FilterQuality.low)
                  else
                    ColoredBox(
                      color: const Color(0xFF1a2536),
                      child: Center(
                          child: Text(
                              region.emoji.isEmpty ? '🗺️' : region.emoji,
                              style: TextStyle(fontSize: width * 0.2))),
                    ),
                  Align(
                    // Measured against the real banner art: the diamond
                    // slot centers at 54% of the banner's height; nudged a
                    // bit further down from there.
                    alignment: const Alignment(0, 0.12),
                    child: Text(
                      '${region.chapterIndex}',
                      style: TextStyle(
                        // The diamond slot is ~23% of the banner's width —
                        // 0.26 fit single digits but overflowed two-digit
                        // chapters (10-15); 0.19 fit both but read large.
                        fontSize: width * 0.15,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ],
                      ),
                    ),
                  ),
                  Align(
                    // Pill slot centers at 64.4% of the banner's height
                    // (0.288); nudged further down from there.
                    alignment: const Alignment(0, 0.41),
                    child: Text(
                      regionChestProgressLabel(
                        chestStatus,
                        region.completedZones,
                        region.totalZones,
                      ),
                      style: TextStyle(
                        fontSize: width * 0.052,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4)
                        ],
                      ),
                    ),
                  ),
                  // Lock badge only makes sense on the dimmed side neighbors —
                  // the focused/center banner is always the player's current
                  // or next-up region, so it never shows the lock icon.
                  if (locked && !emphasize)
                    Positioned(
                      top: width * 0.06,
                      right: width * 0.08,
                      child: Icon(Icons.lock_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: width * 0.14),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rewards panel ────────────────────────────────────────────────────────────

/// Reward tiles for the focused region. When the chest is ready, tapping
/// plays "lid pop + light beam": the tiles shake, each tile's lid flips
/// open over a warm glow, and a beam with sparkles rises out of it.
/// The opening begins immediately while the backend confirms the reward.
class _RewardsPanel extends StatefulWidget {
  final RegionCard region;
  final RegionChestEntry chest;
  final bool claiming;
  final Future<RegionChestClaimResult?> Function() onClaim;
  const _RewardsPanel(
      {super.key,
      required this.region,
      required this.chest,
      required this.claiming,
      required this.onClaim});

  @override
  State<_RewardsPanel> createState() => _RewardsPanelState();
}

class _RewardsPanelState extends State<_RewardsPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..addListener(() => setState(() {}));
  final _slotKeys = [GlobalKey(), GlobalKey()];

  RegionCard get region => widget.region;

  Future<void> _tap() async {
    if (widget.chest.status != RegionChestStatus.ready ||
        widget.claiming ||
        _open.isAnimating) {
      return;
    }
    final request = widget.onClaim();
    if (!RewardFx.enabled(context)) {
      final result = await request;
      if (result == null || !mounted) return;
      await _showReward(result);
      return;
    }
    _open.forward(from: 0);
    AppMotion.haptic(AppHaptic.light);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    for (final (i, key) in _slotKeys.indexed) {
      final r = RewardFx.rectOf(key);
      if (r == null) continue;
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (!mounted) return;
        RewardFx.beam(context, r.topCenter + const Offset(0, 8),
            width: 80, height: 240);
        RewardFx.sparkles(context, r.topCenter, count: 10, spread: 26);
      });
    }
    await Future.delayed(const Duration(milliseconds: 900));
    final result = await request;
    if (result != null && mounted) await _showReward(result);
  }

  Future<void> _showReward(RegionChestClaimResult result) =>
      showRewardRevealPopup(
        context,
        items: [
          RewardRevealItem(
              asset: AppIcons.homeCoinIcon,
              label: '×${result.coins}',
              color: AppColors.orange),
          RewardRevealItem(
              asset: AppIcons.homeGemIcon,
              label: '×${result.gems}',
              color: AppColors.purple),
        ],
        subtitle: 'Region chest claimed',
        heroAsset: AppIcons.rewardChestBurst,
      );

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ms = _open.value * 1100;
    double shake(int i) {
      final p = ((ms - i * 80) / 450).clamp(0.0, 1.0);
      return p <= 0 || p >= 1 ? 0 : math.sin(p * math.pi * 6) * 4 * (1 - p);
    }

    double lid(int i) => _open.isAnimating || _open.value == 1
        ? Curves.easeOutBack
            .transform(((ms - 450 - i * 200) / 380).clamp(0.0, 1.0))
        : 0;
    final tier = _tierIndexFor(region.chapterIndex);
    final coins = widget.chest.coins;
    final gems = widget.chest.gems;
    final tierColor = _tierColors[tier];

    return GestureDetector(
      onTap: _tap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Text(
                widget.chest.status == RegionChestStatus.claimed
                    ? 'Claimed'
                    : widget.claiming
                        ? 'Opening…'
                        : 'Rewards',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  key: _slotKeys[0],
                  angle: shake(0) * math.pi / 180,
                  child: _RewardSlot(
                      iconAsset: AppIcons.homeGemIcon,
                      qty: gems,
                      tierColor: tierColor,
                      lidOpen: lid(0)),
                ),
                const SizedBox(width: 14),
                Transform.rotate(
                  key: _slotKeys[1],
                  angle: shake(1) * math.pi / 180,
                  child: _RewardSlot(
                      iconAsset: AppIcons.homeCoinIcon,
                      qty: coins,
                      tierColor: tierColor,
                      lidOpen: lid(1)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardSlot extends StatelessWidget {
  final String iconAsset;
  final int qty;
  final Color tierColor;

  /// 0 = closed, 1 = lid flipped open (glow showing underneath).
  final double lidOpen;
  const _RewardSlot(
      {required this.iconAsset,
      required this.qty,
      required this.tierColor,
      this.lidOpen = 0});

  @override
  Widget build(BuildContext context) {
    final tile = _tile();
    if (lidOpen <= 0) return tile;
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Warm glow revealed as the lid lifts.
          Positioned.fill(
            child: Opacity(
              opacity: lidOpen.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const RadialGradient(colors: [
                    Color(0xFFFFF6D0),
                    Color(0xFFFFCF5A),
                    Color(0x00FFA11C),
                  ], stops: [
                    0,
                    .45,
                    1
                  ]),
                ),
              ),
            ),
          ),
          // Bottom of the tile stays put, a little brighter.
          ClipRect(
            clipper: const _BandClipper(top: 30),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: .25 * lidOpen),
                  BlendMode.plus),
              child: tile,
            ),
          ),
          // Lid: the top band flips back on its top edge.
          Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .004)
              ..rotateX(-1.9 * lidOpen)
              ..translate(0.0, -4 * lidOpen),
            child:
                ClipRect(clipper: const _BandClipper(bottom: 30), child: tile),
          ),
        ],
      ),
    );
  }

  Widget _tile() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(tierColor, Colors.black, 0.5)!,
            Color.lerp(tierColor, Colors.black, 0.75)!
          ],
        ),
        border: Border.all(color: tierColor, width: 3),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(iconAsset, width: 34, height: 34, fit: BoxFit.contain),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFF1a0f38),
                border: Border.all(color: tierColor),
              ),
              child: Text('×$qty',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFeee2ff))),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps only a horizontal band of the child: y < [bottom] or y >= [top].
class _BandClipper extends CustomClipper<Rect> {
  final double? top, bottom;
  const _BandClipper({this.top, this.bottom});

  @override
  Rect getClip(Size size) => bottom != null
      ? Rect.fromLTRB(0, 0, size.width, bottom!)
      : Rect.fromLTRB(0, top!, size.width, size.height);

  @override
  bool shouldReclip(_BandClipper old) => old.top != top || old.bottom != bottom;
}
