import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/reward_fx.dart';
import '../models/season_models.dart';
import 'season_theme.dart';

/// A single reward tile — one of four states: received / locked / pending / ready.
/// Tapping a `ready` tile calls [onClaim].
///
/// State changes animate: becoming `ready` pops the tile with a glow;
/// being claimed (`ready` → `received`) bursts rays out of the icon while
/// the reward icon flies up and fades.
class SeasonRewardSlot extends StatefulWidget {
  final SeasonRewardView reward;
  final bool isFounderLane;
  final VoidCallback? onClaim;

  const SeasonRewardSlot({
    super.key,
    required this.reward,
    required this.isFounderLane,
    this.onClaim,
  });

  @override
  State<SeasonRewardSlot> createState() => _SeasonRewardSlotState();
}

class _SeasonRewardSlotState extends State<SeasonRewardSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380))
    ..addListener(() => setState(() {}));
  final _icon = FxAnchor();

  @override
  void didUpdateWidget(SeasonRewardSlot old) {
    super.didUpdateWidget(old);
    final was = old.reward.state, now = widget.reward.state;
    if (was == now || !RewardFx.enabled(context)) return;
    if (now == SeasonRewardState.ready) {
      _pop.forward(from: 0);
    } else if (was == SeasonRewardState.ready &&
        now == SeasonRewardState.received) {
      final c = _icon.center;
      if (c == null) return;
      RewardFx.rays(context, c, AppColors.green, radius: 64);
      RewardFx.burst(context, c, AppColors.green, count: 10, distance: 40);
      RewardFx.run(
        context,
        duration: const Duration(milliseconds: 900),
        builder: (t, origin) {
          final p = c - origin + Offset(0, -72 * Curves.easeOut.transform(t));
          final scale = t < .5 ? 1 + .8 * (t / .5) : 1.8 - .4 * ((t - .5) / .5);
          return Positioned(
            left: p.dx - 16,
            top: p.dy - 16,
            child: Opacity(
              opacity: t < .5 ? 1 : 1 - (t - .5) / .5,
              child: Transform.scale(
                scale: scale,
                child: Image.asset(seasonIconAsset(widget.reward.iconKey),
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _pop.value;
    final k = _pop.isAnimating ? (t < .6 ? t / .6 : 1 - (t - .6) / .4) : 0.0;
    return Transform.scale(
      scale: 1 + .04 * k,
      child: _SlotBody(
        reward: widget.reward,
        isFounderLane: widget.isFounderLane,
        onClaim: widget.onClaim,
        icon: _icon,
      ),
    );
  }
}

class _SlotBody extends StatelessWidget {
  final SeasonRewardView reward;
  final bool isFounderLane;
  final VoidCallback? onClaim;
  final FxAnchor icon;

  const _SlotBody({
    required this.reward,
    required this.isFounderLane,
    required this.onClaim,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ready = reward.state == SeasonRewardState.ready;
    final pending = reward.state == SeasonRewardState.pending;
    final received = reward.state == SeasonRewardState.received;
    final locked = reward.state == SeasonRewardState.locked ||
        reward.state == SeasonRewardState.unknown;

    Color border = AppColors.border;
    Color? glow;
    Gradient? bg;
    if (ready) {
      border = AppColors.green;
      glow = AppColors.green.withValues(alpha: 0.5);
      bg = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.green.withValues(alpha: 0.12), AppColors.surface],
      );
    } else if (pending) {
      border = AppColors.orange;
      glow = AppColors.orange.withValues(alpha: 0.4);
      bg = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.orange.withValues(alpha: 0.09), AppColors.surface],
      );
    }

    final rarityColor = seasonRarityColor(reward.rarity);

    final tile = Opacity(
      opacity: received ? 0.42 : (locked ? 0.5 : 1.0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          gradient: bg,
          border: Border.all(color: border, width: ready || pending ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: glow == null
              ? null
              : [BoxShadow(color: glow, blurRadius: 20, spreadRadius: -6)],
        ),
        child: Row(
          children: [
            FxAnchorTarget(
              anchor: icon,
              child: SeasonRewardAsset(
                iconKey: reward.iconKey,
                size: 32,
                locked: locked && !received,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reward.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: locked
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ready
                        ? 'Ready · tap to collect'
                        : pending
                            ? 'In progress'
                            : (rarityColor != null
                                ? (reward.rarity ?? '').toUpperCase()
                                : _typeCaption(reward.type)),
                    style: TextStyle(
                      fontSize: 8.5,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                      color: ready
                          ? AppColors.green
                          : pending
                              ? AppColors.orange
                              : (rarityColor ?? AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            if (ready)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green,
                ),
                child: const Icon(Icons.add_rounded,
                    size: 16, color: Colors.black),
              )
            else if (received)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: AppColors.green),
          ],
        ),
      ),
    );

    if (ready && onClaim != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onClaim,
        child: tile,
      );
    }
    return tile;
  }

  String _typeCaption(String type) {
    switch (type) {
      case 'SeasonXp':
        return 'SEASON XP';
      case 'Xp':
        return 'XP';
      case 'Item':
        return 'GEAR';
      case 'StreakShield':
        return 'UTILITY';
      case 'Title':
        return 'TITLE';
      case 'Cosmetic':
        return 'COSMETIC';
      default:
        return '';
    }
  }
}
