import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/avatar_icons.dart';
import '../../core/constants/class_icons.dart';
import '../../core/constants/title_rank_icons.dart';
import '../../core/motion/app_motion.dart';
import '../../core/services/shell_overlay_notifier.dart';
import '../../core/session/invalidate_user_providers.dart';
import '../../core/widgets/app_icon_image.dart';
import '../../core/widgets/resource_info_dialog.dart';
import '../activity/providers/activity_provider.dart';
import '../character/models/character_profile.dart';
import '../character/providers/character_provider.dart';
import '../integrations/screens/integrations_screen.dart';
import '../titles/providers/titles_provider.dart';
import '../unlocks/screens/explored_features_screen.dart';
import 'account_settings_screen.dart';
import 'edit_avatar_screen.dart';
import 'notification_preferences_screen.dart';
import 'profile_sections.dart';
import 'profile_stat_metadata.dart';
import 'tabs/admin_tab.dart';
import 'xp_history_sheet.dart';

/// Profile: one scrolling page. A compact header (avatar, name, class,
/// title, rank, Power, XP) over stats, personal records, talent bonuses and
/// the last 12 weeks. Settings (and Admin, for admins) sit behind the cog.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    ApiClient.isAdmin().then((v) {
      if (mounted && v) setState(() => _isAdmin = true);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(activityCalendarProvider);
    invalidateUserScopedProviders(ref);
    await ref.read(characterProfileProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(characterProfileProvider);
    final profile = profileAsync.valueOrNull;

    if (profile == null) {
      if (profileAsync.hasError) {
        return Scaffold(
          backgroundColor: kPBg,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Failed to load profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kPTextPri,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profileAsync.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: kPTextSec),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () =>
                        ref.read(characterProfileProvider.notifier).refresh(),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const Scaffold(
        backgroundColor: kPBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: kPBg,
      body: RefreshIndicator(
        color: AppColors.blue,
        backgroundColor: kPSurface,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            ProfileHeader(profile: profile, isAdmin: _isAdmin),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileRise(
                    delay: const Duration(milliseconds: 300),
                    child: ProfileStatsSection(profile: profile),
                  ),
                  const SizedBox(height: 22),
                  const ProfileRise(
                    delay: Duration(milliseconds: 400),
                    child: ProfileRecordsSection(),
                  ),
                  if (profile.talents?.hasAny ?? false) ...[
                    const SizedBox(height: 22),
                    ProfileRise(
                      delay: const Duration(milliseconds: 500),
                      child: ProfileTalentBonusesSection(
                          talents: profile.talents!),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const ProfileRise(
                    delay: Duration(milliseconds: 600),
                    child: ProfileWeeksSection(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact identity header (design: Profile Header Redesign, option D):
/// avatar with its XP ring, name, class and level, settings; then a strip of
/// three tiles for Power, Rank and the equipped title.
class ProfileHeader extends ConsumerWidget {
  final CharacterProfile profile;
  final bool isAdmin;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.isAdmin = false,
  });

  static const _powerInfo = ResourceInfoData(
    name: 'Power',
    icon: AppIcons.homePowerIcon,
    description:
        'Your overall combat rating from stats, equipped gear, and talents.',
    destination: 'Combat',
  );

  void _showSettings(BuildContext context) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161b22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SettingsSheet(parentContext: context, isAdmin: isAdmin),
    );
  }

  void _showXpHistory(BuildContext context) {
    showAppBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const XpHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.of(context).padding.top;
    final titles = ref.watch(titlesProvider).valueOrNull;
    final classAsset = classIconAsset(
      className: profile.className,
      classEmoji: profile.classEmoji,
    );
    final avatarAsset = avatarIconAsset(profile.avatarEmoji);
    final rankAsset = rankIconAsset(profile.rank);
    final titleName = titles?.activeTitleName ?? '';
    final titleAsset =
        titleName.isEmpty ? null : titleIconAsset(name: titleName);
    final xpLeft = profile.xpRemaining < 0 ? 0 : profile.xpRemaining;

    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0b1220), kPBg],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileRise(
            delay: const Duration(milliseconds: 60),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Level ${profile.level}, ${profile.xp} of '
                      '${profile.xpForNextLevel} XP. Open XP history',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showXpHistory(context),
                    child: _AvatarXpRing(
                      progress: profile.xpProgress.clamp(0.0, 1.0).toDouble(),
                      avatarAsset: avatarAsset,
                      avatarEmoji: profile.avatarEmoji,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kPTextPri,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (classAsset != null) ...[
                            AppIconImage(classAsset, size: 15),
                            const SizedBox(width: 5),
                          ],
                          Flexible(
                            child: Text(
                              '${profile.className ?? 'Hero'} · Level ${profile.level}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: kPTextSec),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showXpHistory(context),
                        child: Text(
                          '${fmtXp(xpLeft)} XP to level ${profile.level + 1}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kPTextSec),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Settings',
                  child: GestureDetector(
                    onTap: () => _showSettings(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kPSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPBorder),
                      ),
                      child: const Icon(Icons.settings_outlined,
                          size: 20, color: kPTextPri),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ProfileRise(
            delay: const Duration(milliseconds: 140),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatTile(
                      semanticLabel: 'Power ${profile.power}. What is Power',
                      icon: AppIcons.homePowerIcon,
                      value: '${profile.power}',
                      valueColor: kPGold,
                      label: 'POWER',
                      onTap: () => showResourceInfoDialog(context, _powerInfo),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      semanticLabel: 'Rank ${profile.rank}. Open titles and ranks',
                      icon: rankAsset,
                      value: profile.rank,
                      label: 'RANK',
                      onTap: () => ShellOverlayNotifier.open('titles'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      semanticLabel: titleName.isEmpty
                          ? 'No title equipped. Choose a title'
                          : 'Title $titleName. Change title',
                      icon: titleAsset,
                      fallbackIcon: Icons.workspace_premium_outlined,
                      value: titleName.isEmpty ? 'Choose' : titleName,
                      valueColor: const Color(0xFFC9A7FF),
                      valueSize: 13,
                      label: 'TITLE',
                      chevron: true,
                      onTap: () => ShellOverlayNotifier.open('titles'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar inside an XP progress ring (blue → purple).
class _AvatarXpRing extends StatelessWidget {
  final double progress;
  final String? avatarAsset;
  final String? avatarEmoji;
  const _AvatarXpRing(
      {required this.progress, this.avatarAsset, this.avatarEmoji});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration:
                AppMotion.duration(context, const Duration(milliseconds: 1000)),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(
              size: const Size(72, 72),
              painter: _XpRingPainter(v),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: kPSurface2),
            alignment: Alignment.center,
            child: avatarAsset != null
                ? AppIconImage(avatarAsset!, size: 40, visualScale: 1.45)
                : Text(avatarEmoji ?? '🧙',
                    style: const TextStyle(fontSize: 28)),
          ),
        ],
      ),
    );
  }
}

class _XpRingPainter extends CustomPainter {
  final double progress;
  _XpRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.shortestSide / 2 - 3);
    canvas.drawCircle(
        rect.center,
        rect.width / 2,
        Paint()
          ..color = kPSurface2
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    if (progress <= 0) return;
    canvas.drawArc(
        rect,
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        Paint()
          ..shader =
              const LinearGradient(colors: [kPBlue, kPPurple]).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _XpRingPainter old) => old.progress != progress;
}

/// One tile of the Power · Rank · Title strip.
class _StatTile extends StatelessWidget {
  final String semanticLabel;
  final String? icon;
  final IconData fallbackIcon;
  final String value;
  final Color valueColor;
  final double valueSize;
  final String label;
  final bool chevron;
  final VoidCallback onTap;

  const _StatTile({
    required this.semanticLabel,
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    this.fallbackIcon = Icons.military_tech_outlined,
    this.valueColor = kPTextPri,
    this.valueSize = 15,
    this.chevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kPSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kPBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon != null
                  ? AppIconImage(icon!, size: 28)
                  : Icon(fallbackIcon, size: 28, color: valueColor),
              const SizedBox(height: 8),
              Text(value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      color: valueColor)),
              const Spacer(),
              const SizedBox(height: 2),
              Text(chevron ? '$label ›' : label,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: kPTextSec)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends ConsumerWidget {
  final BuildContext parentContext;
  final bool isAdmin;

  const _SettingsSheet({required this.parentContext, this.isAdmin = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: kPBorder2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kPTextPri,
                    ),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.face_retouching_natural_outlined,
                label: 'Change Avatar',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    parentContext,
                    AppRoute(builder: (_) => const EditAvatarScreen()),
                  );
                },
              ),
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: kPBorder,
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                label: 'Email & Password',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    parentContext,
                    AppRoute(
                      builder: (_) => const AccountSettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: kPBorder,
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    parentContext,
                    AppRoute(
                      builder: (_) => const NotificationPreferencesScreen(),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: kPBorder,
              ),
              _SettingsTile(
                icon: Icons.cable_outlined,
                label: 'Integrations',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    parentContext,
                    AppRoute(
                      builder: (_) => const IntegrationsScreen(),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: kPBorder,
              ),
              _SettingsTile(
                icon: Icons.auto_stories_outlined,
                label: 'Tutorials',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    parentContext,
                    AppRoute(builder: (_) => const ExploredFeaturesScreen()),
                  );
                },
              ),
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: kPBorder,
              ),
              _SettingsTile(
                icon: Icons.animation_rounded,
                label: 'Motion & Feedback',
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!parentContext.mounted) return;
                    showAppBottomSheet<void>(
                      context: parentContext,
                      backgroundColor: const Color(0xFF161b22),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => const _MotionSettingsSheet(),
                    );
                  });
                },
              ),
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: kPBorder,
              ),
              if (isAdmin) ...[
                _SettingsTile(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      parentContext,
                      AppRoute(builder: (_) => const AdminScreen()),
                    );
                  },
                ),
                const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: kPBorder,
                ),
              ],
              _SettingsTile(
                icon: Icons.logout,
                label: 'Logout',
                labelColor: AppColors.red,
                iconColor: AppColors.red,
                onTap: () async {
                  Navigator.pop(context);
                  if (!parentContext.mounted) return;
                  await performLogout(parentContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotionSettingsSheet extends ConsumerWidget {
  const _MotionSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appMotionSettingsProvider);
    const descriptions = {
      AppMotionPreference.system: 'Follow your device accessibility setting',
      AppMotionPreference.full: 'Balanced transitions and celebration effects',
      AppMotionPreference.reduced: 'Short fades without sliding or scaling',
      AppMotionPreference.off: 'Show interface changes immediately',
    };
    const labels = {
      AppMotionPreference.system: 'System',
      AppMotionPreference.full: 'Full',
      AppMotionPreference.reduced: 'Reduced',
      AppMotionPreference.off: 'Off',
    };

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: kPBorder2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Motion & Feedback',
                style: TextStyle(
                  color: kPTextPri,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final preference in AppMotionPreference.values)
              RadioListTile<AppMotionPreference>(
                value: preference,
                groupValue: settings.preference,
                activeColor: AppColors.blue,
                title: Text(
                  labels[preference]!,
                  style: const TextStyle(
                    color: kPTextPri,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  descriptions[preference]!,
                  style: const TextStyle(color: kPTextSec, fontSize: 12),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  AppMotion.haptic(AppHaptic.selection);
                  ref.read(appMotionSettingsProvider).setPreference(value);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: iconColor ?? kPTextSec),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: labelColor ?? kPTextPri,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: iconColor ?? kPTextSec,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
