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

/// Compact identity header: Power and settings on top, then the avatar ring
/// with the level, name, class, equipped title and rank, then the XP bar.
class ProfileHeader extends ConsumerWidget {
  final CharacterProfile profile;
  final bool isAdmin;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.isAdmin = false,
  });

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

    return SizedBox(
      height: top + 206,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Opacity(
              opacity: .55,
              child: Image(
                image: AssetImage(AppIcons.homeSceneBg),
                fit: BoxFit.cover,
                alignment: Alignment(0, -.4),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x8C040810),
                    Color(0x59040810),
                    Color(0xFF040810),
                  ],
                  stops: [0, .45, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: top + 12,
            child: ProfileRise(
              delay: const Duration(milliseconds: 60),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .16)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIconImage(AppIcons.homePowerIcon, size: 20),
                        const SizedBox(width: 6),
                        Text('${profile.power}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.orange)),
                        const SizedBox(width: 5),
                        const Text('POWER',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: kPTextSec)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Settings',
                    child: GestureDetector(
                      onTap: () => _showSettings(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .16)),
                        ),
                        child: const Icon(Icons.settings_outlined,
                            size: 20, color: kPTextPri),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: top + 70,
            child: ProfileRise(
              delay: const Duration(milliseconds: 120),
              child: Row(
                children: [
                  _AvatarRing(
                    level: profile.level,
                    avatarAsset: avatarAsset,
                    avatarEmoji: profile.avatarEmoji,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: kPTextPri,
                                  shadows: [
                                    Shadow(
                                        color: Color(0xB3000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                              color: AppColors.orange,
                              icon: classAsset,
                              label: profile.className ?? 'Hero',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (titleName.isNotEmpty)
                              Semantics(
                                button: true,
                                label: 'Title $titleName. Change title',
                                child: GestureDetector(
                                  onTap: () =>
                                      ShellOverlayNotifier.open('titles'),
                                  child: _Chip(
                                    color: AppColors.purple,
                                    icon: titleAsset,
                                    label: titleName,
                                    pill: true,
                                    chevron: true,
                                  ),
                                ),
                              ),
                            _Chip(
                              color: AppColors.orange,
                              icon: rankAsset,
                              label: profile.rank.toUpperCase(),
                              pill: true,
                              spaced: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 10,
            child: ProfileRise(
              delay: const Duration(milliseconds: 200),
              child: _XpBar(profile: profile),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final int level;
  final String? avatarAsset;
  final String? avatarEmoji;
  const _AvatarRing({required this.level, this.avatarAsset, this.avatarEmoji});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [kPBlue, kPPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: kPBlue.withValues(alpha: .35), blurRadius: 18),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: kPSurface2),
              alignment: Alignment.center,
              child: avatarAsset != null
                  ? AppIconImage(avatarAsset!, size: 48, visualScale: 1.45)
                  : Text(avatarEmoji ?? '🧙',
                      style: const TextStyle(fontSize: 34)),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kPBlue, kPPurple]),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: kPBg, width: 2),
              ),
              child: Text('LV $level',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Color color;
  final String? icon;
  final String label;
  final bool pill;
  final bool chevron;
  final bool spaced;

  const _Chip({
    required this.color,
    required this.label,
    this.icon,
    this.pill = false,
    this.chevron = false,
    this.spaced = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = color == AppColors.purple ? const Color(0xFFC9A7FF) : color;
    return Container(
      padding: EdgeInsets.fromLTRB(icon != null ? 5 : 9, 3, 9, 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(pill ? 999 : 8),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIconImage(icon!, size: 16),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: spaced ? 1 : 0,
                    color: text)),
          ),
          if (chevron) ...[
            const SizedBox(width: 3),
            Icon(Icons.chevron_right_rounded, size: 14, color: text),
          ],
        ],
      ),
    );
  }
}

/// Level and XP bar; tapping it opens the XP history.
class _XpBar extends StatelessWidget {
  final CharacterProfile profile;
  const _XpBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Level ${profile.level}, ${profile.xp} of '
          '${profile.xpForNextLevel} XP. Open XP history',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showAppBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const XpHistorySheet(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('LEVEL ${profile.level}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kPBlue)),
                const Spacer(),
                Text(
                    '${fmtXp(profile.xp)} / ${fmtXp(profile.xpForNextLevel)} XP',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kPTextSec)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 8, color: kPSurface2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                        begin: 0,
                        end: profile.xpProgress.clamp(0.0, 1.0).toDouble()),
                    duration: AppMotion.duration(
                        context, const Duration(milliseconds: 1000)),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        height: 8,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [kPBlue, kPPurple]),
                        ),
                      ),
                    ),
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
