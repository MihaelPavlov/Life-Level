import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../models/season_models.dart';
import 'season_theme.dart';

/// One collected Season reward, joined with the tile it came from so the
/// reveal can show the tile's art, label and rarity (the claim response only
/// carries tier, track and what was granted).
class SeasonRevealReward {
  final int tier;
  final String track;
  final String type;
  final String label;
  final String iconKey;
  final int amount;
  final String? rarity;
  final SeasonClaimResult result;

  const SeasonRevealReward({
    required this.tier,
    required this.track,
    required this.type,
    required this.label,
    required this.iconKey,
    required this.amount,
    required this.rarity,
    required this.result,
  });

  /// [before] is the track as it was before the claim.
  factory SeasonRevealReward.from(SeasonClaimResult r, SeasonTrack before) {
    SeasonRewardView? view;
    for (final t in before.tiers) {
      if (t.tier == r.tier) {
        view = r.track == 'Founder' ? t.founder : t.free;
        break;
      }
    }
    final type = view?.type ??
        (r.grantedTitleKey != null
            ? 'Title'
            : r.grantedItemName != null
                ? 'Item'
                : r.xpAwarded > 0
                    ? 'Xp'
                    : 'None');
    return SeasonRevealReward(
      tier: r.tier,
      track: r.track,
      type: type,
      label: view?.label ?? r.label,
      iconKey: view?.iconKey ?? '',
      amount: view?.amount ?? r.xpAwarded,
      rarity: view?.rarity,
      result: r,
    );
  }

  bool get isFounder => track == 'Founder';
  bool get isXp => type == 'Xp';
  bool get isSeasonXp => type == 'SeasonXp';

  int get xp => result.xpAwarded > 0 ? result.xpAwarded : (isXp ? amount : 0);
  int get seasonXp => isSeasonXp ? amount : 0;

  /// What the player reads as the reward's name.
  String get name {
    if (isXp) return '+$xp XP';
    if (isSeasonXp) return '+$amount Season XP';
    return label;
  }

  String get kind => switch (type) {
        'Xp' => 'XP',
        'SeasonXp' => 'Season XP',
        'Item' => 'Item',
        'StreakShield' => 'Protects your streak',
        'Title' => 'Title',
        'Cosmetic' => 'Cosmetic',
        _ => 'Reward',
      };

  /// Accent: rarity first, then the reward's currency colour.
  Color get accent =>
      seasonRarityColor(rarity) ??
      switch (type) {
        'Xp' => AppColors.green,
        'SeasonXp' => AppColors.orange,
        'StreakShield' => AppColors.blue,
        'Title' => AppColors.purple,
        _ => AppColors.textSecondary,
      };

  /// Value colour on cards and rows: currencies keep their colour, items and
  /// titles read in the primary text colour.
  Color get valueColor => isXp
      ? AppColors.green
      : isSeasonXp
          ? AppColors.orange
          : AppColors.textPrimary;

  /// Short tag on the right of a list row.
  String get tag {
    if (isXp) return '+$xp XP';
    if (isSeasonXp) return '+$amount SXP';
    final r = rarity;
    if (r != null && r.isNotEmpty) {
      return r[0].toUpperCase() + r.substring(1);
    }
    return kind;
  }

  /// One line under the single-reward reveal saying where the reward went.
  String get destination => switch (type) {
        'Xp' => 'Added to your level',
        'SeasonXp' => 'Counts toward your next tier',
        'Item' => '${result.grantedItemName ?? label} added to your bag',
        'StreakShield' => 'Covers one missed day of your streak',
        'Title' => 'New title unlocked — equip it from Titles',
        _ => 'Added to your account',
      };
}

/// Full-screen reveal shown after collecting Season rewards. Replaces the old
/// auto-dismissing bottom sheet:
///   * 1 reward   → centred reveal: big art, name, rarity, where it went
///   * 2–4        → summary: XP / Season XP totals and a 2-column card grid
///   * 5 or more  → summary: total XP (+ level up), a highlighted title, and
///                  compact rows grouped by track
/// Resolves when the player taps Continue.
Future<void> showSeasonClaimReveal(
  BuildContext context, {
  required List<SeasonClaimResult> results,
  required SeasonTrack before,
}) {
  if (results.isEmpty) return Future<void>.value();
  final rewards = [
    for (final r in results) SeasonRevealReward.from(r, before),
  ]..sort((a, b) {
      final t = a.tier.compareTo(b.tier);
      return t != 0 ? t : (a.isFounder ? 1 : 0) - (b.isFounder ? 1 : 0);
    });
  return showAppCelebration<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xEB040810),
    builder: (_) => SeasonClaimReveal(
      rewards: rewards,
      seasonName: before.season?.name ?? 'Season',
    ),
  );
}

class SeasonClaimReveal extends StatefulWidget {
  final List<SeasonRevealReward> rewards;
  final String seasonName;
  const SeasonClaimReveal(
      {super.key, required this.rewards, required this.seasonName});

  @override
  State<SeasonClaimReveal> createState() => _SeasonClaimRevealState();
}

class _SeasonClaimRevealState extends State<SeasonClaimReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  List<SeasonRevealReward> get rewards => widget.rewards;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.value > 0) return;
    if (AppMotion.isFull(context)) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  int? get _newLevel {
    int? level;
    for (final r in rewards) {
      if (r.result.leveledUp && r.result.newLevel != null) {
        level = r.result.newLevel;
      }
    }
    return level;
  }

  /// Fades and lifts a piece in, [order] steps of 80 ms after [start] ms.
  Widget _in(Widget child, {double start = 0, int order = 0}) {
    final begin = ((start + order * 80) / 1100).clamp(0.0, .9);
    final anim = CurvedAnimation(
      parent: _c,
      curve: Interval(begin, math.min(1, begin + .35),
          curve: const Cubic(.2, 1, .3, 1)),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
            offset: Offset(0, 16 * (1 - anim.value)), child: c),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = _newLevel;
    final content = rewards.length == 1
        ? _single(rewards.first)
        : rewards.length <= 4
            ? _grid()
            : _list(level);
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: content,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _in(_continue(level), start: 500),
            ],
          ),
        ),
      ),
    );
  }

  Widget _continue(int? level) {
    final up = level != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          backgroundColor: up ? AppColors.orange : AppColors.blue,
          foregroundColor:
              up ? const Color(0xFF1A1002) : const Color(0xFF04101F),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        child: Text(up ? 'Continue to Level $level' : 'Continue'),
      ),
    );
  }

  // ── 1 reward ───────────────────────────────────────────────────────────────

  Widget _single(SeasonRevealReward r) {
    final accent = r.accent;
    final rarity = r.rarity;
    final pop = CurvedAnimation(
        parent: _c, curve: const Interval(0, .55, curve: Curves.easeOutBack));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _in(Text('${r.track.toUpperCase()} TRACK · TIER ${r.tier}',
            style: _label(AppColors.orange))),
        const SizedBox(height: 6),
        _in(
            const Text('Reward collected',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            order: 1),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: pop,
          builder: (_, child) => Opacity(
            opacity: _c.value < .1 ? _c.value / .1 : 1,
            child: Transform.scale(scale: .6 + .4 * pop.value, child: child),
          ),
          child: _art(r, accent),
        ),
        const SizedBox(height: 18),
        _in(
            Text(r.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: r.isXp || r.isSeasonXp
                        ? r.valueColor
                        : AppColors.textPrimary)),
            start: 300),
        const SizedBox(height: 8),
        _in(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (rarity != null && rarity.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(rarity.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: accent)),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(r.kind,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ],
            ),
            start: 300,
            order: 1),
        const SizedBox(height: 20),
        _in(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: _panel(),
              child: Row(
                children: [
                  Icon(_destinationIcon(r.type),
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r.destination,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            start: 300,
            order: 2),
      ],
    );
  }

  /// Glow, eight rays and the ringed reward art.
  Widget _art(SeasonRevealReward r, Color accent) {
    const box = 220.0;
    Widget ray(double angle, double len, double alpha) => Transform.rotate(
          angle: angle,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 2,
              height: len,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                accent.withValues(alpha: .30),
                accent.withValues(alpha: 0),
              ]),
            ),
            child: const SizedBox.expand(),
          ),
          for (var i = 0; i < 8; i++)
            Positioned.fill(
              child: ray(
                  i * math.pi / 4, i.isEven ? 34 : 26, i.isEven ? .55 : .35),
            ),
          Container(
            width: 132,
            height: 132,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0E151E),
              border: Border.all(color: accent.withValues(alpha: .6), width: 2),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: .35), blurRadius: 40),
              ],
            ),
            child: SeasonRewardAsset(iconKey: r.iconKey, size: 92),
          ),
        ],
      ),
    );
  }

  IconData _destinationIcon(String type) => switch (type) {
        'Item' => Icons.shopping_bag_outlined,
        'Title' => Icons.military_tech_outlined,
        'StreakShield' => Icons.shield_outlined,
        _ => Icons.trending_up_rounded,
      };

  // ── 2–4 rewards ────────────────────────────────────────────────────────────

  Widget _grid() {
    final xp = rewards.fold(0, (s, r) => s + r.xp);
    final sxp = rewards.fold(0, (s, r) => s + r.seasonXp);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _headline(),
        if (xp > 0 || sxp > 0) ...[
          const SizedBox(height: 20),
          _in(
              Row(
                children: [
                  if (xp > 0)
                    Expanded(
                        child: _total(
                            'XP', '+$xp', AppColors.green, 'to your level')),
                  if (xp > 0 && sxp > 0) const SizedBox(width: 10),
                  if (sxp > 0)
                    Expanded(
                        child: _total('SEASON XP', '+$sxp', AppColors.orange,
                            'toward your next tier')),
                ],
              ),
              order: 2),
        ],
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (i, r) in rewards.indexed)
                SizedBox(width: w, child: _in(_card(r), start: 250, order: i)),
            ],
          );
        }),
      ],
    );
  }

  Widget _card(SeasonRevealReward r) {
    final rarity = seasonRarityColor(r.rarity);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111821),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: rarity?.withValues(alpha: .55) ?? const Color(0xFF1E2732),
            width: 1.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -6,
            left: -2,
            child: _chip(r.isFounder ? 'T${r.tier} · F' : 'T${r.tier}',
                r.isFounder ? AppColors.orange : AppColors.textSecondary),
          ),
          Column(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: r.accent.withValues(alpha: .12),
                ),
                child: SeasonRewardAsset(iconKey: r.iconKey, size: 44),
              ),
              const SizedBox(height: 8),
              Text(r.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: r.valueColor)),
              const SizedBox(height: 4),
              Text(r.kind,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── 5+ rewards ─────────────────────────────────────────────────────────────

  Widget _list(int? level) {
    final xp = rewards.fold(0, (s, r) => s + r.xp);
    final titles = rewards.where((r) => r.type == 'Title').toList();
    final free = rewards.where((r) => !r.isFounder && r.type != 'Title');
    final founder = rewards.where((r) => r.isFounder && r.type != 'Title');
    var order = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _headline(),
        if (xp > 0 || level != null) ...[
          const SizedBox(height: 16),
          _in(_xpCard(xp, level), order: 2),
        ],
        for (final t in titles) ...[
          const SizedBox(height: 10),
          _in(_titleRow(t), start: 200),
        ],
        for (final (name, color, group) in [
          ('FREE TRACK', AppColors.textSecondary, free.toList()),
          ('FOUNDER TRACK', AppColors.orange, founder.toList()),
        ])
          if (group.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(name, style: _label(color))),
                Text('${group.length}', style: _label(color)),
              ],
            ),
            const SizedBox(height: 6),
            for (final r in group)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _in(_row(r), start: 250, order: order++),
              ),
          ],
      ],
    );
  }

  Widget _xpCard(int xp, int? level) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E151E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: level != null
                  ? AppColors.orange.withValues(alpha: .5)
                  : const Color(0xFF1E2732),
              width: 1.5),
        ),
        child: Row(
          children: [
            const SeasonRewardAsset(iconKey: 'reward_xp_sparkle', size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL XP', style: _label(AppColors.textSecondary)),
                  Text('+$xp XP',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: AppColors.green,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ],
              ),
            ),
            if (level != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('LEVEL UP', style: _label(AppColors.orange)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.arrow_forward_rounded,
                          size: 14, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text('$level',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.orange)),
                    ],
                  ),
                ],
              ),
          ],
        ),
      );

  Widget _titleRow(SeasonRevealReward r) {
    final rarity = r.rarity;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF120F1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.purple.withValues(alpha: .55), width: 1.5),
      ),
      child: Row(
        children: [
          SeasonRewardAsset(iconKey: r.iconKey, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    rarity == null || rarity.isEmpty
                        ? 'NEW TITLE'
                        : 'NEW TITLE · ${rarity.toUpperCase()}',
                    style: _label(AppColors.purple)),
                const SizedBox(height: 2),
                Text(r.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(SeasonRevealReward r) {
    final tagColor = r.isXp
        ? AppColors.green
        : r.isSeasonXp
            ? AppColors.orange
            : seasonRarityColor(r.rarity) ?? AppColors.textSecondary;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E151E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: r.isFounder
                ? AppColors.orange.withValues(alpha: .22)
                : const Color(0xFF1E2732)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('T${r.tier}',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6E7B88))),
          ),
          SeasonRewardAsset(iconKey: r.iconKey, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(r.isXp || r.isSeasonXp ? r.kind : r.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 8),
          Text(r.tag,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: tagColor)),
        ],
      ),
    );
  }

  // ── Shared ─────────────────────────────────────────────────────────────────

  Widget _headline() {
    final lo = rewards.map((r) => r.tier).reduce(math.min);
    final hi = rewards.map((r) => r.tier).reduce(math.max);
    final hasFree = rewards.any((r) => !r.isFounder);
    final hasFounder = rewards.any((r) => r.isFounder);
    final tiers = lo == hi ? 'Tier $lo' : 'Tiers $lo – $hi';
    return Column(
      children: [
        _in(Text('${widget.seasonName} · $tiers'.toUpperCase(),
            textAlign: TextAlign.center, style: _label(AppColors.orange))),
        const SizedBox(height: 6),
        _in(
            Text('${rewards.length} rewards collected',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            order: 1),
        const SizedBox(height: 4),
        _in(
            Text(
                hasFree && hasFounder
                    ? 'Free + Founder tracks'
                    : hasFounder
                        ? 'Founder track'
                        : 'Free track',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            order: 1),
      ],
    );
  }

  Widget _total(String label, String value, Color color, String sub) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _label(AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 4),
            Text(sub,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: color)),
      );

  BoxDecoration _panel() => BoxDecoration(
        color: const Color(0xFF0E151E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2732)),
      );

  TextStyle _label(Color color) => TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.6,
      color: color);
}
