import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/season_models.dart';
import 'season_theme.dart';

/// A single reward tile — one of four states: received / locked / pending / ready.
/// Tapping a `ready` tile calls [onClaim].
class SeasonRewardSlot extends StatelessWidget {
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  seasonIconAsset(reward.iconKey),
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.card_giftcard_rounded,
                    size: 28,
                    color: AppColors.textMuted,
                  ),
                ),
                if (locked && !received)
                  const Positioned.fill(
                    child: Icon(Icons.lock_rounded,
                        size: 16, color: AppColors.textMuted),
                  ),
              ],
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
                      color: locked ? AppColors.textSecondary : AppColors.textPrimary,
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
                child: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
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
