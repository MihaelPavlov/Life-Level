import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/avatar_icons.dart';
import '../../core/constants/class_icons.dart';
import '../../core/session/invalidate_user_providers.dart';
import '../../core/widgets/app_icon_image.dart';
import '../character/models/character_profile.dart';
import '../character/providers/character_provider.dart';
import '../integrations/screens/integrations_screen.dart';
import '../tutorial/screens/tutorials_hub_screen.dart';
import 'profile_overview_tab.dart';
import 'profile_stat_metadata.dart';
import 'profile_widgets.dart';
import 'tabs/achievements_tab.dart';
import 'tabs/admin_tab.dart';
import 'tabs/equipment_tab.dart';
import 'tabs/inventory_tab.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tab;
  bool _isAdmin = false;
  bool _adminChecked = false;

  @override
  void initState() {
    super.initState();
    _initAdmin();
  }

  Future<void> _initAdmin() async {
    final isAdmin = await ApiClient.isAdmin();
    if (!mounted) return;
    final count = kProfileTabs.length + (isAdmin ? 1 : 0);
    setState(() {
      _isAdmin = isAdmin;
      _adminChecked = true;
      _tab = TabController(length: count, vsync: this)
        ..addListener(() => setState(() {}));
    });
  }

  @override
  void dispose() {
    _tab?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(characterProfileProvider);
    final profile = profileAsync.valueOrNull;

    if (!_adminChecked || profile == null) {
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

    final tabs = [...kProfileTabs, if (_isAdmin) 'Admin'];

    return Scaffold(
      backgroundColor: kPBg,
      body: Column(
        children: [
          ProfileHeader(tabController: _tab!, tabs: tabs, profile: profile),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                ProfileOverviewTab(profile: profile),
                EquipmentTab(onOpenInventory: () => _tab?.animateTo(2)),
                const InventoryTab(),
                const AchievementsTab(),
                if (_isAdmin) const AdminTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final TabController tabController;
  final List<String> tabs;
  final CharacterProfile profile;

  const ProfileHeader({
    super.key,
    required this.tabController,
    required this.tabs,
    required this.profile,
  });

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161b22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SettingsSheet(parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final rankAccent = profileRankColor(profile.rank);
    final classAsset = classIconAsset(
      className: profile.className,
      classEmoji: profile.classEmoji,
    );
    final avatarAsset = avatarIconAsset(profile.avatarEmoji);
    final classText = profile.className ?? 'Hero';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF080e14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x104f9eff), Color(0x00040810)],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: top + 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [kPBlue, kPPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPBlue.withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: avatarAsset != null
                        ? AppIconImage(
                            avatarAsset,
                            size: 42,
                            visualScale: 1.45,
                          )
                        : Text(
                            profile.avatarEmoji ?? '🧙',
                            style: const TextStyle(fontSize: 30),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kPTextPri,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kPGold.withOpacity(0.10),
                          border: Border.all(color: kPGold.withOpacity(0.40)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (classAsset != null) ...[
                              AppIconImage(classAsset, size: 16),
                              const SizedBox(width: 8),
                            ] else if ((profile.classEmoji ?? '').isNotEmpty) ...[
                              Text(
                                profile.classEmoji!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              classText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kPGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          ProfileRankBadge(
                            rank: profile.rank,
                            color: rankAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Level ${profile.level}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kPTextSec,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showSettings(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kPBorder2),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: kPTextSec,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kPBorder)),
            ),
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: kPBlue,
              unselectedLabelColor: kPTextSec,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              indicatorColor: kPBlue,
              indicatorWeight: 2,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              tabs: tabs.map((t) => Tab(text: t, height: 36)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSheet extends ConsumerWidget {
  final BuildContext parentContext;

  const _SettingsSheet({required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
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
              icon: Icons.cable_outlined,
              label: 'Integrations',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(
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
                  MaterialPageRoute(builder: (_) => const TutorialsHubScreen()),
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
