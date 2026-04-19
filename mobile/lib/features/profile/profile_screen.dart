import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/session/invalidate_user_providers.dart';
import '../auth/login_screen.dart';
import '../character/models/character_profile.dart';
import '../character/providers/character_provider.dart';
import '../integrations/screens/integrations_screen.dart';
import 'profile_stat_metadata.dart';
import 'profile_widgets.dart';
import 'profile_overview_tab.dart';
import 'tabs/admin_tab.dart';
import 'tabs/equipment_tab.dart';
import 'tabs/achievements_tab.dart';
import 'tabs/inventory_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────
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

    // Wait for both admin check and profile load.
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kPTextPri),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profileAsync.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: kPTextSec),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => ref.read(characterProfileProvider.notifier).refresh(),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700),
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

    // Profile is available — show it. Silently refreshes in background.
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
                const EquipmentTab(),
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

// ── ProfileHeader ─────────────────────────────────────────────────────────────
class ProfileHeader extends StatelessWidget {
  final TabController tabController;
  final List<String> tabs;
  final CharacterProfile profile;
  const ProfileHeader({super.key, required this.tabController, required this.tabs, required this.profile});

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
    final titleText = '${profile.classEmoji ?? ''} ${profile.className ?? 'Hero'}'.trim();

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

          // ── avatar row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // avatar
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
                    child: Text(
                      profile.avatarEmoji ?? '🧙',
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // identity
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
                      // class badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPGold.withOpacity(0.10),
                          border: Border.all(color: kPGold.withOpacity(0.40)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          titleText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kPGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // rank + level sub-text
                      Row(
                        children: [
                          ProfileRankBadge(rank: profile.rank, color: rankAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Level ${profile.level}',
                            style: const TextStyle(fontSize: 11, color: kPTextSec),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // settings sheet
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
                    child: const Icon(Icons.settings_outlined, size: 18, color: kPTextSec),
                  ),
                ),
              ],
            ),
          ),

          // ── tab bar ────────────────────────────────────────────────
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
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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

// ── _SettingsSheet ─────────────────────────────────────────────────────────────
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
            // drag handle
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
                  MaterialPageRoute(builder: (_) => const IntegrationsScreen()),
                );
              },
            ),
            const Divider(height: 1, indent: 20, endIndent: 20, color: kPBorder),
            _SettingsTile(
              icon: Icons.logout,
              label: 'Logout',
              labelColor: AppColors.red,
              iconColor: AppColors.red,
              onTap: () async {
                // Capture the root Riverpod container BEFORE popping/navigating.
                // After pushAndRemoveUntil runs, this settings-sheet widget is
                // unmounted and its `ref` is no longer usable — but the root
                // ProviderContainer outlives any route transition, so we can
                // invalidate through it safely from a post-frame callback.
                final container = ProviderScope.containerOf(parentContext, listen: false);

                Navigator.pop(context);
                await ApiClient.clearToken();
                if (!parentContext.mounted) return;

                // Navigate FIRST, then invalidate. Invalidating while the old
                // MainShell is still mounted forces every watching widget
                // (including HomeAdventureHero's animated glow) to rebuild
                // into AsyncLoading during the route transition, which
                // visibly "pulses" the incoming LoginScreen. Pushing first
                // removes the old subtree so the transition plays cleanly,
                // then we clear any retained provider state one frame later.
                Navigator.of(parentContext).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  invalidateUserScopedProvidersFromContainer(container);
                });
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
      trailing: Icon(Icons.chevron_right, size: 18, color: iconColor ?? kPTextSec),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
