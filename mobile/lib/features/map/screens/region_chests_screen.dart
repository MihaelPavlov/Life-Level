import '../../unlocks/models/unlock_catalog.dart';
import '../../unlocks/tour/tour_target.dart';
import '../../unlocks/tour/tours/unlock_tours.dart';
import '../../unlocks/tour/unlock_tour_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/constants/app_icons.dart';
import 'dart:math' as math;

import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/api_error_state.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/currency_chip.dart';
import '../../character/providers/character_provider.dart';
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
  /// Set from the tap until the loot lands (or the claim fails).
  String? _claimingRegionId;

  /// The wallet the chips show while loot is in the air: the claim updates
  /// the real one at once, but the chips should only tick up when it lands.
  RegionChestWallet? _heldWallet;
  int _chipPulse = 0;
  final _gemChip = FxAnchor();
  final _coinChip = FxAnchor();

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
        _error =
            playerErrorMessage(e, fallback: 'Could not load region chests.');
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
      _heldWallet = ref.read(regionChestsProvider).valueOrNull?.wallet;
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
        setState(() {
          _heldWallet = null;
          _claimingRegionId = null;
        });
        AppToast.error(context, 'Could not claim the chest. Try again.');
      }
      return null;
    }
  }

  void _lootLanded() {
    if (!mounted) return;
    setState(() {
      // The opening is over once the loot is in the wallet.
      _claimingRegionId = null;
      _heldWallet = null;
      _chipPulse++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chestsAsync = ref.watch(regionChestsProvider);
    final overview = chestsAsync.valueOrNull;
    final wallet = _heldWallet ?? overview?.wallet;

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
                          message: _error ??
                              playerErrorMessage(chestsAsync.error,
                                  fallback: 'Could not load region chests.'),
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
                        FxAnchorTarget(
                          anchor: _gemChip,
                          child: _Pulse(
                            trigger: _chipPulse,
                            child: _currencyChip(context,
                                iconAsset: AppIcons.homeGemIcon,
                                value: _fmt(wallet?.gems ?? 0)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FxAnchorTarget(
                          anchor: _coinChip,
                          child: _Pulse(
                            trigger: _chipPulse,
                            child: _currencyChip(context,
                                iconAsset: AppIcons.homeCoinIcon,
                                value: _fmt(wallet?.coins ?? 0)),
                          ),
                        ),
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
          const rewardsHeight = _kStageHeight + 8 + 48;
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
                      child: _ChestStage(
                        key: ValueKey(focused.name),
                        region: focused,
                        chest: chest,
                        onClaim: () => _claim(chest),
                        gemChip: _gemChip,
                        coinChip: _coinChip,
                        onLootLanded: _lootLanded,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        28, captionTopPad, 28, captionBottomPad),
                    child: Text(
                      _claimingRegionId == chest.regionId
                          ? 'Opening the chest…'
                          : _claimCaption(focused, chest),
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

// ── Chest stage ──────────────────────────────────────────────────────────────

enum _ChestPhase { idle, waiting, opening, opened }

/// The focused region's chest (design: Rewards canvas, "K2 · One big
/// chest"). A ready chest bobs; tapping it (or "Open chest") sends the claim
/// and shakes the chest while the server answers. Only a confirmed claim
/// opens it: the lid pops, the coins and crystals rise out as two tiles and
/// fly into the wallet chips. A failed claim leaves the chest shut.
class _ChestStage extends StatefulWidget {
  final RegionCard region;
  final RegionChestEntry chest;
  final Future<RegionChestClaimResult?> Function() onClaim;

  /// Where the loot lands, and what to call once it has.
  final FxAnchor gemChip;
  final FxAnchor coinChip;
  final VoidCallback onLootLanded;

  const _ChestStage({
    super.key,
    required this.region,
    required this.chest,
    required this.onClaim,
    required this.gemChip,
    required this.coinChip,
    required this.onLootLanded,
  });

  @override
  State<_ChestStage> createState() => _ChestStageState();
}

// Opening timeline (ms): the lid pops at 0, the tiles rise out, hold, then
// take off for the chips.
const _kPopMs = 380.0;
const _kRiseStart = 150.0;
const _kRiseMs = 520.0;
const _kFlyAt = 1100.0;
const _kOpenMs = 1150.0;
const _kChestSize = 150.0;
const _kStageHeight = 156.0;

class _ChestStageState extends State<_ChestStage>
    with TickerProviderStateMixin {
  /// Drives the idle bob and the waiting shake.
  late final AnimationController _loop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400))
    ..addListener(_tick);
  late final AnimationController _open = AnimationController(
      vsync: this, duration: Duration(milliseconds: _kOpenMs.round()))
    ..addListener(_tick);
  final _tileKeys = [GlobalKey(), GlobalKey()];
  _ChestPhase _phase = _ChestPhase.idle;
  RegionChestClaimResult? _result;
  bool _lootPending = false;
  bool _precached = false;

  RegionChestEntry get chest => widget.chest;

  bool get _ready => chest.status == RegionChestStatus.ready;

  /// Opened art once this panel has opened it, or for a chest claimed
  /// before. While waiting the optimistic state already says "claimed", so
  /// the phase wins.
  bool get _showOpen =>
      _phase == _ChestPhase.opening ||
      _phase == _ChestPhase.opened ||
      (_phase == _ChestPhase.idle &&
          chest.status == RegionChestStatus.claimed);

  void _tick() => setState(() {});

  @override
  void initState() {
    super.initState();
    _loop.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Decode the opened art up front so the swap never shows a blank frame.
    precacheImage(
        const AssetImage(AppIcons.regionChestsOpened), context);
  }

  @override
  void dispose() {
    // Leaving mid-flight (back, or focusing another region): let the
    // wallet catch up anyway.
    if (_lootPending) widget.onLootLanded();
    _loop.dispose();
    _open.dispose();
    super.dispose();
  }

  Future<void> _tapOpen() async {
    if (!_ready || _phase != _ChestPhase.idle) return;
    setState(() => _phase = _ChestPhase.waiting);
    AppMotion.haptic(AppHaptic.light);
    // Shake for at least a moment, even when the answer is instant.
    final answers = await Future.wait<Object?>([
      widget.onClaim(),
      Future<void>.delayed(const Duration(milliseconds: 520)),
    ]);
    if (!mounted) return;
    final result = answers.first as RegionChestClaimResult?;
    if (result == null) {
      // The claim failed (the screen shows the error). Nothing opened.
      setState(() => _phase = _ChestPhase.idle);
      return;
    }
    _result = result;
    _lootPending = true;
    if (!RewardFx.enabled(context)) {
      setState(() => _phase = _ChestPhase.opened);
      _landLoot();
      return;
    }
    setState(() => _phase = _ChestPhase.opening);
    AppMotion.haptic(AppHaptic.medium);
    _burstFx();
    await _open.forward(from: 0);
    if (!mounted) return;
    setState(() => _phase = _ChestPhase.opened);
  }

  void _burstFx() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final at = box.localToGlobal(Offset(box.size.width / 2, _kStageHeight / 2));
    RewardFx.burst(context, at, const Color(0xFF8FD3FF),
        count: 14, distance: 90);
    RewardFx.sparkles(context, at,
        count: 10, spread: 50, color: const Color(0xFFBFE6FF));
  }

  /// Fired as the tiles reach their hold: they take off for the chips.
  bool _flown = false;
  void _maybeFly() {
    if (_flown || _open.value * _kOpenMs < _kFlyAt) return;
    _flown = true;
    final result = _result!;
    final from = [for (final k in _tileKeys) RewardFx.centerOf(k)];
    final targets = [widget.gemChip.rect, widget.coinChip.rect];
    final assets = [AppIcons.homeGemIcon, AppIcons.homeCoinIcon];
    final amounts = [result.gems, result.coins];
    final flights = <Future<void>>[];
    for (var i = 0; i < 2; i++) {
      final start = from[i];
      final target = targets[i];
      if (start == null || amounts[i] <= 0) continue;
      // Aim at the chip's icon (its left end).
      final to = target == null
          ? Offset(start.dx, -24)
          : Offset(target.left + 16, target.center.dy);
      flights.add(RewardFx.fly(
        context,
        child: Image.asset(assets[i], width: 34, height: 34),
        from: start,
        to: to,
        lift: -40,
        sideways: i == 0 ? -30 : 30,
        endScale: .5,
        duration: const Duration(milliseconds: 560),
        delay: Duration(milliseconds: i * 100),
      ).then((_) {
        if (target != null && mounted) {
          RewardFx.burst(context, to,
              i == 0 ? AppColors.purple : AppColors.orange,
              count: 8, distance: 22);
        }
      }));
    }
    Future.wait(flights).then((_) {
      AppMotion.haptic(AppHaptic.light);
      _landLoot();
    });
  }

  void _landLoot() {
    if (!_lootPending) return;
    _lootPending = false;
    widget.onLootLanded();
  }

  double _p(double start, double len, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((_open.value * _kOpenMs - start) / len).clamp(0.0, 1.0));

  // ── pieces ────────────────────────────────────────────────────────────────

  Widget _chestArt() {
    final t = _loop.value * 2 * math.pi;
    var dy = 0.0, angle = 0.0, scale = 1.0;
    final motion = RewardFx.enabled(context);
    if (motion && _phase == _ChestPhase.idle && _ready) {
      dy = math.sin(t) * 4;
    } else if (motion && _phase == _ChestPhase.waiting) {
      angle = math.sin(t * 9) * 6 * math.pi / 180;
      scale = .98;
    } else if (_phase == _ChestPhase.opening) {
      final pop = _p(0, _kPopMs, Curves.easeOutBack);
      scale = 1.18 - .18 * pop;
    }
    final dim = !_ready && !_showOpen;
    Widget art = Image.asset(
      _showOpen ? AppIcons.regionChestsOpened : AppIcons.regionChestsHubIcon,
      width: _kChestSize,
      height: _kChestSize,
      fit: BoxFit.contain,
      cacheWidth: 480,
      gaplessPlayback: true,
    );
    if (dim) {
      art = Opacity(
        opacity: .5,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            .4, .4, .2, 0, 0, //
            .3, .4, .3, 0, 0, //
            .3, .3, .5, 0, 0, //
            0, 0, 0, 1, 0,
          ]),
          child: art,
        ),
      );
    } else if (_phase == _ChestPhase.idle && _showOpen) {
      art = Opacity(opacity: .75, child: art); // claimed earlier
    }
    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: angle,
        alignment: const Alignment(0, .7),
        child: Transform.scale(scale: scale, child: art),
      ),
    );
  }

  Widget _halo() {
    final on = switch (_phase) {
      _ChestPhase.opening => _p(0, 300),
      _ChestPhase.opened => 1.0,
      _ => 0.0,
    };
    final flash = _phase == _ChestPhase.opening
        ? math.sin(math.pi * _p(0, 420, Curves.linear))
        : 0.0;
    if (on <= 0 && flash <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: on * .9,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color(0x806EC8FF),
                  Color(0x294F9EFF),
                  Color(0x004F9EFF),
                ], stops: [0, .45, .7]),
              ),
            ),
          ),
          if (flash > 0)
            Opacity(
              opacity: flash,
              child: Transform.scale(
                scale: .5 + flash,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Color(0xF2E6F8FF),
                      Color(0x666EC8FF),
                      Color(0x006EC8FF),
                    ], stops: [0, .35, .65]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The two loot tiles: rise out of the chest, hold, then hand over to
  /// the flying icons.
  Widget _tiles() {
    if (_phase != _ChestPhase.opening || _result == null) {
      return const SizedBox.shrink();
    }
    if (_open.value * _kOpenMs >= _kFlyAt) return const SizedBox.shrink();
    final result = _result!;
    final tiles = [
      (AppIcons.homeGemIcon, result.gems, AppColors.purple, -52.0),
      (AppIcons.homeCoinIcon, result.coins, AppColors.orange, 52.0),
    ];
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < 2; i++)
            Builder(builder: (_) {
              final (asset, qty, color, x) = tiles[i];
              final p = _p(_kRiseStart + i * 90, _kRiseMs, Curves.easeOutBack);
              final fade = _p(_kRiseStart + i * 90, 160);
              return Transform.translate(
                offset: Offset(x * p, 20 - 128 * p),
                child: Opacity(
                  opacity: fade,
                  child: Transform.scale(
                    scale: .3 + .7 * p.clamp(0.0, 1.1),
                    child: _LootTile(
                        key: _tileKeys[i],
                        asset: asset,
                        qty: qty,
                        color: color),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _rewardPreview({required bool faded}) {
    Widget item(String asset, int qty) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(asset, width: 18, height: 18),
            const SizedBox(width: 4),
            Text('×$qty',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        );
    return Opacity(
      opacity: faded ? .45 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(AppIcons.homeGemIcon, chest.gems),
          const SizedBox(width: 12),
          item(AppIcons.homeCoinIcon, chest.coins),
        ],
      ),
    );
  }

  Widget _action() {
    final claimed = _showOpen;
    final waiting = _phase == _ChestPhase.waiting;
    final Widget label;
    if (waiting) {
      label = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF1A0F00)),
          ),
          SizedBox(width: 8),
          Text('Opening…'),
        ],
      );
    } else if (claimed) {
      label = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 18),
          SizedBox(width: 6),
          Text('Claimed'),
        ],
      );
    } else if (_ready) {
      label = const Text('Open chest');
    } else {
      label = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 16),
          SizedBox(width: 6),
          Text('Locked'),
        ],
      );
    }
    final active = _ready && _phase == _ChestPhase.idle;
    return FilledButton(
      onPressed: active ? _tapOpen : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: const Color(0xFF1A0F00),
        disabledBackgroundColor: waiting
            ? AppColors.orange
            : Colors.white.withValues(alpha: .10),
        disabledForegroundColor:
            waiting ? const Color(0xFF1A0F00) : const Color(0xFFc9d1d9),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      child: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _ChestPhase.opening) _maybeFly();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _kStageHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _halo(),
              Semantics(
                button: _ready && _phase == _ChestPhase.idle,
                label: _ready ? 'Open the region chest' : 'Region chest',
                child: GestureDetector(
                  onTap: _tapOpen,
                  child: _chestArt(),
                ),
              ),
              _tiles(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _rewardPreview(faded: _showOpen),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _action(),
          ],
        ),
      ],
    );
  }
}

class _LootTile extends StatelessWidget {
  final String asset;
  final int qty;
  final Color color;
  const _LootTile(
      {super.key, required this.asset, required this.qty, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.black, .45)!,
            Color.lerp(color, Colors.black, .78)!,
          ],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), offset: Offset(0, 6)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(asset, width: 38, height: 38, fit: BoxFit.contain),
          Positioned(
            left: 0,
            right: 0,
            bottom: 3,
            child: Text(
              '×$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: Color(0xE6030710), blurRadius: 3)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pops its child each time [trigger] changes (a chip receiving loot).
class _Pulse extends StatelessWidget {
  final int trigger;
  final Widget child;
  const _Pulse({required this.trigger, required this.child});

  @override
  Widget build(BuildContext context) {
    if (trigger == 0) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      builder: (_, t, c) =>
          Transform.scale(scale: 1 + .18 * math.sin(math.pi * t), child: c),
      child: child,
    );
  }
}
