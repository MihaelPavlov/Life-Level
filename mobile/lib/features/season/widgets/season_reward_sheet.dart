import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../models/season_models.dart';
import 'season_theme.dart';

const _sheetRouteName = '_season_reward_sheet';

/// Lightweight reward confirmation for a claimed Season tile.
///
/// Slides up from the bottom, shows what was collected, and **auto-dismisses**
/// after a short delay — no "Continue" button — so a player can collect several
/// tiers in a row without tapping through a blocking modal each time. Tapping the
/// scrim or dragging it down dismisses it immediately. Claiming another tile
/// while one is still up replaces it rather than stacking.
Future<void> showSeasonRewardSheet(
    BuildContext context, SeasonClaimResult result) {
  final nav = Navigator.of(context);
  // Drop a previous reward sheet that hasn't auto-closed yet.
  nav.popUntil((r) => r.settings.name != _sheetRouteName);
  return showAppBottomSheet<void>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceElevated,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    routeSettings: const RouteSettings(name: _sheetRouteName),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _SeasonRewardSheet(result: result),
  );
}

class _SeasonRewardSheet extends StatefulWidget {
  final SeasonClaimResult result;
  const _SeasonRewardSheet({required this.result});

  @override
  State<_SeasonRewardSheet> createState() => _SeasonRewardSheetState();
}

class _SeasonRewardSheetState extends State<_SeasonRewardSheet>
    with SingleTickerProviderStateMixin {
  static const _visible = Duration(milliseconds: 2000);
  Timer? _dismiss;
  late final AnimationController _bar;

  @override
  void initState() {
    super.initState();
    _bar = AnimationController(vsync: this, duration: _visible)..forward();
    _dismiss = Timer(_visible, () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _dismiss?.cancel();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final isFounder = r.track == 'Founder';
    final accent = isFounder ? AppColors.orange : AppColors.green;

    final String value;
    if (r.xpAwarded > 0) {
      value = '+${r.xpAwarded} XP';
    } else if (r.grantedItemName != null) {
      value = r.grantedItemName!;
    } else {
      value = r.label;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: accent.withValues(alpha: 0.28),
                          blurRadius: 22),
                    ],
                  ),
                  child: Image.asset(
                    seasonIconAsset(_iconFor(r)),
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Text('🎫', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${r.track.toUpperCase()} · TIER ${r.tier} COLLECTED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r.xpAwarded > 0 ? 22 : 16,
                          fontWeight: FontWeight.w900,
                          color: accent,
                          height: 1.1,
                        ),
                      ),
                      if (r.label != value) ...[
                        const SizedBox(height: 2),
                        Text(
                          r.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Thin bar that depletes over the visible window — signals the
            // auto-dismiss without a button.
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: AnimatedBuilder(
                animation: _bar,
                builder: (_, __) => LinearProgressIndicator(
                  value: 1 - _bar.value,
                  minHeight: 3,
                  backgroundColor: AppColors.surface,
                  valueColor:
                      AlwaysStoppedAnimation(accent.withValues(alpha: 0.55)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _iconFor(SeasonClaimResult r) {
    if (r.grantedTitleKey != null) return 'title_marathoner';
    if (r.grantedItemName != null) return 'reward_treasure_chest';
    if (r.xpAwarded > 0) return 'reward_xp_sparkle';
    return 'reward_daily_bonus';
  }
}
