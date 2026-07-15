import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/title_rank_icons.dart';
import '../../core/widgets/app_icon_image.dart';
import 'profile_stat_metadata.dart';

// ── ProfileRankBadge ──────────────────────────────────────────────────────────
class ProfileRankBadge extends StatelessWidget {
  final String rank;
  final Color color;
  const ProfileRankBadge({super.key, required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    final iconAsset = rankIconAsset(rank);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            AppIconImage(
              iconAsset,
              size: 14,
              visualScale: 1.35,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            rank,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ProfileMiniCard ───────────────────────────────────────────────────────────
class ProfileMiniCard extends StatelessWidget {
  final String? iconAsset;
  final String emoji;
  final String label;
  final String value;
  final String sub;
  const ProfileMiniCard({
    super.key,
    this.iconAsset,
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kPSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconAsset != null)
                AppIconImage(
                  iconAsset!,
                  size: 14,
                  visualScale: 1.3,
                )
              else
                Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: kPTextSec,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kPTextPri,
            ),
          ),
          Text(sub, style: const TextStyle(fontSize: 9, color: kPTextSec)),
        ],
      ),
    );
  }
}

// ── ProfilePlaceholderTab ─────────────────────────────────────────────────────
class ProfilePlaceholderTab extends StatelessWidget {
  final String label;
  final String emoji;
  const ProfilePlaceholderTab(this.label, this.emoji, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kPTextPri,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coming soon',
            style: TextStyle(fontSize: 12, color: kPTextSec),
          ),
        ],
      ),
    );
  }
}

// ── ProfileSheetSection ───────────────────────────────────────────────────────
class ProfileSheetSection extends StatelessWidget {
  final String label;
  final Color color;
  final List<String> items;
  const ProfileSheetSection({
    super.key,
    required this.label,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items) ...[
          _buildProfileSheetItem(item),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildProfileSheetItem(String item) {
    final iconAsset = _profileSheetItemIconAsset(item);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: iconAsset != null
              ? AppIconImage(
                  iconAsset,
                  size: 14,
                  visualScale: 1.3,
                )
              : Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 5, right: 10),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _profileSheetItemLabel(item),
            style: const TextStyle(
              fontSize: 12,
              color: kPTextPri,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

String _profileSheetNormalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9+]+'), ' ').trim();

String _profileSheetItemLabel(String value) {
  return value.replaceFirst(RegExp(r'^[^\p{L}\p{N}+]+', unicode: true), '').trim();
}

String? _profileSheetItemIconAsset(String value) {
  final text = _profileSheetNormalize(value);

  if (text.contains('gym')) return AppIcons.activityGym;
  if (text.contains('climbing')) return AppIcons.activityClimbing;
  if (text.contains('weighted cycling')) return AppIcons.activityWeightlifting;
  if (text.contains('running')) return AppIcons.activityRunning;
  if (text.contains('cycling')) return AppIcons.activityCycling;
  if (text.contains('swimming')) return AppIcons.activitySwimming;
  if (text.contains('hiit')) return AppIcons.activityHiit;
  if (text.contains('yoga')) return AppIcons.activityYoga;
  if (text.contains('stretching')) return AppIcons.activityStretching;
  if (text.contains('mobility')) return AppIcons.activityMobility;
  if (text.contains('rest day')) return AppIcons.activityMobility;
  if (text.contains('daily login')) return AppIcons.rewardDailyBonus;
  if (text.contains('streak')) return AppIcons.rewardStreakFire;
  if (text.contains('damage')) return AppIcons.ringBoss;
  if (text.contains('boss')) return AppIcons.ringBoss;
  if (text.contains('map distance')) return AppIcons.mapCurrentLocation;
  if (text.contains('quests')) return AppIcons.questGeneral;
  if (text.contains('xp')) return AppIcons.rewardXpSparkle;
  if (text.contains('dodge')) return AppIcons.statAgility;
  if (text.contains('recovery')) return AppIcons.statFlexibility;
  if (text.contains('hp')) return AppIcons.statStamina;
  if (text.contains('armour')) return AppIcons.avatarWarrior;
  if (text.contains('warrior zones')) return AppIcons.classWarrior;
  if (text.contains('ocean of balance')) return AppIcons.zoneCoralCoast;
  if (text.contains('sprint challenges')) return AppIcons.activityHiit;
  if (text.contains('zen titles')) return AppIcons.ringTitles;
  if (text.contains('champion rank')) return AppIcons.rankChampion;

  return null;
}
