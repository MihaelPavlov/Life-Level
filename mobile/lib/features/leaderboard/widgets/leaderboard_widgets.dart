import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/avatar_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../models/leaderboard_models.dart';

const kPodiumGold = Color(0xFFFFD27A);
const kPodiumSilver = Color(0xFFC9D4E3);
const kPodiumBronze = Color(0xFFE8A35C);

/// Top three on pedestals, 2nd · 1st · 3rd. Each character is centred on its
/// pedestal and stands on it, so all three share one baseline.
class LeaderboardPodium extends StatelessWidget {
  final List<LeaderboardEntry> top;
  final LeaderboardMetric metric;

  const LeaderboardPodium({super.key, required this.top, required this.metric});

  static const _heroH = [150.0, 128.0, 118.0];
  static const _pedestalH = [62.0, 46.0, 36.0];
  static const _colors = [kPodiumGold, kPodiumSilver, kPodiumBronze];

  @override
  Widget build(BuildContext context) {
    Widget slot(int place) => Expanded(
          child: place < top.length
              ? _PodiumColumn(
                  entry: top[place],
                  metric: metric,
                  heroHeight: _heroH[place],
                  pedestalHeight: _pedestalH[place],
                  color: _colors[place],
                )
              : const SizedBox.shrink(),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        slot(1),
        const SizedBox(width: 8),
        slot(0),
        const SizedBox(width: 8),
        slot(2)
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final LeaderboardMetric metric;
  final double heroHeight;
  final double pedestalHeight;
  final Color color;

  const _PodiumColumn({
    required this.entry,
    required this.metric,
    required this.heroHeight,
    required this.pedestalHeight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${entry.username}, rank ${entry.rank}, ${metric.format(entry.score)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: heroHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Soft glow in the pedestal colour where the feet land.
                Positioned(
                  bottom: -12,
                  child: Transform.scale(
                    scaleX: 3.6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          color.withValues(alpha: 0.6),
                          color.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                  ),
                ),
                Image.asset(AppIcons.leaderboardHero,
                    height: heroHeight, fit: BoxFit.fitHeight),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.isMe ? 'You' : entry.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: entry.isMe
                    ? const Color(0xFF7DB6FF)
                    : AppColors.textPrimary),
          ),
          Text(metric.format(entry.score),
              maxLines: 1,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Container(
            height: pedestalHeight,
            width: double.infinity,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.25)
                ],
              ),
              border: Border(
                top: BorderSide(color: color),
                left: BorderSide(color: color),
                right: BorderSide(color: color),
              ),
            ),
            child: Text('${entry.rank}',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      ),
    );
  }
}

/// Round avatar from the player's avatar key, with the emoji as a fallback.
class LeaderboardAvatar extends StatelessWidget {
  final String? avatarEmoji;
  final double size;
  final Color border;

  const LeaderboardAvatar(
      {super.key,
      required this.avatarEmoji,
      this.size = 34,
      this.border = Colors.transparent});

  @override
  Widget build(BuildContext context) {
    final asset = avatarIconAsset(avatarEmoji);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceElevated,
        border: Border.all(color: border, width: 2),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: asset != null
          ? Image.asset(asset, width: size - 4, height: size - 4)
          : Text(avatarEmoji ?? '🙂', style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// A ranked row below the podium.
class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final LeaderboardMetric metric;

  const LeaderboardRow({super.key, required this.entry, required this.metric});

  @override
  Widget build(BuildContext context) {
    final sub = [
      'Lv ${entry.level}',
      if (entry.className != null && entry.className!.isNotEmpty)
        entry.className!,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: entry.isMe ? const Color(0xFF0F1D33) : null,
        border:
            const Border(bottom: BorderSide(color: AppColors.surfaceElevated)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('${entry.rank}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary)),
          ),
          LeaderboardAvatar(avatarEmoji: entry.avatarEmoji),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.isMe ? 'You' : entry.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: entry.isMe
                            ? const Color(0xFF7DB6FF)
                            : AppColors.textPrimary)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(metric.format(entry.score),
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

/// The rank-up chest on your row. It pops in when rewards are stacked,
/// bobs while waiting, and shows how many players you passed.
class RankUpChestButton extends StatefulWidget {
  final int stack;
  final bool busy;
  final VoidCallback onTap;

  const RankUpChestButton(
      {super.key, required this.stack, required this.onTap, this.busy = false});

  @override
  State<RankUpChestButton> createState() => _RankUpChestButtonState();
}

class _RankUpChestButtonState extends State<RankUpChestButton>
    with TickerProviderStateMixin {
  late final _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600))
    ..forward();
  late final _bob = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);

  @override
  void didUpdateWidget(RankUpChestButton old) {
    super.didUpdateWidget(old);
    // A new pass bumps the chest again.
    if (widget.stack > old.stack) _pop.forward(from: 0.4);
  }

  @override
  void dispose() {
    _pop.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open rank-up chest, ${widget.stack} players passed',
      child: AppPressable(
        onTap: widget.busy ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pop, _bob]),
          builder: (context, child) {
            final pop = Curves.elasticOut.transform(_pop.value.clamp(0.0, 1.0));
            final bob = -3 * Curves.easeInOut.transform(_bob.value);
            return Transform.scale(
                scale: pop,
                child:
                    Transform.translate(offset: Offset(0, bob), child: child));
          },
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const RadialGradient(
                        colors: [Color(0xFF3A2A0C), Color(0xFF1E1608)]),
                    border: Border.all(color: AppColors.orange, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.45),
                          blurRadius: 14),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(AppIcons.rewardTreasureChest,
                      width: 36, height: 36),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text('×${widget.stack}',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gold "you climbed" pill; shows once, then fades away.
class ClimbedPill extends StatefulWidget {
  final int stack;
  const ClimbedPill({super.key, required this.stack});

  @override
  State<ClimbedPill> createState() => _ClimbedPillState();
}

class _ClimbedPillState extends State<ClimbedPill>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200))
    ..forward();

  @override
  void didUpdateWidget(ClimbedPill old) {
    super.didUpdateWidget(old);
    if (widget.stack > old.stack) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value * 3200;
        final inT = (t / 400).clamp(0.0, 1.0);
        final outT = ((t - 2600) / 600).clamp(0.0, 1.0);
        return Opacity(
          opacity: (1 - outT) * inT,
          child: Transform.scale(
              scale: Curves.easeOutBack.transform(inT), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
              colors: [Color(0xFFFFC24D), AppColors.orange]),
          boxShadow: [
            BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Text(
          widget.stack == 1
              ? '▲ You climbed · a chest reward stacked'
              : '▲ You climbed · ${widget.stack} rewards stacked',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1204)),
        ),
      ),
    );
  }
}
