import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../models/achievement_models.dart';
import 'road_meta.dart';

// Status colours used everywhere on the roads: green = done, orange = ready
// to claim, blue = in progress.
const kRoadDone = AppColors.green;
const kRoadReady = AppColors.orange;
const kRoadActive = AppColors.blue;
const _kSurface = AppColors.surface;
const _kLine = Color(0xFF21262D);
const _kOff = Color(0xFF30363D);

String fmtNum(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Coins + gems in the header. The anchors are where claimed rewards fly to.
/// When a balance goes up the number counts up and the chip bumps twice in
/// gold, like the design.
class RoadWallet extends StatelessWidget {
  final AchievementWallet wallet;
  final FxAnchor coinAnchor;
  final FxAnchor gemAnchor;
  const RoadWallet({
    super.key,
    required this.wallet,
    required this.coinAnchor,
    required this.gemAnchor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FxAnchorTarget(
          anchor: coinAnchor,
          child: _CountingChip(
              asset: AppIcons.homeCoinIcon,
              value: wallet.coins,
              tint: AppColors.orange),
        ),
        const SizedBox(width: 6),
        FxAnchorTarget(
          anchor: gemAnchor,
          child: _CountingChip(
              asset: AppIcons.homeGemIcon,
              value: wallet.gems,
              tint: const Color(0xFF8CC0FF)),
        ),
      ],
    );
  }
}

class _CountingChip extends StatefulWidget {
  final String asset;
  final int value;
  final Color tint;
  const _CountingChip(
      {required this.asset, required this.value, required this.tint});

  @override
  State<_CountingChip> createState() => _CountingChipState();
}

class _CountingChipState extends State<_CountingChip>
    with TickerProviderStateMixin {
  // Count-up (600 ms, ease-out) and two bumps (2 × 500 ms).
  late final AnimationController _count = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _bump = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  int _from = 0;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _count.value = 1;
  }

  @override
  void didUpdateWidget(_CountingChip old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    if (!AppMotion.isFull(context) || widget.value < old.value) {
      _from = widget.value;
      _count.value = 1;
      return;
    }
    _from = _shown(old.value);
    _count.forward(from: 0);
    _bump.forward(from: 0);
  }

  int _shown(int target) =>
      (_from + (target - _from) * Curves.easeOutCubic.transform(_count.value))
          .round();

  @override
  void dispose() {
    _count.dispose();
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_count, _bump]),
      builder: (context, _) {
        final b = _bump.value;
        final bumping = _bump.isAnimating;
        // scBump: 0 → 1.3 at 35 % → 1, played twice.
        final k = (b * 2) % 1;
        final s = k < .35 ? 1 + .3 * (k / .35) : 1.3 - .3 * ((k - .35) / .65);
        return Transform.scale(
          scale: bumping ? s : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x73000000),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: bumping
                      ? widget.tint.withValues(alpha: .7)
                      : const Color(0x29FFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(widget.asset, width: 16, height: 16),
                const SizedBox(width: 4),
                Text(
                  fmtNum(_shown(widget.value)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: bumping ? widget.tint : Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// XP · coins · gems on one line.
class RewardLine extends StatelessWidget {
  final int xp;
  final int coins;
  final int gems;
  final double fontSize;
  final bool plus;

  /// Where claimed coins / gems lift off from.
  final FxAnchor? coinAnchor;
  final FxAnchor? gemAnchor;
  const RewardLine({
    super.key,
    required this.xp,
    required this.coins,
    required this.gems,
    this.fontSize = 11,
    this.plus = true,
    this.coinAnchor,
    this.gemAnchor,
  });

  @override
  Widget build(BuildContext context) {
    final p = plus ? '+' : '';
    final style = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary);
    final icon = fontSize + 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (xp > 0) ...[
          Text('$p${fmtNum(xp)} XP',
              style: style.copyWith(color: AppColors.orange)),
          const SizedBox(width: 8),
        ],
        _anchored(coinAnchor,
            Image.asset(AppIcons.homeCoinIcon, width: icon, height: icon)),
        const SizedBox(width: 3),
        Text('$p${fmtNum(coins)}', style: style),
        const SizedBox(width: 8),
        _anchored(gemAnchor,
            Image.asset(AppIcons.homeGemIcon, width: icon, height: icon)),
        const SizedBox(width: 3),
        Text('$p$gems', style: style),
      ],
    );
  }

  static Widget _anchored(FxAnchor? a, Widget child) =>
      a == null ? child : FxAnchorTarget(anchor: a, child: child);
}

/// One piece per achievement in the stage: green claimed, orange ready,
/// grey still to do. Pieces that turn green pop one after another (200 ms
/// apart); a stage that just arrived fades its pieces in left to right.
class StagePips extends StatefulWidget {
  final AchievementStage stage;
  final double height;
  final bool fadeIn;
  const StagePips(
      {super.key, required this.stage, this.height = 7, this.fadeIn = false});

  @override
  State<StagePips> createState() => _StagePipsState();
}

class _StagePipsState extends State<StagePips> {
  final _delays = <String, int>{};
  Map<String, bool> _wasClaimed = {};

  List<AchievementDto> _ordered(AchievementStage s) => [
        ...s.achievements.where((a) => a.isClaimed),
        ...s.achievements.where((a) => a.isReady),
        ...s.achievements.where((a) => !a.isUnlocked),
      ];

  @override
  void initState() {
    super.initState();
    _wasClaimed = {
      for (final a in widget.stage.achievements) a.id: a.isClaimed
    };
  }

  @override
  void didUpdateWidget(StagePips old) {
    super.didUpdateWidget(old);
    _delays.clear();
    var n = 0;
    for (final a in _ordered(widget.stage)) {
      if (a.isClaimed && _wasClaimed[a.id] == false) _delays[a.id] = 200 * n++;
    }
    _wasClaimed = {
      for (final a in widget.stage.achievements) a.id: a.isClaimed
    };
  }

  @override
  Widget build(BuildContext context) {
    final list = _ordered(widget.stage);
    return Row(
      children: [
        for (final (i, a) in list.indexed) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _Pip(
              key: ValueKey(a.id),
              color: a.isClaimed
                  ? kRoadDone
                  : a.isReady
                      ? kRoadReady
                      : _kOff,
              height: widget.height,
              popDelay: _delays[a.id],
              fadeInDelay: widget.fadeIn ? 300 + 50 * i : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _Pip extends StatefulWidget {
  final Color color;
  final double height;
  final int? popDelay;
  final int? fadeInDelay;
  const _Pip({
    super.key,
    required this.color,
    required this.height,
    this.popDelay,
    this.fadeInDelay,
  });

  @override
  State<_Pip> createState() => _PipState();
}

class _PipState extends State<_Pip> with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300), value: 1);
  late Color _shown = widget.color;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final d = widget.fadeInDelay;
    if (d != null && _fade.value == 1 && AppMotion.isFull(context)) {
      _fade.value = 0;
      Future.delayed(Duration(milliseconds: d), () {
        if (mounted) _fade.forward();
      });
    }
  }

  @override
  void didUpdateWidget(_Pip old) {
    super.didUpdateWidget(old);
    if (old.color == widget.color) return;
    final d = widget.popDelay;
    if (widget.color == kRoadDone && d != null && AppMotion.isFull(context)) {
      // Keep the old colour until this piece's turn, then pop green.
      Future.delayed(Duration(milliseconds: d), () {
        if (!mounted) return;
        setState(() => _shown = widget.color);
        _pop.forward(from: 0);
      });
    } else {
      _shown = widget.color;
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pop, _fade]),
      builder: (_, __) {
        // scPip: scaleY 1 → 2.6 at 40 % → 1 with a green glow.
        final t = _pop.value;
        final k = !_pop.isAnimating
            ? 0.0
            : t < .4
                ? t / .4
                : 1 - (t - .4) / .6;
        return Opacity(
          opacity: _fade.value,
          child: Transform.scale(
            scaleY: 1 + 1.6 * k,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: _shown,
                borderRadius: BorderRadius.circular(3),
                boxShadow: k > 0
                    ? [
                        BoxShadow(
                            color: kRoadDone.withValues(alpha: k),
                            blurRadius: 14)
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "3 done · 2 ready · 3 to go".
class StageLegend extends StatelessWidget {
  final AchievementStage stage;
  const StageLegend({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    Widget key(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 5),
            Text(t,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        );
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        key(kRoadDone, '${stage.claimed} done'),
        if (stage.ready > 0) key(kRoadReady, '${stage.ready} ready'),
        if (stage.toGo > 0) key(_kOff, '${stage.toGo} to go'),
      ],
    );
  }
}

/// Five numbered circles, Common → Legendary. Opened stages show a check;
/// the current one glows. Tapping a stage shows its achievements.
class StageStepper extends StatelessWidget {
  final List<AchievementStage> stages;
  final int currentIndex;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const StageStepper({
    super.key,
    required this.stages,
    required this.currentIndex,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final n = stages.length;
    final doneUpTo = currentIndex < 0 ? n - 1 : currentIndex;
    return LayoutBuilder(builder: (context, box) {
      const dot = 36.0;
      final step = n > 1 ? (box.maxWidth - dot) / (n - 1) : 0.0;
      return SizedBox(
        height: 58,
        child: Stack(
          children: [
            const Positioned(
              left: dot / 2,
              right: dot / 2,
              top: dot / 2 - 1,
              height: 2,
              child: ColoredBox(color: Color(0xFF1E2632)),
            ),
            AnimatedPositioned(
              duration: AppMotion.duration(
                  context, const Duration(milliseconds: 600)),
              curve: Curves.easeInOut,
              left: dot / 2,
              top: dot / 2 - 1,
              height: 2,
              width: step * doneUpTo,
              child: const ColoredBox(color: kRoadDone),
            ),
            for (final (i, s) in stages.indexed)
              Positioned(
                left: step * i - 10,
                top: 0,
                width: dot + 20,
                child: _StepDot(
                  number: i + 1,
                  tier: s.tier,
                  opened: s.chestOpened,
                  current: i == currentIndex,
                  selected: i == selectedIndex,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final String tier;
  final bool opened;
  final bool current;
  final bool selected;
  final VoidCallback onTap;
  const _StepDot({
    required this.number,
    required this.tier,
    required this.opened,
    required this.current,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = tierColor(tier);
    final active = current || selected;
    return Semantics(
      button: true,
      label: 'Stage $number, $tier',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppMotion.duration(
                  context, const Duration(milliseconds: 400)),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: opened ? kRoadDone : const Color(0xFF0D1117),
                border: Border.all(
                  color: opened
                      ? kRoadDone
                      : active
                          ? c
                          : _kOff,
                  width: active && !opened ? 2.5 : 1.5,
                ),
                boxShadow: current && !opened
                    ? [
                        const BoxShadow(
                            color: Color(0xFF040810), spreadRadius: 4),
                        BoxShadow(
                            color: c.withValues(alpha: .55), blurRadius: 16),
                      ]
                    : null,
              ),
              child: opened
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: Color(0xFF04130A))
                  : Text('$number',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: active ? c : AppColors.textMuted)),
            ),
            const SizedBox(height: 5),
            Text(
              tier,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active
                    ? AppColors.textPrimary
                    : opened
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The stage's chest goal: headline, chest art, pieces bar and legend.
///
/// * chest ready → the card pulses gold, the chest hops, "Open …" appears.
/// * [completing] (the claim that just finished the stage) → "Stage N
///   complete!" in green, "X of X done · chest unlocked", gold pulse ×2 and
///   two chest hops, no button — the chest popup follows.
/// * [nudge] changes → the chest wiggles and the headline flashes green.
/// * [chestAway] → the card's chest dims while the popup shows it big.
/// * [arrived] → a stage the road just moved on to: its chest drops in and
///   its pieces fade in.
class StageCard extends StatefulWidget {
  final AchievementStage stage;
  final int number;
  final int count;
  final FxAnchor chestAnchor;
  final bool completing;
  final bool chestAway;
  final bool arrived;
  final int nudge;
  final VoidCallback? onOpenChest;
  const StageCard({
    super.key,
    required this.stage,
    required this.number,
    required this.count,
    required this.chestAnchor,
    this.completing = false,
    this.chestAway = false,
    this.arrived = false,
    this.nudge = 0,
    this.onOpenChest,
  });

  @override
  State<StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<StageCard> with TickerProviderStateMixin {
  // Chest-ready loop (gold pulse, hop).
  late final AnimationController _loop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  // One-shot wiggle + headline flash after a claim.
  late final AnimationController _nudge = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
  // Chest drop-in when the road moves on to this stage.
  late final AnimationController _drop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700), value: 1);

  bool get _motion => AppMotion.isFull(context);
  bool get _ready => widget.stage.chestReady || widget.completing;

  void _sync() {
    if (_ready && _motion) {
      if (widget.completing) {
        _loop.repeat(count: 2); // scGold 1s × 2, scHop × 2
      } else if (!_loop.isAnimating) {
        _loop.repeat();
      }
    } else {
      _loop.stop();
      _loop.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
    if (widget.arrived && _drop.value == 1 && _motion) {
      _drop.value = 0;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _drop.forward();
      });
    }
  }

  @override
  void didUpdateWidget(StageCard old) {
    super.didUpdateWidget(old);
    if (old.completing != widget.completing ||
        old.stage.chestReady != widget.stage.chestReady) {
      _sync();
    }
    if (old.nudge != widget.nudge && _motion) _nudge.forward(from: 0);
  }

  @override
  void dispose() {
    _loop.dispose();
    _nudge.dispose();
    _drop.dispose();
    super.dispose();
  }

  // scDrop: from −120 px, squash on landing, settle.
  Offset _dropOffset(double t) {
    if (t >= 1) return Offset.zero;
    if (t < .58) {
      return Offset(
          0, -120 * (1 - Curves.easeIn.transform(t / .58)) + 10 * (t / .58));
    }
    if (t < .78) return Offset(0, 10 - 16 * ((t - .58) / .2));
    return Offset(0, -6 * (1 - (t - .78) / .22));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stage;
    final c = tierColor(s.tier);
    final completing = widget.completing;
    final ready = _ready;
    return AnimatedBuilder(
      animation: Listenable.merge([_loop, _nudge, _drop]),
      builder: (context, _) {
        final t = _loop.value;
        final pulse = ready && _loop.isAnimating
            ? (1 - math.cos(t * 2 * math.pi)) / 2
            : 0.0;
        // scHop: up 14 px at 30 %, down, up 6 px at 70 %.
        final hop = !ready || !_loop.isAnimating
            ? 0.0
            : t < .3
                ? 14 * math.sin(t / .3 * math.pi / 2)
                : t < .55
                    ? 14 * math.cos((t - .3) / .25 * math.pi / 2)
                    : t < .85
                        ? 6 * math.sin((t - .55) / .3 * math.pi)
                        : 0.0;
        // rrWiggle: rotate −9°, +8°, −5°, +3° over 0.7 s.
        final n = _nudge.value;
        final wiggling = _nudge.isAnimating;
        final wiggle = wiggling && n < .875
            ? math.sin(n / .875 * 4 * math.pi) * (1 - n / .875) * .16
            : 0.0;
        final flash = wiggling ? math.sin(n * math.pi) : 0.0;
        final border = Color.lerp(c.withValues(alpha: .5), kRoadReady, pulse)!;
        final headline =
            completing ? 'Stage ${widget.number} complete!' : stageHeadline(s);
        final headColor = completing
            ? kRoadDone
            : Color.lerp(s.chestReady ? kRoadReady : AppColors.textPrimary,
                kRoadDone, flash)!;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: _kSurface,
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.3,
              colors: [
                c.withValues(alpha: .18),
                _kSurface.withValues(alpha: 0)
              ],
            ),
            border: Border.all(color: border, width: 1.5),
            boxShadow: pulse > 0
                ? [
                    BoxShadow(
                        color: kRoadReady.withValues(alpha: .65 * pulse),
                        blurRadius: 34 * pulse)
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STAGE ${widget.number} OF ${widget.count} · ${s.tier.toUpperCase()}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: c),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          headline,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: headColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Transform.translate(
                    offset:
                        _dropOffset(_drop.value) + Offset(0, -hop - 4 * flash),
                    child: Transform.rotate(
                      angle: wiggle,
                      alignment: Alignment.bottomCenter,
                      child: FxAnchorTarget(
                        anchor: widget.chestAnchor,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: widget.chestAway
                              ? .15
                              : s.chestOpened
                                  ? .45
                                  : 1,
                          child: Image.asset(
                            AppIcons.shopChestForKey(s.chestKey),
                            width: 76,
                            height: 76,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StagePips(stage: s, fadeIn: widget.arrived),
              const SizedBox(height: 10),
              if (completing)
                Text('${s.total} of ${s.total} done · chest unlocked',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary))
              else if (s.chestReady && widget.onOpenChest != null)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: widget.onOpenChest,
                    style: FilledButton.styleFrom(
                      backgroundColor: kRoadReady,
                      foregroundColor: const Color(0xFF1A1004),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    child: Text('Open ${s.chestName}'),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(child: StageLegend(stage: s)),
                    RewardLine(
                        xp: 0,
                        coins: s.chestCoins,
                        gems: s.chestGems,
                        fontSize: 10.5),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Achievement icon in a circle; dashed ring while still in progress.
class AchievementBadge extends StatelessWidget {
  final AchievementDto a;
  final double size;
  const AchievementBadge({super.key, required this.a, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final c = a.isUnlocked ? kRoadDone : tierColor(a.tier);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: a.isUnlocked
            ? kRoadDone.withValues(alpha: .18)
            : const Color(0xFF0D1117),
        border: Border.all(
            color: a.isUnlocked ? c : c.withValues(alpha: .55),
            width: a.isUnlocked ? 2 : 1.5),
      ),
      child: Text(a.icon, style: TextStyle(fontSize: size * .45, height: 1)),
    );
  }
}

/// An unlocked achievement waiting to be claimed. When [claiming] turns on
/// the row glows gold, a ring pulses and a check stamps in where Claim was;
/// [folded] folds it away.
class ReadyRow extends StatefulWidget {
  final AchievementDto a;
  final bool claiming;
  final bool folded;
  final FxAnchor anchor;
  final FxAnchor coinAnchor;
  final FxAnchor gemAnchor;
  final VoidCallback? onClaim;
  const ReadyRow({
    super.key,
    required this.a,
    required this.claiming,
    required this.anchor,
    required this.coinAnchor,
    required this.gemAnchor,
    required this.onClaim,
    this.folded = false,
  });

  @override
  State<ReadyRow> createState() => _ReadyRowState();
}

class _ReadyRowState extends State<ReadyRow> with TickerProviderStateMixin {
  // rrGlow (0.7 s) and rrRing (0.6 s).
  late final AnimationController _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _ring = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void didUpdateWidget(ReadyRow old) {
    super.didUpdateWidget(old);
    if (!old.claiming && widget.claiming && AppMotion.isFull(context)) {
      _glow.forward(from: 0);
      _ring.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final claiming = widget.claiming;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.folded ? 0 : 1),
      duration: AppMotion.duration(context, const Duration(milliseconds: 350)),
      curve: Curves.easeInOut,
      builder: (context, v, child) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: v,
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: FxAnchorTarget(
          anchor: widget.anchor,
          child: AnimatedBuilder(
            animation: Listenable.merge([_glow, _ring]),
            builder: (context, _) {
              final g = _glow.value;
              final glow = !_glow.isAnimating
                  ? (claiming ? .35 : 0.0)
                  : g < .45
                      ? g / .45
                      : 1 - .6 * ((g - .45) / .55);
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [
                    kRoadReady.withValues(alpha: claiming ? .26 : .14),
                    _kSurface,
                  ], stops: const [
                    0,
                    .7
                  ]),
                  border: Border.all(color: kRoadReady.withValues(alpha: .55)),
                  boxShadow: glow > 0
                      ? [
                          BoxShadow(
                              color: kRoadReady.withValues(alpha: .7 * glow),
                              blurRadius: 26 * glow)
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    AchievementBadge(a: a),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          RewardLine(
                            xp: a.xpReward,
                            coins: a.coinReward,
                            gems: a.gemReward,
                            coinAnchor: widget.coinAnchor,
                            gemAnchor: widget.gemAnchor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      height: 38,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerRight,
                        children: [
                          if (claiming) ...[
                            Positioned(
                              right: 12,
                              child: _Ring(
                                  t: _ring.value, active: _ring.isAnimating),
                            ),
                            Positioned(
                              right: 12,
                              child: _Stamp(key: ValueKey('stamp-${a.id}')),
                            ),
                          ] else
                            SizedBox(
                              height: 38,
                              child: FilledButton(
                                onPressed: widget.onClaim,
                                style: FilledButton.styleFrom(
                                  backgroundColor: kRoadReady,
                                  foregroundColor: const Color(0xFF1A1004),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  textStyle: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800),
                                ),
                                child: const Text('Claim'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// rrRing: gold ring from 0.5× to 2.4×, fading out.
class _Ring extends StatelessWidget {
  final double t;
  final bool active;
  const _Ring({required this.t, required this.active});

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox(width: 38, height: 38);
    final e = const Cubic(.1, .7, .3, 1).transform(t);
    return Opacity(
      opacity: (.9 * (1 - t)).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: .5 + 1.9 * e,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kRoadReady, width: 2),
          ),
        ),
      ),
    );
  }
}

/// rrStamp: green check drops in from 2.4× with a small overshoot.
class _Stamp extends StatelessWidget {
  const _Stamp({super.key});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: kRoadDone),
      child:
          const Icon(Icons.check_rounded, color: Color(0xFF04130A), size: 22),
    );
    if (!AppMotion.isFull(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (_, t, c) {
        final s = t < .6 ? 2.4 - 1.52 * (t / .6) : .88 + .12 * ((t - .6) / .4);
        return Opacity(
          opacity: (t / .6).clamp(0.0, 1.0),
          child: Transform.scale(scale: s, child: c),
        );
      },
      child: child,
    );
  }
}

/// A locked achievement with its bar and what's left, in plain words.
class ProgressRow extends StatelessWidget {
  final AchievementDto a;
  const ProgressRow({super.key, required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kLine),
      ),
      child: Row(
        children: [
          AchievementBadge(a: a, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Text(toGoLabel(a),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8CC0FF))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: a.progressPercent,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF1E2632),
                    color: kRoadActive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Claimed achievements folded into one line; tap to see them.
class DoneRow extends StatefulWidget {
  final List<AchievementDto> done;
  const DoneRow({super.key, required this.done});

  @override
  State<DoneRow> createState() => _DoneRowState();
}

class _DoneRowState extends State<DoneRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final names = widget.done.map((a) => a.title).join(', ');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kLine),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, size: 18, color: kRoadDone),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: '${widget.done.length} done',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          TextSpan(text: ' · $names'),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ),
                    Icon(
                        _open
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration:
                AppMotion.duration(context, const Duration(milliseconds: 250)),
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Column(
                      children: [
                        for (final a in widget.done)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                AchievementBadge(a: a, size: 30),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(a.title,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                ),
                                RewardLine(
                                    xp: a.xpReward,
                                    coins: a.coinReward,
                                    gems: a.gemReward,
                                    fontSize: 10,
                                    plus: false),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Faded teaser for the next stage's chest.
class UpNextRow extends StatelessWidget {
  final AchievementStage stage;
  final int number;
  const UpNextRow({super.key, required this.stage, required this.number});

  @override
  Widget build(BuildContext context) {
    final c = tierColor(stage.tier);
    final started = stage.achievements
        .where((a) => a.isUnlocked || a.currentValue > 0)
        .length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: .7,
            child: Image.asset(AppIcons.shopChestForKey(stage.chestKey),
                width: 44, height: 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UP NEXT · STAGE $number · ${stage.tier.toUpperCase()}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: c)),
                const SizedBox(height: 2),
                Text(
                  '${stage.total} achievement${stage.total == 1 ? '' : 's'}'
                  '${started > 0 ? ' · $started already started' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase section heading with an optional trailing action.
class RoadSectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  final Widget? trailing;
  const RoadSectionTitle(this.text,
      {super.key, this.color = AppColors.textSecondary, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: color)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
