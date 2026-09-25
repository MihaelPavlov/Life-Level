import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/reward_fx.dart';
import '../models/season_models.dart';
import 'season_reward_slot.dart';

/// One row of the track: [Free slot] · [tier badge rail] · [Founder slot].
///
/// "Track ride": when this tier becomes reached, a glowing marker rides
/// down from the row above into the badge, which then pops with a burst.
class SeasonTierRow extends StatefulWidget {
  final SeasonTier tier;
  final void Function(int tier, String track) onClaim;

  const SeasonTierRow({super.key, required this.tier, required this.onClaim});

  @override
  State<SeasonTierRow> createState() => _SeasonTierRowState();
}

class _SeasonTierRowState extends State<SeasonTierRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380))
    ..addListener(() => setState(() {}));
  final _badgeKey = GlobalKey();

  SeasonTier get tier => widget.tier;
  void Function(int tier, String track) get onClaim => widget.onClaim;

  static bool _reached(SeasonTier t) =>
      t.free.state == SeasonRewardState.received ||
      t.free.state == SeasonRewardState.ready;

  @override
  void didUpdateWidget(SeasonTierRow old) {
    super.didUpdateWidget(old);
    if (_reached(old.tier) || !_reached(tier)) return;
    if (!RewardFx.enabled(context)) return;
    final c = RewardFx.centerOf(_badgeKey);
    if (c == null) return;
    final rowH = context.size?.height ?? 86;
    final from = c - Offset(0, rowH);
    RewardFx.run(
      context,
      duration: const Duration(milliseconds: 600),
      builder: (t, origin) {
        final p =
            Offset.lerp(from, c, const Cubic(.4, 0, .2, 1).transform(t))! -
                origin;
        return Positioned(
          left: p.dx - 18,
          top: p.dy - 18,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.orange, width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.orange, blurRadius: 12),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (!mounted) return;
      _pop.forward(from: 0);
      RewardFx.ring(context, c, AppColors.orange, maxRadius: 34);
      RewardFx.burst(context, c, AppColors.green, count: 8, distance: 30);
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _pop.value;
    final k = _pop.isAnimating ? (t < .5 ? t / .5 : 1 - (t - .5) / .5) : 0.0;
    final freeReached = tier.free.state == SeasonRewardState.received ||
        tier.free.state == SeasonRewardState.ready;
    final badgeReady = tier.free.state == SeasonRewardState.ready ||
        tier.founder.state == SeasonRewardState.ready;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      // IntrinsicHeight gives the Row a concrete height so the centered badge
      // rail lays out inside a scrolling ListView (which supplies unbounded
      // vertical constraints).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SeasonRewardSlot(
                reward: tier.free,
                isFounderLane: false,
                onClaim: () => onClaim(tier.tier, 'Free'),
              ),
            ),
            SizedBox(
              width: 44,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 1 + .3 * k,
                    child: Container(
                      key: _badgeKey,
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: freeReached
                            ? const Color(0xFF0f1c12)
                            : AppColors.surfaceElevated,
                        border: Border.all(
                          color: badgeReady
                              ? AppColors.green
                              : (freeReached
                                  ? const Color(0xFF234a2a)
                                  : AppColors.border),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: badgeReady
                            ? [
                                BoxShadow(
                                  color: AppColors.green.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        '${tier.tier}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: freeReached
                              ? AppColors.green
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (tier.isMilestone)
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text('★',
                          style:
                              TextStyle(fontSize: 10, color: AppColors.purple)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SeasonRewardSlot(
                reward: tier.founder,
                isFounderLane: true,
                onClaim: () => onClaim(tier.tier, 'Founder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
